import XCTest
@testable import MapToDo
final class PlanningTests: XCTestCase {
 func testFixedTimeRemainsAndFlexibleMovesPastTravel() {
  let start = Date(timeIntervalSince1970: 100000)
  let fixed = TaskItem(title: "Fixed", scheduledAt: start, durationMinutes: 30)
  let flexible = TaskItem(title: "Flexible", scheduledAt: start, durationMinutes: 20, isFlexible: true, flexibilityEnd: start.addingTimeInterval(7200))
  let result = LocalPlanner.plan(tasks: [fixed, flexible], travelMinutes: [TravelLeg(from: fixed.id, to: flexible.id): 10], weatherBuffers: [:])
  XCTAssertNil(result.changes[fixed.id])
  XCTAssertEqual(result.changes[flexible.id], start.addingTimeInterval(2400))
 }
 func testImpossibleWindowReportsConflict() {
  let start = Date(timeIntervalSince1970: 100000)
  let fixed = TaskItem(scheduledAt: start, durationMinutes: 60)
  let flexible = TaskItem(scheduledAt: start, durationMinutes: 30, isFlexible: true, flexibilityEnd: start.addingTimeInterval(3600))
  let result = LocalPlanner.plan(tasks: [fixed, flexible], travelMinutes: [:], weatherBuffers: [:])
  XCTAssertNil(result.changes[flexible.id])
  XCTAssertFalse(result.conflicts.isEmpty)
 }
 func testWeatherBufferConsumesGapWithoutMovingFixedItem() {
  let start=Date(timeIntervalSince1970:100000)
  let fixed=TaskItem(scheduledAt:start,durationMinutes:30)
  let flexible=TaskItem(scheduledAt:start,durationMinutes:30,isFlexible:true,flexibilityEnd:start.addingTimeInterval(7200))
  let result=LocalPlanner.plan(tasks:[fixed,flexible],travelMinutes:[:],weatherBuffers:[flexible.id:15])
  XCTAssertEqual(result.changes[flexible.id],start.addingTimeInterval(2700))
  XCTAssertNil(result.changes[fixed.id])
 }
}
