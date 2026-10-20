#!/bin/bash
# Official UseDestinationArtifacts workflow: no build, no install of artifacts.
# Current installed Runner must first be launchable. Authorized continuation after the successful smoke; all 20 already-built UI cases.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_noinstall_result="docs/testing/DEVICE_EVIDENCE/UI-noinstall-all20.xcresult"
waypoint_noinstall_log="docs/testing/DEVICE_EVIDENCE/UI-noinstall-all20.log"
if [[ -e "$waypoint_noinstall_result" || -e "$waypoint_noinstall_log" ]]; then
    printf '%s\n' 'Existing evidence must be preserved; no automatic retry.' >&2
    exit 73
fi
exec python3 scripts/memory_guard.py --start-below 74 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_ALL_UI_NOINSTALL.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_noinstall_result" \
    -only-testing:MapToDoUITests/WaypointUITests \
    > "$waypoint_noinstall_log" 2>&1
