import Foundation
import Combine
import CoreLocation
import Network
import UIKit

struct OpenAIRegionPosition: Sendable {
 let countryCode: String?
 let measuredAt: Date
 let mocked: Bool
}
enum OpenAIRegionPolicy {
 static let positionTTL: TimeInterval = 120
 static func allows(positionCountry:String?,networkCountry:String?,positionDate:Date?,now:Date,mocked:Bool=false) -> Bool {
  guard !mocked,let date=positionDate,date <= now,now.timeIntervalSince(date) <= positionTTL,
        let physical=positionCountry?.uppercased(),let network=networkCountry?.uppercased(),
        physical.count == 2,network.count == 2,physical != "ZZ",network != "ZZ",Locale.isoRegionCodes.contains(physical),Locale.isoRegionCodes.contains(network) else { return false }
  return physical != "CN" && network != "CN"
 }
}
struct OpenAIRegionNetworkClient {
 let session: URLSession
 init(session:URLSession? = nil) {
  if let session { self.session=session } else {
   let config=URLSessionConfiguration.ephemeral
   config.httpShouldSetCookies=false;config.httpCookieStorage=nil;config.urlCache=nil
   self.session=URLSession(configuration:config)
  }
 }
 func country() async throws -> String {
  var request=URLRequest(url:URL(string:"https://api.country.is/")!)
  request.timeoutInterval=8
  let (data,response)=try await session.data(for:request)
  guard let http=response as? HTTPURLResponse,(200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
  struct CountryReply: Decodable { let country:String }
  let country=try JSONDecoder().decode(CountryReply.self,from:data).country
  guard country.count == 2,country.uppercased() != "ZZ",Locale.isoRegionCodes.contains(country.uppercased()) else { throw URLError(.cannotParseResponse) }
  return country.uppercased()
 }
}

@MainActor private final class RegionLocationProbe: NSObject,CLLocationManagerDelegate {
 private let manager=CLLocationManager()
 private var pending: CheckedContinuation<OpenAIRegionPosition,Error>?
 private var pendingID: UUID?
 private var geocoder: CLGeocoder?
 override init() { super.init();manager.delegate=self;manager.desiredAccuracy=kCLLocationAccuracyKilometer }
 func locate() async throws -> OpenAIRegionPosition {
  let id=UUID()
  return try await withTaskCancellationHandler {
   try await withCheckedThrowingContinuation { continuation in
    cancelCurrent();pending=continuation;pendingID=id
    switch manager.authorizationStatus {
    case .notDetermined: finish(.failure(CLError(.denied)))
    case .authorizedAlways,.authorizedWhenInUse:manager.requestLocation()
    default:finish(.failure(CLError(.denied)))
    }
   }
  } onCancel: { Task { @MainActor in if self.pendingID == id { self.cancelCurrent() } } }
 }
 private func cancelCurrent() { geocoder?.cancelGeocode();manager.stopUpdatingLocation();finish(.failure(CancellationError())) }
 private func finish(_ result:Result<OpenAIRegionPosition,Error>) {
  let continuation=pending;pending=nil;pendingID=nil;geocoder=nil
  continuation?.resume(with:result)
 }
 func locationManagerDidChangeAuthorization(_ manager:CLLocationManager) {
  guard pending != nil else { return }
  switch manager.authorizationStatus {
  case .authorizedAlways,.authorizedWhenInUse:manager.requestLocation()
  case .denied,.restricted:finish(.failure(CLError(.denied)))
  default:break
  }
 }
 func locationManager(_ manager:CLLocationManager,didFailWithError error:Error) { finish(.failure(error)) }
 func locationManager(_ manager:CLLocationManager,didUpdateLocations locations:[CLLocation]) {
  guard let location=locations.last,location.horizontalAccuracy >= 0,
        Date().timeIntervalSince(location.timestamp) >= 0,
        Date().timeIntervalSince(location.timestamp) <= OpenAIRegionPolicy.positionTTL,
        location.sourceInformation?.isSimulatedBySoftware != true,
        location.sourceInformation?.isProducedByAccessory != true else { finish(.failure(CLError(.locationUnknown)));return }
  let id=pendingID;let geocoder=CLGeocoder();self.geocoder=geocoder
  geocoder.reverseGeocodeLocation(location) { places,error in
   Task { @MainActor in
    guard self.pendingID == id,self.pending != nil else { return }
    guard error == nil,let country=places?.first?.isoCountryCode else { self.finish(.failure(CLError(.geocodeFoundNoResult)));return }
    self.finish(.success(OpenAIRegionPosition(countryCode:country,measuredAt:location.timestamp,mocked:false)))
   }
  }
 }
}

@MainActor final class OpenAIRegionGate:NSObject,ObservableObject,CLLocationManagerDelegate {
 static let shared=OpenAIRegionGate()
 @Published private(set) var isAllowed=false
 @Published private(set) var status=String(localized:"尚未检查 OpenAI 地区可用性。")
 private let permissions=CLLocationManager()
 private let monitor=NWPathMonitor()
 private let network: OpenAIRegionNetworkClient
 private let positionProvider: () async throws -> OpenAIRegionPosition
 private let permissionProvider:(() -> Bool)?
 private var position:OpenAIRegionPosition?
 private var revision=UUID()
 private var silentRefreshID:UUID?
 private var hasInitialPath=false
 private var expiryTask:Task<Void,Never>?
 private struct ActiveTransport {
  let revision:UUID
  let task:URLSessionDataTask
  let continuation:CheckedContinuation<(Data,URLResponse),Error>
 }
 private var activeTransports:[UUID:ActiveTransport]=[:]
 private var backgroundObserver:NSObjectProtocol?
 init(network:OpenAIRegionNetworkClient = .init(),positionProvider:(() async throws -> OpenAIRegionPosition)? = nil,permissionProvider:(() -> Bool)? = nil,monitoringEnabled:Bool = true) {
  self.network=network;self.permissionProvider=permissionProvider
  let probe=RegionLocationProbe()
  self.positionProvider=positionProvider ?? { try await probe.locate() }
  super.init();permissions.delegate=self
  if monitoringEnabled {
  backgroundObserver=NotificationCenter.default.addObserver(forName:UIApplication.didEnterBackgroundNotification,object:nil,queue:.main) { [weak self] _ in Task { @MainActor in self?.invalidate() } }
  monitor.pathUpdateHandler={ [weak self] path in
   Task { @MainActor in
    guard let self else { return }
    if self.hasInitialPath || path.status != .satisfied { self.invalidate() }
    self.hasInitialPath=true
   }
  }
  monitor.start(queue:DispatchQueue(label:"com.waypoint.region.network"))
  }
 }
 deinit {
  monitor.cancel();expiryTask?.cancel()
  for transport in activeTransports.values { transport.task.cancel();transport.continuation.resume(throwing:CancellationError()) }
  if let observer=backgroundObserver { NotificationCenter.default.removeObserver(observer) }
 }
 func invalidate() {
  revision=UUID();expiryTask?.cancel();expiryTask=nil;position=nil;isAllowed=false
  let pending=activeTransports;activeTransports.removeAll()
  for transport in pending.values { transport.task.cancel();transport.continuation.resume(throwing:CancellationError()) }
  status=String(localized:"OpenAI 地区信息已失效，请重新检查。")
 }
 /// Never requests permission: settings may only refresh an existing location grant.
 func refreshIfLocationAuthorized() async {
  guard permissionIsAllowed() else { invalidate();return }
  if isAllowed, (try? requireFreshPosition()) != nil { return }
  guard silentRefreshID == nil,!Task.isCancelled else { return }
  let id=UUID();silentRefreshID=id
  defer { if silentRefreshID == id { silentRefreshID=nil } }
  await withTaskCancellationHandler {
   guard permissionIsAllowed(),!Task.isCancelled else { return }
   await checkAvailability()
   if Task.isCancelled,silentRefreshID == id { invalidate() }
  } onCancel: {
   Task { @MainActor in
    if self.silentRefreshID == id { self.invalidate() }
   }
  }
 }
 func cancelSilentRefresh() {
  guard silentRefreshID != nil else { return }
  silentRefreshID=nil;invalidate()
 }
 func checkAvailability() async {
  invalidate();let token=revision;status=String(localized:"正在检查定位和网络地区…")
  do {
   let physical=try await PlanningTimeout.run(seconds:20) { try await self.positionProvider() }
   guard revision == token,!Task.isCancelled else { return }
   guard OpenAIRegionPolicy.allows(positionCountry:physical.countryCode,networkCountry:physical.countryCode,positionDate:physical.measuredAt,now:Date(),mocked:physical.mocked) else { throw blockedError() }
   position=physical
   try await verifyNetwork(token:token)
  } catch {
   guard revision == token else { return }
   position=nil;isAllowed=false;status=String(localized:"无法确认定位和网络均在中国大陆以外，OpenAI 不可用。")
  }
 }
 func requireFreshPosition() throws {
  guard isAllowed,let physical=position,permissionIsAllowed(),
        physical.countryCode?.uppercased() != "CN",
        physical.countryCode.map { $0.count == 2 && $0.uppercased() != "ZZ" && Locale.isoRegionCodes.contains($0.uppercased()) } == true,
        !physical.mocked,physical.measuredAt <= Date(),Date().timeIntervalSince(physical.measuredAt) <= OpenAIRegionPolicy.positionTTL else {
   invalidate();throw blockedError()
  }
 }
 func authorizeRequest() async throws {
  try requireFreshPosition()
  let token=revision
  try await verifyNetwork(token:token)
 }
 /// The eligibility check and task registration/start execute without an actor hop.
 /// All OpenAI callers must use this transport, never start their own data task.
 func send(_ request:URLRequest,session:URLSession = .shared) async throws -> (Data,URLResponse) {
  guard request.url?.scheme == "https",request.url?.host == "api.openai.com" else { throw blockedError() }
  let id=UUID()
  return try await withTaskCancellationHandler {
   try await authorizeRequest()
   try Task.checkCancellation()
   try requireFreshPosition()
   let permit=revision
   return try await withCheckedThrowingContinuation { continuation in
    // No await is allowed between this final check and resume().
    guard !Task.isCancelled,revision == permit,isAllowed else { continuation.resume(throwing:CancellationError());return }
    do { try requireFreshPosition() } catch { continuation.resume(throwing:error);return }
    let task=session.dataTask(with:request) { [weak self] data,response,error in
     Task { @MainActor in self?.finishTransport(id,data:data,response:response,error:error) }
    }
    activeTransports[id]=ActiveTransport(revision:permit,task:task,continuation:continuation)
    task.resume()
   }
  } onCancel: { Task { @MainActor in self.cancelTransport(id) } }
 }
 private func cancelTransport(_ id:UUID) {
  guard let transport=activeTransports.removeValue(forKey:id) else { return }
  transport.task.cancel();transport.continuation.resume(throwing:CancellationError())
 }
 private func finishTransport(_ id:UUID,data:Data?,response:URLResponse?,error:Error?) {
  guard let transport=activeTransports.removeValue(forKey:id) else { return }
  guard transport.revision == revision,isAllowed else { transport.continuation.resume(throwing:CancellationError());return }
  do { try requireFreshPosition() } catch { transport.continuation.resume(throwing:error);return }
  if let error { transport.continuation.resume(throwing:error) }
  else if let data,let response { transport.continuation.resume(returning:(data,response)) }
  else { transport.continuation.resume(throwing:URLError(.badServerResponse)) }
 }
 private func permissionIsAllowed()->Bool { permissionProvider?() ?? Self.permissionAllows(permissions.authorizationStatus) }
 private static func permissionAllows(_ status:CLAuthorizationStatus)->Bool { status == .authorizedAlways || status == .authorizedWhenInUse }
 private func verifyNetwork(token:UUID) async throws {
  do {
   let country=try await PlanningTimeout.run(seconds:8) { try await self.network.country() }
   guard revision == token,!Task.isCancelled,let physical=position,
         permissionIsAllowed(),
         OpenAIRegionPolicy.allows(positionCountry:physical.countryCode,networkCountry:country,positionDate:physical.measuredAt,now:Date(),mocked:physical.mocked) else { throw blockedError() }
   isAllowed=true;status=String(localized:"定位和网络均已确认在中国大陆以外。")
   expiryTask?.cancel()
   let remaining=max(0,physical.measuredAt.addingTimeInterval(OpenAIRegionPolicy.positionTTL).timeIntervalSinceNow)
   expiryTask=Task { [weak self] in
    do { try await Task.sleep(for:.seconds(remaining));guard self?.revision == token else { return };self?.invalidate() } catch { }
   }
  } catch {
   if revision == token { invalidate();status=String(localized:"无法确认定位和网络均在中国大陆以外，OpenAI 不可用。") }
   throw blockedError()
  }
 }
 private func blockedError()->AIError { .message(String(localized:"OpenAI 仅在定位和网络均明确位于中国大陆以外时可用。请先检查可用性。")) }
 func locationManagerDidChangeAuthorization(_ manager:CLLocationManager) {
  if permissionProvider == nil,!Self.permissionAllows(manager.authorizationStatus) { invalidate() }
 }
}
