# Final candidate acceptance — active work

## Current final receipt — submitted, waiting for review

Actual ASC DOM and screenshot confirm submission **e27f186c-2fb1-450f-a4ed-84081d05968f**, displayed2026-10-11 11:18 America/Los_Angeles. All three items **Waiting for Review**: app1.0.0(3), annualsubscription6821572701, group22464265. `submitted=true`; manual release retained; **not approved or published**. Evidence: docs/release/evidence/build3-review-receipt.json, build3-review-submission-dom.txt and build3-review-submitted.png. Earlier pending/no-receipt statements below are historical checkpoints superseded by this receipt; underlying tests/logs remain preserved. Shutdown is handled separately by root and is not claimed here.


No App Review submission yet. Build2 uploaded and processed, but superseded. Build3 archive has not run.

## Verified R37–R39 scope

- R38 unit: 65 total, 63 pass, 2 notification-permission skips, 0 failures; peak70.02%.
- R37 unchanged map product: four cases pass (existing preview/confirm, real search, pan/pinch/precise long press, editor persistence); replacement case initially failed because test tapped overlay while landscape. R38 portrait/visible-map replacement+cancel case passes47.223s, peak70.38%.
- R38 simplified AI/settings/planning EN+ZH case passes92.177s, peak74.99%; explicit provider/policy consent and cancel verified with no send.
- R38 toggle functional assertions pass but both appearance images dark; do not infer light verification. R39 corrected SDK appearance control case passes28.132s, peak73.12%; root inspected all four actual images and confirms distinct Light/Dark and green ON/gray OFF.
- R39 test-only build passes, main bundle54-file hashes identical to R38; only Runner installed.
- R39 notification settings test opened only this app and found Allow Notifications0; default row-center tap did not change switch. Test FAIL preserved. R40 test adjusts to observed right-side knob position, not yet run.

## Current real product defect, submission blocked

R38 active-subscription gallery fails because access false. Read-only live StoreKit query completes, revealing verified currentEntitlements contains expired17:33:32 record while verified latest and subscribed+verified renewal status contain new18:33:32 expiry. App incorrectly rejects the new renewal due to stale current record. Subscription owner fixes same-lineage newer renewal fallback; independent reviewer checks it; R40 tests pending. This is not dismissed as an expired account or bypassed with demo screenshots.

## Evidence boundaries

No new purchase/sync/paid AI generation. Prior R36 successful user restore and real CRUD remain historical scoped evidence. Notification delivery has not passed yet. iOS17 runtime and real refund/pending lifecycle remain unexecuted. Do not call these passed.

## R40 corrections and actual results

Subscription renewal patch reviewed by owner, root, and independent reviewer. R40 build PASS/strict signatures/install PASS. Subscription28/28 PASS; all unit69 totals68PASS and one foreground notification case FAIL with3assertions from App host delayed empty synchronization. The other real pending/edit/delete/completion notification case PASS.

R40 read-only live StoreKit evidence8557B85C shows cachedHasAccess true before/after while old expired current remains and new subscribed verified status expires18:33:32Z. No purchase/sync was invoked. R40 real subscription CRUD case PASS88.335s/exit0/peak71.67, covering create/edit/relaunch/persistence/delete without demo access. This closes observed real renewal read-only defect; not a refund/pending lifecycle claim.

R40 system permission reauthorize UI PASS: switch changed0→1 and normal App reportsAllowed. R39 row-center tap FAIL remains recorded. R41 isolates notification service integration via explicit DEBUG-only two-env opt-in at both App automatic sync sites; Release returnsfalse unconditionally. Service/UN/delegate and four actual delivery assertions unchanged. R41 build/tests pending.

## R41 actual outcomes

Build PASS/exit0/peak74.76. Only App+notification test host-isolation files differ from R40; Runner40-file bundle hash identical, not reinstalled. Main installed/strictsignaturePASS. Unit69/69 PASS,0skip,0fail, exit0/peak71.86; actual foreground four-notification delivery+dedup/edit/delete/completion cleanup5.829s, actual pending reconciliation0.061s. Integration explicitly isolates App automatic empty-store synchronization; this proves production reminder service+UN/delegate behavior, not background/locked delivery or complete App lifecycle. Gallery running, no result yet.
