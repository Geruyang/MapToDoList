#!/bin/bash
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
# Resume only after owner unlock; serial jobs, sampling only, never purchase.
for waypoint_phase in unit map gallery; do
    waypoint_log="docs/testing/DEVICE_EVIDENCE/R49-${waypoint_phase}-retry1.log"
    waypoint_result="docs/testing/DEVICE_EVIDENCE/R49-${waypoint_phase}-retry1.xcresult"
    waypoint_summary="docs/testing/DEVICE_EVIDENCE/R49-${waypoint_phase}-retry1-summary.json"
    [[ ! -e "$waypoint_log" && ! -e "$waypoint_result" ]]
    python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild test-without-building \
        -xctestrun "docs/testing/DEVICE_R49_${waypoint_phase}_NOINSTALL.xctestrun" \
        -destination 'platform=iOS,id=00008150-00066CE13C43C01C' \
        -jobs 1 -parallel-testing-enabled NO -maximum-concurrent-test-device-destinations 1 \
        -resultBundlePath "$waypoint_result" > "$waypoint_log" 2>&1
    xcrun xcresulttool get test-results summary --path "$waypoint_result" > "$waypoint_summary"
    python3 - "$waypoint_phase" "$waypoint_summary" <<'VERIFY'
import json,sys
expected={'unit':18,'map':9,'gallery':1}[sys.argv[1]]
r=json.load(open(sys.argv[2]))
assert r['passedTests']==expected and r['failedTests']==0 and r['skippedTests']==0, r
print(sys.argv[1]+': '+str(expected)+' passed, 0 failed, 0 skipped')
VERIFY
done
