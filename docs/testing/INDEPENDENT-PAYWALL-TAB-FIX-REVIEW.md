# Independent minimal paywall/tab source review

2026-10-11. Only current source/navigation/test logic inspected. No build, device, browser, parse rerun, signing or App mutation. Installed J1 evidence (including its ongoing 3+2+2 checks) is not transferred to these changed files.

## Exact reviewed source

- `MapToDo/Features/Subscription/SubscriptionView.swift` SHA256 `b27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017`
- `MapToDoUITests/WaypointUITests.swift` SHA256 `3380079a108d37567619dad168bba77042309c21ae70be5d836b3befbe35fcf7`

Both files are currently untracked, so `git diff` cannot supply a committed baseline. Current source matches the specified minimal change: SubscriptionView line 79 hides `.tabBar`; the English smoke preserves the original unfiltered contrast audit at lines 537–539 and appends checks at 540–562. No source PASS is interpreted as runtime PASS.

## Source conclusion

**No blocking defect established in the specified minimal change.** The tab visibility preference is scoped to SubscriptionView. Settings reaches it by NavigationLink (`SettingsView` subscription destination), while Today no-access creation presents it as a sheet (`TodayView.swift:59–61`, :54). The same `@Environment(\.dismiss)` Done button at SubscriptionView:15–20 is appropriate to both navigation and presentation contexts. The added test verifies tab restoration after the pushed view closes and closes the second, sheet-presented paywall before returning to Map. Whether the toolbar visibility preference actually restores correctly on this OS remains precisely what the new runtime assertions must test.

The new management/privacy/terms checks assert reachability without tapping purchase, restore, management or web links. The earlier real-product/eligible-or-ineligible checks and unfiltered contrast audit are preserved; no UI assertion is bypassed for convenience.

## Preconditions and remaining validation gaps

- `launch(reset:true, seeded:true, demoAccess:false, language:"en")` excludes DEBUG demo entitlement but **does not erase actual StoreKit transactions**. The test requires an account with no active annual receipt. Its earlier `subscription.purchase` existence/enabled assertion (520–525) already enforces the no-access product UI at that time, so an active receipt should fail the test rather than yield a false paywall pass. An entitlement acquired externally between those checks and Today Add is still an environmental precondition change; do not describe reset-data as clearing StoreKit. No purchase is issued in this case.
- The scheme has a local StoreKit reference in LaunchAction, not proof that a destination `.xctestrun` does or does not inject it. The exact runtime test configuration must remain the sole-heavy device owner's responsibility. A product metadata load does not certify transaction environment or real trial activation.
- **P2 test coverage gap, not a product defect:** the final Map check (`WaypointUITests.swift:561`) only waits for `map.search` to exist. It does not establish the search field is hittable, editable, or that map interaction works after the sheet closes. The test does verify a working Map tab tap through its shared tap helper; phrase final coverage as “Map tab navigation and search presence,” or add a hittability/input assertion if broader usability is intended.
- Management/terms/privacy assertions establish visible hit targets, not successful management-sheet presentation or legal-link content loading. This is consistent with the stated no-browser/no-purchase minimal test, but cannot close separate end-to-end external-link or StoreKit-management verification.

Recommended next action: one exact-candidate English smoke runtime check under the existing device/memory constraints; preserve all prior strict assertions. No additional product change or rebuild was performed by this review.

## Addendum: long-title form navigation (same date)

Updated UITest SHA256: `4f94c048ab2d00cd6674fe40b91c942dcee867555618d6a44581ea0ef2c8ce87`. SubscriptionView remains `b27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017`. The earlier UITest SHA above is historical, not the current test source.

Inspected change: `exerciseLongTitle` now calls `XCTAssertTrue(scrollToElement("task.title", upward:false), ...)` immediately after tapping `task.location.confirm` (`WaypointUITests.swift:329–331`). The helper (`:692–699`) performs bounded reverse scrolling until the original title element both exists and is hittable; it neither supplies a substitute element nor ignores a missing title. `scrollContent(upward:false)` drags downward, which returns toward the top of the form.

The old `Input-layout-minimal-titles2.log` provides specific support for this navigation correction: the NORMAL cycles emitted editable/reopened or readonly screenshots; the next AXXX L cycle scrolled to locate `task.location.confirm`, tapped it, then waited for `task.title` without returning to the top. Both cases failed at old source line 331 (log lines 294 and 576), before entering the long title in that second cycle. The log sequence supports an offscreen/lazy Form-element hypothesis; it does not establish whether the modified test will now pass.

**Conclusion: source-only test navigation correction; no weakening of title acceptance found.** Current lines 334–347 retain one-line baseline measurement, complete editable value checks, the `>2.5×` height assertion, save, terminate/relaunch, reopen, complete saved title checks and saved wrap-height assertion. Lines 348–350 retain readonly-state and disabled-save checks. `assertReadableTitle` at 358–365 still compares every character including the final marker and bounds the title horizontally. No App source was changed by this addendum or this test correction, and no product-title fix or runtime PASS is claimed. The next exact-candidate run must still exercise both NORMAL and AXXX L cycles and both edit/readonly cases.

## Addendum: provider secure-input navigation after relaunch

Current UITest SHA256: `ffa3e7a61a10e65c8ff2ebcfdc77c6abd4a7677e14bafddd8ff4679636ae5885`. `swiftc -frontend -parse MapToDoUITests/WaypointUITests.swift` actually returned exit 0; no build/install/device action was run.

The minimal addition after reselecting OpenAI (`WaypointUITests.swift:469–473`) scrolls to `ai.key`, retains the original `SecureTextField.exists` assertion, adds a `SecureTextField.isHittable` assertion, and captures the resulting screen. The bounded scroll helper requires exists + hittable and still fails if the element cannot be reached. It cannot replace a SecureField with a normal TextField, silently skip the test, or make absent input succeed.

The original four-provider loop at :416–457 remains intact: Gemini absence, SecureField type, empty-input save disabled, obscured sentinel value, keyboard Done, save result, stored-key state, absence of exposed sentinel text, delete confirmation/cancel retention, confirmed deletion result, absent-key deletion disabled and return to provider picker. Relaunch still verifies persisted OpenAI selection and unavailable Gemini. No acceptance assertion was removed or relaxed.

Old evidence `DEVICE_EVIDENCE/R27-after-restart-key-export2.log:1091–1101` shows the post-relaunch OpenAI selection followed immediately by `Checking existence of ai.key SecureTextField` and failure at old line 470, with no intervening scroll. Earlier in the same case the secure-input/save/delete sequence progressed through all four providers. This supports the stated test navigation correction and is consistent with a lazy/offscreen Form element. It does not prove the product is now correct or the modified case will pass.

Conclusion: **source-reviewed navigation-only correction; no assertion weakening found**. Current-source parse PASS is limited syntax evidence. Future exact-candidate runtime must still run the full case and obtain the new post-relaunch screenshot; earlier installed J1 results remain attached to their original binary/source hashes.
