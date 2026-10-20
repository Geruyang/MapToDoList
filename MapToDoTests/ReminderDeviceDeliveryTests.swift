import XCTest
import UIKit
import UserNotifications
@testable import MapToDo

/// Explicitly opted-in, app-hosted real-device service integration tests.
/// DEBUG host automatic store reconciliation is excluded; this does not certify
/// full App lifecycle synchronization. No permission requests or subscription claims.
@MainActor
final class ReminderDeviceDeliveryTests: XCTestCase {
    private let center = UNUserNotificationCenter.current()
    private var isolatedIDs: [UUID] = []
    private var temporaryDirectory: URL?
    private var prepared = false

    override func tearDown() async throws {
        if prepared {
            // Preparation requires an empty real store and no owned system requests.
            await ReminderService.shared.synchronize(tasks: [])
            let identifiers = isolatedIDs.map { ReminderPlan.identifier(for: $0) }
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
        if let temporaryDirectory { try? FileManager.default.removeItem(at: temporaryDirectory) }
        try await super.tearDown()
    }

    private func prepare(delivery: Bool = false) async throws -> TaskStore {
        guard ProcessInfo.processInfo.environment["WAYPOINT_RUN_NOTIFICATION_DEVICE_TESTS"] == "1" else {
            throw XCTSkip("Real notification tests require root's explicit device-test opt-in.")
        }
        guard ProcessInfo.processInfo.environment["WAYPOINT_NOTIFICATION_DEVICE_TEST_OWNS_SYNC"] == "1" else {
            throw XCTSkip("DEBUG host automatic reminder synchronization must be isolated so the test is the sole synchronization owner.")
        }
        #if targetEnvironment(simulator)
        throw XCTSkip("This acceptance test requires an actual iPhone, not a simulator.")
        #endif
        let settings = await center.notificationSettings()
        let diagnostic: [String: Any] = [
            "hostBundleIdentifier": Bundle.main.bundleIdentifier ?? "unknown",
            "testBundleIdentifier": Bundle(for: Self.self).bundleIdentifier ?? "unknown",
            "authorizationStatus": settings.authorizationStatus.rawValue,
            "alertSetting": settings.alertSetting.rawValue,
            "notificationCenterSetting": settings.notificationCenterSetting.rawValue,
            "timeSensitiveSetting": settings.timeSensitiveSetting.rawValue,
            "applicationState": UIApplication.shared.applicationState.rawValue
        ]
        let diagnosticData = try JSONSerialization.data(withJSONObject: diagnostic, options: [.sortedKeys, .prettyPrinted])
        let attachment = XCTAttachment(data: diagnosticData, uniformTypeIdentifier: "public.json")
        attachment.name = "Notification permission context (no private payload)"
        attachment.lifetime = .keepAlways
        add(attachment)
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            throw XCTSkip("Notification permission is denied/undetermined; no prompt or permission reset will be performed.")
        }
        guard ReminderService.shared.isEnabled else {
            throw XCTSkip("User has disabled reminders; test will not change that preference.")
        }
        let productionStore = TaskStore(arguments: [])
        guard productionStore.errorMessage == nil else {
            throw XCTSkip("Personal data could not be read; an empty decoded view is not proof of safe isolation.")
        }
        guard productionStore.tasks.isEmpty else {
            throw XCTSkip("Production reminder reconciliation replaces owned requests; personal tasks exist, so isolation is not safe.")
        }
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        guard !pending.contains(where: { $0.identifier.hasPrefix(ReminderPlan.identifierPrefix) }),
              !delivered.contains(where: { $0.request.identifier.hasPrefix(ReminderPlan.identifierPrefix) }) else {
            throw XCTSkip("Existing owned pending/delivered notifications must be preserved; use an approved isolated app container.")
        }
        if delivery {
            guard ProcessInfo.processInfo.environment["WAYPOINT_NOTIFICATION_FOCUS_OFF_CONFIRMED"] == "1" else {
                throw XCTSkip("User must confirm baseline Focus/DND is off; current DND-on state is not delivery evidence.")
            }
            guard settings.alertSetting == .enabled, settings.notificationCenterSetting == .enabled,
                  UIApplication.shared.applicationState == .active else {
                throw XCTSkip("Foreground alert/Notification Center permissions and an active app are required.")
            }
        }
        // Explicit DEBUG host ownership disables only automatic App reminder sync.
        // The test still exercises the production service, delegate and real UN center;
        // no repeat scheduling or settle sleep is used to hide conflicting snapshots.
        await ReminderService.shared.synchronize(tasks: [])
        let baseline = await center.pendingNotificationRequests()
        XCTAssertFalse(baseline.contains { $0.identifier.hasPrefix(ReminderPlan.identifierPrefix) })
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ReminderDevice-" + UUID().uuidString)
        temporaryDirectory = directory
        prepared = true
        return TaskStore(fileURL: directory.appendingPathComponent("tasks.json"), arguments: [])
    }

    private func task(after seconds: TimeInterval, advance: Int = 0) -> TaskItem {
        let item = TaskItem(title: "FICTIONAL REMINDER TEST " + UUID().uuidString,
                            locationName: "Fictional test location", scheduledAt: Date().addingTimeInterval(seconds),
                            reminderMinutes: advance, reminderMode: .silent)
        isolatedIDs.append(item.id)
        return item
    }

