import Foundation
import Combine
import StoreKit
#if DEBUG
import UIKit
#endif

/// Pure validation complements StoreKit signature verification; never grants local trial time.
enum SubscriptionEntitlementPolicy {
    static func allowsAccess(productID: String, expirationDate: Date?, revocationDate: Date?, now: Date) -> Bool {
        productID == "com.waypoint.maptodo.annual" && revocationDate == nil && (expirationDate.map { $0 > now } ?? false)
    }
}

@MainActor
final class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()
    static let productID = "com.waypoint.maptodo.annual"
    @Published private(set) var hasAccess = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isPurchasing = false
    enum RestorePhase { case syncing, checkingEntitlements }
    @Published private(set) var isRestoring = false
    @Published private(set) var restorePhase: RestorePhase?
    @Published private(set) var isPurchasePending = false
    @Published private(set) var product: Product?
    @Published private(set) var isEligibleForTrial = false
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isLocalTestTransaction = false
    @Published private(set) var message: String?
    private let entitlementReader: @MainActor () async -> EntitlementSnapshot
    private let productLoader: @MainActor () async throws -> ProductPayload
    private let productTimeoutSeconds: Double
    private let restoreSyncAction: @MainActor () async throws -> Void
    private let restoreSyncTimeoutSeconds: Double
    private let restoreEntitlementTimeoutSeconds: Double
    private var restoreWaitTask: Task<Void, Never>?
    private var restoreStartedAt: Date?
    private var entitlementRevision: UInt64 = 0
    private var productOperationID: UUID?
    private var restoreOperationID: UUID?
    private var updatesTask: Task<Void, Never>?
    private var expirationTask: Task<Void, Never>?

    init(entitlementReader: (@MainActor () async -> EntitlementSnapshot)? = nil,
         productLoader: (@MainActor () async throws -> ProductPayload)? = nil,
         productTimeoutSeconds: Double = 15,
         restoreSyncAction: (@MainActor () async throws -> Void)? = nil,
         restoreSyncTimeoutSeconds: Double = 120,
         restoreEntitlementTimeoutSeconds: Double = 15) {
        self.entitlementReader = entitlementReader ?? { await Self.readEntitlements() }
        self.productLoader = productLoader ?? { try await Self.loadProduct() }
        self.productTimeoutSeconds = productTimeoutSeconds
        self.restoreSyncAction = restoreSyncAction ?? { try await AppStore.sync() }
        self.restoreSyncTimeoutSeconds = restoreSyncTimeoutSeconds
        self.restoreEntitlementTimeoutSeconds = restoreEntitlementTimeoutSeconds
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    guard transaction.productID == Self.productID else { continue }
                    self.isPurchasePending = false
                    await self.refreshEntitlements()
                    await transaction.finish()
                } else {
                    self.message = String(localized: "购买凭证验证失败，请重试或恢复购买。")
                    await self.refreshEntitlements()
                }
            }
        }
    }

    deinit { updatesTask?.cancel(); expirationTask?.cancel(); restoreWaitTask?.cancel() }

    struct ProductPayload: Sendable {
        let product: Product?
        let isEligibleForTrial: Bool
    }

    private static func loadProduct() async throws -> ProductPayload {
        let product = try await Product.products(for: [Self.productID]).first
        var eligible = false
        if let subscription = product?.subscription,
           let offer = subscription.introductoryOffer,
           offer.paymentMode == .freeTrial,
           ((offer.period.unit == .day && offer.period.value == 7) || (offer.period.unit == .week && offer.period.value == 1)) {
            eligible = await subscription.isEligibleForIntroOffer
        }
        return ProductPayload(product: product, isEligibleForTrial: eligible)
    }

    func refresh() async {
        // Entitlements are independent of an earlier stalled product/eligibility load.
        await refreshEntitlements()
        guard !isRefreshing else { return }
        let operationID = UUID()
        productOperationID = operationID
        isRefreshing = true
        if !isRestoring { message = nil }
        defer {
            if productOperationID == operationID {
                productOperationID = nil
                isRefreshing = false
            }
        }
        let loader = productLoader
        do {
            let payload = try await SubscriptionTimeout.run(seconds: productTimeoutSeconds) { try await loader() }
            guard productOperationID == operationID else { return }
            product = payload.product
            isEligibleForTrial = payload.isEligibleForTrial
            if product == nil && !isRestoring { message = String(localized: "暂时无法获取订阅商品，请检查网络或稍后重试。") }
        } catch {
            guard productOperationID == operationID else { return }
            product = nil
            isEligibleForTrial = false
            if !isRestoring {
                if (error as? URLError)?.code == .timedOut {
                    message = String(localized: "获取订阅商品超时，请检查网络后重试。")
                } else {
                    message = String(format: NSLocalizedString("无法获取 App Store 商品：%@", comment: "StoreKit error"), error.localizedDescription)
                }
            }
        }
    }

    func purchase() async {
        #if DEBUG
        let diagnosticID = UUID()
        let diagnosticStart = Date()
        recordDiagnostic("purchase.entry", operationID: diagnosticID, startedAt: diagnosticStart)
        #endif
        guard let product, !isPurchasing, !isRefreshing, !isPurchasePending, !hasAccess else {
            #if DEBUG
            recordDiagnostic("purchase.guardBlocked", operationID: diagnosticID, startedAt: diagnosticStart)
            #endif
            return
        }
        isPurchasing = true
        message = nil
        defer {
            isPurchasing = false
            #if DEBUG
            recordDiagnostic("purchase.end", operationID: diagnosticID, startedAt: diagnosticStart)
            #endif
        }
        do {
            #if DEBUG
            recordDiagnostic("purchase.sdk.start", operationID: diagnosticID, startedAt: diagnosticStart)
            #endif
            let result = try await product.purchase()
            #if DEBUG
            let resultName: String
            switch result {
            case .success(.verified(_)): resultName = "successVerified"
            case .success(.unverified(_, _)): resultName = "successUnverified"
            case .pending: resultName = "pending"
            case .userCancelled: resultName = "userCancelled"
            @unknown default: resultName = "unknown"
            }
            recordDiagnostic("purchase.sdk.return", operationID: diagnosticID, startedAt: diagnosticStart, result: resultName)
            #endif
            switch result {
            case .success(let result):
                guard case .verified(let transaction) = result else {
                    message = String(localized: "购买凭证验证失败，未开通权益。")
                    await refreshEntitlements()
                    return
                }
                await refreshEntitlements()
                await transaction.finish()
                if hasAccess { message = String(localized: "订阅已生效。") }
            case .pending:
                isPurchasePending = true
                message = String(localized: "购买等待批准，批准后会自动更新权益。")
            case .userCancelled: message = String(localized: "购买已取消。")
            @unknown default: message = String(localized: "购买尚未完成，请稍后恢复购买。")
            }
        } catch {
            #if DEBUG
            recordDiagnostic("purchase.sdk.error", operationID: diagnosticID, startedAt: diagnosticStart, error: error)
            #endif
            message = String(format: NSLocalizedString("购买未完成：%@", comment: "StoreKit error"), error.localizedDescription)
        }
    }

    /// A rejection may not emit a transaction update. Only an explicit user retry
    /// releases the local pending lock; Apple still decides approval and entitlement.
    func retryPendingPurchase() async {
        guard isPurchasePending, !isPurchasing, !isRefreshing else { return }
        await refresh()
        guard !hasAccess else { return }
        isPurchasePending = false
        await purchase()
    }

    func restore() async {
        guard !isPurchasing else { return }
        let operationID = UUID()
        let startedAt = Date()
        restoreOperationID = operationID
        restoreStartedAt = startedAt
        isPurchasing = true
        isRestoring = true
        restorePhase = .syncing
        message = nil
        #if DEBUG
        recordDiagnostic("restore.entry", operationID: operationID, startedAt: startedAt)
        #endif
        let work = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.performRestore(operationID: operationID, startedAt: startedAt)
        }
        restoreWaitTask = work
        await work.value
    }

    /// Ends this app's waiting UI, not an Apple transaction or subscription.
    func stopWaitingForRestore() {
        guard isRestoring, let operationID = restoreOperationID else { return }
        let work = restoreWaitTask
        let startedAt = restoreStartedAt ?? Date()
        // Invalidate first, so the cancelled waiter and any late SDK result cannot write.
        restoreOperationID = nil
        restoreWaitTask = nil
        restoreStartedAt = nil
        isPurchasing = false
        isRestoring = false
        restorePhase = nil
        message = String(localized: "已停止等待，尚未确认恢复。此操作不会取消 Apple 购买或订阅。")
        #if DEBUG
        recordDiagnostic("restore.stoppedWaiting", operationID: operationID, startedAt: startedAt)
        #endif
        work?.cancel()
    }

    private func performRestore(operationID: UUID, startedAt: Date) async {
        defer {
            if restoreOperationID == operationID {
                restoreOperationID = nil
                restoreWaitTask = nil
                restoreStartedAt = nil
                isPurchasing = false
                isRestoring = false
                restorePhase = nil
            }
            #if DEBUG
            recordDiagnostic("restore.end", operationID: operationID, startedAt: startedAt)
            #endif
        }
        let syncAction = restoreSyncAction
        let reader = entitlementReader
        do {
            // Manual Apple authentication has its own finite interactive budget.
            try await SubscriptionTimeout.run(seconds: restoreSyncTimeoutSeconds) {
                #if DEBUG
                self.recordDiagnostic("restore.sync.start", operationID: operationID, startedAt: startedAt)
                do {
                    try await syncAction()
                } catch {
                    self.recordDiagnostic("restore.sync.error", operationID: operationID, startedAt: startedAt, error: error)
                    throw error
                }
                self.recordDiagnostic("restore.sync.return", operationID: operationID, startedAt: startedAt)
                #else
                try await syncAction()
                #endif
            }
            guard restoreOperationID == operationID, !Task.isCancelled else { return }
            restorePhase = .checkingEntitlements
            // Start ordering protection when the post-sync read begins, not before
            // the user spends time in authentication or legitimate updates arrive.
            entitlementRevision &+= 1
            let readRevision = entitlementRevision
            let snapshot = try await SubscriptionTimeout.run(seconds: restoreEntitlementTimeoutSeconds) {
                #if DEBUG
                self.recordDiagnostic("restore.entitlement.start", operationID: operationID, startedAt: startedAt)
                #endif
                let snapshot = await reader()
                #if DEBUG
                self.recordDiagnostic("restore.entitlement.return", operationID: operationID, startedAt: startedAt)
                #endif
                return snapshot
            }
            guard restoreOperationID == operationID, !Task.isCancelled else { return }
            applyEntitlements(snapshot, revision: readRevision)
            message = hasAccess ? String(localized: "已恢复有效订阅。") : String(localized: "没有找到有效订阅。")
        } catch {
            guard restoreOperationID == operationID else { return }
            #if DEBUG
            recordDiagnostic((error as? URLError)?.code == .timedOut ? "restore.timeout" : "restore.error", operationID: operationID, startedAt: startedAt, error: error)
            #endif
            if (error as? URLError)?.code == .timedOut {
                message = restorePhase == .syncing
                    ? String(localized: "等待 Apple 同步超时，尚未确认恢复。请完成系统账户验证后重试。")
                    : String(localized: "核对购买权益超时，尚未确认恢复，请重试。")
            } else {
                message = String(format: NSLocalizedString("恢复失败：%@", comment: "StoreKit error"), error.localizedDescription)
            }
        }
    }

    struct EntitlementSnapshot: Sendable {
        var expirationDate: Date?
        var isLocalTest = false
    }

    func refreshEntitlements() async {
        // A status/network read may take time. Its pending result must never
        // extend access beyond the last verified expiration date.
        if let expirationDate, expirationDate <= Date() {
            hasAccess = false
            self.expirationDate = nil
            isLocalTestTransaction = false
            // Do not cancel the current expiration task here: its reader may
            // return a genuine renewal that should re-enable verified access.
        }
        entitlementRevision &+= 1
        let readRevision = entitlementRevision
        let snapshot = await entitlementReader()
        applyEntitlements(snapshot, revision: readRevision)
    }

    /// Normalized real StoreKit evidence; only the verification cases below
    /// construct production records. Injection enables deterministic policy tests.
    struct TransactionEvidence: Sendable {
        var productID: String
        var expirationDate: Date?
        var revocationDate: Date?
        var isUpgraded: Bool
        var isVerified: Bool
        var isLocalTest: Bool
        var originalID: UInt64? = nil
        var purchaseDate: Date? = nil
        var signedDate: Date? = nil
        var environment: AppStore.Environment? = nil
    }

    struct SubscriptionStatusEvidence: Sendable {
        var state: Product.SubscriptionInfo.RenewalState
        var transaction: TransactionEvidence
        var renewalIsVerified: Bool
        var renewalProductID: String
        var renewalOriginalID: UInt64? = nil
    }

    private static func evidence(_ transaction: Transaction, verified: Bool) -> TransactionEvidence {
        .init(productID: transaction.productID, expirationDate: transaction.expirationDate,
              revocationDate: transaction.revocationDate, isUpgraded: transaction.isUpgraded,
              isVerified: verified, isLocalTest: transaction.environment == .xcode,
              originalID: transaction.originalID, purchaseDate: transaction.purchaseDate,
              signedDate: transaction.signedDate, environment: transaction.environment)
    }

    private static func readEntitlements() async -> EntitlementSnapshot {
        var current: [TransactionEvidence] = []
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction): current.append(evidence(transaction, verified: true))
            case .unverified(let transaction, _): current.append(evidence(transaction, verified: false))
            }
        }
        return await resolveEntitlements(current: current) {
            // Resolve the group through the exact live product. No group ID/cache
            // or latest-transaction-only guess is used to grant subscription access.
            guard let product = try await Product.products(for: [Self.productID]).first,
                  product.id == Self.productID, let subscription = product.subscription else { return [] }
            var statuses: [SubscriptionStatusEvidence] = []
            for status in try await subscription.status {
                guard case .verified(let transaction) = status.transaction,
                      case .verified(let renewal) = status.renewalInfo else { continue }
                statuses.append(.init(state: status.state, transaction: evidence(transaction, verified: true),
                                      renewalIsVerified: true, renewalProductID: renewal.currentProductID,
                                      renewalOriginalID: renewal.originalTransactionID))
            }
            return statuses
        }
    }

    /// A status fallback addresses the observed R34 empty-current/active-status
    /// inconsistency. Hard current denials win; a stale expired transaction can
    /// only be superseded by a strictly newer verified same-lineage renewal.
    static func resolveEntitlements(current: [TransactionEvidence],
                                    statusLoader: @escaping @MainActor () async throws -> [SubscriptionStatusEvidence],
                                    statusTimeoutSeconds: Double = 10) async -> EntitlementSnapshot {
        func allows(_ transaction: TransactionEvidence) -> Bool {
            transaction.isVerified && !transaction.isUpgraded &&
            SubscriptionEntitlementPolicy.allowsAccess(productID: transaction.productID,
                                                       expirationDate: transaction.expirationDate,
                                                       revocationDate: transaction.revocationDate, now: Date())
        }
        func snapshot(_ transactions: [TransactionEvidence]) -> EntitlementSnapshot {
            let best = transactions.filter(allows).max {
                ($0.expirationDate ?? .distantPast) < ($1.expirationDate ?? .distantPast)
            }
            return .init(expirationDate: best?.expirationDate, isLocalTest: best?.isLocalTest ?? false)
        }
        let matching = current.filter { $0.productID == Self.productID }
        if !matching.isEmpty && matching.allSatisfy(allows) { return snapshot(matching) }
        // Expiry alone may describe a stale current transaction (observed R38).
        // Revocation, upgrade, failed verification and missing expiry are not
        // stale-expiry evidence and may never be overwritten by a positive status.
        let hasHardDenial = matching.contains {
            !$0.isVerified || $0.isUpgraded || $0.revocationDate != nil || $0.expirationDate == nil
        }
        guard !hasHardDenial else { return .init(expirationDate: nil) }
        let expired = matching.filter { !allows($0) }
        func supersedesExpiredCurrent(_ newer: TransactionEvidence) -> Bool {
            expired.allSatisfy { old in
                guard let oldOriginal = old.originalID, let newOriginal = newer.originalID,
                      oldOriginal == newOriginal,
                      let oldPurchase = old.purchaseDate, let newPurchase = newer.purchaseDate,
                      let oldSigned = old.signedDate, let newSigned = newer.signedDate,
                      let oldExpiry = old.expirationDate, let newExpiry = newer.expirationDate,
                      let oldEnvironment = old.environment, let newEnvironment = newer.environment else { return false }
                return oldEnvironment == newEnvironment && oldPurchase < oldExpiry &&
                    newPurchase > oldPurchase && newPurchase >= oldExpiry &&
                    newPurchase < newExpiry && newPurchase <= Date() &&
                    newSigned >= newPurchase && newSigned > oldSigned && newExpiry > oldExpiry
            }
        }
        // A sequence may include both the old expiry and the verified new renewal.
        // Do not reject that mixed set, or trust an arbitrary unrelated active item.
        let renewedCurrent = matching.filter(allows).filter(supersedesExpiredCurrent)
        if !renewedCurrent.isEmpty { return snapshot(renewedCurrent) }
        do {
            let statuses = try await SubscriptionTimeout.run(seconds: statusTimeoutSeconds) { try await statusLoader() }
            let eligible = statuses.filter {
                // This patch intentionally does not add grace-period entitlement.
                $0.state == .subscribed && $0.renewalIsVerified &&
                $0.renewalProductID == Self.productID && allows($0.transaction) &&
                $0.transaction.originalID != nil && $0.renewalOriginalID == $0.transaction.originalID &&
                supersedesExpiredCurrent($0.transaction)
            }
            return snapshot(eligible.map(\.transaction))
        } catch {
            return .init(expirationDate: nil)
        }
    }

    private func applyEntitlements(_ snapshot: EntitlementSnapshot, revision: UInt64) {
        guard revision == entitlementRevision else { return }
        // Recheck wall-clock time after every await, not only during enumeration.
        let activeExpiration = snapshot.expirationDate.flatMap { $0 > Date() ? $0 : nil }
        // Empty, expired, or revoked StoreKit results clear any prior access.
        expirationDate = activeExpiration
        hasAccess = activeExpiration != nil
        if hasAccess { isPurchasePending = false }
        isLocalTestTransaction = activeExpiration != nil && snapshot.isLocalTest
        expirationTask?.cancel()
        if let activeExpiration {
            expirationTask = Task { [weak self] in
                let seconds = max(0, activeExpiration.timeIntervalSinceNow)
                do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
                await self?.refreshEntitlements()
            }
        }
    }

    #if DEBUG
    /// Local bounded SDK-boundary evidence only. Never logs account or transaction data.
    private func recordDiagnostic(_ phase: String, operationID: UUID, startedAt: Date,
                                  result: String? = nil, error: Error? = nil) {
        let activeScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        var record: [String: Any] = [
            "time": ISO8601DateFormatter().string(from: Date()),
            "operationUUID": operationID.uuidString,
            "phase": phase,
            "elapsedSeconds": max(0, Date().timeIntervalSince(startedAt)),
            "productID": Self.productID,
            "canMakePayments": SKPaymentQueue.canMakePayments(),
            "hasForegroundActiveScene": !activeScenes.isEmpty,
            "hasKeyWindow": activeScenes.contains { $0.windows.contains(where: \.isKeyWindow) },
            "taskIsCancelled": Task.isCancelled,
            "flags": ["isRefreshing": isRefreshing, "isPurchasing": isPurchasing,
                      "isRestoring": isRestoring, "isPurchasePending": isPurchasePending,
                      "hasAccess": hasAccess, "productAvailable": product != nil,
                      "isEligibleForTrial": isEligibleForTrial]
        ]
        if let result { record["purchaseResult"] = result }
        if let error {
            var codes: [[String: Any]] = []
            var current: NSError? = error as NSError
            // Only read the designated underlying-error link; never serialize userInfo.
            for _ in 0..<3 {
                guard let value = current else { break }
                codes.append(["domain": value.domain, "code": value.code])
                current = value.userInfo[NSUnderlyingErrorKey] as? NSError
            }
            record["errorCodes"] = codes
        }
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let encoded = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]) else { return }
        let file = directory.appendingPathComponent("waypoint-storekit-diagnostics.jsonl")
        var contents = (try? Data(contentsOf: file)) ?? Data()
        contents.append(encoded)
        contents.append(0x0A)
        let limit = 64 * 1024
        if contents.count > limit {
            contents = Data(contents.suffix(limit))
            if let firstNewline = contents.firstIndex(of: 0x0A) {
                contents = Data(contents.suffix(from: contents.index(after: firstNewline)))
            } else { contents = Data() }
        }
        try? contents.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    #endif

}
