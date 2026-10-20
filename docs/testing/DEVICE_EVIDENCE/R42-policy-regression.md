# R42 extracted policy regression evidence

These are the actual observed lightweight Swift harness runs. They compile and execute only the extracted pure `MapLandmarkCandidate` / `MapSelectionPolicy` declarations plus assertions, using Foundation. They are **not XCTest**, a full app build, or MapKit/device validation.

## RED before production change

Old policy extracted exactly from MapScreen SHA `712b7a7796f66d4374b524edd96d9b2b66465d796d41895873e1ac05d699a313`, beginning at `struct MapLandmarkCandidate` to EOF. Regression expected a 120m / 40pt candidate inside radius250 to be accepted. Original24pt policy rejected it.

Actual command:
```sh
swift /tmp/waypoint-old-poi-policy.swift
```
Observed stdout:
```text
Old policy label-nearby expected 0, actual: nil
```
Exit status: **1**. Archived exact harness: `R42-old-poi-policy.swift`, SHA256 `0c2bf7d6a7c94ddbd07bcf0bcb6f58d33f6f31244f586290f6e7c4eaef78bf83`.

## GREEN after production change

New extracted policy from MapScreen SHA `c9f445ebef0129b7ead56d7ad53590f2501bc05bac7754e0f076ff176435cb8b` includes native-POI suppression and manual-name merge helpers, 48pt acceptance, query60..300m and hard200m acceptance. Harness assertions cover nearby label acceptance, >200m rejection, exact no-snap, manual-name preservation, and native suppression.

Actual command:
```sh
swift /tmp/waypoint-new-poi-policy.swift
```
Observed stdout:
```text
GREEN: nearby label / far bound / exact hold / manual name / native suppression
```
Exit status: **0**. Archived exact harness: `R42-new-poi-policy.swift`, SHA256 `7ef79b934c39940ba251c00514393b3788be17d8b6e79b2a52cc9e4262a53d70`.

## Final frozen source and scope

Following UI/gesture review, frozen MapScreen SHA is `c0bfdbc123b7b19e2ce740d529e08c901bff8f4b2f56295f15d7062f34f9191c`. The pure policy declarations are unchanged from GREEN. Owned XCTest source `MapToDoTests/MapTests.swift` SHA is `da24d26a53037da7b42b729ead06c9cc7beaa89bb02d6af15a0f97cb141b295c`.

Actual final syntax command:
```sh
xcrun swiftc -frontend -parse MapToDo/Features/Map/MapScreen.swift MapToDoTests/MapTests.swift
```
Observed no stdout; exit status **0**. No XCTest execution, Xcodebuild, installation, device or simulator operation performed by this agent for R42. Native MapFeature recognizer arbitration, cancel/reselection, preview input and layout still require parent-coordinated full build/runtime checks.

## Final presentation binding guard

Final MapScreen SHA after stale-name-field safeguard: `9e1c5c2e2432d05dd1ecb7d6886388b5428599c3715b311215297772449b1539`. Name binding getter/setter require the captured selection UUID to still match, and coordinate/search/existing selection paths clear name keyboard focus. The pure policy and owned XCTest source remain unchanged. Repeated final `swiftc -frontend -parse` command above produced no output and exit **0**. No build or runtime test added.
