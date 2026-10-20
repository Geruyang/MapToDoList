# Resume physical-device testing — October 11, 2026

## Authorization and scope

The user most recently authorized continued physical-device testing, bug fixes and progressing to final App Store review submission. Root coordinates implementation, release decisions and submission. Manual release remains selected; an authorized submission is not evidence that upload or review submission has occurred.

The first release keeps GLM, Qwen, DeepSeek and OpenAI API Key access. ChatGPT subscription/OAuth integration was canceled; the commercial application was never submitted. The user's accepted OpenAI scope remains limited authentication/catalog/no-quota evidence with **zero new generation POSTs**. Read-only model access is not successful generation and is not a blanket no-cost guarantee.

## Responsibilities

- Root: coordinate work, integrate fixes, evaluate release gates and control publishing/submission.
- device_tests: sole owner of the heavy-resource slot for build, install and physical-device test execution; preserve raw commands, logs, actual outcomes and memory samples.
- map_tasks: read-only main-thread/code review under root's coordination. No independent heavy build/test job.
- export: read-only subordinate oversight of execution/review evidence plus documentation. Compare supplied raw logs and result reports; do not approve root, assign work or terminate another agent. Wait for root to supply new evidence; do not frequently poll or infer results from a running process.

## Resource and evidence rules

Only one heavy job at a time. The user's memory ceiling is 80%; the guard stops the owned job at 75% estimated system memory to leave headroom. Record configured startup thresholds and actual initial/peak samples per run. A sampled overshoot is reported as observed, not rewritten to the stop threshold. Do not modify or terminate unrelated user applications.

Distinguish written tests, attempted execution, executed cases and confirmed PASS. An interrupted suite has no complete suite result. Retain failed/skipped/not-run cases, raw screenshots and incomplete xcresults. Do not call an unfinished gallery complete, a timeout exit a restored subscription, a build a UI pass, authentication a generation pass, or saved store metadata a submission.

Do not change API credentials or purchase history as part of this oversight. Never copy credential contents into logs, reports, screenshots or chat. Any authorized purchase/account action must be recorded separately by its owner; none is performed by this documentation role.

## Baseline when this record was prepared

- Candidate test build exited 0; start 71.8%, peak 74.8%. Log contains `-j1 ... -j8`; internal Swift jobs=1 effectiveness was not established. Outer `-jobs 1` and the guard were used.
- Focused eight: 0 PASS / 1 FAIL / 1 interrupted / 6 not run. EnglishMarketSmoke failed on a 136-second snapshot timeout before the AI assertion. Gallery interrupted. Guard first observed >75% at 76.7% and stopped with exit 75. Interrupted xcresult lacks Info.plist; two original PNGs show no visible modal, with ownership undetermined. Source: `docs/testing/DEVICE_INPUT_LAYOUT_J1_RESULTS.md`.
- ReadonlySandbox did not run because baseline 74.5% exceeded start-below-72%; stop remained 75%, no retry. Root's last supplied memory sample was 74.2%.
- Earlier evidence remains separate: 40 logic PASS; full 20 UI 18 PASS / 1 FAIL / 1 SKIP. Restore 15-second timeout exit PASS did not prove successful restoration.
- Original unfunded OpenAI credential: GET /models HTTP 200 with gpt-6.1-sol visible; retry sent zero generation POSTs. Historical generation returned 429 insufficient_quota. The 47 later candidates returned 401; none selected. No new credential check occurs in this record.
- ASC eight-type privacy declaration published after user legal confirmation; English and Simplified Chinese metadata saved. No upload/review submission recorded. Website 90218a2 live.

## Next evidence handling

When root provides new logs/results, verify: one-heavy ownership and actual memory samples; exact executed cases and result availability; failed/skipped/interrupted/not-run outcomes; credential/purchase-history invariants supported by the supplied evidence; and consistency between source review and claimed runtime behavior. Record unknowns explicitly. Then update RELEASE-READINESS.md and EXTERNAL-CONFIGURATION.md only with observed facts, preserving historical evidence.

This file prepares the record; it launches no build/test, polls no agent, changes no credential or purchase history, and makes no new runtime success claim.

## Evidence review — Snapshot minimal-configuration control

Read the result report, raw `DEVICE_EVIDENCE/Snapshot-minimal-config-single.log`, its summary JSON and the runner script. The raw log confirms one selected case, 43.839-second failure, final `TEST EXECUTE FAILED`, peak 73.7%, sequential `-jobs 1`, no parallel testing and one destination. The runner is `test-without-building`; report states the same installed J1 candidate and no build/install/source modification. Startup display rounds to 72.0%; the strict-start acceptance of the underlying unrounded value is reported by the owner, not independently recoverable from that rounded line. No overlapping heavy job is evidenced in these supplied artifacts; this review does not invent a whole-system process audit.