    private func ownedPending() async -> [UNNotificationRequest] {
        let ids = Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) })
        return await center.pendingNotificationRequests().filter { ids.contains($0.identifier) }
    }

    private func ownedDelivered() async -> [UNNotification] {
        let ids = Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) })
        return await center.deliveredNotifications().filter { ids.contains($0.request.identifier) }
    }

    private func awaitPendingIDs(_ expected: Set<String>) async throws -> [UNNotificationRequest] {
        let deadline = Date().addingTimeInterval(5)
        repeat {
            guard UIApplication.shared.applicationState == .active else {
                throw XCTSkip("Host left foreground; this execution cannot certify the foreground notification scope.")
            }
            let requests = await ownedPending()
            if Set(requests.map(\.identifier)) == expected { return requests }
            // Bounded observable polling, not a fixed settle delay. It never re-schedules
            // fixtures to mask a conflicting host synchronize(empty) call.
            try await Task.sleep(for: .milliseconds(100))
        } while Date() < deadline
        XCTFail("Expected isolated pending IDs were not observed; host reconciliation interference or scheduling failure is not delivery PASS.")
        return await ownedPending()
    }

    func testActualPendingEditDeleteAndCompletionReconciliation() async throws {
        let store = try await prepare()
        var edited = task(after: 300)
        let deleted = task(after: 300)
        let completed = task(after: 300)
        [edited, deleted, completed].forEach { store.upsert($0) }
        XCTAssertNil(store.errorMessage)
        await ReminderService.shared.synchronize(tasks: store.tasks)
        let initial = try await awaitPendingIDs(Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) }))
        XCTAssertEqual(Set(initial.map(\.identifier)), Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) }))
        edited.title += " EDITED"
        edited.scheduledAt = Date().addingTimeInterval(600)
        store.upsert(edited)
        store.remove(deleted.id)
        store.toggleCompletion(completed.id)
        await ReminderService.shared.synchronize(tasks: store.tasks)
        let remaining = try await awaitPendingIDs([ReminderPlan.identifier(for: edited.id)])
        XCTAssertEqual(remaining.count, 1)
        let request = try XCTUnwrap(remaining.first)
        XCTAssertEqual(request.identifier, ReminderPlan.identifier(for: edited.id))
        XCTAssertEqual(request.content.title, edited.title)
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        let fireDate = try XCTUnwrap(trigger.nextTriggerDate())
        XCTAssertEqual(fireDate.timeIntervalSince1970, edited.scheduledAt.timeIntervalSince1970, accuracy: 1)
        XCTAssertNil(ReminderService.shared.errorMessage)
    }

    func testActualForegroundDeliveryDedupAndDeliveredEditDeleteCompletionCleanup() async throws {
        let store = try await prepare(delivery: true)
        var edited = task(after: 66, advance: 1) // Real advance alert at roughly +6 seconds; start stays future.
        let deleted = task(after: 66, advance: 1)
        let completed = task(after: 66, advance: 1)
        let dismissed = task(after: 66, advance: 1)
        [edited, deleted, completed, dismissed].forEach { store.upsert($0) }
        await ReminderService.shared.synchronize(tasks: store.tasks)
        let initial = try await awaitPendingIDs(Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) }))
        XCTAssertEqual(initial.count, 4)
        let deadline = Date().addingTimeInterval(30)
        var observed: [UNNotification] = []
        repeat {
            guard UIApplication.shared.applicationState == .active else {
                XCTFail("App left foreground; this run cannot certify foreground delivery.")
                return
            }
            observed = await ownedDelivered()
            if observed.count == 4 { break }
            try await Task.sleep(for: .milliseconds(500))
        } while Date() < deadline
        XCTAssertEqual(Set(observed.map { $0.request.identifier }), Set(isolatedIDs.map { ReminderPlan.identifier(for: $0) }), "OS delivery must be observed, not inferred from scheduling.")
        guard observed.count == 4 else { return }
        // Simulate Notification Center dismissal, then activate-style reconciliation.
        center.removeDeliveredNotifications(withIdentifiers: [ReminderPlan.identifier(for: dismissed.id)])
        await ReminderService.shared.synchronize(tasks: store.tasks)
        let afterDismissal = await ownedPending()
        XCTAssertTrue(afterDismissal.isEmpty, "Previously triggered unchanged advance alerts must not be requeued at task start.")
        edited.title += " EDITED AFTER DELIVERY"
        edited.scheduledAt = Date().addingTimeInterval(300)
        store.upsert(edited)
        store.remove(deleted.id)
        store.toggleCompletion(completed.id)
        await ReminderService.shared.synchronize(tasks: store.tasks)
        // UN removals are asynchronous; poll observable state for a bounded interval.
        let cleanupDeadline = Date().addingTimeInterval(5)
        var leftovers = await ownedDelivered()
        while !leftovers.isEmpty && Date() < cleanupDeadline {
            try await Task.sleep(for: .milliseconds(200))
            leftovers = await ownedDelivered()
        }
        XCTAssertTrue(leftovers.isEmpty)
        let updated = try await awaitPendingIDs([ReminderPlan.identifier(for: edited.id)])
        XCTAssertEqual(updated.map(\.identifier), [ReminderPlan.identifier(for: edited.id)])
        XCTAssertEqual(updated.first?.content.title, edited.title)
        XCTAssertNil(ReminderService.shared.errorMessage)
        // Does not establish physical sound, background/locked delivery, real tap navigation,
        // persistence across process restart, or subscription access. Those remain separate checks.
    }
}
