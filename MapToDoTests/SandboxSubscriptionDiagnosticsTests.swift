import XCTest
import StoreKit
@testable import MapToDo

/// Read-only live service metadata. Run alone on the signed physical device with
/// StoreKit configuration disabled. Never invokes purchase/sync/reset/SKTestSession.
@MainActor
final class SandboxSubscriptionDiagnosticsTests: XCTestCase {
    func testReadOnlyLiveProductEligibilityAndVerifiedEntitlementMetadata() async throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This live sandbox diagnostic requires the authorized signed physical device; a skip is not sandbox evidence.")
        #else
        let requestedAt = ISO8601DateFormatter().string(from: Date())
        var evidence: [String: Any] = [
            "kind": "read_only_live_storekit_metadata",
            "productID": SubscriptionStore.productID,
            "requestedAt": requestedAt,
            "purchaseAttempted": false,
            "restoreSyncAttempted": false,
            "purchaseHistoryReset": false,
            "metadataEnvironment": "Cannot be proven from Product alone; inspect verified transaction environment when present."
        ]
        do {
            let metadata = try await SubscriptionTimeout.run(seconds: 20) {
                let storefront = await Storefront.current
                let product = try await Product.products(for: [SubscriptionStore.productID]).first
                let eligibility = await product?.subscription?.isEligibleForIntroOffer
                return (storefront, product, eligibility)
            }
            if let storefront = metadata.0 {
                evidence["storefront"] = ["id": storefront.id, "countryCode": storefront.countryCode]
            } else { evidence["storefront"] = NSNull() }
            guard let product = metadata.1 else {
                evidence["result"] = "product_unavailable"
                attach(evidence)
                XCTFail("Actual StoreKit product unavailable; no fixture or purchase fallback is allowed")
                return
            }
            var productRecord: [String: Any] = [
                "id": product.id,
                "displayPrice": product.displayPrice,
                "price": NSDecimalNumber(decimal: product.price).stringValue,
                "currencyCode": product.priceFormatStyle.currencyCode,
                "type": String(describing: product.type),
                "eligibleForIntroOffer": metadata.2 as Any? ?? NSNull()
            ]
            if let subscription = product.subscription {
                productRecord["duration"] = period(subscription.subscriptionPeriod)
                if let offer = subscription.introductoryOffer {
                    productRecord["introductoryOffer"] = [
                        "period": period(offer.period),
                        "periodCount": offer.periodCount,
                        "paymentMode": String(describing: offer.paymentMode),
                        "displayPrice": offer.displayPrice
                    ]
                    XCTAssertEqual(offer.paymentMode, .freeTrial)
                    XCTAssertTrue((offer.period.unit == .day && offer.period.value == 7) ||
                                  (offer.period.unit == .week && offer.period.value == 1))
                } else { XCTFail("Configured one-week introductory offer is absent from live metadata") }
                XCTAssertEqual(subscription.subscriptionPeriod.unit, .year)
                XCTAssertEqual(subscription.subscriptionPeriod.value, 1)
            } else { XCTFail("Live product is missing auto-renewable subscription metadata") }
            XCTAssertEqual(product.id, SubscriptionStore.productID)
            XCTAssertEqual(product.type, .autoRenewable)
            if metadata.0?.countryCode == "USA" {
                XCTAssertEqual(product.price, Decimal(string: "9.99"))
                XCTAssertEqual(product.priceFormatStyle.currencyCode, "USD")
            }
            evidence["product"] = productRecord
            let transactions = try await SubscriptionTimeout.run(seconds: 10) {
                var records: [[String: Any]] = []
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction) where transaction.productID == SubscriptionStore.productID:
                        records.append([
                            "productID": transaction.productID,
                            "verification": "verified",
                            "environment": String(describing: transaction.environment),
                            "expirationDate": transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) } as Any? ?? NSNull(),
                            "isRevoked": transaction.revocationDate != nil
                        ])
                        XCTAssertNotEqual(transaction.environment, .xcode, "Local StoreKit session contaminates real sandbox evidence")
                        XCTAssertEqual(transaction.environment, .sandbox, "Existing matching transaction is not a sandbox transaction")
                    case .unverified(let transaction, _) where transaction.productID == SubscriptionStore.productID:
                        records.append(["productID": transaction.productID, "verification": "unverified"])
                        XCTFail("Matching transaction failed verification; never report an entitlement")
                    default: break
                    }
                }
                return records
            }
            evidence["currentEntitlements"] = transactions
            evidence["entitlementInterpretation"] = transactions.isEmpty
                ? "No matching current entitlement; no purchase performed and sandbox transaction environment remains unproven."
                : "See verification and environment for matching existing entitlements; no purchase performed."
            evidence["result"] = "metadata_returned"
            attach(evidence)
        } catch {
            // Domain/code are diagnostics; full localized errors may contain account details.
            let nsError = error as NSError
            evidence["result"] = "service_error"
            evidence["errorDomain"] = nsError.domain
            evidence["errorCode"] = nsError.code
            attach(evidence)
            XCTFail("Live read-only StoreKit metadata request failed (domain/code in evidence)")
        }
        #endif
    }

    /// A diagnostic PASS means the bounded read-only queries completed; it is
    /// never a claim that a purchase, restore, or entitlement activation passed.
    func testReadOnlyLiveEntitlementMismatchLatestAndSubscriptionStatus() async throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Live entitlement mismatch diagnosis requires the authorized signed physical device; skip is not transaction evidence.")
        #else
        var evidence: [String: Any] = [
            "kind": "read_only_live_entitlement_mismatch",
            "productID": SubscriptionStore.productID,
            "requestedAt": diagnosticTimestamp(Date()),
            "requestedAtEpochSeconds": Date().timeIntervalSince1970,
            "purchaseAttempted": false, "restoreSyncAttempted": false,
            "transactionFinishAttempted": false, "purchaseHistoryReset": false,
            "interpretation": "Query completion is diagnostic evidence only. Empty/expired/unverified results never establish purchase or access.",
            "appCachedHasAccessBefore": SubscriptionStore.shared.hasAccess
        ]
        var product: Product?
        var failedReads = 0
        var started = Date()
        do {
            product = try await SubscriptionTimeout.run(seconds: 20) {
                try await Product.products(for: [SubscriptionStore.productID]).first
            }
            evidence["productRead"] = diagnosticStage(started: started, result: product == nil ? "empty" : "returned")
            if let product { evidence["returnedProductID"] = product.id }
        } catch {
            failedReads += 1
            evidence["productRead"] = diagnosticStage(started: started, result: "error", error: error)
        }

        started = Date()
        do {
            let records = try await SubscriptionTimeout.run(seconds: 10) {
                var records: [[String: Any]] = []
                for await result in Transaction.currentEntitlements {
                    if case .verified(let transaction) = result,
                       transaction.productID != SubscriptionStore.productID { continue }
                    records.append(self.diagnosticVerification(result))
                }
                return records
            }
            evidence["currentEntitlementsRead"] = diagnosticStage(started: started, result: records.isEmpty ? "empty" : "returned")
            evidence["currentEntitlements"] = records
        } catch {
            failedReads += 1
            evidence["currentEntitlementsRead"] = diagnosticStage(started: started, result: "error", error: error)
        }

        started = Date()
        do {
            let latest = try await SubscriptionTimeout.run(seconds: 10) {
                await Transaction.latest(for: SubscriptionStore.productID)
            }
            evidence["latestRead"] = diagnosticStage(started: started, result: latest == nil ? "empty" : "returned")
            evidence["latestTransaction"] = latest.map { diagnosticVerification($0) } as Any? ?? NSNull()
        } catch {
            failedReads += 1
            evidence["latestRead"] = diagnosticStage(started: started, result: "error", error: error)
        }

        started = Date()
        if let subscription = product?.subscription {
            do {
                let statuses = try await SubscriptionTimeout.run(seconds: 15) { try await subscription.status }
                evidence["subscriptionStatusRead"] = diagnosticStage(started: started, result: statuses.isEmpty ? "empty" : "returned")
                evidence["subscriptionStatuses"] = statuses.map { status -> [String: Any] in
                    var record: [String: Any] = ["state": diagnosticRenewalState(status.state),
                                               "transaction": diagnosticVerification(status.transaction)]
                    switch status.renewalInfo {
                    case .verified(let renewal):
                        record["renewalVerification"] = "verified"
                        record["gracePeriodExpirationDate"] = renewal.gracePeriodExpirationDate.map { diagnosticTimestamp($0) } as Any? ?? NSNull()
                    case .unverified(_, let error):
                        record["renewalVerification"] = "unverified"
                        record["renewalVerificationError"] = diagnosticError(error)
                    }
                    return record
                }
            } catch {
                failedReads += 1
                evidence["subscriptionStatusRead"] = diagnosticStage(started: started, result: "error", error: error)
            }
        } else {
            failedReads += 1
            evidence["subscriptionStatusRead"] = diagnosticStage(started: started, result: "unavailable_without_subscription_product")
        }
        evidence["completedAt"] = diagnosticTimestamp(Date())
        evidence["appCachedHasAccessAfter"] = SubscriptionStore.shared.hasAccess
        evidence["failedReadCount"] = failedReads
        evidence["result"] = failedReads == 0 ? "read_only_queries_completed" : "partial_read_failure"
        attach(evidence)
        XCTAssertEqual(failedReads, 0, "A bounded read-only query failed; inspect whitelisted phase evidence, not credentials.")
        #endif
    }

    private func diagnosticVerification(_ result: VerificationResult<Transaction>) -> [String: Any] {
        switch result {
        case .verified(let transaction):
            let now = Date()
            return [
                "verification": "verified", "productID": transaction.productID,
                "matchesRequestedProduct": transaction.productID == SubscriptionStore.productID,
                "environment": String(describing: transaction.environment),
                "purchaseDate": diagnosticTimestamp(transaction.purchaseDate),
                "expirationDate": transaction.expirationDate.map { diagnosticTimestamp($0) } as Any? ?? NSNull(),
                "revocationDate": transaction.revocationDate.map { diagnosticTimestamp($0) } as Any? ?? NSNull(),
                "isRevoked": transaction.revocationDate != nil, "isUpgraded": transaction.isUpgraded,
                "signedDate": diagnosticTimestamp(transaction.signedDate),
                "now": diagnosticTimestamp(now), "nowEpochSeconds": now.timeIntervalSince1970,
                "nowMinusSignedDateSeconds": now.timeIntervalSince(transaction.signedDate),
                "expirationMinusNowSeconds": transaction.expirationDate.map { $0.timeIntervalSince(now) } as Any? ?? NSNull(),
                "currentAppPolicyAllowsAccess": SubscriptionEntitlementPolicy.allowsAccess(
                    productID: transaction.productID, expirationDate: transaction.expirationDate,
                    revocationDate: transaction.revocationDate, now: now)
            ]
        case .unverified(_, let error):
            // Do not serialize or inspect the untrusted transaction payload.
            return ["verification": "unverified", "verificationError": diagnosticError(error)]
        }
    }

    private func diagnosticStage(started: Date, result: String, error: Error? = nil) -> [String: Any] {
        let completed = Date()
        var record: [String: Any] = ["result": result, "startedAt": diagnosticTimestamp(started),
                                     "completedAt": diagnosticTimestamp(completed),
                                     "elapsedSeconds": completed.timeIntervalSince(started)]
        if let error { record["error"] = diagnosticError(error) }
        return record
    }

    private func diagnosticTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func diagnosticError(_ error: Error) -> [String: Any] {
        let value = error as NSError
        return ["domain": value.domain, "code": value.code]
    }

    private func diagnosticRenewalState(_ state: Product.SubscriptionInfo.RenewalState) -> String {
        switch state {
        case .subscribed: return "subscribed"
        case .expired: return "expired"
        case .inBillingRetryPeriod: return "inBillingRetryPeriod"
        case .inGracePeriod: return "inGracePeriod"
        case .revoked: return "revoked"
        default: return "unknown"
        }
    }

    private func period(_ period: Product.SubscriptionPeriod) -> [String: Any] {
        ["unit": String(describing: period.unit), "value": period.value]
    }

    private func attach(_ payload: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = "SANDBOX_READ_ONLY_STOREKIT_METADATA"
            attachment.lifetime = .keepAlways
            add(attachment)
        } catch { XCTFail("Unable to encode redacted StoreKit diagnostic evidence") }
    }
}
