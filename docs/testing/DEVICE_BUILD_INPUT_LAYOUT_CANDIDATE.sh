#!/bin/bash
# Build only: no device installation or launch. Existing evidence is preserved.
# Coordinator owns the unique slot; sample must be below70 before invocation.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_candidate_log="docs/testing/DEVICE_EVIDENCE/Input-layout-candidate-build.log"
waypoint_candidate_result="docs/testing/DEVICE_EVIDENCE/Input-layout-candidate-build.xcresult"
if [[ -e "$waypoint_candidate_log" || -e "$waypoint_candidate_result" ]]; then
    printf '%s\n' 'Preserve the previous candidate build; choose a new evidence name.' >&2
    exit 73
fi
xcodegen generate
exec python3 scripts/memory_guard.py --start-below 70 --stop-at 75 -- \
    xcodebuild build-for-testing \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_candidate_result" \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_candidate_log" 2>&1