Result JSON confirms total 1, passed 0, failed 1, skipped 0, failure `Contrast failed`. Raw activities reach `ai.analysis.exportHelp`, `ai.analysis.apiHelp`, `export.start`, `export.end`, export/back navigation, subscription purchase-control/eligibility checks and final contrast audit. The earlier snapshot timeout did not reproduce here; a configuration-boundary hypothesis remains unproven at individual-flag/root-cause level. Do not label the case PASS.

The owner’s report identifies notification interference at the navigation title and restricts private notification images to local evidence. This reviewer did not render or redistribute them. The raw log contains purchase-control lookups but no purchase/Restore tap; the report records no account password input. This supports the limited “no purchase initiated by this case” observation, not a provider/account-history audit. No credential action is performed by this reviewer.

Subscription review notes were saved by root with Save disabled and a supplied evidence screenshot; this is metadata saving, not submission. Screenshot attachment remains pending. User Do Not Disturb response is pending. Prior failures and guard interruption remain recorded; no next-run success is presumed. Documentation-only review; no new build/test/process termination/account action.

## Evidence review — one-use read-only StoreKit metadata

Read the Sandbox-readonly-live raw log, summary JSON, redacted metadata attachment, runner and test source. Log/summary agree: one test executed, one PASS, zero failure/skip, 0.020-second test body, execution succeeded; owner records exit0. Memory is baseline72.6%, peak73.3%. Runner explicitly declares the coordinator’s single-use start<73 exception for this read-only test, no build/install/UI/video, stop75; guard source samples every0.5s. This does not authorize start73 for UI or future general runs. Root’s stated basis was the earlier ~1.7-point single-case increment; user80 ceiling unchanged. The previously rejected start72 attempt remains historical.

Payload confirms product com.waypoint.maptodo.annual, USA storefront, USD9.99, one-year subscription, seven-day FreeTrial, eligible=true. currentEntitlements is empty; no verified transaction environment is present. purchaseAttempted, restoreSyncAttempted and purchaseHistoryReset are false. Source calls product/eligibility/current-entitlement readers and contains no purchase, sync or reset invocation. Therefore record live metadata PASS only; no sandbox transaction, purchase or restore completion is proven. This review performs no credential/purchase-history mutation.

UI retry remains pending user Do Not Disturb response and start<72/stop75. No future UI result is presumed. Distribution plan includes prepared WMO constraints; actual emitted archive command and final distribution artifacts still await execution. No archive/export/upload was performed by this review. Updated both latest handoffs with these distinctions.

## Evidence review — user confirmations and post-DND retry

Root reports all three requested replies: DND enabled/device remains connected; unused apps/pages closed; Content Rights explicitly confirmed. Root saved Yes in ASC and manually reviewed the saved content-rights-saved.png evidence. This is a rights-field save, not submission. Root sample68.5% is distinct from runner raw initial68.6%.

Read DEVICE_RUN_ENGLISH_AFTER_DND.sh, English-minimal-after-DND.log and summary JSON. Script uses unchanged installed J1/minimal manifest, test-without-building, strict start72/stop75, outer jobs1/no parallel/one destination. Raw evidence confirms exactly one executed case,0PASS/1FAIL,42.870s, peak69.8%, Contrast failed; owner records exit65. No snapshot timeout recurred. Purchase controls were queried, not purchased. No credential/purchase-history action is performed by this reviewer. New contrast attachments are under analysis by owners; do not guess root cause or announce a fix. The planned3+2+2 batches remain unopened after this prerequisite failed. Prior failed/interrupted evidence is retained.

## Evidence review — J1 batches and next source

Read gallery3/titles2/key-export2 raw logs and independent paywall/tab review with long-title addendum. Raw executed counts: gallery3 three PASS, peak71.7%; titles2 two FAIL, peak73.3%, old line331 before entering the AXXX L title after location confirmation; key/export2 baseline72.1 rejected with “Not started”, no executed result. Preserve all failures and distinguish gallery case PASS from full app acceptance.

Root accepted the independent source-only review. Current UITest SHA4f94c048ab2d00cd6674fe40b91c942dcee867555618d6a44581ea0ef2c8ce87; subscription source SHAb27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017. Review finds scoped paywall tab hiding and added navigation checks, plus bounded title reverse-scroll preserving existing acceptance checks. Its limits remain: Map search presence is not full input usability; management/legal hit targets are not external flow verification. Installed J1 results cannot prove changed source runtime behavior.

One Debug incremental build is authorized for the device owner, envSWIFTC_MAXIMUM_DETERMINISM=1, start72/stop75, outerjobs1; no xcodegen/clean/install. This record neither launches it nor predicts its result. ExportOptions export/upload plists were prepared and plistlib-validated by root, as recorded in distribution plan; no export/upload. Docs-only oversight; no credential/purchase-history action or agent dispatch/termination.

## Final round evidence — R27 controlled incremental build

