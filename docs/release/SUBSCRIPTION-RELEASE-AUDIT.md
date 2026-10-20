# Subscription release audit — 2026-10-11

## Current R35/R36 audit checkpoint

Current product uses verified subscription-status fallback when exact-SKU currentEntitlements is empty, with transaction verification/expiry/revocation checks. R35 live evidence has empty current plus verified active Sandbox status/latest transaction; appCachedAfter=true. R36 no-demo real-access1/1PASS confirms actual create/edit/relaunch/persistence/delete for the same frozen Main App.23/23logicPASS remains scoped logic evidence. See DEVICE_R36_REAL_ACCESS.md; do not infer complete purchase/restore lifecycle.

Current restore deadlines are **120 seconds for Apple sync + 15 seconds for entitlement read** (product load15seconds). Stop/cancellation/late-result handling remains subject to real UI authentication interruptions. R35restoreUIFAIL encountered late Apple sign-in and XCTest default Cancel; neither Stop defect nor successful restoration was isolated. Renewal/expiry/revocation and notification delivery gaps remain. R36AI check and finalarchive are pending. Earlier audit below is historical and its old15second-sync description must not guide current execution.

## Historical audit — retained evidence

Scope: read-only source/release review of the frozen candidate. No source mutation, build, simulator, device action, purchase, or App Store Connect write was performed. The device agent's current 29-case run is in progress; this report does not infer its outcome. Earlier environment and test history remains in [SUBSCRIPTIONS.md](../configuration/SUBSCRIPTIONS.md); saved App Store Connect fields remain in [EXTERNAL-CONFIGURATION.md](EXTERNAL-CONFIGURATION.md). This report supplies the release verdict, targeted risks, review-note draft and execution procedure rather than duplicating that chronology.

## Verdict and factual checks

Subscription release acceptance is **OPEN**. US USD9.99/year, one-week free introductory offer and 174-region availability (excluding mainland China) are recorded as saved by the coordinator, not independently exercised by this audit. App Store approval, paid-app agreement readiness, live storefront product delivery and actual sandbox purchase lifecycle remain separate gates. No sandbox lifecycle is claimed passed.

| Concern | Current source behavior | Practical limit |
| --- | --- | --- |
| Authentic access | Only verified current entitlement for exact `com.waypoint.maptodo.annual`, no revocation, future nonnil expiry grants access | StoreKit environment lifecycle still requires acceptance |
| Trial | Checks actual free introductory offer with seven-day/one-week duration and Apple eligibility; never uses install date | Eligibility must be checked on both fresh and already-used sandbox accounts |
| Price | Paywall uses actual Product.displayPrice; local fixture is9.99 | Storefront conversion and actual purchase sheet must match |
| Launch/foreground | App calls shared.refresh at launch and foreground; default access false | refresh can remain busy while product request stalls; see risk below |
| Expiry | Timer at transaction expiry plus update/foreground reconciliation | Background timers are not guaranteed; foreground reconciliation is required |
| Revocation | Verified product updates reread current entitlement; absent/revoked transactions clear access | Must test receipt/status propagation on supported Apple environment |
| Restore | Explicit user action only;15second non-cooperative deadline around sync plus immutable entitlement read; independent restoring state and operation UUID | Timeout cancels waiter, not necessarily Apple UI/SDK work; no success is fabricated |
| Late restore result | Losing work has no direct app UI mutation; single-resume state rejects late result | A real verified Apple transaction update may legitimately activate access later; that is distinct from stale restore message |
| Pending | Pending gives no access; normal purchase locked; explicit status check or rejection retry available | A rejection may not yield a transaction update; local lock is transient, not entitlement |
| Expired data | Existing task detail/view/navigation/weather and export remain available; editor save, completion and planning apply check AccessPolicy | User deletion is allowed as data control; DEBUG demo bypass requires both test/demo flags and compiles out in Release |
| Legal/exit | Real privacy/terms links; Done and legal labels have44pt minimum content regions; Done not disabled during restore | Latest physical accessibility/link behavior awaits actual regression result |

