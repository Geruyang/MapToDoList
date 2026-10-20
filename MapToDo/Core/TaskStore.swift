import Foundation
import Combine

@MainActor final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published var errorMessage: String?
    private let fileURL: URL
    private var isReadOnly = false

    init(fileURL: URL? = nil, arguments: [String] = ProcessInfo.processInfo.arguments) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var filename = "tasks-v1.json"
        #if DEBUG
        if arguments.contains("--uitesting") { filename = "ui-testing-tasks-v1.json" }
        #endif
        self.fileURL = fileURL ?? base.appendingPathComponent("Waypoint", isDirectory: true).appendingPathComponent(filename)
        #if DEBUG
        if fileURL == nil && arguments.contains("--uitesting") && arguments.contains("--reset-data") {
            try? FileManager.default.removeItem(at: self.fileURL)
        }
        #endif
        load()
        #if DEBUG
        if fileURL == nil && arguments.contains("--uitesting") && arguments.contains("--seed-demo") && tasks.isEmpty && !isReadOnly {
            persist(Self.demoTasks())
        }
        #endif
    }
    func upsert(_ item: TaskItem) {
        if let message = item.validationMessage { errorMessage = message; return }
        var next = tasks
        if let index = next.firstIndex(where: { $0.id == item.id }) { next[index] = item } else { next.append(item) }
        persist(next)
    }
    func remove(_ id: UUID) { persist(tasks.filter { $0.id != id }) }
    func toggleCompletion(_ id: UUID) {
        var next = tasks
        guard let index = next.firstIndex(where: { $0.id == id }) else { return }
        next[index].isCompleted.toggle()
        persist(next)
    }
    func replaceSchedule(_ changes: [UUID: Date]) {
        var next = tasks
        for (id, date) in changes {
            guard let index = next.firstIndex(where: { $0.id == id }), next[index].isFlexible,
                  date >= next[index].scheduledAt,
                  date.addingTimeInterval(Double(next[index].durationMinutes) * 60) <= next[index].flexibilityEnd else {
                errorMessage = String(localized: "方案包含固定事项变更或超出可安排时间，请重新规划。")
                return
            }
            next[index].scheduledAt = date
        }
        persist(next)
    }
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let decoded = try JSONDecoder().decode([TaskItem].self, from: Data(contentsOf: fileURL))
            guard Set(decoded.map(\.id)).count == decoded.count, decoded.allSatisfy({ $0.validationMessage == nil }) else { throw CocoaError(.coderReadCorrupt) }
            tasks = decoded.sorted { $0.scheduledAt < $1.scheduledAt }
        } catch {
            isReadOnly = true
            errorMessage = String(localized: "无法读取已保存的事项。原始文件已保留，暂时停止写入以保护数据。")
        }
    }
    private func persist(_ next: [TaskItem]) {
        guard !isReadOnly else { errorMessage = String(localized: "原始数据需要恢复，尚未保存新的修改。"); return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(next)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            tasks = next.sorted { $0.scheduledAt < $1.scheduledAt }
            errorMessage = nil
        } catch { errorMessage = String(localized: "保存失败：\(error.localizedDescription)。请检查设备剩余空间。") }
    }
    #if DEBUG
    static func demoTasks() -> [TaskItem] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date())
        func hour(_ value: Int) -> Date { calendar.date(byAdding: .hour, value: value, to: day)! }
        return [
            TaskItem(title: "街角咖啡，慢慢开始", notes: "带上笔记本，整理这周的灵感。", locationName: "武康路", latitude: 31.2108, longitude: 121.4387, scheduledAt: hour(10), durationMinutes: 45),
            TaskItem(title: "去书店寻找新灵感", notes: "看看旅行和设计的新书。", locationName: "上海图书馆", latitude: 31.2075, longitude: 121.4435, scheduledAt: hour(13), durationMinutes: 60, isFlexible: true, flexibilityEnd: hour(17)),
            TaskItem(title: "和朋友吃一顿晚餐", locationName: "静安寺", latitude: 31.2231, longitude: 121.4453, scheduledAt: hour(18), durationMinutes: 90)
        ]
    }
    #endif
}
