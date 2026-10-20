#!/bin/bash
# User removed memory threshold; keep single build, sampling only.
# Preserve previous refusal/interruption evidence. No xcodegen/clean/install/test.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_controlled_log=docs/testing/DEVICE_EVIDENCE/R38-map-region-diagnostics-Debug-build.log
waypoint_controlled_result=docs/testing/DEVICE_EVIDENCE/R38-map-region-diagnostics-Debug-build.xcresult
if [[ -e "$waypoint_controlled_log" || -e "$waypoint_controlled_result" ]]; then exit 73; fi
exec env SWIFTC_MAXIMUM_DETERMINISM=1 python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- \
    xcodebuild build-for-testing \
    -project MapToDo.xcodeproj -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_controlled_result" \
    DEVELOPMENT_TEAM=VA8X63NPCS \
    > "$waypoint_controlled_log" 2>&1
