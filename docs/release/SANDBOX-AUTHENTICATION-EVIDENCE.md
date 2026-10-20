# R29 evidence and restore authentication design

Prepared2026-10-11 for coordinator review. R30 source remains frozen. No build, device call, account operation, purchase, or source modification was performed for this report.

## What R29 actually proves

Evidence: `docs/testing/DEVICE_EVIDENCE/R29-storekit-user-restore-timeout.jsonl`.

- Purchase entered with real product available, no busy/pending/access guard, canMakePayments=true, foreground-active scene and key window=true. SDK returned userCancelled after20.34seconds, Task.isCancelled=false. The user reports cancelling because the panel lacked an explicit Sandbox explanation. This rules out an immediate app-side cancellation for this attempt, but does not prove the panel's environment or exact presentation hierarchy.
- Restore reached AppStore.sync and never reached sync.return or entitlement.start. The app's own15second timeout completed at15.97seconds with NSURLErrorDomain-1001. The losing sync task then reported StoreKit.StoreKitError code1 at16.89seconds with taskIsCancelled=true. The second error follows our cancellation; it must not be presented as an independently observed Apple/network failure.
- No verified transaction was produced. Product delivery and logged-in test-account reports are not transaction environment evidence. No successful purchase or restore is claimed.

## Official Apple environment and authentication evidence

Apple's [Sandbox testing documentation](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox) identifies development-signed apps built/run from Xcode and TestFlight apps as Sandbox test routes. Its development-account instructions describe the visible `[Environment: Sandbox]` indication after sign-in and say that a missing indication means production. A development certificate readout alone does not establish which installed app, launch configuration, account session and system panel the user is interacting with. The documentation does not promise identical UI wording on every OS presentation variant; it does explicitly describe this indication as the environment check. Do not assert the panel displayed it when it was not observed.

Apple's [TestFlight purchase guidance](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight) explicitly states that apps downloaded from TestFlight automatically operate in Sandbox. [Apple's testing-environment comparison](https://developer.apple.com/documentation/StoreKit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox) states test purchases incur no charges. A verified TestFlight-installed candidate is therefore a documented alternative to repeating the same ambiguous development panel. Download provenance/build must be recorded; an App Store production install is not TestFlight. Sandbox controls/account choice are separate from the no-charge TestFlight environment; do not sign the user out of unrelated Media & Purchases without separate necessity/authorization.

Apple's [AppStore.sync documentation](https://developer.apple.com/documentation/storekit/appstore/sync%28%29) says sync prompts for authentication and should only run after an explicit user action. It also says ordinary launch/reinstall can read currentEntitlements without sync. Apple gives no15second guarantee for manual authentication. The present global15second budget can interrupt a user-driven authentication flow; that is an application waiting-policy issue, not evidence of Apple outage.

## Next validation without repeating the same failed user action

1. Finish remaining nonpurchase R30 acceptance. Preserve R29 as a cancelled purchase/restore-wait timeout, not a service outage or transaction pass.
2. Prefer the already-authorized TestFlight candidate after upload/processing and verify the installed beta build identity. This provides Apple's explicit automatic-Sandbox guarantee and avoids asking the user to repeat an ambiguous development panel unchanged.
3. For the single next approved purchase observation, capture only the panel type, build provenance, presence of Sandbox/test-no-charge wording and non-account confirmation terms. Distinguish an Apple sign-in/authentication prompt from the final payment confirmation. Password, account identity and side-key/biometric confirmation remain with the user. If actual installation is not verified TestFlight and the environment remains ambiguous, stop before approving.
4. After confirmation, read the exact verified transaction for com.waypoint.maptodo.annual: environment=sandbox, no revocation, future expiry. Current diagnostics records environment/expiry/revoked fields; manually require a nonempty matching set and future date because its empty-entitlement metadata pass is not a purchase pass. Existing nocharge guarantees do not replace verifying that the app unlocks and restores correctly.

## Minimal restore patch design — NOT IMPLEMENTED

Keep the Restore button as the only trigger for AppStore.sync. Keep normal purchase behavior, eligibility and entitlement checks unchanged. Do not extend the product loader's15second limit.

- Split restoration into two sequential waits: AppStore.sync gets a120second finite interactive budget; after sync returns, current-entitlement retrieval gets its own15second limit. Use SubscriptionTimeout so a noncooperative loser cannot keep the UI waiter suspended.
- Represent the phase as syncing versus checking entitlements. During syncing, tell the user Apple may request account verification; do not call an unfinished authentication phase a network failure. During checking, display that verified purchase status is being checked.
- Keep one restore operation UUID and an owned task handle. The UI's Stop waiting action invalidates the operation UUID first, cancels the app waiter, and clears its restoring/busy UI state. It must not claim that an Apple payment, subscription, or system authentication session was cancelled. The system may still own a separate prompt.
- Every state/message/snapshot application and cleanup checks its operation UUID. Late sync or reader completion cannot overwrite a newer operation. Create the entitlement-read revision when the post-sync read actually begins; reject older read revisions and recheck expiry with current Date as already implemented.
- A verified Transaction.updates event continues to reconcile real access even after Stop waiting. This is actual Apple evidence, not a late stale restore success. No stopped/timed-out flow grants access on its own.
- Keep Done usable. Prevent a second app restore while the current waiter is active; allow retry after Stop waiting or a phase deadline. Preserve15second entitlement and product failure semantics separately from the120second user-auth phase.

### Required regressions before acceptance

Add deterministic injected sync action and short test-only timing parameters; production defaults must remain real AppStore.sync/120seconds and real entitlement reader/15seconds. No live purchase is necessary for these race tests.

- Sync waits beyond the old short budget but completes within the interactive budget: entitlement retrieval starts only after sync completion.
- Sync never cooperates: interactive deadline clears busy with a sync-wait message, never access.
- Sync succeeds but entitlement retrieval stalls: separate entitlement deadline clears busy, never access.
- Stop waiting clears busy and preserves the distinction from cancellation of an Apple transaction.
- Old sync or old read released after stop/new restore cannot replace newer phase/message/access snapshot.
- Verified later transaction event still reconciles authentic access; expired/revoked results remain denied.
- UI: Stop waiting visible only during restore, minimum44pt hit area, Done always usable; both push and sheet dismissal retain restored tabs.

These are proposed tests, not new test source and not execution evidence. Update the existing UI restore assertion to accept the phase-specific terminal outcomes and Stop waiting behavior; do not shorten or skip its assertions to mask the problem.

### Proposed localization keys (coordinate single-writer resources)

| Chinese key | English value |
| --- | --- |
| 正在同步购买。Apple 可能会要求验证账户，请在系统提示中完成。 | Syncing purchases. Apple may ask you to verify your account in a system prompt. |
| 正在核对已验证的购买权益… | Checking verified purchase access… |
| 停止等待 | Stop waiting |
| 已停止等待，尚未确认恢复。此操作不会取消 Apple 购买或订阅。 | Stopped waiting; restoration has not been confirmed. This does not cancel an Apple purchase or subscription. |
| 等待 Apple 同步超时，尚未确认恢复。请完成系统账户验证后重试。 | Waiting for Apple synchronization timed out; restoration has not been confirmed. Complete any system account verification, then retry. |
| 核对购买权益超时，尚未确认恢复，请重试。 | Checking purchase access timed out; restoration has not been confirmed. Please retry. |

The planned120second value is an app UX policy, not an Apple SLA. Coordinator authorization/source-lock release is still required before implementation; nothing in this document claims R30 already contains this patch.
