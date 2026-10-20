import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var editorDestination: TaskEditorDestination?
    @State private var showingExport = false
    @State private var showingSubscription = false
    @State private var showingCompleted = true
    @State private var pendingDeletion: TaskItem?
    // Real scrollable tail space, rather than a scroll-view inset. Floating
    // system tabs can overlap content even when it nearly fits the viewport.
    @ScaledMetric(relativeTo: .headline) private var bottomContentClearance = 80.0
    private var today: [TaskItem] { store.tasks.filter { Calendar.current.isDateInToday($0.scheduledAt) }.sorted { $0.scheduledAt < $1.scheduledAt } }
    private var upcoming: [TaskItem] { store.tasks.filter { $0.scheduledAt >= Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! }.sorted { $0.scheduledAt < $1.scheduledAt } }
    private var overdue: [TaskItem] { store.tasks.filter { $0.scheduledAt < Calendar.current.startOfDay(for: Date()) && !$0.isCompleted }.sorted { $0.scheduledAt < $1.scheduledAt } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Date(), format: .dateTime.month().day().weekday(.wide)).font(.subheadline).foregroundStyle(Theme.secondary)
                        Text("把今天，走成行迹").font(.largeTitle.bold()).foregroundStyle(Theme.ink)
                        if !today.isEmpty {
                            Text(String.localizedStringWithFormat(NSLocalizedString("今日 %lld 项 · 已完成 %lld 项", comment: ""), today.count, today.filter(\.isCompleted).count))
                                .foregroundStyle(Theme.secondary)
                                .accessibilityLabel("今日完成进度")
                                .accessibilityValue(String.localizedStringWithFormat(NSLocalizedString("今日 %lld 项 · 已完成 %lld 项", comment: ""), today.count, today.filter(\.isCompleted).count))
                            ProgressView(value: Double(today.filter(\.isCompleted).count), total: Double(today.count))
                                .tint(Theme.accent).accessibilityHidden(true)
                        }
                    }
                    Toggle("显示已完成", isOn: $showingCompleted)
                        .tint(Theme.toggleOn)
                        .accessibilityIdentifier("today.showCompleted")
                    if store.tasks.isEmpty {
                        ContentUnavailableView("从第一件小事开始", systemImage: "mappin.circle")
                    } else {
                        section("待跟进", tasks: overdue)
                        section("今日事项", tasks: today, emptyMessage: "今天没有安排，给自己留一点余白。")
                        section("未来行程", tasks: upcoming)
                    }
                    Button { openEditor(nil) } label: { Label("添加事项", systemImage: "plus") }
                        .buttonStyle(WaypointPrimaryButtonStyle()).accessibilityIdentifier("task.add")
                }.padding(20)
                    .padding(.bottom, bottomContentClearance)
            }
                .background(Theme.canvas).navigationTitle("今日").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showingExport = true } label: { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("导出行程").accessibilityIdentifier("export.open") } }
                .confirmationDialog("删除后无法恢复", isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }), titleVisibility: .visible) {
                    Button("删除事项", role: .destructive) {
                        if let task = pendingDeletion { store.remove(task.id) }
                        pendingDeletion = nil
                    }
                    Button("取消", role: .cancel) { pendingDeletion = nil }
                }
                .sheet(isPresented: $showingSubscription) { SubscriptionView() }
                .sheet(item: $editorDestination) { destination in TaskEditorView(task: destination.task, timeZoneNotice: destination.timeZoneNotice).id(destination.id) }
                .sheet(isPresented: $showingExport) { NavigationStack { ExportView().toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showingExport = false } } } } }
        }
    }
    private func openEditor(_ task: TaskItem?) {
        guard task != nil || AccessPolicy.canWrite else { showingSubscription = true; return }
        editorDestination = TaskEditorDestination(task: task)
    }
    @ViewBuilder private func section(_ title: String, tasks: [TaskItem], emptyMessage: String? = nil) -> some View {
        let visible = tasks.filter { showingCompleted || !$0.isCompleted }
        if !visible.isEmpty || emptyMessage != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey(title)).font(.title3.weight(.semibold)).foregroundStyle(Theme.ink)
                if visible.isEmpty { Text(LocalizedStringKey(tasks.isEmpty ? (emptyMessage ?? "没有事项") : "没有事项")).font(.subheadline).foregroundStyle(Theme.secondary) }
                ForEach(visible) { task in
                    VStack(alignment: .leading, spacing: 6) {
                        WaypointTaskRow(task: task, complete: { if AccessPolicy.canWrite { store.toggleCompletion(task.id) } else { showingSubscription = true } }, edit: { openEditor(task) })
                            .contextMenu { Button("编辑", systemImage: "pencil") { openEditor(task) }; Button("删除", systemImage: "trash", role: .destructive) { pendingDeletion = task } }
                    }
                }
            }
        }
    }
}
