import XCTest
@testable import MapToDo

@MainActor
final class SubscriptionConcurrencyTests: XCTestCase {
    func testOlderActiveSnapshotCannotOverwriteNewerRevocation() async {
        let gate = SnapshotGate()
        var reads = 0
        let store = SubscriptionStore(entitlementReader: {
            reads += 1
            if reads == 1 { return await gate.read() }
            return .init(expirationDate: nil)
        })
        let oldRead = Task { await store.refreshEntitlements() }
        await fulfillment(of: [gate.started], timeout: 1)
        await store.refreshEntitlements()
        XCTAssertFalse(store.hasAccess)
        gate.resume(.init(expirationDate: Date().addingTimeInterval(3600)))
        await oldRead.value
        XCTAssertFalse(store.hasAccess, "An older active read must not undo a newer revoked read")
    }

    func testSnapshotAlreadyExpiredAtApplyCannotGrantAccess() async {
        let store = SubscriptionStore(entitlementReader: {
            .init(expirationDate: Date().addingTimeInterval(-1), isLocalTest: true)
        })
        await store.refreshEntitlements()
        XCTAssertFalse(store.hasAccess)
        XCTAssertNil(store.expirationDate)
        XCTAssertFalse(store.isLocalTestTransaction)
    }

    func testForegroundRechecksEntitlementsDuringStuckProductRequestAndTimeoutAllowsRetry() async {
        let productGate = ProductGate()
        var entitlementReads = 0
        var productReads = 0
        let store = SubscriptionStore(entitlementReader: {
            entitlementReads += 1
            return .init(expirationDate: entitlementReads == 1 ? Date().addingTimeInterval(3600) : nil)
        }, productLoader: {
            productReads += 1
            if productReads == 1 { return await productGate.read() }
            return .init(product: nil, isEligibleForTrial: false)
        }, productTimeoutSeconds: 0.2)
        let initial = Task { await store.refresh() }
        await fulfillment(of: [productGate.started], timeout: 1)
        XCTAssertTrue(store.isRefreshing)
        await store.refresh()
        XCTAssertFalse(store.hasAccess, "Foreground read must not be skipped by a stuck price request")
        await initial.value
        XCTAssertFalse(store.isRefreshing)
        XCTAssertNil(store.product)
        XCTAssertNotNil(store.message)
        await store.refresh()
        XCTAssertEqual(productReads, 2, "A timed-out request must permit a new load")
        let currentMessage = store.message
        productGate.resume(.init(product: nil, isEligibleForTrial: true))
        await Task.yield()
        XCTAssertFalse(store.isEligibleForTrial, "Late payload must not overwrite current state")
        XCTAssertEqual(store.message, currentMessage)
    }

    func testRestoreAllowsLongerAuthenticationBeforeSeparateEntitlementDeadline() async throws {
        var syncCompleted = false
        let store = SubscriptionStore(entitlementReader: {
            XCTAssertTrue(syncCompleted, "Entitlements must not be read before Apple sync returns")
            return .init(expirationDate: nil)
        }, restoreSyncAction: {
            try await Task.sleep(for: .milliseconds(80))
            syncCompleted = true
        }, restoreSyncTimeoutSeconds: 1, restoreEntitlementTimeoutSeconds: 0.03)
        await store.restore()
        XCTAssertTrue(syncCompleted)
        XCTAssertFalse(store.isRestoring)
        XCTAssertFalse(store.isPurchasing)
        XCTAssertFalse(store.hasAccess)
        XCTAssertEqual(store.message, String(localized: "没有找到有效订阅。"))
    }

    func testNonCooperativeSyncDeadlineClearsBusyWithoutGrantingAccess() async {
        let sync = SyncGate()
        var reads = 0
        let store = SubscriptionStore(entitlementReader: {
            reads += 1
            return .init(expirationDate: Date().addingTimeInterval(3600))
        }, restoreSyncAction: { await sync.wait() }, restoreSyncTimeoutSeconds: 0.03)
        let operation = Task { await store.restore() }
        await fulfillment(of: [sync.started], timeout: 1)
        XCTAssertEqual(store.restorePhase, .syncing)
        await operation.value
        XCTAssertEqual(reads, 0)
        XCTAssertFalse(store.isRestoring)
        XCTAssertFalse(store.isPurchasing)
        XCTAssertFalse(store.hasAccess)
        XCTAssertEqual(store.message, String(localized: "等待 Apple 同步超时，尚未确认恢复。请完成系统账户验证后重试。"))
        sync.finish()
        await Task.yield()
        XCTAssertEqual(reads, 0, "A timed-out sync must never continue into the next entitlement phase")
    }