## Findings requiring targeted verification

No new **already reproduced** P1 access bypass was found in this read-only pass. Do not downgrade the unresolved real StoreKit acceptance gate because the policy unit tests pass.

**P2, source-supported availability risk: unbounded product loading.** SubscriptionStore.refresh lines49–66 holds isRefreshing across Product.products. A request that never completes keeps purchase/retry disabled and causes foreground refresh to return before rechecking entitlement. Expiry timer and Transaction.updates still provide independent reconciliation, so this is not evidence of permanent paid access. Reproduce with a cancellability-ignoring product loader or supported network failure harness, verify busy state can settle and foreground entitlement checks still run. This risk was reported to the coordinator; no source change made during freeze.

**Concurrency hypothesis, not a confirmed failure: stale entitlement snapshot ordering.** Restore reads an immutable snapshot, then returns to MainActor to apply it. A revocation/expiry update could be processed between read and apply. Operation UUID protects against another restore, not every independent entitlement update. Design a deterministic harness that suspends snapshot completion, applies revocation, then resumes the old snapshot; require the final state to remain denied. Current code has no injectable entitlement reader, so no reproduction was run or claimed. Consider a shared entitlement revision and revalidation-at-apply only if the hypothesis reproduces.

**Configuration invariant:** billing grace period must remain OFF until verified renewal-status/grace-expiration support is implemented. Current policy denies past transaction expiry, even if Apple could offer grace in currentEntitlements. This is a documented compatibility limit, not an enabled production failure.

## App Store Connect subscription review notes — draft for coordinator

> Waypoint — Map & To-Do does not require an app account or sign-in. Open Settings → Subscription & Trial to review the annual subscription. The product identifier is com.waypoint.maptodo.annual. US price is USD9.99 per year; storefront-localized price is displayed by StoreKit. Eligible Apple accounts are offered a one-week free trial followed by the annual renewal price; account eligibility and the final terms are confirmed by Apple’s purchase sheet.
>
> An active verified subscription/trial enables creating and editing map tasks and generating/applying plans. Existing tasks can always be viewed, navigated and exported after expiry. Users can also delete their local data. Restore Purchases and Manage or Cancel Subscription are available on the same screen. Restore may request Apple authentication; if it does not complete, the app reports a timeout and allows retry without claiming restoration. Privacy Policy and Terms of Use are linked on the paywall; the terms page links Apple’s standard EULA.
>
> Public support: https://geruyang.github.io/waypoint-support/ . Privacy: https://geruyang.github.io/waypoint-support/privacy/ . Terms: https://geruyang.github.io/waypoint-support/terms/ . No developer or AI-provider credentials are necessary to inspect the subscription flow.

This is prepared text, not saved or submitted by this audit. Do not include demo-access arguments, a local StoreKit fixture, or an unsupported assertion that sandbox purchases were verified. Before submission attach a screenshot from the actual candidate showing real localized price/offer, and associate the first subscription with the submitted app version. Verify product availability, review metadata and agreements using the coordinator’s authorized App Store Connect workflow.

## Sandbox lifecycle execution checklist — NOT_RUN until recorded

Use a signed development build with the Xcode StoreKit fixture disabled, or an authorized TestFlight build. Use Apple's sandbox environment and designated test account, confirm the Apple sheet identifies the test environment before approving; stop if the environment is production or unclear. No account passwords, full receipts, signing secrets or AI keys go in evidence. Run one device/heavy job under the existing memory policy. Keep local StoreKitTest and real sandbox evidence separate.

Record each case with candidate commit/build, OS/device, account label (not credentials), storefront, Apple environment, initial state, steps, observed product/transaction attributes, expected/actual access, timestamps and screenshot/log reference. Label unavailable scenarios BLOCKED/NOT_RUN with reason. A network failure is not a valid purchase lifecycle pass.

