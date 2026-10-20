import Foundation

struct WeatherSnapshot: Sendable {
    let temperatureCelsius: Double
    let condition: String
    let symbolName: String
    let precipitationChance: Double
    let date: Date
    let isForecast: Bool
    let attribution: String
    let bufferMinutes: Int
}

enum WeatherProviderError: LocalizedError {
    case invalidLocation
    case unavailableDate
    case serviceUnavailable
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidLocation: return String(localized: "地点坐标无效，无法查询天气。")
        case .unavailableDate: return String(localized: "该时间不在可用的逐小时预报范围内，无法提供天气。")
        case .serviceUnavailable: return String(localized: "暂时无法连接 Apple Weather。请检查网络并稍后重试。")
        case .offline: return String(localized: "当前离线且没有有效天气缓存，请联网后重试。")
        }
    }
}

enum WeatherPolicy {
    static let cacheLifetime: TimeInterval = 15 * 60

    static func formattedTemperature(celsius: Double, locale: Locale = .current) -> String {
        let temperature = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let style = Measurement<UnitTemperature>.FormatStyle(
            width: .abbreviated, locale: locale, usage: .weather,
            numberFormatStyle: .number.precision(.fractionLength(0)))
        return temperature.formatted(style)
    }

    static func validCoordinates(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    static func isCacheFresh(fetchedAt: Date, now: Date) -> Bool {
        let age = now.timeIntervalSince(fetchedAt)
        return age >= 0 && age < cacheLifetime
    }

    /// Each sample covers its own hour only. Never fill a missing hour or clamp to a boundary.
    static func hourlySample(in samples: [WeatherSnapshot], for date: Date) throws -> WeatherSnapshot {
        guard let sample = samples.first(where: { date >= $0.date && date < $0.date.addingTimeInterval(3600) }) else {
            throw WeatherProviderError.unavailableDate
        }
        return sample
    }

    /// A conservative planning heuristic, not a safety forecast or a prediction of travel delay.
    static func bufferMinutes(precipitationChance: Double, symbolName: String) -> Int {
        if ["bolt", "snow", "sleet", "hail", "hurricane", "tornado", "blizzard"].contains(where: symbolName.contains) { return 30 }
        if precipitationChance >= 0.7 { return 20 }
        if precipitationChance >= 0.4 { return 10 }
        return 0
    }
}
