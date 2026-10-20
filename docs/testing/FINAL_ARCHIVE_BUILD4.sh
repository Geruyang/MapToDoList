#!/bin/bash
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
[[ ! -e build/distribution/Waypoint-1.0.0-4.xcarchive && ! -e docs/testing/DISTRIBUTION_EVIDENCE/Build4-archive.xcresult ]]
exec env SWIFTC_MAXIMUM_DETERMINISM=1 python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild archive -project MapToDo.xcodeproj -scheme MapToDo -configuration Release -destination 'generic/platform=iOS' -jobs 1 -allowProvisioningUpdates -derivedDataPath build/DistributionData -archivePath build/distribution/Waypoint-1.0.0-4.xcarchive -resultBundlePath docs/testing/DISTRIBUTION_EVIDENCE/Build4-archive.xcresult DEVELOPMENT_TEAM=VA8X63NPCS MARKETING_VERSION=1.0.0 CURRENT_PROJECT_VERSION=4 SWIFT_COMPILATION_MODE=wholemodule > docs/testing/DISTRIBUTION_EVIDENCE/Build4-archive.log 2>&1
