import XCTest
import Security
@testable import MapToDo
final class AIParsingTests: XCTestCase {
 func testFixedTimeSuggestionIsRejected() {
  let task = TaskItem(title:"Fixed")
  let text = "{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"2026-10-11T08:00:00Z\"}]}"
  XCTAssertThrowsError(try AIService.parse(text,tasks:[task]))
 }
 func testMalformedResponseIsRejected() {
  XCTAssertThrowsError(try AIService.parse("not json",tasks:[]))
 }
 func testValidFlexibleWindowSuggestion() throws {
  let start = Date(timeIntervalSince1970: 100000)
  let task=TaskItem(scheduledAt:start,isFlexible:true,flexibilityEnd:start.addingTimeInterval(7200))
  let date=start.addingTimeInterval(600)
  let text="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"\(ISO8601DateFormatter().string(from:date))\"}]}"
  XCTAssertEqual(try AIService.parse(text,tasks:[task]).changes[task.id],date)
 }
 func testOutsideWindowIsRejected() {
  let task=TaskItem(scheduledAt:Date(timeIntervalSince1970:100000),isFlexible:true)
  let text="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"2026-10-11T08:00:00Z\"}]}"
  XCTAssertThrowsError(try AIService.parse(text,tasks:[task]))
 }
 func testUnselectedFixedAppointmentBlocksApply() {
  let start=Date(timeIntervalSince1970:100000)
  let selected=TaskItem(scheduledAt:start,durationMinutes:30,isFlexible:true)
  let unselected=TaskItem(title:"Appointment",scheduledAt:start.addingTimeInterval(1800),durationMinutes:60)
  let proposal=PlanPreview(changes:[selected.id:start.addingTimeInterval(1800)])
  XCTAssertFalse(AIService.validate(preview:proposal,allTasks:[selected,unselected]).conflicts.isEmpty)
 }
 func testQwenRegionalEndpointsMatchOfficialDomains() throws {
  XCTAssertEqual(QwenRegion.singapore.baseURL,"https://dashscope-intl.aliyuncs.com/compatible-mode/v1")
  XCTAssertEqual(QwenRegion.beijing.baseURL,"https://dashscope.aliyuncs.com/compatible-mode/v1")
  XCTAssertEqual(QwenRegion.virginia.baseURL,"https://dashscope-us.aliyuncs.com/compatible-mode/v1")
  XCTAssertThrowsError(try QwenRegion.virginia.modelsBaseURL(workspace:""))
  XCTAssertThrowsError(try QwenRegion.beijing.modelsBaseURL(workspace:"bad/host"))
  XCTAssertEqual(try QwenRegion.virginia.modelsBaseURL(workspace:"llm-test"),"https://llm-test.us-east-1.maas.aliyuncs.com/api/v1")
 }
}

extension AIParsingTests {
 func testGeminiConcatenatesTextPartsAndSkipsThoughts() throws {
  let response: [String:Any] = ["candidates":[["finishReason":"STOP","content":["parts":[["text":"private reasoning","thought":true],["text":"{\"changes\":"],["text":"[]}"]]]]]]
  XCTAssertEqual(try AIService.responseText(response,provider:.gemini),"{\"changes\":[]}")
 }
 func testTruncatedOpenAIResponseIsRejected() {
  XCTAssertThrowsError(try AIService.responseText(["status":"incomplete","output":[]],provider:.openAI))
 }
 func testOpenAIResponsesEnvelopeExtractsOutputText() throws {
  let response: [String:Any] = ["status":"completed","output":[["type":"reasoning","summary":[]],["type":"message","content":[["type":"output_text","text":"{\"changes\":[]}"]]]]]
  XCTAssertEqual(try AIService.responseText(response,provider:.openAI),"{\"changes\":[]}")
 }
 func testCompletedFlexibleTaskCannotBeMoved() {
  let task=TaskItem(scheduledAt:Date(timeIntervalSince1970:100000),isFlexible:true,isCompleted:true)
  let text="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"1970-01-02T03:46:40Z\"}]}"
  XCTAssertThrowsError(try AIService.parse(text,tasks:[task]))
 }
 func testFractionalSecondsAndOffsetRepresentSameInstant() throws {
  let start=Date(timeIntervalSince1970:100000)
  let task=TaskItem(scheduledAt:start,isFlexible:true)
  let text="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"1970-01-02T11:46:40.000+08:00\"}]}"
  XCTAssertEqual(try AIService.parse(text,tasks:[task]).changes[task.id],start)
 }
 func testUnrelatedHistoricalConflictDoesNotBlockNewChanges() {
  let start=Date(timeIntervalSince1970:100000)
  let oldA=TaskItem(scheduledAt:start,durationMinutes:60)
  let oldB=TaskItem(scheduledAt:start,durationMinutes:60)
  let future=TaskItem(scheduledAt:start.addingTimeInterval(86400),isFlexible:true)
  let proposal=PlanPreview(changes:[future.id:future.scheduledAt.addingTimeInterval(600)])
  XCTAssertTrue(AIService.validate(preview:proposal,allTasks:[oldA,oldB,future]).conflicts.isEmpty)
 }
}

