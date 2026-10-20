import Foundation
import Combine
import CryptoKit
import UserNotifications

struct ReminderScheduleRecord: Codable, Equatable {
    let fireDate: Date
    let fingerprint: String
}

struct ReminderPlan {
    struct Entry {
        let task: TaskItem
        let fireDate: Date
    }
    let entries: [Entry]
    let overflowCount: Int
    static let identifierPrefix = "waypoint.task."

    static func openedTaskID(identifier: String, actionIdentifier: String, taskID: String?) -> UUID? {
        guard identifier.hasPrefix(identifierPrefix), actionIdentifier == UNNotificationDefaultActionIdentifier,
              let taskID, let id = UUID(uuidString: taskID), identifier == self.identifier(for: id) else { return nil }
        return id
    }

    static func identifier(for id: UUID) -> String { identifierPrefix + id.uuidString }

    static func fingerprint(for task: TaskItem) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(task) else { return "" }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func make(tasks: [TaskItem], now: Date = Date(), records: [UUID: ReminderScheduleRecord] = [:]) -> ReminderPlan {
        let eligible = tasks.compactMap { task -> Entry? in
            guard !task.isCompleted, task.reminderMinutes >= 0, task.scheduledAt > now else { return nil }
            if let record = records[task.id], record.fingerprint == fingerprint(for: task), record.fireDate <= now {
                return nil
            }
            let advanceDate = task.scheduledAt.addingTimeInterval(-Double(task.reminderMinutes) * 60)
            let fireDate = advanceDate > now ? advanceDate : task.scheduledAt
            return Entry(task: task, fireDate: fireDate)
        }.sorted {
            if $0.fireDate == $1.fireDate { return $0.task.id.uuidString < $1.task.id.uuidString }
            return $0.fireDate < $1.fireDate
        }
        return ReminderPlan(entries: Array(eligible.prefix(60)), overflowCount: max(0, eligible.count - 60))
    }
}

@MainActor
final class ReminderService: NSObject, ObservableObject {
    static let shared = ReminderService()
    @Published var openedTaskID: UUID?
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var timeSensitiveSetting: UNNotificationSetting = .notSupported
    @Published private(set) var scheduledCount = 0
    @Published private(set) var overflowCount = 0
    @Published private(set) var errorMessage: String?
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            Task { await synchronize(tasks: latestTasks) }
        }
    }
    private static let recordsKey = "reminders.scheduleRecords.v1"
    private var scheduleRecords: [UUID: ReminderScheduleRecord] = [:]
    private static let enabledKey = "reminders.enabled"
    private let center: UNUserNotificationCenter
    private var latestTasks: [TaskItem] = []
    private var revision: UInt = 0
    private var synchronizing = false

    private override init() {
        center = .current()
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: Self.recordsKey),
           let records = try? JSONDecoder().decode([UUID: ReminderScheduleRecord].self, from: data) {
            scheduleRecords = records
        }
        super.init()
        center.delegate = self
    }

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        timeSensitiveSetting = settings.timeSensitiveSetting
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            await synchronize(tasks: latestTasks)
            return granted
        } catch {
            errorMessage = String(localized: "无法请求通知权限：\(error.localizedDescription)")
            await refreshAuthorization()
            return false
        }
    }

    // Coalesce overlapping calls; the active loop always reconciles the newest snapshot.
    func synchronize(tasks: [TaskItem]) async {
        latestTasks = tasks
        revision &+= 1
        guard !synchronizing else { return }
        synchronizing = true
        defer { synchronizing = false }
        repeat {
            let currentRevision = revision
            let snapshot = latestTasks
            await refreshAuthorization()
            guard currentRevision == revision else { continue }
            let now = Date()
            let plan = ReminderPlan.make(tasks: snapshot, now: now, records: scheduleRecords)
            overflowCount = plan.overflowCount
            let allowed = authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
            let entries = isEnabled && allowed ? plan.entries : []
            let pending = await center.pendingNotificationRequests()
            guard currentRevision == revision else { continue }
            // Replace owned requests so every edit (time, text, mode) is reflected.
            let owned = pending.map(\.identifier).filter { $0.hasPrefix(ReminderPlan.identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: owned)
            let retainedIDs = Set(snapshot.map(\.id))
            // Preserve elapsed records even after taps/dismissals remove OS notifications.
            // All future requests are being replaced; retain records only after add succeeds.
            scheduleRecords = scheduleRecords.filter { id, record in
                retainedIDs.contains(id) && record.fireDate <= now
            }
            persistRecords()
            let delivered = await center.deliveredNotifications()
            guard currentRevision == revision else { continue }
            let validTasks = Dictionary(uniqueKeysWithValues: snapshot.filter { !$0.isCompleted && $0.reminderMinutes >= 0 }.map { (ReminderPlan.identifier(for: $0.id), $0) })
            let staleDelivered = delivered.compactMap { notification -> String? in
                let request = notification.request
                guard request.identifier.hasPrefix(ReminderPlan.identifierPrefix) else { return nil }
                guard isEnabled, let task = validTasks[request.identifier],
                      request.content.userInfo["taskFingerprint"] as? String == ReminderPlan.fingerprint(for: task) else { return request.identifier }
                return nil
            }
            center.removeDeliveredNotifications(withIdentifiers: staleDelivered)
            errorMessage = nil
            var count = 0
            for entry in entries {
                guard currentRevision == revision else { break }
                do {
                    try await center.add(Self.request(for: entry))
                    scheduleRecords[entry.task.id] = ReminderScheduleRecord(fireDate: entry.fireDate, fingerprint: ReminderPlan.fingerprint(for: entry.task))
                    persistRecords()
                    count += 1
                } catch {
                    errorMessage = String(localized: "部分提醒未能安排：\(error.localizedDescription)")
                }
            }
            if currentRevision == revision {
                scheduledCount = count
                return
            }
        } while true
    }

    private func persistRecords() {
        if let data = try? JSONEncoder().encode(scheduleRecords) {
            UserDefaults.standard.set(data, forKey: Self.recordsKey)
        }
    }

    private static func request(for entry: ReminderPlan.Entry) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = entry.task.title.isEmpty ? String(localized: "待办提醒") : entry.task.title
        content.body = entry.task.locationName.isEmpty ? String(localized: "该事项即将开始。") : String(localized: "地点：\(entry.task.locationName)")
        content.userInfo = ["taskID": entry.task.id.uuidString, "taskFingerprint": ReminderPlan.fingerprint(for: entry.task)]
        content.sound = entry.task.reminderMode == .silent ? nil : .default
        content.interruptionLevel = entry.task.reminderMode == .timeSensitive ? .timeSensitive : (entry.task.reminderMode == .silent ? .passive : .active)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entry.fireDate)
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: ReminderPlan.identifier(for: entry.task.id), content: content, trigger: trigger)
    }
}

extension ReminderService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let request = response.notification.request
        let id = ReminderPlan.openedTaskID(identifier: request.identifier, actionIdentifier: response.actionIdentifier, taskID: request.content.userInfo["taskID"] as? String)
        if let id {
            Task { @MainActor in self.openedTaskID = id }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        var options: UNNotificationPresentationOptions = [.banner, .list]
        if notification.request.content.sound != nil { options.insert(.sound) }
        completionHandler(options)
    }
}
