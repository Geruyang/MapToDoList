import XCTest
@testable import MapToDo

final class AIReleaseGateTests: XCTestCase {
 func testReleaseOffersExactlyFourProviders() {
  XCTAssertEqual(AIProvider.availableProviders,[.glm,.qwen,.deepSeek,.openAI])
  XCTAssertFalse(AIProvider.gemini.isAvailable)
 }
 func testOldGeminiSelectionMovesToAvailableGLMModel() {
  XCTAssertEqual(AISelectionPolicy.normalized(providerName:"Gemini",model:"gemini-3.8-flash"),AISelection(provider:.glm,model:"glm-5.3"))
 }
 func testEnabledCustomModelIsPreserved() {
  XCTAssertEqual(AISelectionPolicy.normalized(providerName:"Qwen",model:"my-custom-model"),AISelection(provider:.qwen,model:"my-custom-model"))
 }
 func testMigrationOnlyChangesNonSecretPreferences() {
  let name="WaypointAIReleaseGateTests-"+UUID().uuidString
  let defaults=UserDefaults(suiteName:name)!
  defer { defaults.removePersistentDomain(forName:name) }
  defaults.set("Gemini",forKey:"ai.provider")
  defaults.set("gemini-old",forKey:"ai.model")
  defaults.set("unchanged",forKey:"unrelated.setting")
  AISelectionPolicy.migrate(defaults:defaults)
  XCTAssertEqual(defaults.string(forKey:"ai.provider"),"GLM")
  XCTAssertEqual(defaults.string(forKey:"ai.model"),"glm-5.3")
  XCTAssertEqual(defaults.string(forKey:"unrelated.setting"),"unchanged")
 }
 func testGeminiModelRequestsAreRejectedBeforeAuthentication() async {
  do { _=try await AIService().models(provider:.gemini); XCTFail("Disabled provider request allowed") }
  catch { XCTAssertEqual(error.localizedDescription,String(localized:"Gemini 在此版本中不可用，请选择其他服务。")) }
 }
 func testGeminiGenerationIsRejectedBeforeAuthentication() async {
  do { _=try await AIService().suggest(tasks:[],provider:.gemini,model:"gemini-old"); XCTFail("Disabled provider generation allowed") }
  catch { XCTAssertEqual(error.localizedDescription,String(localized:"Gemini 在此版本中不可用，请选择其他服务。")) }
 }
}


extension AIReleaseGateTests {
 func testOpenAIRequiresBothKnownNonMainlandCountriesAndFreshRealPosition() {
  let now=Date(timeIntervalSince1970:1_800_000_000)
  for (physical,network,allowed) in [("US","US",true),("CN","US",false),("US","CN",false),("CN","CN",false),("HK","MO",true),("ZZ","US",false),("US","ZZ",false),("","US",false)] {
   XCTAssertEqual(OpenAIRegionPolicy.allows(positionCountry:physical,networkCountry:network,positionDate:now,now:now),allowed,"\(physical)/\(network)")
  }
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:nil,networkCountry:"US",positionDate:now,now:now))
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:"US",networkCountry:nil,positionDate:now,now:now))
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:"US",networkCountry:"US",positionDate:nil,now:now))
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:"US",networkCountry:"US",positionDate:now.addingTimeInterval(-121),now:now))
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:"US",networkCountry:"US",positionDate:now.addingTimeInterval(1),now:now))
  XCTAssertFalse(OpenAIRegionPolicy.allows(positionCountry:"US",networkCountry:"US",positionDate:now,now:now,mocked:true))
 }
 func testRegionFilteringAndMigrationPreserveOnlyEligibleProviderChoices() {
  XCTAssertEqual(AIProvider.eligibleProviders(openAIAllowed:false),[.glm,.qwen,.deepSeek])
  XCTAssertEqual(AIProvider.eligibleProviders(openAIAllowed:true),[.glm,.qwen,.deepSeek,.openAI])
  XCTAssertEqual(AISelectionPolicy.normalized(providerName:"OpenAI",model:"custom-openai",openAIAllowed:false),AISelection(provider:.glm,model:"glm-5.3"))
  XCTAssertEqual(AISelectionPolicy.normalized(providerName:"OpenAI",model:"custom-openai",openAIAllowed:true),AISelection(provider:.openAI,model:"custom-openai"))
 }
 @MainActor func testUnverifiedOpenAIServiceCallsFailBeforeAuthenticationOrTransmission() async {
  OpenAIRegionGate.shared.invalidate()
  do { _=try await AIService().models(provider:.openAI); XCTFail("Unverified OpenAI model request allowed") }
  catch { XCTAssertTrue(error.localizedDescription.contains("OpenAI")) }
  do { _=try await AIService().suggest(tasks:[],provider:.openAI,model:"test-model"); XCTFail("Unverified OpenAI generation allowed") }
  catch { XCTAssertTrue(error.localizedDescription.contains("OpenAI")) }
 }
}

