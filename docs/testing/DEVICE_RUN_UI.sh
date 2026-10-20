#!/bin/bash
# Prepared command only. Run after the main coordinator releases the unique
# build/test slot and regenerates the project to include DeviceIntegrationTests.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_device_results="docs/testing/DEVICE_EVIDENCE/UI-and-weather-first.xcresult"
waypoint_device_log="docs/testing/DEVICE_EVIDENCE/UI-and-weather-first.log"
if [[ -e "$waypoint_device_results" ]]; then
    printf '%s\n' 'Existing result bundle must be preserved; use a new result path for a new run.' >&2
    exit 73
fi
if ! rg -q 'DeviceIntegrationTests.swift' MapToDo.xcodeproj/project.pbxproj; then
    printf '%s\n' 'Project generation does not yet include DeviceIntegrationTests.swift; coordinator must regenerate it first.' >&2
    exit 74
fi
mkdir -p docs/testing/DEVICE_EVIDENCE
# Reuse the existing device DerivedData to avoid a redundant full SDK/module
# cache build. xcodebuild will incrementally rebuild changed candidate sources.
exec python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- \
    xcodebuild test \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_device_results" \
    -only-testing:MapToDoUITests/WaypointUITests/testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission \
    -only-testing:MapToDoUITests/WaypointUITests/testCreateEditPersistAndDeleteTask \
    -only-testing:MapToDoUITests/WaypointUITests/testCancelCreationDoesNotPersistTask \
    -only-testing:MapToDoUITests/WaypointUITests/testMapPointOpensEditorAndPersistsChosenLocation \
    -only-testing:MapToDoUITests/WaypointUITests/testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess \
    -only-testing:MapToDoUITests/WaypointUITests/testFiveAIProvidersUseSecureInputAndCanSaveAndDeleteKeys \
    -only-testing:MapToDoUITests/WaypointUITests/testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall \
    -only-testing:MapToDoTests/DeviceIntegrationTests/testLiveWeatherKitCurrentForecastAndAppleAttribution \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_device_log" 2>&1
