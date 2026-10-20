import XCTest
@testable import MapToDo
final class PlanningTimeoutTests: XCTestCase {
 func testOperationThatIgnoresCancellationDoesNotHoldWaiter() async {
  let start=Date()
  do {
   let _: Int = try await PlanningTimeout.run(seconds:0.01) {
    await withCheckedContinuation { continuation in DispatchQueue.global().asyncAfter(deadline:.now()+0.3) { continuation.resume(returning:1) } }
   }
   XCTFail("Expected timeout")
  } catch { XCTAssertLessThan(Date().timeIntervalSince(start),0.2) }
 }
}
