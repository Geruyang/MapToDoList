# Resume after freeing host memory

Checkpoint: 2026-10-11. No build upload or App Review submission. Review submission is authorized; retain manual release. User ceiling is 80% host memory; use one heavy job, 0.5-second guard, stop at 75%. No heavy process should be left running at this checkpoint.

### New R33/R34 checkpoint — supersedes earlier candidate/account state

- User reauthenticated ASC. Root’s actual TestFlight snapshot says “提交构建版本以开始测试”: no build present and build2 unused. Previous saved ZH metadata evidence remains valid; no upload/review submission.
- User authenticated on iPhone and reports an Apple purchase/subscription, while the app still shows no valid subscription and new-task read-only access. Root reviewed `R33-user-purchase-restore-mismatch.jsonl`: repeated `successVerified` followed by end `hasAccess=false`. Restore now completes normal sync/reader-return paths around42s/15.19s, not the earlier timeout. **Transaction environment/expiry are unknown; this is neither Sandbox nor working-access PASS.** Diagnose without another purchase.
- R33 product change only moves the map-card parent accessibility ID to its title. Independent source review passed; device build exit0/peak54.72%, signatures and built family[1] verified, **not installed**. R33 simulator strict test FAIL for missing pin/empty map; full accessibility coordinate/confirm/cancel IDs returned, but later hittability/save steps did not run. See `docs/testing/SIMULATOR_R33_MAP_DIAGNOSTIC.md`. Do not claim map acceptance.
- R34 changes only the read-only diagnostic test (SHA08a001…a994c1). Root build session85364 is **in progress**, with no PASS yet. Planned physical diagnostic reads latest/status/expiry through a whitelist, no new purchase. Its results remain unknown.

## Latest R31/R32 handoff — supersedes earlier running statuses

- R31 device units **56/56 PASS**. map4 **0/4 PASS, four FAIL**, all at `confirm.isHittable`, not coordinate checks. Do not describe coordinate correctness as failed or the map suite as passed.
- R31 UI3: English PASS; AI final unscrolled provider-picker assertion FAIL (R32 test navigation correction prepared); restore SKIP because Apple sign-in UI was present. A skip is not restoration or sandbox transaction success.
- R32 changes tests only: build PASS; main App bundle hash is identical to R31, only Runner installed. **R32 tests have not yet run.** No product fix/new runtime PASS is inferred from this test-only build.
- `R32-user-restore-reported-timeout.jsonl` mixes R29, injected R31 unit diagnostics and UI restore-start events. It contains no matching complete operation for the newly reported user timeout. Authentication questions await the user; neither a new completed timeout path nor a successful restore is established by that mixed log.
- Root saved ASC Simplified Chinese description (**1157 characters**); verification is in progress and is **not yet claimed complete**. No App Store build upload/review submission. Existing website publication and saved metadata/privacy/rights evidence remain separate.

## Latest resumed checkpoint

After restart, R27 Debug build exit0/peak70.6, both strict signatures PASS,94 bundle digests; single Main/Runner installs succeeded, peak67.6. Exact-candidate English1PASS/peak68.3 and titles2PASS/peak70.5. Final key/export2 exit65/1PASS1FAIL/peak73.6: export passed, all four-provider save/delete iterations completed, then post-relaunch secure-field exists failed at line470. Read-only diagnosis is in progress; root cause is unknown. These tests made no purchase.

User confirmed **first release iPhone only**. map_tasks is updating project.yml/pbxproj; validation remains pending. iPad is outside first-release gates, not passed. No build upload/review submission or complete sandbox purchase/restore lifecycle is established. Older checkpoint below is preserved as historical evidence, not current installed state; iPhone now has successful R27.

### R28 preparation update

Two iPhone-only configurations passed independent device static review; built UIDeviceFamily remains pending. Secure-field final test navigation changed only in tests (scroll, preserved exists, hittable, capture), SHAffa3e7…ae5885; independent review/parsePASS does not fix product or prove runtime. R28 scripts/manifest/inputhash prepared, not run.

ASC readonly access restored: signed in, preparing submission/manualrelease/no build. Noheavy memory76.7 fell to75.4 after root closed its own tab/reset. Questions to close other Codex pages/previews and personally confirm genuine Sandbox trial await user answers. No purchase or new source runtime/build success.

## Historical pre-restart checkpoint

