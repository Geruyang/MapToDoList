import XCTest
import StoreKit
import StoreKitTest
@testable import MapToDo

/// Real StoreKit local transactions; requires MapToDo.storekit in the test bundle.
/// These tests do not contact App Store Connect or charge an Apple account.
final class StoreKitLifecycleTests: XCTestCase {
    @MainActor
    private func session() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "MapToDo")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    @MainActor
    func testFirstEligiblePurchaseActivatesVerifiedLocalTrial() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = SubscriptionStore()
        await store.refresh()
        XCTAssertNotNil(store.product, "Local StoreKit product must load")
        XCTAssertEqual(store.product?.price, Decimal(string: "9.99"))
        XCTAssertTrue(store.isEligibleForTrial, "A reset local account must be eligible")
        XCTAssertFalse(store.hasAccess, "Eligibility alone must not grant access")

        await store.purchase()
        XCTAssertTrue(store.hasAccess)
        XCTAssertTrue(store.isLocalTestTransaction)
        XCTAssertNotNil(store.expirationDate)
        let transaction = try await verifiedCurrentTransaction()
        XCTAssertEqual(transaction.environment, .xcode)
        XCTAssertEqual(transaction.offerType, .introductory)
        XCTAssertEqual(transaction.productID, SubscriptionStore.productID)
        await store.refresh()
        XCTAssertFalse(store.isEligibleForTrial, "Used introductory offer must not be offered again")
    }

    @MainActor
    func testRestoreFindsExistingVerifiedPurchaseOnFreshStore() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let transaction = try await session.buyProduct(identifier: SubscriptionStore.productID)
        await transaction.finish()
        let relaunchedStore = SubscriptionStore()
        XCTAssertFalse(relaunchedStore.hasAccess, "No cached/local entitlement bypass")
        await relaunchedStore.restore()
        XCTAssertTrue(relaunchedStore.hasAccess)
        XCTAssertTrue(relaunchedStore.isLocalTestTransaction)
    }

    @MainActor
    func testRefundTransactionListenerRevokesPreviouslyGrantedAccess() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = SubscriptionStore()
        await store.refresh()
        await store.purchase()
        XCTAssertTrue(store.hasAccess)
        let transaction = try await verifiedCurrentTransaction()
        try session.refundTransaction(identifier: UInt(transaction.id))
        // Do not call refresh: this assertion specifically verifies Transaction.updates.
        try await waitForAccess(false, store: store)
        XCTAssertNil(store.expirationDate)
    }

    @MainActor
    func testExpiredSubscriptionClearsAccessAndRestoreDoesNotReactivateIt() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = SubscriptionStore()
        await store.refresh()
        await store.purchase()
        XCTAssertTrue(store.hasAccess)
        try session.expireSubscription(productIdentifier: SubscriptionStore.productID)
        try await waitForAccess(false, store: store)
        await store.restore()
        XCTAssertFalse(store.hasAccess)
        XCTAssertNil(store.expirationDate)
    }

    @MainActor
    func testAskToBuyPendingBlocksDuplicatesThenApprovalGrantsAccess() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = SubscriptionStore()
        await store.refresh()
        await store.purchase()
        XCTAssertTrue(store.isPurchasePending)
        XCTAssertFalse(store.hasAccess)
        let pendingTransactions = session.allTransactions()
        let pending = try XCTUnwrap(pendingTransactions.first)
        await store.purchase()
        XCTAssertEqual(session.allTransactions().count, pendingTransactions.count, "Pending requests must block duplicate purchase calls")
        await store.refresh()
        XCTAssertTrue(store.isPurchasePending, "Refresh must not infer denial from absent entitlements")
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        try await waitForAccess(true, store: store)
        XCTAssertFalse(store.isPurchasePending)
    }

    @MainActor
    func testDeclinedAskToBuyCanExplicitlyRetryWithoutGrantingAccess() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = SubscriptionStore()
        await store.refresh()
        await store.purchase()
        XCTAssertTrue(store.isPurchasePending)
        let pending = try XCTUnwrap(session.allTransactions().first)
        try session.declineAskToBuyTransaction(identifier: pending.identifier)
        await store.refresh()
        XCTAssertFalse(store.hasAccess)
        // Apple does not provide a general API to query an outstanding request's rejection.
        // The explicit retry reconciles entitlements first, then submits a new Apple request.
        await store.retryPendingPurchase()
        XCTAssertTrue(store.isPurchasePending)
        XCTAssertFalse(store.hasAccess)
        let replacement = try XCTUnwrap(session.allTransactions().last)
        XCTAssertNotEqual(replacement.identifier, pending.identifier)
        try session.approveAskToBuyTransaction(identifier: replacement.identifier)
        try await waitForAccess(true, store: store)
        XCTAssertFalse(store.isPurchasePending)
    }

    @MainActor
    private func waitForAccess(_ expected: Bool, store: SubscriptionStore) async throws {
        let deadline = Date().addingTimeInterval(10)
        while store.hasAccess != expected && Date() < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(store.hasAccess, expected, "StoreKit transaction listener did not reconcile within 10 seconds")
    }

    private func verifiedCurrentTransaction() async throws -> Transaction {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == "com.waypoint.maptodo.annual" {
                return transaction
            }
        }
        throw NSError(domain: "StoreKitLifecycleTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected verified entitlement missing"])
    }
}
