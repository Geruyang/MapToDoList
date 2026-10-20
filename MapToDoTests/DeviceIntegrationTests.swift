import XCTest
import WeatherKit
@testable import MapToDo

/// Live, signed physical-device integration coverage. Exclude this class from
/// ordinary simulator/logic test runs; service or signing failures are failures.
@MainActor final class DeviceIntegrationTests: XCTestCase {
    func testLiveWeatherKitCurrentForecastAndAppleAttribution() async throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Live WeatherKit requires a signed physical iOS device. Simulator hardware skip is not weather verification.")
        #else
        let latitude = 37.7749
        let longitude = -122.4194
        let requestedAt = Date()
        let forecastAt = requestedAt.addingTimeInterval(3600)
        // A fresh actor has no existing cache, so the first call must fetch real
        // WeatherKit data. Coordinates are public; no location permission is used.
        let provider = WeatherProvider()
        do {
            let attribution = try await provider.attribution()
            let current = try await provider.current(latitude: latitude, longitude: longitude)
            let forecast = try await provider.forecast(latitude: latitude, longitude: longitude, date: forecastAt)

            XCTAssertEqual(attribution.legalPageURL.scheme, "https")
            XCTAssertFalse(attribution.legalPageURL.host?.isEmpty ?? true)
            XCTAssertEqual(attribution.combinedMarkLightURL.scheme, "https")
            XCTAssertEqual(attribution.combinedMarkDarkURL.scheme, "https")
            XCTAssertFalse(current.isForecast)
            XCTAssertTrue(forecast.isForecast)
            XCTAssertTrue(current.temperatureCelsius.isFinite)
            XCTAssertTrue(forecast.temperatureCelsius.isFinite)
            XCTAssertFalse(current.condition.isEmpty)
            XCTAssertFalse(forecast.condition.isEmpty)
            XCTAssertFalse(current.symbolName.isEmpty)
            XCTAssertFalse(forecast.symbolName.isEmpty)
            XCTAssertEqual(current.attribution, "Apple Weather")
            XCTAssertEqual(forecast.attribution, "Apple Weather")
            XCTAssertTrue(forecast.precipitationChance.isFinite)
            XCTAssertTrue((0...1).contains(forecast.precipitationChance))
            XCTAssertLessThanOrEqual(forecast.date, forecastAt)
            XCTAssertLessThan(forecastAt, forecast.date.addingTimeInterval(3600),
                              "Forecast must cover the requested hour, not an unrelated current/boundary sample.")

            attach([
                "kind": "physical_device_live_weatherkit",
                "requestedAt": stamp(requestedAt),
                "forecastRequestedAt": stamp(forecastAt),
                "completedAt": stamp(Date()),
                "latitude": latitude,
                "longitude": longitude,
                "current": record(current),
                "forecast": record(forecast),
                "legalPageURL": attribution.legalPageURL.absoluteString,
                "combinedMarkLightURL": attribution.combinedMarkLightURL.absoluteString,
                "combinedMarkDarkURL": attribution.combinedMarkDarkURL.absoluteString
            ], name: "DEVICE_LIVE_WEATHERKIT_RESPONSE")
        } catch {
            attach([
                "kind": "physical_device_live_weatherkit_failure",
                "requestedAt": stamp(requestedAt),
                "completedAt": stamp(Date()),
                "latitude": latitude,
                "longitude": longitude,
                "errorType": String(reflecting: type(of: error)),
                "error": error.localizedDescription
            ], name: "DEVICE_LIVE_WEATHERKIT_FAILURE")
            XCTFail("Live WeatherKit failed on the physical device: \(error.localizedDescription)")
        }
        #endif
    }

    private func stamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func record(_ snapshot: WeatherSnapshot) -> [String: Any] {
        [
            "sampleAt": stamp(snapshot.date),
            "temperatureCelsius": snapshot.temperatureCelsius.isFinite ? snapshot.temperatureCelsius as Any : NSNull(),
            "condition": snapshot.condition,
            "symbolName": snapshot.symbolName,
            "precipitationChance": snapshot.precipitationChance.isFinite ? snapshot.precipitationChance as Any : NSNull(),
            "isForecast": snapshot.isForecast,
            "attribution": snapshot.attribution,
            "bufferMinutes": snapshot.bufferMinutes
        ]
    }

    private func attach(_ payload: [String: Any], name: String) {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        } catch {
            XCTFail("Could not encode live WeatherKit evidence: \(error.localizedDescription)")
        }
    }
}
