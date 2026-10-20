import CoreLocation
import Combine

struct MapLocationResult {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D?
}

/// Only an explicit, outstanding locate request may produce a camera event.
struct MapLocationRequestState {
    private(set) var isPending = false
    mutating func begin() { isPending = true }
    mutating func cancel() { isPending = false }
    mutating func finish(coordinate: CLLocationCoordinate2D?) -> MapLocationResult? {
        guard isPending else { return nil }
        isPending = false
        return MapLocationResult(coordinate: coordinate)
    }
}

@MainActor
final class MapLocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var message: String?
    @Published private(set) var result: MapLocationResult?
    private var request = MapLocationRequestState()
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    func locate() {
        request.begin()
        message = nil
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: fail("定位不可用，你仍可搜索或点击地图选点。可在系统设置中开启定位。")
        @unknown default: fail("定位暂不可用")
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard request.isPending else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: fail("定位不可用，你仍可搜索或点击地图选点。可在系统设置中开启定位。")
        case .notDetermined: break
        @unknown default: fail("定位暂不可用")
        }
    }
    func cancelRequest() { request.cancel() }
    private func fail(_ text: String) {
        guard let completed = request.finish(coordinate: nil) else { return }
        message = text
        result = completed
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let value = locations.last?.coordinate else { fail("暂时无法获取位置，请搜索或点击地图选点。"); return }
        guard let completed = request.finish(coordinate: value) else { return }
        coordinate = value
        result = completed
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { fail("暂时无法获取位置，请搜索或点击地图选点。") }
}
