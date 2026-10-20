#!/bin/bash
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
[[ ! -e docs/testing/DISTRIBUTION_EVIDENCE/Build4-upload.log ]]
# Execute only after final runtime/visual acceptance. Version4 becomes used once uploaded.
exec python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild -exportArchive \
    -archivePath build/distribution/Waypoint-1.0.0-4.xcarchive \
    -exportPath build/distribution/upload-build4 \
    -exportOptionsPlist build/distribution/ExportOptions-upload.plist \
    -allowProvisioningUpdates > docs/testing/DISTRIBUTION_EVIDENCE/Build4-upload.log 2>&1
