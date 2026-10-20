import Foundation
import CoreLocation
import WeatherKit

actor WeatherProvider {
    static let shared = WeatherProvider()
    private let service = WeatherService.shared
    private var cache: [LocationKey: CacheEntry] = [:]
    private var attributionCache: WeatherAttribution?

    private struct LocationKey: Hashable {
        let latitude: Double
        let longitude: Double
    }
    private struct CacheEntry {
        let fetchedAt: Date
        let current: WeatherSnapshot
        let hourly: [WeatherSnapshot]
    }

    func forecast(latitude: Double, longitude: Double, date: Date) async throws -> WeatherSnapshot {
        // Today's task still requires the hourly weather at its scheduled time.
        let entry = try await fetch(latitude: latitude, longitude: longitude)
        return try WeatherPolicy.hourlySample(in: entry.hourly, for: date)
    }

    /// Extra entry point for cards that show current conditions alongside a task's forecast.
    func current(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        try await fetch(latitude: latitude, longitude: longitude).current
    }

    /// Apple supplies the legal link and light/dark marks; do not invent attribution URLs.
    func attribution() async throws -> WeatherAttribution {
        if let attributionCache { return attributionCache }
        let value = try await service.attribution
        attributionCache = value
        return value
    }

    private func fetch(latitude: Double, longitude: Double) async throws -> CacheEntry {
        guard WeatherPolicy.validCoordinates(latitude: latitude, longitude: longitude) else { throw WeatherProviderError.invalidLocation }
        let key = LocationKey(latitude: latitude, longitude: longitude)
        let now = Date()
        if let entry = cache[key], WeatherPolicy.isCacheFresh(fetchedAt: entry.fetchedAt, now: now) { return entry }
        do {
            let weather = try await service.weather(for: CLLocation(latitude: latitude, longitude: longitude))
            let hours = weather.hourlyForecast.forecast.map { hour in
                WeatherSnapshot(temperatureCelsius: hour.temperature.converted(to: .celsius).value,
                                condition: hour.condition.description, symbolName: hour.symbolName,
                                precipitationChance: hour.precipitationChance, date: hour.date,
                                isForecast: true, attribution: "Apple Weather",
                                bufferMinutes: WeatherPolicy.bufferMinutes(precipitationChance: hour.precipitationChance, symbolName: hour.symbolName))
            }
            let current = weather.currentWeather
            // CurrentWeather has no probability field. Use only its containing hourly probability.
            let probability = (try? WeatherPolicy.hourlySample(in: hours, for: current.date).precipitationChance) ?? .nan
            let snapshot = WeatherSnapshot(temperatureCelsius: current.temperature.converted(to: .celsius).value,
                                           condition: current.condition.description, symbolName: current.symbolName,
                                           precipitationChance: probability, date: current.date, isForecast: false,
                                           attribution: "Apple Weather", bufferMinutes: WeatherPolicy.bufferMinutes(precipitationChance: probability, symbolName: current.symbolName))
            let entry = CacheEntry(fetchedAt: Date(), current: snapshot, hourly: hours)
            cache[key] = entry
            // Bound in-memory cache and its retention; no location history is persisted.
            cache = cache.filter { WeatherPolicy.isCacheFresh(fetchedAt: $0.value.fetchedAt, now: Date()) }
            if cache.count > 64, let oldest = cache.min(by: { $0.value.fetchedAt < $1.value.fetchedAt })?.key { cache.removeValue(forKey: oldest) }
            return entry
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let urlError = error as? URLError, [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed].contains(urlError.code) { throw WeatherProviderError.offline }
            throw WeatherProviderError.serviceUnavailable
        }
    }
}