| Case | Concrete execution | Expected evidence |
| --- | --- | --- |
| Product delivery | Fresh sandbox account; open paywall; inspect one-year product, actual price and seven-day offer; compare Apple sheet without buying | Exact product, localized annual renewal amount, offer length; no access before approval |
| Eligible trial | Account with cleared eligible purchase history; approve test purchase | Verified sandbox transaction, introductory offer, future expiry; editing/planning allowed; no local-test badge |
| Ineligible repeat | Use same account after trial use without clearing history; reopen paywall | Eligibility false; paid annual CTA and real price; no second promised trial |
| User cancellation | Cancel Apple purchase confirmation on fresh account | Cancelled message, busy reset, access false; no task creation enabled |
| Pending | If Apple's sandbox account scenario supports pending, submit and approve/reject externally; otherwise run the two actual SKTestSession Ask-to-Buy cases on a working runtime and label sandbox pending coverage unavailable | No access while pending; ordinary duplicate request blocked; verified approval grants; denial plus explicit retry remains safe |
| Restore valid | Purchase; relaunch/reinstall without deleting server purchase history; inspect launch access, then explicitly restore | Verified entitlement survives fresh process; restore success only on verified active state |
| Restore empty | Fresh separate account with no purchase; explicit Restore | No entitlement and no access; no fabricated trial |
| Restore stalled | Deny/leave authentication unanswered or use controlled connection failure; retain system prompts if present | App waiter settles around15seconds, timeout message, Restore enabled again and Done can exit; Apple UI may remain separately controlled by system |
| Late result/retry | After timeout begin another restore, then complete earlier Apple authentication if system allows | Earlier waiter cannot overwrite new operation message/busy state; actual verified transaction updates are allowed to reconcile real access |
| Renewal | Set sandbox renewal speed using Apple's account controls; observe a real accelerated renewal and foreground refresh | Verified new transaction/expiry, uninterrupted access; record configured speed rather than assuming durations |
| Cancellation/expiry | Cancel auto-renew in Apple subscription settings; first confirm access until current expiry, then wait for accelerated expiry and foreground | Cancellation alone does not revoke prepaid time; expiry clears writes/planning while saved data view/export remain |
| Billing retry | With grace disabled, use Apple's sandbox failure/renewal controls if available | Expired unpaid period denied; successful subsequent verified renewal restores access |
| Refund/revoke | Exercise an Apple-supported sandbox refund/revocation mechanism available to the test account/harness; if unavailable, use SKTestSession.refundTransaction on a working local runtime and retain sandbox refund as BLOCKED | Revocation/absence clears access, no need to press Restore; no production refund or invented server event |
| Region/localization | At least US English plus an enabled non-US storefront and zh-Hans UI; check mainland China availability separately | Actual converted displayPrice, correct eligible/ineligible text and working HTTPS legal links; excluded storefront cannot be sold an invented fixture |

Sandbox purchase-history resets restore repeatability but change eligibility, so record exactly when reset was performed. Apple documents accelerated sandbox renewal and configurable speed; do not substitute the local seven-day wall clock or an arbitrary fixed renewal duration.

## Primary references

