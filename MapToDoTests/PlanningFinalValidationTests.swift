import XCTest
@testable import MapToDo
final class PlanningFinalValidationTests: XCTestCase {
 func testOutsideRangeNeighborIsIncludedAndBlocksInsufficientTransfer() {
  let base=Date(timeIntervalSince1970:100000)
  let moved=TaskItem(title:"Moved",scheduledAt:base,isFlexible:true)
  let next=TaskItem(title:"Outside range",scheduledAt:base.addingTimeInterval(3900))
  let proposal=PlanPreview(changes:[moved.id:base.addingTimeInterval(1800)])
  let context=PlanningFinalValidation.context(preview:proposal,allTasks:[moved,next])
  XCTAssertEqual(Set(context.tasks.map(\.id)),Set([moved.id,next.id]))
  let checked=PlanningFinalValidation.check(preview:proposal,context:context,travelMinutes:[TravelLeg(from:moved.id,to:next.id):60],weatherBuffers:[:])
  XCTAssertFalse(checked.conflicts.isEmpty)
 }
 func testTargetTimeWeatherBufferCanMakeTransferConflict() {
  let base=Date(timeIntervalSince1970:100000)
  let moved=TaskItem(title:"Moved",scheduledAt:base,isFlexible:true)
  let next=TaskItem(title:"Next",scheduledAt:base.addingTimeInterval(4500))
  let proposal=PlanPreview(changes:[moved.id:base.addingTimeInterval(1800)])
  let context=PlanningFinalValidation.context(preview:proposal,allTasks:[moved,next])
  let checked=PlanningFinalValidation.check(preview:proposal,context:context,travelMinutes:[TravelLeg(from:moved.id,to:next.id):10],weatherBuffers:[next.id:15])
  XCTAssertFalse(checked.conflicts.isEmpty)
 }
 func testFinalWeatherDependencyReceivesChangedTargetDate() async {
  let base=Date(timeIntervalSince1970:100000)
  let task=TaskItem(scheduledAt:base,isFlexible:true,flexibilityEnd:base.addingTimeInterval(172800))
  let target=base.addingTimeInterval(86400)
  let proposal=PlanPreview(changes:[task.id:target])
  let dependencies=PlanningValidationDependencies(weatherBuffer:{ item in XCTAssertEqual(item.scheduledAt,target); return 15 },travel:{ _,_,_ in 0 })
  let checked=await PlanningService().validateFinal(preview:proposal,allTasks:[task],mode:.walking,dependencies:dependencies)
  XCTAssertEqual(checked.changes[task.id],target)
 }
}
