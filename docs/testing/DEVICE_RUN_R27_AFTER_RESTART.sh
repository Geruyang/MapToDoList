#!/bin/bash
# One explicitly selected batch against the successfully installed R27 candidate.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_batch="${1:-}"
case "$waypoint_batch" in english|titles2|key-export2) ;; *) exit 64 ;; esac
waypoint_log="docs/testing/DEVICE_EVIDENCE/R27-after-restart-${waypoint_batch}.log"
waypoint_result="docs/testing/DEVICE_EVIDENCE/R27-after-restart-${waypoint_batch}.xcresult"
if [[ -e "$waypoint_log" || -e "$waypoint_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun "docs/testing/DEVICE_R27_${waypoint_batch}_NOINSTALL.xctestrun" \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_result" \
    > "$waypoint_log" 2>&1
