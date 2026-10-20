#!/bin/bash
# One authorized read-only state diagnostic after the user reported cancellation.
# User revoked memory thresholds: sampling only, no threshold guard/kills.
# No build/install/purchase/AppStore.sync/reset/SKTestSession or retry.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_cancel_log=docs/testing/DEVICE_EVIDENCE/R27-user-cancelled-storekit-readonly.log
waypoint_cancel_result=docs/testing/DEVICE_EVIDENCE/R27-user-cancelled-storekit-readonly.xcresult
if [[ -e "$waypoint_cancel_log" || -e "$waypoint_cancel_result" ]]; then exit 73; fi
exec python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- \
    xcodebuild test-without-building \
    -xctestrun docs/testing/DEVICE_SANDBOX_R27_USER_CANCEL_STATE.xctestrun \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_cancel_result" \
    > "$waypoint_cancel_log" 2>&1