## Confirmations already completed

- User enabled iPhone Do Not Disturb, kept the device connected/unlocked, and closed unused applications/pages. Do not ask for these again unless the state changes. Notification-delivery testing will require restoring notification delivery later.
- User explicitly confirmed the content-rights declaration. Root selected Yes, completed the dialog, saved App information, and verified the saved text. Evidence: `docs/release/evidence/content-rights-saved.png`.
- Subscription review screenshot and notes are saved in App Store Connect. The screenshot reflects the prior J1 paywall and must be reconciled with the final layout after R27 verification.

## Current source and installed artifact

The iPhone still has J1. Do not install the partial contents of `build/DeviceData`.

- `SubscriptionView.swift`: hides the tab bar only on the subscription destination, preserving actions and accessibility IDs. SHA256 `b27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017`.
- `WaypointUITests.swift`: preserves the unfiltered contrast audit, checks management/legal controls and tab navigation after push/sheet dismissal, and returns to the title after confirming a location in the long-title test. SHA256 `4f94c048ab2d00cd6674fe40b91c942dcee867555618d6a44581ea0ef2c8ce87`.
- Independent source review: `docs/testing/INDEPENDENT-PAYWALL-TAB-FIX-REVIEW.md`. Syntax parsing passed; these changes have not passed device execution.

## Actual results

- English single-case retry after Do Not Disturb: FAIL, 42.870s, peak69.8%; no snapshot timeout. The current defect is Manage/cancel text behind the floating tab bar, independently confirmed as R27. The trial CTA itself has good contrast.
- J1 gallery: English/Chinese/AXXXL 3/3 PASS, peak71.7%. Independent review closed Today bottom-button obstruction (R22); this is not R27 validation.
- J1 long-title batch: 0/2 PASS, both failed at old line331 in the second AXXX cycle after confirming location; peak73.3%. NORMAL branches reached save/reopen/read-only assertions, but complete cases failed. Navigation back to the title is now explicit in source; keep every original title-content/height/persistence assertion.
- Key/export batch did not start: baseline72.1 met/exceeded start72. No case was executed.
- New Debug build first attempt did not start at baseline72.4/start72.
- One controlled build used start73/stop75 and actually began at72.5, then the guard stopped it at75.0 (exit75). `SWIFTC_MAXIMUM_DETERMINISM=1` produced the actual driver override remark for App and unit targets. This was not a successful build. Logs and 63 source-input digests: `docs/testing/DEVICE_EVIDENCE/R27-title-nav-Controlled-*`.
- Root sampled73.0% after the build stopped. Do not keep raising thresholds or looping retries.

## Next sequence

1. After the user reopens Codex, sample memory and confirm no leftover task-owned build/test. Restore browser access only when needed; the old browser2/tab2 binding was unavailable after a REPL reset, and root did not close any user tab.
2. Resume the necessary incremental Debug build with a new log/result path, existing DerivedData, single Xcode job and `SWIFTC_MAXIMUM_DETERMINISM=1`; no clean or project generation is needed. Prefer baseline below72 with stop75. Verify success, signatures and source/artifact bindings before installing.
3. Install the successful candidate once, then use minimal UseDestinationArtifacts manifests to avoid recurring reinstall/trust changes. Verify English paywall contrast and return navigation, both title cases, and key/export cases in small serial batches. Request user action only for an actual device-security prompt.
4. Reconcile the UI evidence and replace the subscription review image with the final layout. Complete live Sandbox purchase/restore only after no-access UI cases; the prior read-only metadata pass is not a transaction pass. Apple authentication must be performed by the user, and the purchase sheet must explicitly identify Sandbox.
5. Complete remaining notification/system-share/service/device coverage. Current user scope is iPhone only, so iPad is not a first-release gate and is not verified. iOS17 runtime remains absent; do not silently mark it passed. Keep the accepted limited OpenAI test scope: original valid local credential, no generation spending, no ChatGPT subscription integration.
6. Final Release archive/export/signature checks, TestFlight acceptance and authorized App Review submission with manual release. ExportOptions plists are prepared and plistlib-validated under `build/distribution`; no export/upload has run.

Related status: `RELEASE-READINESS.md`, `EXTERNAL-CONFIGURATION.md`, `DISTRIBUTION-UPLOAD-PLAN.md`, device and simulator matrices. Preserve previous failed/interrupted evidence.
