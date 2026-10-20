import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TaskStore
    @ObservedObject private var reminders = ReminderService.shared
    @State private var notificationTask: TaskItem?
    var body: some View {
        VStack(spacing: 0) {
            if AccessPolicy.isDemo {
                Text("演示模式 · 示例数据").font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(8)
                    .foregroundStyle(Theme.ink).background(Theme.softGreen)
                    .accessibilityIdentifier("demo.banner")
            }
            TabView {
                MapScreen().tabItem { Label("地图", systemImage: "map").accessibilityIdentifier("tab.map") }
                TodayView().tabItem { Label("今日", systemImage: "checklist").accessibilityIdentifier("tab.today") }
                PlanningView().tabItem { Label("规划", systemImage: "point.topleft.down.curvedto.point.bottomright.up").accessibilityIdentifier("tab.planning") }
                SettingsView().tabItem { Label("设置", systemImage: "gearshape").accessibilityIdentifier("tab.settings") }
            }.tint(Theme.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.canvas)
        .sheet(item: $notificationTask) { task in TaskEditorView(task: task) }
        .onChange(of: reminders.openedTaskID, initial: true) { _, id in
            guard let id else { return }
            reminders.openedTaskID = nil
            notificationTask = store.tasks.first { $0.id == id }
        }
    }
}
