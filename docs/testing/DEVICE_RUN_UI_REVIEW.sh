#!/bin/bash
# Prepared only. The coordinator must grant the single heavy-resource slot.
# USER RESUMED: the user explicitly resumed verification; the coordinator
# granted this one frozen-candidate run with start<70%, stop75%, and jobs1.
# Physical device only; preserves all previous evidence, never starts a simulator.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_ui_review_results="docs/testing/DEVICE_EVIDENCE/UI-review-regression.xcresult"
waypoint_ui_review_log="docs/testing/DEVICE_EVIDENCE/UI-review-regression.log"
if [[ -e "$waypoint_ui_review_results" || -e "$waypoint_ui_review_log" ]]; then
    printf '%s\n' 'Evidence already exists; choose a new filename before running.' >&2
    exit 73
fi
mkdir -p docs/testing/DEVICE_EVIDENCE
xcodegen generate
exec python3 scripts/memory_guard.py --start-below 70 --stop-at 75 -- \
    xcodebuild test \
    -project MapToDo.xcodeproj \
    -scheme MapToDo \
    -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
    -jobs 1 \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-device-destinations 1 \
    -allowProvisioningUpdates \
    -derivedDataPath build/DeviceData \
    -resultBundlePath "$waypoint_ui_review_results" \
    -only-testing:MapToDoUITests \
    -only-testing:MapToDoTests/SubscriptionTimeoutTests \
    -only-testing:MapToDoTests/AIReleaseGateTests \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_ui_review_log" 2>&1
