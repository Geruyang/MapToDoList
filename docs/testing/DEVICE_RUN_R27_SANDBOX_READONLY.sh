#!/bin/bash
# PREPARED only. Root authorization required after the user's manual Sandbox step.
# Never purchases/restores/resets history or installs/rebuilds any artifacts.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_r27_sandbox_log=docs/testing/DEVICE_EVIDENCE/R27-after-purchase-sandbox-readonly.log
waypoint_r27_sandbox_result=docs/testing/DEVICE_EVIDENCE/R27-after-purchase-sandbox-readonly.xcresult
if [[ -e "$waypoint_r27_sandbox_log" || -e "$waypoint_r27_sandbox_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_SANDBOX_R27_AFTER_PURCHASE_NOINSTALL.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_r27_sandbox_result" \
    > "$waypoint_r27_sandbox_log" 2>&1