private final class RegionLookupStub: URLProtocol {
 private static let replyLock=NSLock()
 private static var storedReply: (URLRequest) -> (Int, String) = { _ in (200,"{\"country\":\"US\"}") }
 static var reply: (URLRequest) -> (Int, String) {
  get { replyLock.lock();defer { replyLock.unlock() };return storedReply }
  set { replyLock.lock();storedReply=newValue;replyLock.unlock() }
 }
 override class func canInit(with request: URLRequest) -> Bool { true }
 override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
 override func startLoading() {
  let (status, body)=Self.reply(request)
  let response=HTTPURLResponse(url:request.url!,statusCode:status,httpVersion:nil,headerFields:["Content-Type":"application/json"])!
  client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
  client?.urlProtocol(self,didLoad:Data(body.utf8))
  client?.urlProtocolDidFinishLoading(self)
 }
 override func stopLoading() {}
}

// Every fixture has a separate routing token. No request can fall through to a
// real network, and delayed completions obey URLProtocol's stopLoading contract.
private final class RegionTransportStub: URLProtocol {
 private static let registryLock=NSLock()
 private static var registry:[String:(RegionTransportStub)->Void]=[:]
 private let completionLock=NSRecursiveLock()
 private var finished=false
 private var stopped=false
 private var stopObserver:(()->Void)?
 static func register(_ token:String,handler:@escaping (RegionTransportStub)->Void) {
  registryLock.lock();registry[token]=handler;registryLock.unlock()
 }
 static func unregister(_ token:String) { registryLock.lock();registry.removeValue(forKey:token);registryLock.unlock() }
 override class func canInit(with request:URLRequest)->Bool { true }
 override class func canonicalRequest(for request:URLRequest)->URLRequest { request }
 override func startLoading() {
  let token=request.value(forHTTPHeaderField:"X-Waypoint-Test-Route") ?? ""
  Self.registryLock.lock();let handler=Self.registry[token];Self.registryLock.unlock()
  guard let handler else { client?.urlProtocol(self,didFailWithError:URLError(.unsupportedURL));return }
  handler(self)
 }
 func observeStop(_ observer:@escaping ()->Void) { completionLock.lock();stopObserver=observer;completionLock.unlock() }
 override func stopLoading() {
  completionLock.lock();let observer=stopped ? nil : stopObserver;stopped=true;completionLock.unlock();observer?()
 }
 func respond(_ body:String) {
  completionLock.lock();defer { completionLock.unlock() }
  guard !finished,!stopped else { return };finished=true
  let response=HTTPURLResponse(url:request.url!,statusCode:200,httpVersion:nil,headerFields:["Content-Type":"application/json"])!
  client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
  client?.urlProtocol(self,didLoad:Data(body.utf8))
  client?.urlProtocolDidFinishLoading(self)
 }
}

