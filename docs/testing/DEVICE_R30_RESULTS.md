# R30 candidate verification

Current candidate includes dual physical/network non-mainland OpenAI gate, cancellation-safe OpenAI transport, GLM defaults, map preview confirmation, camera-intent repair, independent accessible coordinates, and DEBUG-only StoreKit diagnostics.

- Source freeze: `DEVICE_EVIDENCE/R30-inputs.json` (56 files). Source hashes rechecked after build.
- Build-for-testing: exit 0, TEST BUILD SUCCEEDED, highest sampled memory 73.32%. User revoked previous memory limits; sampling only and one heavy job remain.
- App and Runner strict/deep signature verification: exit 0. Bundle file digests: `R30-bundle-sha256.json` (94 files). Actual device family `[1]` (iPhone only).
- Install and device tests: NOT RUN yet. Phone still R29 until the R30 install receipt is recorded.
- R29 map4: 0/4 pass, exit 65, highest sample 71.06%; preserved failures. R30 map repair is not yet runtime verified.
- Simulator iOS 26.2 local StoreKit comparison: separate owner running from frozen R30 source; no result yet.

## Actual R29 user StoreKit attempt

Sanitized original log: `DEVICE_EVIDENCE/R29-storekit-user-restore-timeout.jsonl`. Purchase began with active scene/key window and canMakePayments true; user canceled the unlabelled panel and StoreKit returned userCancelled at 20.34 seconds. This is not purchase success and does not independently identify the environment.

Restore entered AppStore.sync, then the app's own 15-second timeout fired at 15.97 seconds (NSURLErrorDomain -1001). sync later returned an error with Task cancellation true, after the timeout canceled the operation. No entitlement-read phase started. The late StoreKit error is not independent evidence of a server or account failure. No verified transaction occurred.

Next restore change under review: allow a longer bounded user-authentication period and explicit cancellation of waiting, then separately bound entitlement reads. Do not repeat the identical purchase/restore request to the user without new evidence.

## Release status

No R30 release archive/export/upload/review submission. Final submission remains authorized, with manual release. Device transaction/notification acceptance and release checks remain open.
