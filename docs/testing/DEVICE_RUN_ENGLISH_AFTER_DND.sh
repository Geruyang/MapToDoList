#!/bin/bash
# Single authorized rerun after user enabled Do Not Disturb and released resources.
# Installed J1 artifacts and exact minimal-control test manifest remain unchanged.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_dnd_log=docs/testing/DEVICE_EVIDENCE/English-minimal-after-DND.log
waypoint_dnd_result=docs/testing/DEVICE_EVIDENCE/English-minimal-after-DND.xcresult
if [[ -e "$waypoint_dnd_log" || -e "$waypoint_dnd_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_SNAPSHOT_MINIMAL_CONFIG_SINGLE.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_dnd_result" \
    > "$waypoint_dnd_log" 2>&1
