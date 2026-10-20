#!/bin/bash
# PREPARED only. Coordinator authorizes which batch to run after system quiet.
# Same installed J1 binary, minimal proven no-install configuration; no build.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_minimal_batch="${1:-}"
case "$waypoint_minimal_batch" in
    gallery3) waypoint_minimal_manifest=docs/testing/DEVICE_MINIMAL_GALLERY3_NOINSTALL.xctestrun ;;
    titles2) waypoint_minimal_manifest=docs/testing/DEVICE_MINIMAL_TITLES2_NOINSTALL.xctestrun ;;
    key-export2) waypoint_minimal_manifest=docs/testing/DEVICE_MINIMAL_KEY_EXPORT2_NOINSTALL.xctestrun ;;
    *) printf '%s\n' 'Select gallery3, titles2, or key-export2 after coordinator authorization.' >&2; exit 64 ;;
esac
waypoint_minimal_log="docs/testing/DEVICE_EVIDENCE/Input-layout-minimal-${waypoint_minimal_batch}.log"
waypoint_minimal_result="docs/testing/DEVICE_EVIDENCE/Input-layout-minimal-${waypoint_minimal_batch}.xcresult"
if [[ -e "$waypoint_minimal_log" || -e "$waypoint_minimal_result" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 72 --stop-at 75 -- \
    xcodebuild test-without-building \
    -xctestrun "$waypoint_minimal_manifest" \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -resultBundlePath "$waypoint_minimal_result" \
    > "$waypoint_minimal_log" 2>&1
