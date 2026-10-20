import XCTest
import StoreKit
@testable import MapToDo

final class SubscriptionTests: XCTestCase {
    func testExpiredAndRevokedEntitlementsNeverGrantAccess() {
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertFalse(SubscriptionEntitlementPolicy.allowsAccess(productID: SubscriptionStore.productID, expirationDate: now, revocationDate: nil, now: now))
        XCTAssertFalse(SubscriptionEntitlementPolicy.allowsAccess(productID: SubscriptionStore.productID, expirationDate: now.addingTimeInterval(10), revocationDate: now, now: now))
    }
    func testOnlyExpectedActiveSubscriptionGrantsAccess() {
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertTrue(SubscriptionEntitlementPolicy.allowsAccess(productID: SubscriptionStore.productID, expirationDate: now.addingTimeInterval(1), revocationDate: nil, now: now))
        XCTAssertFalse(SubscriptionEntitlementPolicy.allowsAccess(productID: "other", expirationDate: now.addingTimeInterval(1), revocationDate: nil, now: now))
        XCTAssertFalse(SubscriptionEntitlementPolicy.allowsAccess(productID: SubscriptionStore.productID, expirationDate: nil, revocationDate: nil, now: now))
    }

    @MainActor
    func testEmptyCurrentEntitlementsUsesVerifiedSubscribedStatusToGrantStoreAccess() async {
        let expiry = Date().addingTimeInterval(3150)
        let status = statusEvidence(expiry: expiry)
        let store = SubscriptionStore(entitlementReader: {
            await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [status] })
        })
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasAccess, "R34: empty current sequence must not hide an active doubly verified subscription status")
        XCTAssertEqual(store.expirationDate, expiry)
    }

    @MainActor
    func testStatusFallbackRejectsExpiredOrMissingExpiration() async {
        for expiry in [Date().addingTimeInterval(-1), nil] as [Date?] {
            let status = statusEvidence(expiry: expiry)
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [status] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testStatusFallbackRejectsRevocationAndUpgrade() async {
        for mutation in 0..<2 {
            var status = statusEvidence()
            if mutation == 0 { status.transaction.revocationDate = Date() }
            else { status.transaction.isUpgraded = true }
            let candidate = status
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testStatusFallbackRequiresBothTransactionAndRenewalVerification() async {
        for mutation in 0..<2 {
            var status = statusEvidence()
            if mutation == 0 { status.transaction.isVerified = false }
            else { status.renewalIsVerified = false }
            let candidate = status
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testStatusFallbackRejectsWrongTransactionOrRenewalProduct() async {
        for mutation in 0..<2 {
            var status = statusEvidence()
            if mutation == 0 { status.transaction.productID = "another.subscription" }
            else { status.renewalProductID = "another.subscription" }
            let candidate = status
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testStatusFallbackDoesNotExpandExpiredRevokedRetryOrGraceStates() async {
        for state in [Product.SubscriptionInfo.RenewalState.expired, .revoked, .inBillingRetryPeriod, .inGracePeriod] {
            var status = statusEvidence()
            status.state = state
            let candidate = status
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testNonCooperativeStatusFallbackTimesOutAndDiscardsLateActiveResult() async {
        let gate = StatusEvidenceGate()
        let store = SubscriptionStore(entitlementReader: {
            await SubscriptionStore.resolveEntitlements(current: [], statusLoader: { await gate.read() }, statusTimeoutSeconds: 0.03)
        })
        let read = Task { await store.refreshEntitlements() }
        await fulfillment(of: [gate.started], timeout: 1)
        await read.value
        XCTAssertFalse(store.hasAccess)
        gate.resume([statusEvidence()])
        await Task.yield()
        XCTAssertFalse(store.hasAccess)
        XCTAssertNil(store.expirationDate)
    }

    @MainActor
    func testExplicitCurrentDenialCannotBeOverriddenByOlderActiveStatus() async {
        for mutation in 0..<4 {
            var current = statusEvidence().transaction
            switch mutation {
            case 0: current.revocationDate = Date()
            case 1: current.isUpgraded = true
            case 2: current.isVerified = false
            default: current.expirationDate = nil
            }
            let candidate = current
            let oldStatus = statusEvidence()
            var statusRequests = 0
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [candidate], statusLoader: {
                statusRequests += 1
                return [oldStatus]
            })
            XCTAssertNil(snapshot.expirationDate)
            XCTAssertEqual(statusRequests, 0, "A matching current denial must not consult an older positive status")
        }
    }

    @MainActor
    func testStaleExpiredCurrentIsReplacedOnlyByVerifiedNewerSameLineageRenewal() async {
        let now = Date()
        var old = statusEvidence().transaction
        old.purchaseDate = now.addingTimeInterval(-4000)
        old.signedDate = now.addingTimeInterval(-1000)
        old.expirationDate = now.addingTimeInterval(-400)
        var renewed = statusEvidence(expiry: now.addingTimeInterval(3200))
        renewed.transaction.purchaseDate = old.expirationDate
        renewed.transaction.signedDate = now.addingTimeInterval(-300)
        let stale = old, candidate = renewed
        let store = SubscriptionStore(entitlementReader: {
            await SubscriptionStore.resolveEntitlements(current: [stale], statusLoader: { [candidate] })
        })
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasAccess, "R38: stale expired current must not conceal a verified new subscribed renewal")
        XCTAssertEqual(store.expirationDate, renewed.transaction.expirationDate)
    }

    @MainActor
    func testMixedCurrentOldExpiryAndStrictlyNewerSameLineageActiveRenewalGrantsAccess() async {
        let now = Date()
        var old = statusEvidence().transaction
        old.purchaseDate = now.addingTimeInterval(-4000)
        old.signedDate = now.addingTimeInterval(-1000)
        old.expirationDate = now.addingTimeInterval(-400)
        var renewed = statusEvidence().transaction
        renewed.purchaseDate = old.expirationDate
        renewed.signedDate = now.addingTimeInterval(-300)
        var requests = 0
        let snapshot = await SubscriptionStore.resolveEntitlements(current: [old, renewed], statusLoader: {
            requests += 1
            return []
        })
        XCTAssertEqual(snapshot.expirationDate, renewed.expirationDate)
        XCTAssertEqual(requests, 0, "Verified current renewal with strict lineage proof should not require network fallback")
        var revokedOld = old
        revokedOld.revocationDate = now
        let denied = await SubscriptionStore.resolveEntitlements(current: [revokedOld, renewed], statusLoader: { [] })
        XCTAssertNil(denied.expirationDate, "Active current evidence must not bypass an explicit matching revocation")
        var unrelated = renewed
        unrelated.originalID = 456
        let mismatch = await SubscriptionStore.resolveEntitlements(current: [old, unrelated], statusLoader: { [] })
        XCTAssertNil(mismatch.expirationDate, "An arbitrary active current entry cannot override stale current from another lineage")
    }

    @MainActor
    func testExpiredCurrentCannotBeReplacedByUnrelatedOrNotNewerStatus() async {
        let now = Date()
        var old = statusEvidence().transaction
        old.purchaseDate = now.addingTimeInterval(-4000)
        old.signedDate = now.addingTimeInterval(-1000)
        old.expirationDate = now.addingTimeInterval(-400)
        for mutation in 0..<9 {
            var renewed = statusEvidence()
            renewed.transaction.purchaseDate = now.addingTimeInterval(-400)
            renewed.transaction.signedDate = now.addingTimeInterval(-300)
            switch mutation {
            case 0: renewed.transaction.originalID = 456; renewed.renewalOriginalID = 456
            case 1: renewed.renewalOriginalID = 456
            case 2: renewed.transaction.purchaseDate = old.purchaseDate
            case 3: renewed.transaction.signedDate = old.signedDate
            case 4: renewed.transaction.purchaseDate = now.addingTimeInterval(-500)
            case 5: renewed.transaction.environment = .production
            case 6: renewed.transaction.originalID = nil
            case 7: renewed.transaction.purchaseDate = nil
            default: renewed.transaction.signedDate = nil
            }
            let stale = old, candidate = renewed
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [stale], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate, "Mutation \(mutation) must not override expired current without newer same-lineage proof")
        }
    }

    @MainActor
    func testExpiredCurrentStillRejectsInvalidRenewalStatusEvidence() async {
        let now = Date()
        var old = statusEvidence().transaction
        old.purchaseDate = now.addingTimeInterval(-4000)
        old.signedDate = now.addingTimeInterval(-1000)
        old.expirationDate = now.addingTimeInterval(-400)
        for mutation in 0..<9 {
            var renewed = statusEvidence()
            renewed.transaction.purchaseDate = old.expirationDate
            renewed.transaction.signedDate = now.addingTimeInterval(-300)
            switch mutation {
            case 0: renewed.transaction.isVerified = false
            case 1: renewed.renewalIsVerified = false
            case 2: renewed.transaction.revocationDate = now
            case 3: renewed.transaction.isUpgraded = true
            case 4: renewed.transaction.productID = "another.subscription"
            case 5: renewed.renewalProductID = "another.subscription"
            case 6: renewed.state = .expired
            case 7: renewed.transaction.expirationDate = old.expirationDate
            default: renewed.transaction.expirationDate = nil
            }
            let stale = old, candidate = renewed
            let snapshot = await SubscriptionStore.resolveEntitlements(current: [stale], statusLoader: { [candidate] })
            XCTAssertNil(snapshot.expirationDate)
        }
    }

    @MainActor
    func testValidCurrentEntitlementAvoidsStatusNetworkAndStatusErrorFailsClosed() async {
        let active = statusEvidence().transaction
        var requests = 0
        let snapshot = await SubscriptionStore.resolveEntitlements(current: [active], statusLoader: {
            requests += 1
            throw URLError(.notConnectedToInternet)
        })
        XCTAssertEqual(snapshot.expirationDate, active.expirationDate)
        XCTAssertEqual(requests, 0)
        let failed = await SubscriptionStore.resolveEntitlements(current: [], statusLoader: {
            throw URLError(.notConnectedToInternet)
        })
        XCTAssertNil(failed.expirationDate)
    }

    @MainActor
    func testPreviouslyGrantedAccessIsDeniedAtExpiryBeforeSlowReaderFinishes() async {
        let gate = ExpirySnapshotGate()
        let expiry = Date().addingTimeInterval(0.2)
        var reads = 0
        let store = SubscriptionStore(entitlementReader: {
            reads += 1
            if reads == 1 { return .init(expirationDate: expiry, isLocalTest: true) }
            return await gate.read()
        })
        await store.refreshEntitlements()
        XCTAssertTrue(store.hasAccess)
        XCTAssertTrue(store.isLocalTestTransaction)
        // The actual production expiration task starts the next read at expiry.
        // A stalled SDK read must not extend the already-expired access window.
        await fulfillment(of: [gate.started], timeout: 2)
        XCTAssertGreaterThanOrEqual(Date(), expiry)
        XCTAssertFalse(store.hasAccess, "Expired cached access must be cleared before awaiting status/network work")
        XCTAssertNil(store.expirationDate)
        XCTAssertFalse(store.isLocalTestTransaction)
        // A later valid renewal can still grant access through the same reader.
        let renewalExpiry = Date().addingTimeInterval(3600)
        gate.resume(.init(expirationDate: renewalExpiry))
        await fulfillment(of: [gate.completed], timeout: 1)
        for _ in 0..<10 where !store.hasAccess { await Task.yield() }
        XCTAssertTrue(store.hasAccess)
        XCTAssertEqual(store.expirationDate, renewalExpiry)
    }

    private func statusEvidence(expiry: Date? = Date().addingTimeInterval(3600)) -> SubscriptionStore.SubscriptionStatusEvidence {
        .init(state: .subscribed,
              transaction: .init(productID: "com.waypoint.maptodo.annual", expirationDate: expiry,
                                 revocationDate: nil, isUpgraded: false, isVerified: true, isLocalTest: false,
                                 originalID: 123, purchaseDate: Date().addingTimeInterval(-100),
                                 signedDate: Date().addingTimeInterval(-10), environment: .sandbox),
              renewalIsVerified: true, renewalProductID: "com.waypoint.maptodo.annual", renewalOriginalID: 123)
    }

}


@MainActor
private final class StatusEvidenceGate {
    let started = XCTestExpectation(description: "Status fallback suspended")
    private var continuation: CheckedContinuation<[SubscriptionStore.SubscriptionStatusEvidence], Never>?
    func read() async -> [SubscriptionStore.SubscriptionStatusEvidence] {
        await withCheckedContinuation { continuation in self.continuation = continuation; started.fulfill() }
    }
    func resume(_ statuses: [SubscriptionStore.SubscriptionStatusEvidence]) {
        continuation?.resume(returning: statuses)
        continuation = nil
    }
}


@MainActor
private final class ExpirySnapshotGate {
    let started = XCTestExpectation(description: "Expired entitlement read suspended")
    let completed = XCTestExpectation(description: "Renewed entitlement read returned")
    private var continuation: CheckedContinuation<SubscriptionStore.EntitlementSnapshot, Never>?
    func read() async -> SubscriptionStore.EntitlementSnapshot {
        let snapshot = await withCheckedContinuation { continuation in
            self.continuation = continuation
            started.fulfill()
        }
        completed.fulfill()
        return snapshot
    }
    func resume(_ snapshot: SubscriptionStore.EntitlementSnapshot) {
        continuation?.resume(returning: snapshot)
        continuation = nil
    }
}
