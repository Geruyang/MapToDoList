#!/bin/bash
# Coordinator's one controlled Debug experiment: start<73/stop75, sole slot.
# Preserve previous72.4 refusal. No xcodegen/clean/install/test or retries.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_controlled_log=docs/testing/DEVICE_EVIDENCE/R27-title-nav-Controlled-Debug-build.log
waypoint_controlled_result=docs/testing/DEVICE_EVIDENCE/R27-title-nav-Controlled-Debug-build.xcresult
if [[ -e "$waypoint_controlled_log" || -e "$waypoint_controlled_result" ]]; then exit 73; fi
exec env SWIFTC_MAXIMUM_DETERMINISM=1 python3 scripts/memory_guard.py --start-below 73 --stop-at 75 -- \
    xcodebuild build-for-testing \
    -project MapToDo.xcodeproj -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_controlled_result" \
    DEVELOPMENT_TEAM=VA8X63NPCS \
    > "$waypoint_controlled_log" 2>&1
