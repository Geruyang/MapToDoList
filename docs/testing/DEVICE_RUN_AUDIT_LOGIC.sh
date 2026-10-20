#!/bin/bash
# App-hosted pure logic only. UI Runner, WeatherKit live calls, StoreKit purchases,
# and simulators are excluded. Requires the coordinator's exclusive-slot grant.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
waypoint_audit_results="docs/testing/DEVICE_EVIDENCE/Audit-fixes-logic.xcresult"
waypoint_audit_log="docs/testing/DEVICE_EVIDENCE/Audit-fixes-logic.log"
if [[ -e "$waypoint_audit_results" || -e "$waypoint_audit_log" ]]; then
    printf '%s\n' 'Evidence already exists; select a new filename before retrying.' >&2
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
    -resultBundlePath "$waypoint_audit_results" \
    -only-testing:MapToDoTests/AIParsingTests \
    -only-testing:MapToDoTests/AIReleaseGateTests \
    -only-testing:MapToDoTests/PlanningFinalValidationTests \
    -only-testing:MapToDoTests/SubscriptionConcurrencyTests \
    -only-testing:MapToDoTests/SubscriptionTimeoutTests \
    -only-testing:MapToDoTests/SubscriptionTests \
    -only-testing:MapToDoTests/PlanningTests \
    -only-testing:MapToDoTests/PlanningTimeoutTests \
    DEVELOPMENT_TEAM=VA8X63NPCS > "$waypoint_audit_log" 2>&1
