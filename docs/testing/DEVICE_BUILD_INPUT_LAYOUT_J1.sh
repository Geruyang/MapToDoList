#!/bin/bash
# Single authorized experiment: start<72/stop75, nested Swift frontend jobs1.
# No build/test/install retries and no clean/cache/index/source changes.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_j1_log="docs/testing/DEVICE_EVIDENCE/Input-layout-J1-build.log"
waypoint_j1_result="docs/testing/DEVICE_EVIDENCE/Input-layout-J1-build.xcresult"
if [[ "${1:-}" == "--guard-child" ]]; then
    xcodegen generate
    exec xcodebuild build-for-testing \
        -project MapToDo.xcodeproj \
        -scheme MapToDo \
        -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
        -jobs 1 \
        -parallel-testing-enabled NO \
        -allowProvisioningUpdates \
        -derivedDataPath build/DeviceData \
        -resultBundlePath "$waypoint_j1_result" \
        DEVELOPMENT_TEAM=VA8X63NPCS \
        OTHER_SWIFT_FLAGS='$(inherited) -j1'
fi
if [[ -e "$waypoint_j1_log" || -e "$waypoint_j1_result" ]]; then
    printf '%s\n' 'Existing J1 evidence must be preserved; no automatic retry.' >&2
    exit 73
fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    bash docs/testing/DEVICE_BUILD_INPUT_LAYOUT_J1.sh --guard-child \
    > "$waypoint_j1_log" 2>&1
