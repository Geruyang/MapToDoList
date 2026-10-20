import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ExportView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var start = Calendar.current.startOfDay(for: Date())
    @State private var end = Calendar.current.startOfDay(for: Date())
    @State private var format: ExportFormat = .text
    @State private var copied = false
    @State private var shareFile: ExportShareFile?
    @State private var activeShareURL: URL?
    @State private var errorMessage: String?

    private var selected: [TaskItem] { ExportFormatter.filtered(store.tasks, from: start, through: end) }
    private var preview: String { ExportFormatter.render(selected, format: format) }

    var body: some View {
        Form {
            Section {
                DatePicker("开始日期", selection: $start, displayedComponents: .date)
                    .accessibilityIdentifier("export.start")
                    .onChange(of: start) { _, value in if end < value { end = value } }
                DatePicker("结束日期", selection: $end, in: start..., displayedComponents: .date)
                    .accessibilityIdentifier("export.end")
            } header: { Text("导出日期范围") } footer: {
                Text("包含结束日期全天，以设备时区 \(TimeZone.current.identifier) 筛选。每项显示所在地时间。")
            }
            Section("格式") {
                Picker("导出格式", selection: $format) {
                    ForEach(ExportFormat.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.menu)
                    .accessibilityIdentifier("export.format")
                Label("已选 \(selected.count) 项事项", systemImage: "checklist")
                    .accessibilityIdentifier("export.count")
            }
            Section("内容预览") {
                if selected.isEmpty {
                    ContentUnavailableView("此范围没有事项", systemImage: "calendar.badge.exclamationmark", description: Text("调整日期范围后即可导出。"))
                } else {
                    Text(preview).font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("export.preview")
                }
            }
            Section {
                Button {
                    UIPasteboard.general.string = preview
                    copied = true
                } label: { Label(copied ? String(localized: "已复制") : String(localized: "复制内容"), systemImage: copied ? "checkmark" : "doc.on.doc") }
                    .accessibilityIdentifier("export.copy")
                Button { prepareShare() } label: { Label("分享文件", systemImage: "square.and.arrow.up") }
                    .accessibilityIdentifier("export.share")
            }.disabled(selected.isEmpty)
        }
        .navigationTitle("导出事项")
        .onChange(of: preview) { _, _ in copied = false }
        .sheet(item: $shareFile, onDismiss: cleanUpShare) { file in
            ExportActivityView(url: file.url) { shareFile = nil }
        }
        .alert("无法导出文件", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func prepareShare() {
        guard shareFile == nil else { return }
        cleanUpShare()
        do {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("WaypointExports", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            // Recover older files left behind by an interrupted process without
            // removing a recent export that another window could be sharing.
            for oldURL in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]) {
                let modified = try oldURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                if let modified, modified < Date().addingTimeInterval(-86_400) {
                    try? FileManager.default.removeItem(at: oldURL)
                }
            }
            let url = directory.appendingPathComponent("Waypoint-\(UUID().uuidString.prefix(8)).\(format.fileExtension)")
            try Data(preview.utf8).write(to: url, options: [.atomic, .completeFileProtection])
            activeShareURL = url
            shareFile = ExportShareFile(url: url)
        } catch { errorMessage = error.localizedDescription }
    }

    private func cleanUpShare() {
        if let activeShareURL { try? FileManager.default.removeItem(at: activeShareURL) }
        activeShareURL = nil
    }
}

private struct ExportShareFile: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ExportActivityView: UIViewControllerRepresentable {
    let url: URL
    let onCompletion: () -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.async { onCompletion() }
        }
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