extension AIParsingTests {
 func testChangedTaskConflictsWithLongUnselectedAppointment() {
  let start=Date(timeIntervalSince1970:100000)
  let long=TaskItem(title:"Long",scheduledAt:start,durationMinutes:180)
  let nested=TaskItem(title:"Nested",scheduledAt:start.addingTimeInterval(600),durationMinutes:10)
  let moved=TaskItem(title:"Moved",scheduledAt:start.addingTimeInterval(20000),isFlexible:true)
  let proposal=PlanPreview(changes:[moved.id:start.addingTimeInterval(3600)])
  XCTAssertFalse(AIService.validate(preview:proposal,allTasks:[long,nested,moved]).conflicts.isEmpty)
 }
}

extension AIParsingTests {
 func testOpenAIRequestExplicitlyDisablesResponseStorage() {
  let body=AIService.openAIRequestBody(prompt:"synthetic",model:"test-model")
  XCTAssertEqual(body["store"] as? Bool,false)
  XCTAssertEqual(body["input"] as? String,"synthetic")
  XCTAssertEqual(body["model"] as? String,"test-model")
 }
 func testTransmissionIDsAreTemporaryAndMapBackLocally() {
  let task=TaskItem(title:"Synthetic appointment")
  let first=AIService.transmissionTasks([task])
  let second=AIService.transmissionTasks([task])
  XCTAssertNotEqual(first.tasks[0].id,task.id)
  XCTAssertNotEqual(first.tasks[0].id,second.tasks[0].id)
  XCTAssertEqual(first.localIDs[first.tasks[0].id],task.id)
  XCTAssertEqual(first.tasks[0].title,task.title)
 }
}

extension AIParsingTests {
 func testKeychainErrorsDescribeRecoveryWithoutRawStatusCodes() {
  let cases: [(OSStatus,String)] = [
   (errSecInteractionNotAllowed,String(localized:"钥匙串暂时无法访问，请解锁设备后重试。")),
   (errSecNotAvailable,String(localized:"系统钥匙串暂时不可用，请稍后重试。")),
   (errSecMissingEntitlement,String(localized:"应用的钥匙串权限配置有误，请联系开发者。"))
  ]
  for (status,expected) in cases {
   XCTAssertEqual(AIKeychain.userError(status).localizedDescription,expected)
   XCTAssertFalse(AIKeychain.userError(status).localizedDescription.contains(String(status)))
  }
 }
}

extension AIParsingTests {
 func testSerializedTimeDoesNotLoseFractionalWindowPrecision() {
  let date=Date(timeIntervalSince1970:100000.500)
  let text=AIService.timestamp(date)
  XCTAssertTrue(text.contains(".500"))
  let task=TaskItem(scheduledAt:date,isFlexible:true)
  let json="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"\(text)\"}]}"
  XCTAssertEqual(try? AIService.parse(json,tasks:[task]).changes[task.id],date)
 }
 func testModelRefreshSnapshotRejectsChangedWorkspace() {
  let old=AIModelRefreshSnapshot(provider:.qwen,region:.beijing,workspace:"old")
  XCTAssertFalse(old.matches(provider:.qwen,region:.beijing,workspace:"new"))
  XCTAssertFalse(old.matches(provider:.openAI,region:.beijing,workspace:"old"))
 }
}


extension AIParsingTests {
 func testFineFractionalTimestampRoundtripKeepsExactLowerBound() throws {
  let date=Date(timeIntervalSince1970:1800000000.1234567)
  let text=AIService.timestamp(date)
  let task=TaskItem(scheduledAt:date,isFlexible:true)
  let json="{\"changes\":[{\"id\":\"\(task.id)\",\"start\":\"\(text)\"}]}"
  XCTAssertEqual(try AIService.parse(json,tasks:[task]).changes[task.id],date)
 }
}
