import SwiftUI
import WeatherKit

struct WeatherCardView: View {
    @Environment(\.timeZone) private var displayTimeZone
    @Environment(\.locale) private var displayLocale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let latitude: Double
    let longitude: Double
    let date: Date
    @Environment(\.colorScheme) private var colorScheme
    @State private var current: WeatherSnapshot?
    @State private var forecast: WeatherSnapshot?
    @State private var attribution: WeatherAttribution?
    @State private var errorMessage: String?
    @State private var loading = false
    @State private var activeRequestID: UUID?
    @State private var retryCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("地点天气", systemImage: "cloud.sun")
                .font(.headline)
            if loading { ProgressView("正在获取天气…") }
            if let current { weatherRow(current, title: String(localized: "当前天气")) }
            if let forecast {
                weatherRow(forecast, title: String(localized: "事项时间预报"))
                Text("规划天气缓冲：\(forecast.bufferMinutes) 分钟（经验估计）")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let errorMessage {
                Text(errorMessage).font(.subheadline).foregroundStyle(.secondary)
                Button("重试") { retryCount += 1 }.disabled(loading)
            }
            if let attribution, current != nil || forecast != nil {
                weatherLayout {
                    AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { Text(" Weather") }
                    .frame(width: 100, height: 24)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    Link(destination: attribution.legalPageURL) {
                        Text("天气数据来源")
                            .font(.caption)
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task(id: "\(latitude):\(longitude):\(date.timeIntervalSince1970):\(retryCount)") { await load() }
    }

    private var weatherLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
    }

    private func weatherRow(_ snapshot: WeatherSnapshot, title: String) -> some View {
        weatherLayout {
            HStack(alignment: .top) {
                Image(systemName: snapshot.symbolName).font(.title2).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.medium))
                    Text(LocalTimeFormatter.string(snapshot.date, timeZoneIdentifier: displayTimeZone.identifier, includeDate: true)).font(.caption).foregroundStyle(.secondary)
                    Text(snapshot.condition).font(.caption)
                }
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing) {
                Text(WeatherPolicy.formattedTemperature(celsius: snapshot.temperatureCelsius, locale: displayLocale)).font(.title3.weight(.semibold))
                if snapshot.precipitationChance.isFinite {
                    Text("降水概率 \(Int(snapshot.precipitationChance * 100))%").font(.caption)
                } else {
                    Text("降水概率不可用").font(.caption)
                }
            }
        }
    }

    @MainActor private func load() async {
        let requestID = UUID()
        activeRequestID = requestID
        loading = true
        current = nil
        forecast = nil
        attribution = nil
        errorMessage = nil
        defer {
            if activeRequestID == requestID { loading = false }
        }
        do {
            // Attribution must be available before presenting WeatherKit data.
            let mark = try await WeatherProvider.shared.attribution()
            let conditions = try await WeatherProvider.shared.current(latitude: latitude, longitude: longitude)
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            attribution = mark
            current = conditions
            do {
                let value = try await WeatherProvider.shared.forecast(latitude: latitude, longitude: longitude, date: date)
                guard !Task.isCancelled, activeRequestID == requestID else { return }
                forecast = value
            } catch {
                guard !Task.isCancelled, activeRequestID == requestID else { return }
                errorMessage = error.localizedDescription
            }
        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }
            errorMessage = (error as? WeatherProviderError)?.localizedDescription ?? WeatherProviderError.serviceUnavailable.localizedDescription
        }
    }
}