private final class RegionTransportFixture {
 private let lock=NSLock()
 private let token=UUID().uuidString
 private var counts:[String:Int]=[:]
 private var stopCounts:[String:Int]=[:]
 private var stopExpectations:[String:XCTestExpectation]=[:]
 private var countryHandler:((RegionTransportStub)->Void)?
 private var apiHandler:((RegionTransportStub)->Void)?
 private var held:RegionTransportStub?
 lazy var session:URLSession = {
  let config=URLSessionConfiguration.ephemeral
  config.protocolClasses=[RegionTransportStub.self]
  config.httpAdditionalHeaders=["X-Waypoint-Test-Route":token]
  return URLSession(configuration:config)
 }()
 init() { RegionTransportStub.register(token) { [weak self] request in self?.receive(request) } }
 func close() { session.invalidateAndCancel();RegionTransportStub.unregister(token) }
 func count(_ host:String)->Int { lock.lock();defer { lock.unlock() };return counts[host,default:0] }
 func stoppedCount(_ host:String)->Int { lock.lock();defer { lock.unlock() };return stopCounts[host,default:0] }
 func expectStop(_ host:String,expectation:XCTestExpectation) { lock.lock();stopExpectations[host]=expectation;lock.unlock() }
 func delay(_ host:String,started:XCTestExpectation) {
  let handler:(RegionTransportStub)->Void = { [weak self] request in
   guard let self else { return };self.lock.lock();self.held=request;self.lock.unlock();started.fulfill()
  }
  lock.lock();if host == "api.country.is" { countryHandler=handler } else { apiHandler=handler };lock.unlock()
 }
 func releaseHeld(_ body:String) {
  lock.lock();let request=held;held=nil;lock.unlock();request?.respond(body)
 }
 private func receive(_ request:RegionTransportStub) {
  let host=request.request.url?.host ?? ""
  request.observeStop { [weak self] in
   guard let self else { return }
   self.lock.lock();self.stopCounts[host,default:0]+=1
   let expectation=self.stopExpectations.removeValue(forKey:host);self.lock.unlock();expectation?.fulfill()
  }
  lock.lock();counts[host,default:0]+=1
  let handler=host == "api.country.is" ? countryHandler : apiHandler;lock.unlock()
  guard host == "api.country.is" || host == "api.openai.com" else {
   XCTFail("Unexpected transport host");request.respond("{}");return
  }
  if let handler { handler(request) }
  else { request.respond(host == "api.country.is" ? "{\"country\":\"US\"}" : "{\"ok\":true}") }
 }
}

extension AIReleaseGateTests {
 @MainActor private func transportGate(_ fixture:RegionTransportFixture,country:String? = "US")->OpenAIRegionGate {
  OpenAIRegionGate(network:OpenAIRegionNetworkClient(session:fixture.session),positionProvider:{ OpenAIRegionPosition(countryCode:country,measuredAt:Date(),mocked:false) },permissionProvider:{true},monitoringEnabled:false)
 }
 private func openAITransportRequest()->URLRequest { URLRequest(url:URL(string:"https://api.openai.com/v1/models")!) }

 // Catches a gate that blocks valid evidence or never starts the approved task.
 @MainActor func testAllowedRegionTransportReturnsResponseAfterNetworkRecheck() async throws {
  let fixture=RegionTransportFixture();defer { fixture.close() }
  let gate=transportGate(fixture);await gate.checkAvailability()
  XCTAssertTrue(gate.isAllowed)
  let (data,response)=try await gate.send(openAITransportRequest(),session:fixture.session)
  XCTAssertEqual(data,Data("{\"ok\":true}".utf8))
  XCTAssertEqual((response as? HTTPURLResponse)?.statusCode,200)
  XCTAssertEqual(fixture.count("api.country.is"),2)
  XCTAssertEqual(fixture.count("api.openai.com"),1)
  gate.invalidate()
 }

 // Catches querying the IP service, or starting OpenAI, with disallowed position.
 @MainActor func testMainlandAndUnknownPositionNeverQueryCountryOrStartOpenAI() async {
  for country in ["CN",nil,"ZZ"] as [String?] {
   let fixture=RegionTransportFixture();defer { fixture.close() }
   let gate=transportGate(fixture,country:country);await gate.checkAvailability()
   XCTAssertFalse(gate.isAllowed)
   do { _=try await gate.send(openAITransportRequest(),session:fixture.session);XCTFail("Disallowed position started a transport") } catch {}
   XCTAssertEqual(fixture.count("api.country.is"),0)
   XCTAssertEqual(fixture.count("api.openai.com"),0)
  }
 }

 // Catches re-enabling a revoked permit when a previously started IP lookup wins.
 @MainActor func testLateCountryResponseAfterInvalidationNeverStartsOpenAI() async throws {
  let fixture=RegionTransportFixture();defer { fixture.close() }
  let gate=transportGate(fixture);await gate.checkAvailability()
  let started=expectation(description:"Send country recheck started")
  fixture.delay("api.country.is",started:started)
  let request=openAITransportRequest()
  let operation=Task { try await gate.send(request,session:fixture.session) }
  defer { operation.cancel();gate.invalidate() }
  await fulfillment(of:[started],timeout:2)
  gate.invalidate();fixture.releaseHeld("{\"country\":\"US\"}")
  let result=try await PlanningTimeout.run(seconds:2) { await operation.result }
  if case .success=result { XCTFail("Late country response authorized OpenAI") }
  XCTAssertFalse(gate.isAllowed)
  XCTAssertEqual(fixture.count("api.openai.com"),0)
 }