- [AppStore.sync](https://developer.apple.com/documentation/storekit/appstore/sync%28%29): explicit synchronization can request authentication; normal entitlement retrieval does not need a restore button press.
- [currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements): refunded/revoked products are absent from the current entitlement set.
- [Testing purchases with sandbox](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox): sandbox accounts, purchase-history reset and account controls.
- [Testing an auto-renewable subscription](https://developer.apple.com/documentation/storekit/testing-an-auto-renewable-subscription): accelerated renewal and selectable speed.
- [Testing failing renewals](https://developer.apple.com/documentation/storekit/testing-failing-subscription-renewals-and-in-app-purchases): supported billing issue controls.
- [Apple Developer Forums runtime issue](https://developer.apple.com/forums/thread/826971): recorded local StoreKit configuration failure diagnosis; this is not proof of sandbox failure or success.

## Source remediation after audit — pending execution

The coordinator authorized repairing the two source-supported risks after the device run ended. Product and introductory eligibility now load into one immutable ProductPayload under SubscriptionTimeout with a15second deadline; only the current product-operation UUID may apply it. Foreground refresh checks entitlements before deciding whether another product load is already busy. Entitlement reads use a monotonically advancing revision, so an older read cannot overwrite a newer read; apply also rechecks expiration against current Date and clears the local-test marker when access is denied. Production defaults remain real StoreKit readers. Optional reader/loader injection supports deterministic regressions, not a release entitlement bypass.

SubscriptionConcurrencyTests adds three source-only cases: older active read released after newer revoked read; expired snapshot at application; stuck product request with independent foreground revocation, timeout retry and discarded late payload. Regression source was written before implementing the ordering guard, but no red/green run was authorized or claimed. Swift frontend parse passed; this is neither typecheck nor runtime evidence. The latest candidate must run SubscriptionConcurrencyTests together with SubscriptionTimeoutTests, SubscriptionTests, and the separate six StoreKitLifecycleTests on a supported environment. Earlier four real StoreKit failures remain historical evidence until a real lifecycle rerun replaces them.

## Read-only live Sandbox diagnostic draft

User confirmed a Sandbox account was created and signed into the iPhone. That account state alone does not prove a particular StoreKit process uses Sandbox. Read-only inspection found the current shared scheme's StoreKitConfigurationFileReference only under LaunchAction; TestAction has no StoreKit reference. project.yml likewise sets only Run's local configuration. No .xctestrun or .xctestplan exists under the inspected build directory. A generated test-run artifact outside that directory remains unverified and must be inspected for any StoreKitConfigurationFilePath/URL or environment override before execution. A bundled .storekit resource alone does not initialize SKTestSession, but running StoreKitLifecycleTests in the same process does initialize a local session. Never run those local cases alongside a live Sandbox diagnostic.

New source-only draft: MapToDoTests/SandboxSubscriptionDiagnosticsTests.swift, method testReadOnlyLiveProductEligibilityAndVerifiedEntitlementMetadata. Existing DeviceIntegrationTests is Weather-only; existing StoreKitLifecycleTests controls local test transactions, so neither proves live Sandbox metadata. The new method is physical-device-only and reads actual Storefront, exact Product, annual duration, localized price/currency, introductory seven-day offer, current account eligibility and verified matching transaction environment. It attaches redacted JSON without account identifiers, transaction IDs, receipts/JWS or credentials. It calls no purchase, AppStore.sync, history reset or SKTestSession API. Product reads have20second bounded waiting and current-entitlement enumeration10seconds. Simulator execution is explicitly skipped, not accepted as live evidence.

Before integrating, the coordinator should generate the test target, prepare an isolated no-local-StoreKit test execution and run only this method with the authorized physical device under the memory policy. Disable Run's local StoreKit file if a preceding app launch might select it; do not change user purchase history. Inspect any generated xctestrun before executing. Draft source frontend parse passed, but no project change, compile, device call or test run was performed by this task.

Acceptance interpretation: live product metadata can pass with zero matching entitlements; that proves no purchase occurred and cannot prove a sandbox transaction environment. Eligibility is recorded, not forced true because history is intentionally preserved. A matching existing transaction must be verified and environment Sandbox; Xcode or Production contamination is a diagnostic failure. Actual price must be9.99/USD only for US storefront; other storefronts retain real converted values. No metadata failure triggers fixture or purchase fallback. This draft does not replace any missing purchase/renewal/refund/expiry lifecycle acceptance.

## Copy-ready review text consistency check

`SUBSCRIPTION-REVIEW-NOTES.txt` is the coordinator's copy-ready English subscription review-note draft, checked against current paywall labels and write gates. It explicitly includes marking/unmarking task completion because TodayView and MapScreen gate that mutation on AccessPolicy.canWrite. It preserves view/navigation/export/deletion after expiry and states that optional provider API keys/credits are separate from Waypoint access; there is no consumer ChatGPT/OpenAI subscription integration. This prepared wording is not saved externally by this audit and is not sandbox verification. Actual candidate paywall screenshot and real sandbox metadata/lifecycle results remain separate evidence requirements; do not infer them from this text.
