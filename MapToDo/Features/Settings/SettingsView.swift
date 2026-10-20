import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").font(.largeTitle).foregroundStyle(Theme.accent)
                        Text("行迹 Waypoint").font(.title.bold()).foregroundStyle(Theme.ink)
                        Text("把待办放回生活的地图里。" ).foregroundStyle(Theme.secondary)
                    }.padding(.vertical, 12)
                }
                Section("你的偏好") {
                    NavigationLink { ReminderSettingsView() } label: { Label("提醒与通知", systemImage: "bell") }
                    NavigationLink { AISettingsView() } label: { Label("AI 服务配置", systemImage: "sparkles") }.accessibilityIdentifier("settings.ai")
                    NavigationLink { SubscriptionView() } label: { Label("订阅与试用", systemImage: "leaf") }.accessibilityIdentifier("settings.subscription")
                }
                Section("你的数据") {
                    NavigationLink { ExportView() } label: { Label("导出行程", systemImage: "square.and.arrow.up") }
                    NavigationLink { PrivacyInformationView() } label: { Label("隐私与数据", systemImage: "hand.raised") }
                }
                Section("支持与隐私") {
                    Link(destination: AppLinks.support) { Label("支持网站", systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("settings.support")
                    Link(destination: AppLinks.privacy) { Label("在线隐私政策", systemImage: "hand.raised") }
                        .accessibilityIdentifier("settings.privacy")
                }
                Section {
                    Text("版本 1.0").font(.footnote).foregroundStyle(Theme.secondary)
                }
            }.scrollContentBackground(.hidden).background(Theme.canvas).tint(Theme.ink).navigationTitle("设置")
        }
    }
}

private struct PrivacyInformationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("由你掌握的行迹").font(.title.bold())
                Text("事项保存在此设备。卸载应用可能移除本地数据，请先导出重要行程。")
                Text("地图搜索、路线与天气需要向相应服务发送地点信息。位置权限由你主动开启，可在系统设置中修改。")
                Text("AI 规划由你主动发起。发送前会确认服务商与发送内容。API 密钥保存在系统钥匙串。")
                Text("卸载应用不一定会删除钥匙串中的 API 密钥。请在 AI 设置中删除各服务密钥。")
                Link("阅读完整隐私政策", destination: AppLinks.privacy)
                Text("导出的文件可能包含地点、时间和备注，请只分享给你信任的人。")
            }.foregroundStyle(Theme.ink).padding(20)
        }.background(Theme.canvas).navigationTitle("隐私与数据").navigationBarTitleDisplayMode(.inline)
    }
}
