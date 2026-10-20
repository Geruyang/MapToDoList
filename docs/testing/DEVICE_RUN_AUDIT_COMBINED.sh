#!/bin/bash
# One authorized frozen-candidate run after the user confirmed device trust.
# This run alone uses start<72%, stop75%, 0.5s memory sampling. No simulator.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_combined_results="docs/testing/DEVICE_EVIDENCE/Audit-fixes-combined.xcresult"
waypoint_combined_log="docs/testing/DEVICE_EVIDENCE/Audit-fixes-combined.log"
if [[ -e "$waypoint_combined_results" || -e "$waypoint_combined_log" ]]; then
    printf '%s\n' 'Evidence already exists; do not overwrite or automatically retry.' >&2
    exit 73
fi
mkdir -p docs/testing/DEVICE_EVIDENCE
xcodegen generate
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_combined_results" \
    -only-testing:MapToDoTests/AIParsingTests \
    -only-testing:MapToDoTests/AIReleaseGateTests \
    -only-testing:MapToDoTests/PlanningFinalValidationTests \
    -only-testing:MapToDoTests/SubscriptionConcurrencyTests \
    -only-testing:MapToDoTests/SubscriptionTimeoutTests \
    -only-testing:MapToDoTests/SubscriptionTests \
    -only-testing:MapToDoTests/PlanningTests \
    -only-testing:MapToDoTests/PlanningTimeoutTests \
    -only-testing:MapToDoUITests \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_combined_log" 2>&1
