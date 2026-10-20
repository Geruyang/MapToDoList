#!/bin/bash
# One smoke after the user manually opened Main App and saw its Map. No build/xcodegen.
# This one no-compilation smoke was specifically authorized at start<74%,
# stop75%, 0.5s sampling. It does not authorize a build or a broader UI suite.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_smoke_results="docs/testing/DEVICE_EVIDENCE/Runner-smoke-after-mainapp-verify.xcresult"
waypoint_smoke_log="docs/testing/DEVICE_EVIDENCE/Runner-smoke-after-mainapp-verify.log"
if [[ -e "$waypoint_smoke_results" || -e "$waypoint_smoke_log" ]]; then
    printf '%s\n' 'Preserve existing smoke evidence; no automatic retry.' >&2
    exit 73
fi
exec python3 scripts/memory_guard.py --start-below 74 --stop-at 75 -- \
    xcodebuild test-without-building \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_smoke_results" \
    -only-testing:MapToDoUITests/WaypointUITests/testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission \
    > "$waypoint_smoke_log" 2>&1
