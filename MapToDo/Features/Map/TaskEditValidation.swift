import Foundation

enum TaskEditValidation {
    static func error(title: String, latitude: Double, longitude: Double, start: Date, flexible: Bool, latest: Date, duration: Int) -> String? {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return String(localized: "请填写事项标题") }
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else { return String(localized: "请选择有效地点") }
        guard duration > 0 else { return String(localized: "时长必须大于零") }
        if flexible && latest < start.addingTimeInterval(Double(duration) * 60) { return String(localized: "最晚结束时间需容纳事项时长") }
        return nil
    }
}
