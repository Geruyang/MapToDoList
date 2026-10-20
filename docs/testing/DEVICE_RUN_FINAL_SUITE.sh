#!/bin/bash
# Prepared only; run after the main coordinator broadcasts that all sources are
# frozen and grants the exclusive build/test slot. Never starts a simulator.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_final_results="docs/testing/DEVICE_EVIDENCE/Final-logic-and-ui.xcresult"
waypoint_final_log="docs/testing/DEVICE_EVIDENCE/Final-logic-and-ui.log"
if [[ -e "$waypoint_final_results" || -e "$waypoint_final_log" ]]; then
    printf '%s\n' 'Prior final-suite evidence exists; preserve it and choose a new name.' >&2
    exit 73
fi
mkdir -p docs/testing/DEVICE_EVIDENCE
exec python3 scripts/memory_guard.py --start-below 70 --stop-at 75 -- \
    xcodebuild test \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_final_results" \
    -only-testing:MapToDoTests \
    -only-testing:MapToDoUITests \
    -skip-testing:MapToDoTests/StoreKitLifecycleTests \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_final_log" 2>&1
