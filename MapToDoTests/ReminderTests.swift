import XCTest
import UserNotifications
@testable import MapToDo

final class ReminderTests: XCTestCase {
    func testNotificationTapAcceptsOwnedMatchingDefaultAction() {
        let id = UUID()
        XCTAssertEqual(ReminderPlan.openedTaskID(identifier: ReminderPlan.identifier(for: id), actionIdentifier: UNNotificationDefaultActionIdentifier, taskID: id.uuidString), id)
    }

    func testNotificationTapRejectsOtherActionsAndInvalidPayloads() {
        let id = UUID()
        let identifier = ReminderPlan.identifier(for: id)
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: "other." + id.uuidString, actionIdentifier: UNNotificationDefaultActionIdentifier, taskID: id.uuidString))
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: identifier, actionIdentifier: UNNotificationDismissActionIdentifier, taskID: id.uuidString))
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: identifier, actionIdentifier: "custom", taskID: id.uuidString))
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: identifier, actionIdentifier: UNNotificationDefaultActionIdentifier, taskID: "invalid"))
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: identifier, actionIdentifier: UNNotificationDefaultActionIdentifier, taskID: nil))
        XCTAssertNil(ReminderPlan.openedTaskID(identifier: identifier, actionIdentifier: UNNotificationDefaultActionIdentifier, taskID: UUID().uuidString))
    }

    func testOnlyFutureEnabledIncompleteTasksAreScheduled() {
        let now = Date(timeIntervalSince1970: 1_000)
        let future = TaskItem(title: "Future", scheduledAt: now.addingTimeInterval(600), reminderMinutes: 5)
        let disabled = TaskItem(scheduledAt: now.addingTimeInterval(600), reminderMinutes: -1)
        let completed = TaskItem(scheduledAt: now.addingTimeInterval(600), reminderMinutes: 0, isCompleted: true)
        let past = TaskItem(scheduledAt: now.addingTimeInterval(-60), reminderMinutes: 5)
        let plan = ReminderPlan.make(tasks: [disabled, completed, past, future], now: now)
        XCTAssertEqual(plan.entries.map(\.task.id), [future.id])
        XCTAssertEqual(plan.entries.first?.fireDate, now.addingTimeInterval(300))
    }


    func testElapsedAdvanceReminderFallsBackToFutureTaskStart() {
        let now = Date(timeIntervalSince1970: 1_000)
        let task = TaskItem(scheduledAt: now.addingTimeInterval(300), reminderMinutes: 15)
        let plan = ReminderPlan.make(tasks: [task], now: now)
        XCTAssertEqual(plan.entries.map(\.task.id), [task.id])
        XCTAssertEqual(plan.entries.first?.fireDate, task.scheduledAt)
    }

    func testPreviouslyScheduledAdvanceDoesNotRepeatAfterTriggerEvenWithoutDeliveredNotification() {
        let start = Date(timeIntervalSince1970: 10_000)
        let task = TaskItem(scheduledAt: start, reminderMinutes: 15)
        let record = ReminderScheduleRecord(fireDate: start.addingTimeInterval(-900), fingerprint: ReminderPlan.fingerprint(for: task))
        XCTAssertTrue(ReminderPlan.make(tasks: [task], now: start.addingTimeInterval(-840), records: [task.id: record]).entries.isEmpty)
        let restored = try! JSONDecoder().decode([UUID: ReminderScheduleRecord].self, from: JSONEncoder().encode([task.id: record]))
        XCTAssertTrue(ReminderPlan.make(tasks: [task], now: start.addingTimeInterval(-840), records: restored).entries.isEmpty)
    }

    func testEditedPreviouslyRemindedTaskCanScheduleAgain() {
        let start = Date(timeIntervalSince1970: 10_000)
        var task = TaskItem(scheduledAt: start, reminderMinutes: 15)
        let record = ReminderScheduleRecord(fireDate: start.addingTimeInterval(-900), fingerprint: ReminderPlan.fingerprint(for: task))
        task.title = "Updated"
        let plan = ReminderPlan.make(tasks: [task], now: start.addingTimeInterval(-840), records: [task.id: record])
        XCTAssertEqual(plan.entries.first?.fireDate, start)
        XCTAssertEqual(ReminderPlan.fingerprint(for: task).count, 64)
    }

    func testStartedAndPastTasksAreNotScheduled() {
        let now = Date(timeIntervalSince1970: 1_000)
        let started = TaskItem(scheduledAt: now, reminderMinutes: 15)
        let past = TaskItem(scheduledAt: now.addingTimeInterval(-60), reminderMinutes: 0)
        XCTAssertTrue(ReminderPlan.make(tasks: [started, past], now: now).entries.isEmpty)
    }

    func testNearestSixtyAreRetainedAndOverflowReported() {
        let now = Date(timeIntervalSince1970: 1_000)
        let tasks = (1...65).reversed().map { TaskItem(scheduledAt: now.addingTimeInterval(Double($0 * 60)), reminderMinutes: 0) }
        let plan = ReminderPlan.make(tasks: tasks, now: now)
        XCTAssertEqual(plan.entries.count, 60)
        XCTAssertEqual(plan.overflowCount, 5)
        XCTAssertEqual(plan.entries.first?.fireDate, now.addingTimeInterval(60))
        XCTAssertEqual(plan.entries.last?.fireDate, now.addingTimeInterval(3_600))
    }

    func testIdentifierSurvivesEditingAndCompletedTaskIsRemoved() {
        let now = Date(timeIntervalSince1970: 1_000)
        var task = TaskItem(scheduledAt: now.addingTimeInterval(600), reminderMinutes: 0)
        let identifier = ReminderPlan.identifier(for: task.id)
        task.scheduledAt = now.addingTimeInterval(1_200)
        XCTAssertEqual(ReminderPlan.identifier(for: task.id), identifier)
        task.isCompleted = true
        XCTAssertTrue(ReminderPlan.make(tasks: [task], now: now).entries.isEmpty)
    }
}
