#!/bin/bash
# Eight freshly built UI regressions, official UseDestinationArtifacts; no install.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_focused_log=docs/testing/DEVICE_EVIDENCE/Input-layout-focused.log
waypoint_focused_result=docs/testing/DEVICE_EVIDENCE/Input-layout-focused.xcresult
if [[ -e "$waypoint_focused_log" || -e "$waypoint_focused_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 74 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_INPUT_LAYOUT_FOCUSED_NOINSTALL.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_focused_result" \
    > "$waypoint_focused_log" 2>&1
