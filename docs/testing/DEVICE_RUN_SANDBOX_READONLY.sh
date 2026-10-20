#!/bin/bash
# One read-only live StoreKit diagnostic, no fixture/purchase/sync/install/build.
# Coordinator's single-use exception: start<73, stop75 unchanged, no UI/video.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_sandbox_log=docs/testing/DEVICE_EVIDENCE/Sandbox-readonly-live.log
waypoint_sandbox_result=docs/testing/DEVICE_EVIDENCE/Sandbox-readonly-live.xcresult
if [[ -e "$waypoint_sandbox_log" || -e "$waypoint_sandbox_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 73 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_SANDBOX_READONLY_NOINSTALL.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_sandbox_result" \
    > "$waypoint_sandbox_log" 2>&1