 // Catches dropping the active-task registry or delivering success after revoke.
 @MainActor func testInvalidationCancelsActiveTransportAndRejectsLateResponse() async throws {
  let fixture=RegionTransportFixture();defer { fixture.close() }
  let gate=transportGate(fixture);await gate.checkAvailability()
  let started=expectation(description:"OpenAI transport started")
  let stopped=expectation(description:"Revoked transport stopped")
  fixture.expectStop("api.openai.com",expectation:stopped)
  fixture.delay("api.openai.com",started:started)
  let request=openAITransportRequest()
  let operation=Task { try await gate.send(request,session:fixture.session) }
  defer { operation.cancel();gate.invalidate() }
  await fulfillment(of:[started],timeout:2)
  gate.invalidate()
  let result=try await PlanningTimeout.run(seconds:2) { await operation.result }
  await fulfillment(of:[stopped],timeout:2)
  // A delayed success is now attempted after URLSession acknowledged cancellation.
  // The protocol must not deliver callbacks after stopLoading; the caller already
  // received cancellation, and the late URLSession completion cannot resume it.
  fixture.releaseHeld("{\"ok\":true}")
  switch result {
  case .success:XCTFail("Revoked active transport delivered success")
  case .failure(let error):XCTAssertTrue(error is CancellationError)
  }
  XCTAssertFalse(gate.isAllowed)
  XCTAssertEqual(fixture.count("api.openai.com"),1)
  XCTAssertEqual(fixture.stoppedCount("api.openai.com"),1)
 }

 // Catches a cancellation handler that leaves the registered request suspended.
 @MainActor func testCallerCancellationEndsActiveTransportWithoutSuccess() async throws {
  let fixture=RegionTransportFixture();defer { fixture.close() }
  let gate=transportGate(fixture);await gate.checkAvailability()
  let started=expectation(description:"Cancelable OpenAI transport started")
  let stopped=expectation(description:"Caller-canceled transport stopped")
  fixture.expectStop("api.openai.com",expectation:stopped)
  fixture.delay("api.openai.com",started:started)
  let request=openAITransportRequest()
  let operation=Task { try await gate.send(request,session:fixture.session) }
  defer { operation.cancel();gate.invalidate() }
  await fulfillment(of:[started],timeout:2)
  operation.cancel()
  let result=try await PlanningTimeout.run(seconds:2) { await operation.result }
  await fulfillment(of:[stopped],timeout:2)
  fixture.releaseHeld("{\"ok\":true}")
  switch result {
  case .success:XCTFail("Canceled caller received success")
  case .failure(let error):XCTAssertTrue(error is CancellationError)
  }
  XCTAssertEqual(fixture.count("api.openai.com"),1)
  XCTAssertEqual(fixture.stoppedCount("api.openai.com"),1)
 }
}