    func testPostSyncEntitlementDeadlineIsIndependentAndNeverGrantsAccess() async {
        let snapshot = SnapshotGate()
        let store = SubscriptionStore(entitlementReader: { await snapshot.read() },
                                      restoreSyncAction: {}, restoreSyncTimeoutSeconds: 1,
                                      restoreEntitlementTimeoutSeconds: 0.03)
        let operation = Task { await store.restore() }
        await fulfillment(of: [snapshot.started], timeout: 1)
        XCTAssertEqual(store.restorePhase, .checkingEntitlements)
        await operation.value
        XCTAssertFalse(store.isRestoring)
        XCTAssertFalse(store.hasAccess)
        XCTAssertEqual(store.message, String(localized: "核对购买权益超时，尚未确认恢复，请重试。"))
        snapshot.resume(.init(expirationDate: Date().addingTimeInterval(3600)))
        await Task.yield()
        XCTAssertFalse(store.hasAccess)
    }

    func testStopWaitingClearsBusyAndDoesNotClaimAppleTransactionCancellation() async {
        let sync = SyncGate()
        let store = SubscriptionStore(entitlementReader: { .init(expirationDate: nil) },
                                      restoreSyncAction: { await sync.wait() })
        let operation = Task { await store.restore() }
        await fulfillment(of: [sync.started], timeout: 1)
        store.stopWaitingForRestore()
        await operation.value
        XCTAssertFalse(store.isRestoring)
        XCTAssertFalse(store.isPurchasing)
        XCTAssertNil(store.restorePhase)
        XCTAssertFalse(store.hasAccess)
        XCTAssertEqual(store.message, String(localized: "已停止等待，尚未确认恢复。此操作不会取消 Apple 购买或订阅。"))
        sync.finish()
        await Task.yield()
    }

    func testStoppedSyncCannotOverwriteNewRestoreStateWhenItReturnsLate() async {
        let oldSync = SyncGate()
        var syncCalls = 0
        var reads = 0
        let store = SubscriptionStore(entitlementReader: {
            reads += 1
            return .init(expirationDate: nil)
        }, restoreSyncAction: {
            syncCalls += 1
            if syncCalls == 1 { await oldSync.wait() }
        })
        let oldOperation = Task { await store.restore() }
        await fulfillment(of: [oldSync.started], timeout: 1)
        store.stopWaitingForRestore()
        await oldOperation.value
        await store.restore()
        let currentMessage = store.message
        XCTAssertEqual(currentMessage, String(localized: "没有找到有效订阅。"))
        oldSync.finish()
        await Task.yield()
        XCTAssertEqual(reads, 1)
        XCTAssertEqual(store.message, currentMessage)
        XCTAssertFalse(store.isRestoring)
        XCTAssertFalse(store.hasAccess)
    }

    func testStoppedSnapshotCannotUndoNewRevocationButLaterEntitlementReconciliationStillWorks() async {
        let oldSnapshot = SnapshotGate()
        var reads = 0
        let store = SubscriptionStore(entitlementReader: {
            reads += 1
            if reads == 1 { return await oldSnapshot.read() }
            // Models a later valid verified-reader result, then a revocation.
            return .init(expirationDate: reads == 3 ? Date().addingTimeInterval(3600) : nil)
        }, restoreSyncAction: {})
        let oldOperation = Task { await store.restore() }
        await fulfillment(of: [oldSnapshot.started], timeout: 1)
        store.stopWaitingForRestore()
        await oldOperation.value
        await store.restore()
        let currentMessage = store.message
        oldSnapshot.resume(.init(expirationDate: Date().addingTimeInterval(3600)))
        await Task.yield()
        XCTAssertFalse(store.hasAccess)
        XCTAssertEqual(store.message, currentMessage)
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasAccess, "Stopping the app waiter must not disable subsequent real entitlement reconciliation")
        await store.refreshEntitlements()
        XCTAssertFalse(store.hasAccess, "Subsequent revocation must still deny access")
    }

}

@MainActor
private final class SnapshotGate {
    let started = XCTestExpectation(description: "Snapshot read suspended")
    private var continuation: CheckedContinuation<SubscriptionStore.EntitlementSnapshot, Never>?
    func read() async -> SubscriptionStore.EntitlementSnapshot {
        await withCheckedContinuation { continuation in self.continuation = continuation; started.fulfill() }
    }
    func resume(_ snapshot: SubscriptionStore.EntitlementSnapshot) { continuation?.resume(returning: snapshot); continuation = nil }
}

@MainActor
private final class ProductGate {
    let started = XCTestExpectation(description: "Product read suspended")
    private var continuation: CheckedContinuation<SubscriptionStore.ProductPayload, Never>?
    func read() async -> SubscriptionStore.ProductPayload {
        await withCheckedContinuation { continuation in self.continuation = continuation; started.fulfill() }
    }
    func resume(_ payload: SubscriptionStore.ProductPayload) { continuation?.resume(returning: payload); continuation = nil }
}

@MainActor
private final class SyncGate {
    let started = XCTestExpectation(description: "Apple sync suspended")
    private var continuation: CheckedContinuation<Void, Never>?
    func wait() async {
        await withCheckedContinuation { continuation in self.continuation = continuation; started.fulfill() }
    }
    func finish() { continuation?.resume(); continuation = nil }
}
