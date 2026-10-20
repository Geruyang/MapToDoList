import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case text, markdown, ics
    var id: String { rawValue }
    var title: String {
        switch self { case .text: return String(localized: "纯文本"); case .markdown: return String(localized: "Markdown"); case .ics: return String(localized: "日历 ICS") }
    }
    var fileExtension: String { self == .ics ? "ics" : self == .markdown ? "md" : "txt" }
}

enum ExportFormatter {
    static func filtered(_ tasks: [TaskItem], from start: Date, through end: Date, calendar: Calendar = .current) -> [TaskItem] {
        let lower = calendar.startOfDay(for: start)
        guard let upper = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)), upper > lower else { return [] }
        return tasks.filter { $0.scheduledAt >= lower && $0.scheduledAt < upper }.sorted {
            $0.scheduledAt == $1.scheduledAt ? $0.id.uuidString < $1.id.uuidString : $0.scheduledAt < $1.scheduledAt
        }
    }

    static func render(_ tasks: [TaskItem], format: ExportFormat, generatedAt: Date = Date()) -> String {
        if format == .ics { return calendar(tasks, generatedAt: generatedAt) }
        return tasks.map { task in
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.timeZone = TimeZone(identifier: task.timeZoneIdentifier) ?? .current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let time = formatter.string(from: task.scheduledAt) + " – " + formatter.string(from: task.endDate) + " (" + formatter.timeZone.identifier + ")"
            let location = task.locationName.isEmpty ? String(localized: "未命名地点") : task.locationName
            let coordinates = String(format: "%.6f, %.6f", locale: Locale(identifier: "en_US_POSIX"), task.latitude, task.longitude)
            if format == .markdown {
                return String(localized: "- [\(task.isCompleted ? "x" : " ")] \(markdown(task.title))\n  - 时间：\(time)\n  - 地点：\(markdown(location))（\(coordinates)）") + (task.notes.isEmpty ? "" : String(localized: "\n  - 备注：") + markdown(task.notes).replacingOccurrences(of: "\n", with: "\n    "))
            }
            return String(localized: "\(task.isCompleted ? "✓" : "○") \(task.title)\n时间：\(time)\n地点：\(location)（\(coordinates)）") + (task.notes.isEmpty ? "" : String(localized: "\n备注：\(task.notes)"))
        }.joined(separator: "\n\n")
    }

    private static func markdown(_ value: String) -> String {
        value.reduce(into: "") { result, character in
            if "\\`*_{}[]<>#|".contains(character) { result.append("\\") }
            result.append(character)
        }
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
    }

    private static func fold(_ line: String) -> String {
        var result = "", count = 0
        for scalar in line.unicodeScalars {
            let value = String(scalar)
            if count + value.utf8.count > 75 { result += "\r\n "; count = 1 }
            result += value
            count += value.utf8.count
        }
        return result
    }

    private static func calendar(_ tasks: [TaskItem], generatedAt: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Waypoint//MapToDo//ZH", "CALSCALE:GREGORIAN", "METHOD:PUBLISH"]
        for task in tasks {
            lines += ["BEGIN:VEVENT", "UID:\(task.id.uuidString)@waypoint.local", "DTSTAMP:\(formatter.string(from: generatedAt))", "DTSTART:\(formatter.string(from: task.scheduledAt))", "DTEND:\(formatter.string(from: task.endDate))", "SUMMARY:\(escape(task.title))", "LOCATION:\(escape(task.locationName))", "DESCRIPTION:\(escape(task.notes))", String(format: "GEO:%.6f;%.6f", locale: Locale(identifier: "en_US_POSIX"), task.latitude, task.longitude), "STATUS:CONFIRMED", "END:VEVENT"]
        }
        lines += ["END:VCALENDAR"]
        return lines.map(fold).joined(separator: "\r\n") + "\r\n"
    }
}