Read DEVICE_R27_CONTROLLED_BUILD_RESULTS.md and compact raw log facts. Preserve strict72 preflight baseline72.4 rejection/no xcodebuild separately. Root then authorized single controlled start73/stop75,0.5s,soleheavy,outerjobs1,SWIFTC_MAXIMUM_DETERMINISM=1. Actual log baseline72.5, guard trigger75.0 at line127, TEST BUILD INTERRUPTED, owner exit75. Driver recognized overriding-j for App and Tests at56/82; this is real recognition distinct from prior OTHER_SWIFT_FLAGS-j1...-j8, not a systemwide memory bound.63file digest records freeze inputs.

No BUILD SUCCEEDED/install/test/retry. Partial DerivedData may mix incomplete outputs and is forbidden as installable/release candidate. Owner container proof states installed App/Runner remain J1; source review results are not transferred into J1 runtime evidence. End-of-run owner ps confirms heavy slot released. Root sampled73.0 afterward and will not increase thresholds or retry in this session.

Next is a user Codex restart request to release session memory, followed by a unique incremental path/no clean under guards, then successful-build-only single install/English/title/key-export, remaining transactions/notifications and distribution steps. This is a plan, not performed actions. iPad/iOS17 runtime gaps remain; rights confirmation is done and will not be requested again. No credential/purchase-history mutation or new upload/submission.

## Resumed evidence — after restart

Root reports restart/no residual owned job and68.3% sample. Read new build/install/English/titles logs and94-entry bundle digest JSON; installation main/runner JSON outcomes success. Raw build TEST BUILD SUCCEEDED/peak70.6, installpeak67.6, English1PASSpeak68.3, titles2PASSpeak70.5. Strict codesign twoPASS supplied by root. Reviewed source inputs unchanged4f94…/b271…. No new agent/source action by this observer.

At one read of the current key-export log, export passed43.895s and key test started; root session18106 remains running. Do not claim full2PASS or future result. Current UI does not purchase; fixture Keychain operations are not real provider authentication or unauthorized credential replacement. Exact-candidate passing cases are scoped; previous failures remain in history. StoreKit lifecycle, remaining services, iPad/iOS17, distribution/upload/review not closed. Docs-only evidence handling; no poll loop/heavy/browser/agent dispatch or termination.

## Final key/export batch and iPhone-only scope

One read of completed raw key-export log confirms exportPASS43.895s, keyFAIL168.241s at line470,2executed/1failure,peak73.6; root records exit65. Four-provider save/delete iterations completed before post-relaunch secure-field exists failure. Read-only device diagnosis pending; no root-cause assertion. No purchase/provider credential acceptance is inferred.

User selects iPhone-only first release; map owner updates project.yml/pbxproj under root coordination. This observer performs no dispatch/build/browser/publishing. iPad removed from launch gates by scope, not by a passing test; minimum iOS17 and other transaction/notification/delivery gates remain. Source-family change completion/validation awaits evidence. Old failed runs stay intact.

## R28 preparation and resource handoff

Root supplies independent device static approval of iPhone-only two configuration edits, built UIDeviceFamily pending. Read independent review currentUITestSHAffa3e7a61a10e65c8ff2ebcfdc77c6abd4a7677e14bafddd8ff4679636ae5885 and actual parseexit0; test-only scroll/exists/hittable/capture, no product repair or runtimePASS. R28 prepared assets unrun.

Root readonly ASC confirms signed-in/preparing/manualrelease/no build. Noheavy sample76.7→75.4 after own-tab close/reset. Other Codex pages/previews and personal Sandbox trial confirmation are pending user replies; no implied approval/completion. No other agent document modified; no observer browser/heavy/credential/purchase action.

## Current resource policy and new scope

User explicitly withdrew80% cap/start-stop thresholds. Singleheavy and sampling remain; older guard evidence remains historical. Device owner holds the slot for post-cancellation read-only StoreKit, result pending. User reports cancellation/restoretimeout/noSandbox/no purchase: no lifecyclePASS.

Map pending-pin confirmation and OpenAI dual-country fail-closed gate are under implementation/review, no runtime acceptance claimed. Export oversight proposes disclosures only; no source/localization/website/ASC mutation. ipwhois official documentation read confirms free commercial use/1000daily perclientIP/noSLA, which does not establish retention/privacy compliance. Prior memory wait requests no longer gate work.

## R31/R32 supplied evidence update

Root supplies R31unit56PASS; map4 allconfirm.isHittableFAIL, notcoords; UI3ENPASS/AIfinalunscrolledpickerFAIL/restoreSKIPApplelogin. R32test-onlybuildPASS/mainApphashidenticalR31/Runneronlyinstall/testsnotrun. Preserve candidate distinctions and old evidence.

Reported restore jsonl mixesR29/R31injectedunits/UIstart with no complete matching new operation; no user-timeout conclusion. Authquestionsawaituser. ZHASCdescription1157chars saved but rootverificationpending. This docs-only record performs no device/browser/credential/account action and no release.
