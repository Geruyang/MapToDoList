import XCTest
@testable import MapToDo

final class SubscriptionTimeoutTests: XCTestCase {
    func testNonCooperativeOperationTimesOutWithoutWaitingForItsResult() async throws {
        let start = Date()
        do {
            _ = try await SubscriptionTimeout.run(seconds: 0.02) {
                // Deliberately ignores cancellation, matching a stuck SDK request.
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        continuation.resume(returning: true)
                    }
                }
            }
            XCTFail("Unconfirmed SDK result must not become a successful restore")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
            XCTAssertLessThan(Date().timeIntervalSince(start), 0.8)
        }
    }

    func testLateResultCannotReplaceANewOperationResult() async throws {
        do {
            _ = try await SubscriptionTimeout.run(seconds: 0.01) {
                await withCheckedContinuation { continuation in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        continuation.resume(returning: "late old result")
                    }
                }
            }
            XCTFail("Expected timeout")
        } catch { XCTAssertEqual((error as? URLError)?.code, .timedOut) }
        let current = try await SubscriptionTimeout.run(seconds: 1) { "current result" }
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(current, "current result")
    }

    func testSuccessfulOperationReturnsVerifiedWorkResultBeforeDeadline() async throws {
        let result = try await SubscriptionTimeout.run(seconds: 1) { 42 }
        XCTAssertEqual(result, 42)
    }
}
