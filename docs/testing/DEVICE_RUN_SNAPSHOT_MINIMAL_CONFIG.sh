#!/bin/bash
# One-variable control at the test-configuration boundary: reuse the successful
# minimal no-install configuration with the same new installed binary and case.
# Does not establish which optional generated instrumentation causes a difference.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_snapshot_log=docs/testing/DEVICE_EVIDENCE/Snapshot-minimal-config-single.log
waypoint_snapshot_result=docs/testing/DEVICE_EVIDENCE/Snapshot-minimal-config-single.xcresult
if [[ -e "$waypoint_snapshot_log" || -e "$waypoint_snapshot_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_SNAPSHOT_MINIMAL_CONFIG_SINGLE.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_snapshot_result" \
    > "$waypoint_snapshot_log" 2>&1
