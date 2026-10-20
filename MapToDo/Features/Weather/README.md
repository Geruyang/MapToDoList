# Weather integration

The shared `WeatherProvider.forecast(latitude:longitude:date:)` contract always selects the hour containing the requested task instant. The upper boundary is exclusive; missing hours, past dates outside the returned series, and future dates beyond the returned series throw `WeatherProviderError.unavailableDate`. There is no clamping to current conditions. Apple documents up to 10 days of hourly forecasts; the implementation uses the actual returned hours rather than assuming that horizon is guaranteed.

Additional entry points: `current(latitude:longitude:)` returns current conditions; `attribution()` returns native `WeatherAttribution` with Apple's mark URLs and legal page URL. `WeatherCardView` presents current conditions and the requested task forecast together. It only presents data after attribution has loaded, uses the mark matching color scheme, and links the returned legal attribution URL.

The actor caches at most 64 exact coordinate pairs in memory for 15 minutes. Expired entries are never used as live forecasts; offline requests without fresh cache fail explicitly. No weather/location cache is persisted to disk. Current weather's displayed precipitation probability is the probability of its containing forecast hour; when that hour is missing the UI says unavailable instead of inventing a value.

The buffer is an explicit heuristic: probability >=40% adds 10 minutes, >=70% adds 20 minutes; snow, sleet, hail, lightning, hurricane, tornado, or blizzard symbols add 30 minutes. This is not a safety assessment or an estimate from Apple of travel delay. Consumers should report unavailable weather and continue with their own explicit planning fallback rather than silently treating unavailable data as fair weather.

## Signing and release requirement

Main coordinator must enable WeatherKit for the App ID in the Apple Developer portal and the target Signing & Capabilities panel, using `com.apple.developer.weatherkit = true` in the signed entitlements. Weather owner has not modified entitlements. Simulator SDK compilation does not prove capability provisioning, production service access, or commercial/legal readiness. Perform a signed device network test for current/hourly results and attribution, offline tests with fresh and expired cache, and a date beyond the returned hourly horizon before release.

Use Apple WeatherKit, not a noncommercial free API in a paid app. WeatherKit is included with Apple Developer Program membership and has service quotas and agreement requirements. The coordinator must review the current WeatherKit agreement for the subscription's value-added functionality and raw-weather display, and the Apple Weather trademark/data-source requirements before release.

Primary sources: https://developer.apple.com/weatherkit/ and https://developer.apple.com/documentation/weatherkit/weatherservice

## Verification performed

- iOS 17 simulator SDK `swiftc -typecheck` on all three feature Swift files: exit 0.
- Standalone Foundation executable exercised 14 assertions for hour boundaries, gaps, buffer rules, cache expiry, and invalid coordinates: exit 0.
- `MapToDoTests/WeatherTests.swift` contains four XCTest cases for the same pure behavior. Full target test run remains for main after project generation; an attempted standalone XCTest executable failed because Xcode's XCTest Swift overlay was not configured for that direct compilation command. No signed WeatherKit service request has been verified.
