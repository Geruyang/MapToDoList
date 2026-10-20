# Final distribution and upload plan

Read-only audit, 2026-10-11. No build/archive/export/upload, browser, signing/account change, private-key access, or credential output. Final execution is authorized by the user; device owner retains the single heavy-task slot and memory sampling. User has withdrawn memory ceilings/start-stop limits; obsolete guarded commands are not current instructions.

## Current actual outcome

Retry1archive/export/upload allPASS, build1.0.0(2)used; ASCprocessing completion not yet observed, no AppReviewsubmission. Actual archive `build/distribution/Waypoint-1.0.0-2-retry1.xcarchive`; IPA `build/distribution/export-build2/MapToDo.ipa`; upload records `build/distribution/upload-records`. See Final-distribution.md. **Do not execute the templates below or reupload build2**; they are retained execution history/templates for a future unused build only.

## Historical audit evidence (preserved; not candidate acceptance)

- `project.yml`: bundle `com.waypoint.maptodo`, team `VA8X63NPCS`, Automatic signing, Release version `1.0.0`, build `1`, iOS 17+. At the initial audit no options existed; export/upload plists were later prepared and verified as recorded below.
- Old `build/release/Waypoint-Release.xcarchive` is **not submission-ready as-is**: recorded Apple Development signature, development profile, `get-task-allow=true`, build 1, created 2026-10-11 08:46:18 UTC. It also predates later UI/review fixes. Preserve it as evidence; create a new archive from the frozen candidate. A development-signed automatic archive can subsequently be re-signed during App Store export; “Release” compilation alone is not distribution signing.
- `security find-identity -v -p codesigning` found one valid Apple Development and two valid Apple Distribution identities for this team. This checks usable identity metadata; no private keys were read/exported.
- Xcode preference metadata contains one account record in `DVTDeveloperAccountManagerAppleIDLists`. Account identifier/email and credential values were withheld. Prior authorized provisioning succeeded, but metadata presence does **not** prove the session is still authenticated or has upload permissions.
- Installed Xcode `xcodebuild -help` confirms `method=app-store-connect`, `destination=export|upload`, automatic re-signing, and `-allowProvisioningUpdates` using an existing Xcode Accounts login. It also supports ASC authentication key path/ID/issuer flags; no key was sought or read. Prefer the existing Xcode account, not an unconfigured API-key path.

## Preconditions for archive/export/TestFlight upload

Current accepted non-purchase evidence: R34map4PASS, R36real-access1PASS and R36AI-settingsPASS(exit0,peak58.81); frozen Main App hashes remain R35. First final archive failedexit65/peak62.86 on missing per-file.o after compile; preserve its log. Retry1 runs session26722 with freshbuild/DistributionData and standardWMO/no hidden parallelNO overrides via FINAL_ARCHIVE_RETRY1.sh; not yet successful. No export/upload. Root awaits user manual restore and notification checks for later review gates. One heavy job with sampling only; no memory start/stop ceiling. Preserve earlier failures in historical logs rather than treating them as current outcomes.

Verify source/artifact bindings, UI/map/regional gate checks, signing/entitlements/privacy/icons and absence of Release test bypass. Confirm1.0.0(2) is unused in ASC or select the next unused build consistently. Verify existing account/team/upload permission and automatic distribution provisioning. Manual release remains selected; ASC EN/ZH/shared review notes are saved, ZH1157chars persistence verified, no build uploaded.

**Genuine Sandbox transaction lifecycle is not a prerequisite for the initial TestFlight upload.** After non-purchase checks pass, archive/export/upload can establish the TestFlight environment for real sandbox validation. This upload does not imply final App Review readiness.

## Preconditions for App Review submission (after TestFlight)

Complete required real Sandbox purchase/restore/expiration/revocation checks with user-owned authentication and notification/service checks; distinguish real transactions from metadata/local-fixture tests. Reconcile final screenshots (including subscription review image), product/build association, metadata/privacy and remaining iOS17 runtime gap. Root must accept remaining submission gates before review submission. iPad is outside this first release and is not claimed passed. User submission authorization persists; no generic reauthorization is required, but neither unverified lifecycle nor unresolved candidate defects become PASS by authorization.

