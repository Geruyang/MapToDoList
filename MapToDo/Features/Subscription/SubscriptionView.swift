import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject private var subscription = SubscriptionStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var showManagement = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Text("完成")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .accessibilityIdentifier("subscription.close")
                }
                Image(systemName: "map.fill").font(.largeTitle).foregroundStyle(.green)
                Text("行迹年度订阅").font(.largeTitle.bold())
                Text("在地图上安排事项，获取提醒、规划路线与天气参考。已有事项始终可以查看和导出。")
                if subscription.hasAccess {
                    Label("订阅有效", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    if let expiration = subscription.expirationDate { Text("当前权益至 \(expiration.formatted(date: .abbreviated, time: .shortened))") }
                    if subscription.isLocalTestTransaction { Text("StoreKit 本地测试权益，不代表真实购买。").font(.caption) }
                } else if let product = subscription.product {
                    Text("\(product.displayPrice) / 年").font(.title.bold()).accessibilityIdentifier("subscription.price")
                    Text(subscription.isEligibleForTrial ? String(localized: "符合资格：免费试用 7 天，随后按上方年费自动续订。") : String(localized: "此账户当前不适用 7 天免费试用，购买后按上方年费收费。"))
                    Button(subscription.isEligibleForTrial ? String(localized: "开始 7 天免费试用") : String(localized: "订阅一年")) {
                        Task { await subscription.purchase() }
                    }
                    .buttonStyle(WaypointPrimaryButtonStyle())
                    .disabled(subscription.isPurchasing || subscription.isRefreshing || subscription.isPurchasePending)
                    .accessibilityIdentifier("subscription.purchase")
                } else {
                    Text(subscription.isRefreshing ? String(localized: "正在获取 App Store 价格与资格…") : String(localized: "订阅商品暂不可用"))
                    Button("重新获取商品") { Task { await subscription.refresh() } }.disabled(subscription.isRefreshing)
                }
                if subscription.isPurchasePending {
                    Text("购买正在等待批准。批准后权益会自动更新；如果请求已被拒绝，可重新发起。")
                    Button("检查购买状态") { Task { await subscription.refresh() } }
                        .disabled(subscription.isRefreshing || subscription.isPurchasing)
                        .accessibilityIdentifier("subscription.checkPending")
                    Button("请求已被拒绝，重新购买") { Task { await subscription.retryPendingPurchase() } }
                        .disabled(subscription.isRefreshing || subscription.isPurchasing)
                        .accessibilityIdentifier("subscription.retryPending")
                }
                if subscription.isRestoring {
                    ProgressView(subscription.restorePhase == .syncing
                        ? String(localized: "正在同步购买。Apple 可能会要求验证账户，请在系统提示中完成。")
                        : String(localized: "正在核对已验证的购买权益…"))
                    Button { subscription.stopWaitingForRestore() } label: {
                        Text("停止等待")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("subscription.stopWaiting")
                } else if subscription.isPurchasing {
                    ProgressView("正在等待 App Store…")
                }
                if let message = subscription.message { Text(message).font(.callout).accessibilityIdentifier("subscription.message") }
                Text("款项由 Apple 账户收取。订阅自动续订，除非在当前周期结束前至少 24 小时取消。符合资格的试用在 7 天后转为付费年度订阅；请提前至少 24 小时取消以避免收费。您可在 Apple 订阅设置中管理或取消。实际价格和确认条款以 App Store 为准。")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("恢复购买") { Task { await subscription.restore() } }
                    .disabled(subscription.isPurchasing).accessibilityIdentifier("subscription.restore")
                Button("管理或取消订阅") { showManagement = true }.accessibilityIdentifier("subscription.manage")
                HStack {
                    Link(destination: AppLinks.privacy) {
                        Text("隐私政策")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .accessibilityIdentifier("subscription.privacy")
                    Spacer()
                    Link(destination: AppLinks.terms) {
                        Text("使用条款")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .accessibilityIdentifier("subscription.terms")
                }
                .font(.footnote)
            }.padding(24)
        }
        .navigationTitle("订阅")
        .toolbar(.hidden, for: .tabBar)
        .task { await subscription.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await subscription.refresh() } } }
        .manageSubscriptionsSheet(isPresented: $showManagement)
    }
}
