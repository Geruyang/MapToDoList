import XCTest
import CoreLocation
@testable import MapToDo

final class MapTests: XCTestCase {
    func testBlankTitleCannotBeSaved() {
        XCTAssertNotNil(TaskEditValidation.error(title: " \n", latitude: 31, longitude: 121, start: Date(), flexible: false, latest: Date(), duration: 30))
    }
    func testFlexibleWindowMustFitDuration() {
        let start = Date(timeIntervalSince1970: 0)
        XCTAssertNotNil(TaskEditValidation.error(title: "Meet", latitude: 31, longitude: 121, start: start, flexible: true, latest: start.addingTimeInterval(600), duration: 30))
        XCTAssertNil(TaskEditValidation.error(title: "Meet", latitude: 31, longitude: 121, start: start, flexible: true, latest: start.addingTimeInterval(1800), duration: 30))
    }
    func testInvalidCoordinatesCannotBeSaved() {
        XCTAssertNotNil(TaskEditValidation.error(title: "Meet", latitude: 91, longitude: 121, start: Date(), flexible: false, latest: Date(), duration: 30))
    }
    func testRepeatedAndLongitudeOnlyLocationResultsProduceDistinctCameraEvents() throws {
        var request = MapLocationRequestState()
        let coordinates = [CLLocationCoordinate2D(latitude: 37, longitude: -122),
                           CLLocationCoordinate2D(latitude: 37, longitude: -122),
                           CLLocationCoordinate2D(latitude: 37, longitude: -121)]
        var ids = Set<UUID>()
        for coordinate in coordinates {
            request.begin()
            let result = try XCTUnwrap(request.finish(coordinate: coordinate))
            ids.insert(result.id)
            XCTAssertEqual(result.coordinate?.longitude, coordinate.longitude)
            XCTAssertFalse(request.isPending)
        }
        XCTAssertEqual(ids.count, 3, "Each explicit locate completion must trigger a fresh camera event.")
    }
    func testFailureConsumesRequestAndIgnoresLateSuccess() throws {
        var request = MapLocationRequestState()
        request.begin()
        XCTAssertNil(try XCTUnwrap(request.finish(coordinate: nil)).coordinate)
        XCTAssertFalse(request.isPending)
        XCTAssertNil(request.finish(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122)))
    }
    func testInitialAndCancelledRequestsCannotMoveCamera() {
        var request = MapLocationRequestState()
        let coordinate = CLLocationCoordinate2D(latitude: 37, longitude: -122)
        XCTAssertNil(request.finish(coordinate: coordinate), "Initialization must not emit a camera event.")
        request.begin()
        request.cancel()
        XCTAssertNil(request.finish(coordinate: coordinate), "Leaving the screen must ignore a late result.")
    }
    func testTapSelectsNearestLandmarkWithinBothScreenAndMeterTolerance() {
        let candidates = [MapLandmarkCandidate(distanceMeters: 40, distancePoints: 15),
                          MapLandmarkCandidate(distanceMeters: 20, distancePoints: 8),
                          MapLandmarkCandidate(distanceMeters: 5, distancePoints: 60)]
        XCTAssertEqual(MapSelectionPolicy.nearestIndex(candidates, radius: 80, exact: false), 1)
        XCTAssertNil(MapSelectionPolicy.nearestIndex([MapLandmarkCandidate(distanceMeters: 201, distancePoints: 10)], radius: 500, exact: false), "Zooming out must not snap to a distant landmark.")
        XCTAssertNil(MapSelectionPolicy.nearestIndex([MapLandmarkCandidate(distanceMeters: 30, distancePoints: 10)], radius: 20, exact: false))
        XCTAssertEqual(MapSelectionPolicy.queryRadius(metersPerTolerance: 1000), 300)
        XCTAssertEqual(MapSelectionPolicy.queryRadius(metersPerTolerance: 2), 60)
    }
    func testEquidistantLandmarksUseStableFirstResultAndRejectInvalidDistances() {
        let candidates = [MapLandmarkCandidate(distanceMeters: .nan, distancePoints: 0),
                          MapLandmarkCandidate(distanceMeters: 10, distancePoints: 8),
                          MapLandmarkCandidate(distanceMeters: 10, distancePoints: 8)]
        XCTAssertEqual(MapSelectionPolicy.nearestIndex(candidates, radius: 100, exact: false), 1)
        XCTAssertNil(MapSelectionPolicy.nearestIndex([], radius: 100, exact: false))
    }
    func testLongPressExactModeNeverChoosesLandmarkEvenAtSameCoordinate() {
        XCTAssertNil(MapSelectionPolicy.nearestIndex([MapLandmarkCandidate(distanceMeters: 0, distancePoints: 0)], radius: 100, exact: true))
    }
    func testTapScreenToleranceUsesCapturedScaleInsteadOfLaterCamera() {
        let capturedScale = 60.0
        let candidates = [MapLandmarkCandidate(distanceMeters: 30, distancePoints: MapSelectionPolicy.screenDistance(meters: 30, touchScaleMeters: capturedScale)),
                          MapLandmarkCandidate(distanceMeters: 70, distancePoints: MapSelectionPolicy.screenDistance(meters: 70, touchScaleMeters: capturedScale))]
        XCTAssertEqual(candidates[0].distancePoints, 24)
        XCTAssertEqual(MapSelectionPolicy.nearestIndex(candidates, radius: 100, exact: false), 0)
        XCTAssertNil(MapSelectionPolicy.nearestIndex([candidates[1]], radius: 100, exact: false), "A later zoom must not widen the original touch tolerance.")
        XCTAssertTrue(MapSelectionPolicy.screenDistance(meters: 10, touchScaleMeters: 0).isInfinite)
    }
    func testNearbyLabelTapCanSelectLandmarkBeyondOldTinyTolerance() {
        let candidate = MapLandmarkCandidate(distanceMeters: 120, distancePoints: 40)
        XCTAssertEqual(MapSelectionPolicy.nearestIndex([candidate], radius: 250, exact: false), 0)
        XCTAssertNil(MapSelectionPolicy.nearestIndex([MapLandmarkCandidate(distanceMeters: 201, distancePoints: 10)], radius: 300, exact: false))
    }
    // R43 explicit user requirement expands native acceptance to every marked feature kind.
    func testNativeFeatureAcceptanceUsesCoordinateValidityAndGestureSuppressionOnly() {
        XCTAssertTrue(MapSelectionPolicy.acceptsNativeFeature(latitude: 37, longitude: -122, suppressed: false))
        XCTAssertFalse(MapSelectionPolicy.acceptsNativeFeature(latitude: 37, longitude: -122, suppressed: true))
        for pair in [(Double.nan, 0.0), (0, Double.infinity), (91, 0), (0, -181)] {
            XCTAssertFalse(MapSelectionPolicy.acceptsNativeFeature(latitude: pair.0, longitude: pair.1, suppressed: false))
        }
        XCTAssertTrue(MapSelectionPolicy.acceptsNativeFeature(latitude: -90, longitude: 180, suppressed: false))
    }
    func testInvalidResolvedMapItemRetainsTappedFeatureCoordinate() {
        let fallback = MapSelectionPolicy.resolvedCoordinate(latitude: .nan, longitude: 121, fallbackLatitude: 37, fallbackLongitude: -122)
        XCTAssertEqual(fallback.latitude, 37)
        XCTAssertEqual(fallback.longitude, -122)
        let valid = MapSelectionPolicy.resolvedCoordinate(latitude: 31, longitude: 121, fallbackLatitude: 37, fallbackLongitude: -122)
        XCTAssertEqual(valid.latitude, 31)
        XCTAssertEqual(valid.longitude, 121)
    }
    func testUniversalMarkedPlaceNameFallbackSkipsBlankNamesAndPreservesManualInput() {
        XCTAssertEqual(MapSelectionPolicy.placeName(itemName: "Company", placemarkName: "Address", address: nil, featureName: "Marker", fallback: "Selected place"), "Company")
        XCTAssertEqual(MapSelectionPolicy.placeName(itemName: "  ", placemarkName: "Residence", address: nil, featureName: "Marker", fallback: "Selected place"), "Residence")
        XCTAssertEqual(MapSelectionPolicy.placeName(itemName: nil, placemarkName: nil, address: "Square address", featureName: "Marker", fallback: "Selected place"), "Square address")
        XCTAssertEqual(MapSelectionPolicy.placeName(itemName: nil, placemarkName: nil, address: nil, featureName: "Charger", fallback: "Selected place"), "Charger")
        XCTAssertEqual(MapSelectionPolicy.placeName(itemName: nil, placemarkName: " ", address: nil, featureName: nil, fallback: "Selected place"), "Selected place")
        XCTAssertEqual(MapSelectionPolicy.resolvedName(suggested: "Residence", current: "My place", wasEdited: true), "My place")
    }
    func testManualPlaceNameWinsLateLookupIncludingWhitespaceDraft() {
        XCTAssertEqual(MapSelectionPolicy.resolvedName(suggested: "Late shop", current: "My meeting place", wasEdited: true), "My meeting place")
        XCTAssertEqual(MapSelectionPolicy.resolvedName(suggested: "Late shop", current: "   ", wasEdited: true), "   ")
        XCTAssertEqual(MapSelectionPolicy.resolvedName(suggested: "Shop", current: "Map pin", wasEdited: false), "Shop")
        XCTAssertEqual(MapSelectionPolicy.resolvedName(suggested: " ", current: "Tapped feature", wasEdited: false), "Tapped feature")
    }
    func testNativeHitAtObserved229msCancelsGenericFallbackBeforeViewportMutation() {
        var arbitration = MapTapArbitration()
        let tap = arbitration.schedule(now: 100)
        XCTAssertFalse(arbitration.consume(tap, now: 100.162), "R44's early fallback must remain pending.")
        // R44 device trace: native feature arrives at 229ms; its handler cancels this token.
        arbitration.cancel()
        XCTAssertFalse(arbitration.consume(tap, now: 100.501))
    }
    func testEmptyMapTapMayFallbackOnlyOnceAfterNativePriorityWindow() {
        var arbitration = MapTapArbitration()
        let tap = arbitration.schedule(now: 100)
        XCTAssertFalse(arbitration.consume(tap, now: 100.499))
        XCTAssertTrue(arbitration.consume(tap, now: 100.5))
        XCTAssertFalse(arbitration.consume(tap, now: 101))
    }
    func testReplacementAndMovementDiscardStaleGenericTapTokens() {
        var arbitration = MapTapArbitration()
        let old = arbitration.schedule(now: 100)
        let replacement = arbitration.schedule(now: 100.2)
        XCTAssertFalse(arbitration.consume(old, now: 101))
        arbitration.cancel() // Long press, pan, pinch, saved pin, explicit cancellation or leaving.
        XCTAssertFalse(arbitration.consume(replacement, now: 101))
    }
}
