import SwiftUI
import UIKit

enum Theme {
    static let canvas = adaptive(0xF5F3EC, 0x101D18)
    static let surface = adaptive(0xFFFEFA, 0x192C24)
    static let ink = adaptive(0x173B32, 0xF2F5EC)
    static let secondary = adaptive(0x56665F, 0xB4C2B7)
    static let accent = adaptive(0xCF6148, 0xF29B7D)
    static let toggleOn = adaptive(0x21845D, 0x29956B)
    static let softGreen = adaptive(0xE6EDE4, 0x2D473A)
    static let border = adaptive(0xD9DFD6, 0x3C5546)
    static let actionFill = adaptive(0x173B32, 0xC5DDC2)
    static let actionLabel = adaptive(0xFFFFFF, 0x10271D)
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

struct WaypointPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(16)
            .foregroundStyle(Theme.actionLabel).background(Theme.actionFill.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WaypointTaskRow: View {
    let task: TaskItem
    let complete: () -> Void
    let edit: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: complete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24)).foregroundStyle(task.isCompleted ? Theme.ink : Theme.secondary)
                    .frame(width: 44, height: 44)
            }.buttonStyle(.plain)
                .accessibilityLabel(LocalizedStringKey(task.isCompleted ? "标记为未完成" : "完成事项"))
                .accessibilityValue(task.title)
                .accessibilityIdentifier("task.complete.\(task.id.uuidString)")
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title).font(.headline).strikethrough(task.isCompleted).foregroundStyle(Theme.ink)
                    Label(task.locationName.isEmpty ? NSLocalizedString("未指定地点", comment: "") : task.locationName, systemImage: "mappin.and.ellipse")
                    Label {
                        Text(LocalTimeFormatter.string(task.scheduledAt, timeZoneIdentifier: task.timeZoneIdentifier, includeDate: true))
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: { Image(systemName: "clock") }
                    Label {
                        Text("时长 \(task.durationMinutes) 分钟")
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: { Image(systemName: "hourglass") }
                }.font(.subheadline).foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            }.buttonStyle(.plain).accessibilityHint("打开事项详情")
        }.padding(12).frame(minHeight: 76).background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
            .accessibilityIdentifier("task.row.\(task.id.uuidString)")
    }
}
