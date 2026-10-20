#!/usr/bin/env python3
"""Prepare only the UI no-install manifest from this candidate's generated file.

Does not build, install, launch, or test. App-hosted Sandbox environment must be
reviewed separately from the freshly generated unit-test configuration.
"""
import argparse
import copy
import hashlib
import json
import plistlib
from pathlib import Path

FOCUSED = [
    "testLongEditableTitleWrapsAndSurvivesSaveAndRelaunch",
    "testLongReadonlyTitleWrapsAndRemainsWholeWithoutAccess",
    "testScreenshotGalleryOfPrimaryScreens",
    "testEnglishScreenshotGalleryOfPrimaryScreens",
    "testLargestAccessibilityTypeScreenshotGalleryOfPrimaryScreens",
    "testFourAIProvidersUseSecureInputAndCanSaveAndDeleteKeysWhileGeminiIsUnavailable",
    "testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess",
    "testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    report = args.output.with_suffix(".configuration-proof.json")
    if args.output.exists() or report.exists():
        parser.error("Output exists; preserve candidate evidence rather than overwrite it")
    generated = plistlib.loads(args.source.read_bytes())
    candidates = [target for config in generated.get("TestConfigurations", [])
                  for target in config.get("TestTargets", [])
                  if target.get("BlueprintName") == "MapToDoUITests"]
    if not candidates:
        # Current Xcode build-for-testing emits format1; previously handwritten
        # destination-artifact manifests were format2. Support both explicitly.
        candidates = [target for target in generated.values()
                      if isinstance(target, dict)
                      and target.get("BlueprintName") == "MapToDoUITests"]
    if len(candidates) != 1:
        parser.error("Expected exactly one generated MapToDoUITests configuration")
    target = copy.deepcopy(candidates[0])
    for key in ("TestBundlePath", "TestHostPath", "UITargetAppPath",
                "DependentProductPaths", "SkipTestIdentifiers"):
        target.pop(key, None)
    target.update({
        "UseDestinationArtifacts": True,
        "TestHostBundleIdentifier": "com.waypoint.MapToDoUITests.xctrunner",
        "TestBundleDestinationRelativePath": "__TESTHOST__/PlugIns/MapToDoUITests.xctest",
        "UITargetAppBundleIdentifier": "com.waypoint.maptodo",
        # The same empty UI-host environment was verified in the prior no-install
        # smoke/all20. Tests configure language/data/access only in app.launch().
        "TestingEnvironmentVariables": {},
        "EnvironmentVariables": {},
        "ParallelizationEnabled": False,
        "SystemAttachmentLifetime": "keepAlways",
        "UserAttachmentLifetime": "keepAlways",
        "OnlyTestIdentifiers": ["WaypointUITests/" + name for name in FOCUSED],
    })
    fixture_paths = []
    def check(value, path="root"):
        if isinstance(value, dict):
            for key, item in value.items():
                if "storekit" in key.lower():
                    fixture_paths.append(path + "." + key)
                check(item, path + "." + key)
        elif isinstance(value, list):
            for index, item in enumerate(value):
                check(item, path + "[" + str(index) + "]")
        elif isinstance(value, str) and ".storekit" in value.lower():
            fixture_paths.append(path)
    check(target)
    if fixture_paths:
        parser.error("Unexpected StoreKit fixture configuration: " + str(fixture_paths))
    result = {"__xctestrun_metadata__": {"FormatVersion": 2},
              "TestConfigurations": [{"Name": "InputLayoutFocusedNoInstall",
                                      "IsEnabled": True, "TestTargets": [target]}]}
    args.output.write_bytes(plistlib.dumps(result))
    report.write_text(json.dumps({
        "generatedSource": str(args.source.resolve()),
        "generatedSourceSHA256": hashlib.sha256(args.source.read_bytes()).hexdigest(),
        "outputSHA256": hashlib.sha256(args.output.read_bytes()).hexdigest(),
        "onlyUIIdentifiers": target["OnlyTestIdentifiers"],
        "useDestinationArtifacts": True,
        "installationPathsRemoved": True,
        "storeKitFixtureConfiguration": False,
        "executionStatus": "NOT_RUN",
    }, indent=2) + "\n")
    print("Prepared eight UI identifiers; no build/install/launch/test performed.")


if __name__ == "__main__":
    main()
