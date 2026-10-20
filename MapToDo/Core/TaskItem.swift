import Foundation
import CoreLocation

enum ReminderMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard, silent, timeSensitive
    var id: String { rawValue }
    var title: String {
        switch self { case .standard: String(localized: "声音提醒"); case .silent: String(localized: "静音通知"); case .timeSensitive: String(localized: "时效性提醒") }
    }
}

enum TravelMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case walking, driving, transit
    var id: String { rawValue }
    var title: String {
        switch self { case .walking: String(localized: "步行"); case .driving: String(localized: "驾车"); case .transit: String(localized: "公共交通") }
    }
}

struct TaskItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var notes: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var scheduledAt: Date
    var durationMinutes: Int
    var isFlexible: Bool
    var flexibilityEnd: Date
    var reminderMinutes: Int
    var reminderMode: ReminderMode
    var isCompleted: Bool
    var createdAt: Date
    var timeZoneIdentifier: String
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var endDate: Date { scheduledAt.addingTimeInterval(Double(durationMinutes) * 60) }
    init(id: UUID = UUID(), title: String = "", notes: String = "", locationName: String = "", latitude: Double = 37.7749, longitude: Double = -122.4194, scheduledAt: Date = Date(), durationMinutes: Int = 30, isFlexible: Bool = false, flexibilityEnd: Date? = nil, reminderMinutes: Int = 15, reminderMode: ReminderMode = .standard, isCompleted: Bool = false, createdAt: Date = Date(), timeZoneIdentifier: String = TimeZone.current.identifier) {
        self.id = id; self.title = title; self.notes = notes; self.locationName = locationName
        self.latitude = latitude; self.longitude = longitude; self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes; self.isFlexible = isFlexible
        self.flexibilityEnd = flexibilityEnd ?? scheduledAt.addingTimeInterval(7200)
        self.reminderMinutes = reminderMinutes; self.reminderMode = reminderMode
        self.isCompleted = isCompleted; self.createdAt = createdAt; self.timeZoneIdentifier = timeZoneIdentifier
    }
    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return String(localized: "请填写事项名称。") }
        if !latitude.isFinite || !longitude.isFinite || !(-90...90).contains(latitude) || !(-180...180).contains(longitude) { return String(localized: "请选择有效的地图地点。") }
        if !(1...1440).contains(durationMinutes) { return String(localized: "事项时长应在 1 分钟至 24 小时之间。") }
        if isFlexible && flexibilityEnd < endDate { return String(localized: "可安排时间窗口不足以完成这件事。") }
        if TimeZone(identifier: timeZoneIdentifier) == nil { return String(localized: "事项时区无效，请重新选择时间。") }
        return nil
    }
}

/// Explicit task time zone, independent of the device's current time zone.
enum LocalTimeFormatter {
    static func string(_ date: Date, timeZoneIdentifier: String, includeDate: Bool = false) -> String {
        let zone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = zone
        formatter.dateStyle = includeDate ? .medium : .none
        formatter.timeStyle = .short
        return formatter.string(from: date) + " " + (zone.abbreviation(for: date) ?? zone.identifier)
    }
}