extension AIReleaseGateTests {
 private func regionTestClient() -> OpenAIRegionNetworkClient {
  let config=URLSessionConfiguration.ephemeral
  config.protocolClasses=[RegionLookupStub.self]
  return OpenAIRegionNetworkClient(session:URLSession(configuration:config))
 }
 func testRegionLookupValidatesCountryAndDoesNotSendLocationOrAPIKey() async throws {
  RegionLookupStub.reply={ request in
   XCTAssertEqual(request.url?.absoluteString,"https://api.country.is/")
   XCTAssertNil(request.httpBody)
   XCTAssertNil(request.value(forHTTPHeaderField:"Authorization"))
   return (200,"{\"country\":\"US\",\"ip\":\"192.0.2.1\"}")
  }
  let country=try await regionTestClient().country()
  XCTAssertEqual(country,"US")
  for response in [(200,"{}"),(200,"{\"country\":\"ZZ\"}"),(429,"{\"country\":\"US\"}"),(500,"{\"country\":\"US\"}")] {
   RegionLookupStub.reply={ _ in response }
   do { _=try await regionTestClient().country(); XCTFail("Invalid region response allowed") }
   catch {}
  }
 }
 @MainActor func testSilentRefreshWithoutPermissionDoesNotLocateOrQueryNetwork() async {
  RegionLookupStub.reply={ _ in XCTFail("Denied permission queried network");return (200,"{\"country\":\"US\"}") }
  let gate=OpenAIRegionGate(network:regionTestClient(),positionProvider:{ XCTFail("Denied permission requested location");return OpenAIRegionPosition(countryCode:"US",measuredAt:Date(),mocked:false) },permissionProvider:{false},monitoringEnabled:false)
  await gate.refreshIfLocationAuthorized()
  XCTAssertFalse(gate.isAllowed)
 }
 @MainActor func testSilentAuthorizedRefreshSkipsAlreadyFreshAllowance() async {
  var probes=0
  RegionLookupStub.reply={ _ in (200,"{\"country\":\"US\"}") }
  let gate=OpenAIRegionGate(network:regionTestClient(),positionProvider:{ probes += 1;return OpenAIRegionPosition(countryCode:"US",measuredAt:Date(),mocked:false) },permissionProvider:{true},monitoringEnabled:false)
  await gate.refreshIfLocationAuthorized()
  XCTAssertTrue(gate.isAllowed)
  await gate.refreshIfLocationAuthorized()
  XCTAssertEqual(probes,1)
 }
 @MainActor func testSilentRefreshCanRestartBeforeOldPositionCompletes() async {
  var oldPosition:CheckedContinuation<OpenAIRegionPosition,Error>?
  var probes=0
  let started=expectation(description:"Old position started")
  RegionLookupStub.reply={ _ in (200,"{\"country\":\"US\"}") }
  let gate=OpenAIRegionGate(network:regionTestClient(),positionProvider:{
   probes += 1
   if probes == 1 { return try await withCheckedThrowingContinuation { oldPosition=$0;started.fulfill() } }
   return OpenAIRegionPosition(countryCode:"US",measuredAt:Date(),mocked:false)
  },permissionProvider:{true},monitoringEnabled:false)
  let old=Task { await gate.refreshIfLocationAuthorized() }
  await fulfillment(of:[started],timeout:2)
  gate.cancelSilentRefresh()
  XCTAssertFalse(gate.isAllowed)
  await gate.refreshIfLocationAuthorized()
  XCTAssertTrue(gate.isAllowed)
  oldPosition?.resume(returning:OpenAIRegionPosition(countryCode:"CN",measuredAt:Date(),mocked:false))
  await old.value
  XCTAssertTrue(gate.isAllowed)
  XCTAssertEqual(probes,2)
 }
 @MainActor func testRegionGateRechecksNetworkAndRevokesPermission() async throws {
  RegionLookupStub.reply={ _ in (200,"{\"country\":\"US\"}") }
  var permission=true
  let gate=OpenAIRegionGate(network:regionTestClient(),positionProvider:{ OpenAIRegionPosition(countryCode:"US",measuredAt:Date(),mocked:false) },permissionProvider:{permission},monitoringEnabled:false)
  await gate.checkAvailability()
  XCTAssertTrue(gate.isAllowed)
  RegionLookupStub.reply={ _ in (200,"{\"country\":\"CN\"}") }
  do { try await gate.authorizeRequest(); XCTFail("Changed network did not revoke access") } catch {}
  XCTAssertFalse(gate.isAllowed)
  RegionLookupStub.reply={ _ in (200,"{\"country\":\"US\"}") }
  await gate.checkAvailability()
  XCTAssertTrue(gate.isAllowed)
  permission=false
  XCTAssertThrowsError(try gate.requireFreshPosition())
  XCTAssertFalse(gate.isAllowed)
 }
 @MainActor func testInvalidationRejectsLateLocationAndNeverQueriesNetwork() async {
  var continuation:CheckedContinuation<OpenAIRegionPosition,Error>?
  let started=expectation(description:"Position probe started")
  RegionLookupStub.reply={ _ in XCTFail("An invalidated check sent a network request");return (200,"{\"country\":\"US\"}") }
  let gate=OpenAIRegionGate(network:regionTestClient(),positionProvider:{ try await withCheckedThrowingContinuation { continuation=$0;started.fulfill() } },permissionProvider:{true},monitoringEnabled:false)
  let operation=Task { await gate.checkAvailability() }
  await fulfillment(of:[started],timeout:2)
  guard let pending=continuation else { operation.cancel();XCTFail("Position probe did not start");return }
  gate.invalidate()
  pending.resume(returning:OpenAIRegionPosition(countryCode:"US",measuredAt:Date(),mocked:false))
  await operation.value
  XCTAssertFalse(gate.isAllowed)
 }
}
