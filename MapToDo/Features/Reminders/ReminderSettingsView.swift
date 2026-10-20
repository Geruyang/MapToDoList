import SwiftUI
import UIKit
import UserNotifications

struct ReminderSettingsView: View {
    @StateObject private var service = ReminderService.shared
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var store: TaskStore
    @State private var requesting = false

    var body: some View {
        Form {
            Section {
                Toggle("启用事项提醒", isOn: $service.isEnabled).tint(Theme.toggleOn)
                    .accessibilityIdentifier("reminders.enabled")
                LabeledContent("通知权限", value: permissionText)
                LabeledContent("系统时效通知", value: timeSensitiveText)
                if service.authorizationStatus == .notDetermined {
                    Button(requesting ? String(localized: "正在请求…") : String(localized: "允许通知")) {
                        requesting = true
                        Task {
                            _ = await service.requestAuthorization()
                            requesting = false
                        }
                    }
                    .disabled(requesting)
                    .accessibilityIdentifier("reminders.authorize")
                } else if service.authorizationStatus == .denied {
                    Text("通知权限已关闭，事项仍会保存。请在系统设置中允许通知后返回。")
                        .foregroundStyle(.secondary)
                    Button("打开系统设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } header: { Text("通知") }
            Section {
                LabeledContent("已安排提醒", value: "\(service.scheduledCount) / 60")
                if service.overflowCount > 0 {
                    Text("还有 \(service.overflowCount) 个提醒暂未安排。当前仅安排最近的 60 个；请再次打开 App 以安排后续提醒。App 关闭时不会自动补齐超限提醒。")
                        .foregroundStyle(.secondary)
                }
            } header: { Text("提醒安排") }
            if let error = service.errorMessage {
                Section { Text(error).foregroundStyle(.red) } header: { Text("提醒状态") }
            }
        }
        .navigationTitle("提醒设置")
        .task { await service.synchronize(tasks: store.tasks) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await service.synchronize(tasks: store.tasks) } }
        }
    }

    private var timeSensitiveText: String {
        switch service.timeSensitiveSetting {
        case .enabled: String(localized: "已允许")
        case .disabled: String(localized: "已关闭，将遵循普通通知设置")
        case .notSupported: String(localized: "系统不支持或尚未授权")
        @unknown default: String(localized: "未知")
        }
    }

    private var permissionText: String {
        switch service.authorizationStatus {
        case .notDetermined: String(localized: "尚未询问")
        case .denied: String(localized: "已关闭")
        case .authorized: String(localized: "已允许")
        case .provisional: String(localized: "暂时允许（安静通知）")
        case .ephemeral: String(localized: "临时允许")
        @unknown default: String(localized: "未知")
        }
    }
}