## Prepared command template — do not run alongside active Retry1

Run from `/Users/geruyang/AIProject/MapToDoList` only after the prerequisites. The new paths below must not already contain another result bundle/archive.

```sh
mkdir -p build/distribution docs/testing/DISTRIBUTION_EVIDENCE
SWIFTC_MAXIMUM_DETERMINISM=1 python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild archive -project MapToDo.xcodeproj -scheme MapToDo -configuration Release -destination 'generic/platform=iOS' -jobs 1 -allowProvisioningUpdates -derivedDataPath build/DistributionData -archivePath build/distribution/Waypoint-1.0.0-2-retry1.xcarchive -resultBundlePath docs/testing/DISTRIBUTION_EVIDENCE/Final-archive.xcresult DEVELOPMENT_TEAM=VA8X63NPCS MARKETING_VERSION=1.0.0 CURRENT_PROJECT_VERSION=2 SWIFT_COMPILATION_MODE=wholemodule
```

Concurrency correction prepared after the J1 test build: see `SWIFT-CONCURRENCY-PLAN.md` for installed-spec and Swift driver evidence. Do not use `OTHER_SWIFT_FLAGS=-j1` as proof of a limit: Xcode appended `-j8` after it in J1. At the next necessary archive, inspect the actual emitted WMO command for `-num-threads 1`; this prepared command has not yet run. Sampling-only wrapper remains required for recording memory; it imposes no start/stop threshold. Keep the sole-heavy rule.

Export/upload options were subsequently prepared at `build/distribution/ExportOptions-export.plist` and `ExportOptions-upload.plist` and round-trip validated with plistlib. Preparing these files does not run export or upload. The equivalent creation commands are:

```sh
python3 - <<'PY'
import plistlib
from pathlib import Path
base = dict(method='app-store-connect', signingStyle='automatic', teamID='VA8X63NPCS', manageAppVersionAndBuildNumber=False, uploadSymbols=True, stripSwiftSymbols=True)
for destination in ('export', 'upload'):
    options = dict(base, destination=destination)
    path = Path('build/distribution') / ('ExportOptions-' + destination + '.plist')
    path.write_bytes(plistlib.dumps(options))
PY
python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild -exportArchive -archivePath build/distribution/Waypoint-1.0.0-2-retry1.xcarchive -exportOptionsPlist build/distribution/ExportOptions-export.plist -exportPath build/distribution/export-build2 -allowProvisioningUpdates
```

Before upload, inspect the actual exported IPA, its signature and embedded profile: bundle/version/build, Apple Distribution, `get-task-allow=false`, expected team/application identifier, WeatherKit/time-sensitive capabilities, privacy manifest and icons. Compare its candidate/metadata to the archive; export success alone is not upload acceptance. Retain `DistributionSummary.plist` and export logs. Then use the same archive for Xcode's integrated upload:

```sh
python3 docs/testing/DEVICE_MEMORY_SAMPLE_ONLY.py -- xcodebuild -exportArchive -archivePath build/distribution/Waypoint-1.0.0-2-retry1.xcarchive -exportOptionsPlist build/distribution/ExportOptions-upload.plist -exportPath build/distribution/upload-records -allowProvisioningUpdates
```

If the existing account session is unavailable, stop at the specific authentication error. Xcode → Settings → Accounts and Organizer → Distribute App → App Store Connect provide the existing-account route; no need to manufacture or print a credential. ASC API-key flags are an alternative only if an authorized key is separately provisioned through a secure workflow; they are not assumed available.

## After upload

Record the returned upload identifier/result, wait for App Store Connect processing and any validation messages, select the processed **1.0.0 (2)** build (or the agreed replacement number), attach the first subscription and complete review metadata. Verify **Manually release this version** before the user-authorized review submission. `destination=upload` uploads a build; it does not submit the version for review or select manual release. Processing/review acceptance and final distribution signature remain unverified by this plan.
