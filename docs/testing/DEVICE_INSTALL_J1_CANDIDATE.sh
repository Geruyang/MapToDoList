#!/bin/bash
# Exactly one install for each freshly built authorized App/Runner; no uninstall.
set -euo pipefail
cd /Users/geruyang/AIProject/MapToDoList
if [[ "${1:-}" == "--guard-child" ]]; then
    xcrun devicectl device install app --device 2050E692-2C1D-5D9D-967A-EABA499B386F \
        --json-output docs/testing/DEVICE_EVIDENCE/Input-layout-J1-install-main.json \
        build/DeviceData/Build/Products/Debug-iphoneos/MapToDo.app
    exec xcrun devicectl device install app --device 2050E692-2C1D-5D9D-967A-EABA499B386F \
        --json-output docs/testing/DEVICE_EVIDENCE/Input-layout-J1-install-runner.json \
        build/DeviceData/Build/Products/Debug-iphoneos/MapToDoUITests-Runner.app
fi
waypoint_install_log=docs/testing/DEVICE_EVIDENCE/Input-layout-J1-install.log
if [[ -e "$waypoint_install_log" ]]; then exit 73; fi
exec python3 scripts/memory_guard.py --start-below 74 --stop-at 75 -- \
    bash docs/testing/DEVICE_INSTALL_J1_CANDIDATE.sh --guard-child \
    > "$waypoint_install_log" 2>&1
