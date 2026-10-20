import XCTest
@testable import MapToDo

final class WeatherTests: XCTestCase {
    func testSelectsContainingHourAndRejectsUpperBoundary() throws {
        let start = Date(timeIntervalSince1970: 1_800_000)
        let samples = [sample(start), sample(start.addingTimeInterval(3600))]
        XCTAssertEqual(try WeatherPolicy.hourlySample(in: samples, for: start.addingTimeInterval(3599)).date, start)
        XCTAssertEqual(try WeatherPolicy.hourlySample(in: samples, for: start.addingTimeInterval(3600)).date, samples[1].date)
        XCTAssertThrowsError(try WeatherPolicy.hourlySample(in: samples, for: start.addingTimeInterval(7200)))
        XCTAssertThrowsError(try WeatherPolicy.hourlySample(in: samples, for: start.addingTimeInterval(-1)))
    }

    func testGapDoesNotSelectClosestWeather() {
        let start = Date(timeIntervalSince1970: 1_800_000)
        XCTAssertThrowsError(try WeatherPolicy.hourlySample(in: [sample(start), sample(start.addingTimeInterval(7200))], for: start.addingTimeInterval(4000)))
    }

    func testBufferUsesRainAndSevereConditions() {
        XCTAssertEqual(WeatherPolicy.bufferMinutes(precipitationChance: 0.1, symbolName: "sun.max"), 0)
        XCTAssertEqual(WeatherPolicy.bufferMinutes(precipitationChance: 0.5, symbolName: "cloud.rain"), 10)
        XCTAssertEqual(WeatherPolicy.bufferMinutes(precipitationChance: 0.9, symbolName: "cloud.rain"), 20)
        XCTAssertEqual(WeatherPolicy.bufferMinutes(precipitationChance: 0.1, symbolName: "cloud.bolt.rain"), 30)
    }

    func testCacheExpiryAndCoordinates() {
        XCTAssertTrue(WeatherPolicy.isCacheFresh(fetchedAt: Date(timeIntervalSince1970: 100), now: Date(timeIntervalSince1970: 999)))
        XCTAssertFalse(WeatherPolicy.isCacheFresh(fetchedAt: Date(timeIntervalSince1970: 100), now: Date(timeIntervalSince1970: 1000)))
        XCTAssertFalse(WeatherPolicy.isCacheFresh(fetchedAt: Date(timeIntervalSince1970: 100), now: Date(timeIntervalSince1970: 99)))
        XCTAssertFalse(WeatherPolicy.validCoordinates(latitude: .nan, longitude: 120))
        XCTAssertFalse(WeatherPolicy.validCoordinates(latitude: 91, longitude: 120))
    }

    func testTemperatureUsesLocalePreferredUnit() {
        let us = WeatherPolicy.formattedTemperature(celsius: 20, locale: Locale(identifier: "en_US"))
        let gb = WeatherPolicy.formattedTemperature(celsius: 20, locale: Locale(identifier: "en_GB"))
        XCTAssertTrue(us.contains("68"))
        XCTAssertTrue(us.contains("F"))
        XCTAssertTrue(gb.contains("20"))
        XCTAssertTrue(gb.contains("C"))
    }

    private func sample(_ date: Date) -> WeatherSnapshot {
        WeatherSnapshot(temperatureCelsius: 20, condition: "晴", symbolName: "sun.max", precipitationChance: 0.1, date: date, isForecast: true, attribution: "Apple Weather", bufferMinutes: 0)
    }
}
