# R42 independent source review

Review scope: compact map markers, native/background/saved selection arbitration, manual place names, cancellation, TaskEditor name persistence and navigation copy. Read-only product review by `ui_design`; no source edits, compile, build, installation, browser or device operations. **No new runtime PASS is claimed.**

## Exact reviewed files

| File | SHA256 |
|---|---|
| `MapToDo/Features/Map/MapScreen.swift` | `9e1c5c2e2432d05dd1ecb7d6886388b5428599c3715b311215297772449b1539` |
| `MapToDoTests/MapTests.swift` | `da24d26a53037da7b42b729ead06c9cc7beaa89bb02d6af15a0f97cb141b295c` |
| `MapToDo/Features/Map/TaskEditorView.swift` | `275e3cf27000a59efde1d51c3d7faa5cbddc9a5c22a344883a153ba38afe0e1a` |
| `MapToDo/Resources/en.lproj/Localizable.strings` | `2be0491bb4629dc31e18ba3d3e7d5a04f342c92cb77b07d88fb47e80fd4026e1` |
| `MapToDo/Resources/zh-Hans.lproj/Localizable.strings` | `83e6a56655c7ef7cd478fcf0000fc656e7cee6ca70131a5b1c56a673b5e493bd` |

The earlier MapScreen `c0bf…9191c` review identified a name-focus boundary; the final `9e1c…1539` adds focus clearing and captured-selection binding guards. Findings below refer to the final version.

## Findings

**No remaining source blocker found within this scope.** This is source acceptance for the next coordinated build, not device or accessibility approval.

- **Compact markers:** saved graphic28/glyph12 and selected graphic32/glyph14 are centered inside transparent44×44 frames. Both Annotation anchors are explicitly `.center`; no graphic offset changes the coordinate. Fill/stroke apply to the inner badge. Selected accent ring and different glyph distinguish state alongside size, while surface separation and dynamic colors retain light/dark design. Fixed glyph sizes avoid AX expansion inside fixed circles. Saved Button retains plain style, contentShape and button accessibility traits. Actual44pt hit testing and contrast against map tiles require runtime.
- **Native/gesture priority:** background selection uses simultaneous SpatialTap, allowing native MapKit gestures. Native POI selection cancels the150ms deferred generic tap; saved task preview cancels deferred work and suppresses generic/native handling for0.7s. If generic recognition precedes saved-button action, cancellation removes its deferred work; if it follows, the suppression guard rejects it. Long press and pan/pinch also suppress accidental taps. This supports intended arbitration; recognizer timing still needs actual native-label, saved-pin, pan/pinch and exact-hold tests.
- **Manual name race:** name-field getter/setter require the captured selection UUID. All lookup callbacks verify active lookupID/pendingSelection.id; native and nearby responses additionally verify request object identity. Both POI merge and geocoder merge preserve `userEditedName`, including a whitespace draft so async metadata cannot silently turn an invalid manual value into a valid one. Blank/whitespace Confirm is disabled. Coordinates/time zone are not changed by the name binding; native POI resolution may intentionally resolve the coordinate before its request finishes, while generic reverse-geocoding only supplies metadata.
- **Cancel and transition:** cancel clears focus, pending selection, lookup UUID and deferred/native/nearby/geocode work; late callbacks fail their guards. Search result, coordinate and existing-task selection each clear name focus. Confirm opens the editor and clears pending state; no map-preview rename directly updates TaskStore. Existing tasks remain viewable without write access; their preview does not expose editable name input. Leaving Map cancels asynchronous work/location request; returning-card persistence is existing local view state, not a saved task.
- **AX layout:** one bounded details ScrollView, separate unique coordinate sibling, and horizontal normal/vertical AX actions remain. New writable preview has one labeled name field rather than duplicate name heading. The field has44pt minimum height, up to3 visible lines and Done focus dismissal. Actual AXXXL keyboard/action/card clearance is not established by source or R41 images; these are changed R42 views.
- **TaskEditor:** editable place name binds only `draft.locationName`; Save trims it and substitutes localized map-point fallback when blank. Rename alone does not change title, coordinates, time or time zone. Existing title trimming and explicit location-picker coordinate/time-zone changes remain separate. Readonly now uses naturally wrapping fixed-vertical Text with the same `task.location` ID, closing the earlier disabled-three-line source risk. Draft comparison still protects Cancel/dismiss. Editable long names can scroll inside their3-line field; check keyboard editing and full saved/readonly value in runtime.
- **Copy/attribution:** Chinese `开始导航` maps exactly to English `Open directions`; native `MKMapItem.openInMaps` remains the action. No app-authored map-provider caption was added. Native MapKit attribution has not been hidden, covered by a newly introduced overlay, or edited out. Empty feature-selection content affects the optional POI selection presentation, not native map attribution.

## Evidence and next verification boundary

`R42-policy-regression.md` records the owner's extracted pure-policy RED/GREEN harness and syntax parse. These are **not XCTest or app/MapKit runtime**. MapTests source covers manual-name precedence, native suppression, coordinate-intent policy and touch-time distance limits; it does not execute asynchronous UI callback races or prove native recognizer priority.

Next coordinated candidate should verify unchanged saved-pin selection, native POI label selection, exact long press plus pan/pinch, rapid reselection/cancel with delayed responses, and manual name persistence. Include normal/AX name edit→Done→Confirm, center anchor and44pt saved-pin hit area, readonly full name, and light/dark screenshots. R41 remains valid prior screenshot evidence only; it cannot approve R42 compact markers or edited-place UI.

## DEBUG native-map attribution probe: source-only addendum

Reviewed `MapToDo/App/MapToDoApp.swift` SHA256 `df3f5ff233ceae14ae27e36d7b2020784a4f6f2d7c785abdbca09dff6bfe10df`.

- Probe MapKit import and view branch are inside `#if DEBUG`. Both `--uitesting` and `--native-map-attribution-probe` are required; ordinary Debug launches use RootView, and the Release source branch is unconditionally RootView.
- The probe branch constructs a standard native Map at the public Shanghai coordinate31.2304/121.4737, with no custom annotations, overlays, cards, branding text or custom map controls. Its only additional view modifier is a diagnostic accessibility ID. It does not hide native attribution.
- Shared App environment, subscription/reminder lifecycle and error alert remain outside the branch. Thus normal lifecycle behavior was not removed. If a store error presents that shared alert, the capture would not be a clean native-map attribution comparison; verify the eventual screenshot is alert-free.
- Actual probe screenshots and Release binary string verification are pending. Source proves isolation of the visual branch, **not that any specific logo has already been observed on the standalone Map**, nor that the archive has been inspected. Root owns adding the probe string to the Release verifier before archive.

No product source change or compile/runtime operation was performed by this reviewer for the probe.

## R43 all-native-kind source follow-up and R42 actual image evidence

Reviewed MapScreen SHA256 `37dbd4bbcfbadc8ca8dd3582b3a29b03b0c5ed88c67682a2248e90df9b6cb131` and MapTests SHA256 `58d6d1494bae90cb7e03b6432add1a31696b7cd19aa4c24f45401e3d07ff746d`. No product edits or compile/device operation by this reviewer.

**Source accepted; no new blocker found.** Native feature acceptance now checks only finite/in-range coordinates and gesture suppression; it has no feature-kind filter. Nearby search also explicitly uses no POI category filter. Resolved item coordinates are validated, with invalid values retaining the tapped feature coordinate. Automatic names use the first nonblank item name→placemark name→address→feature title→localized fallback. Manual name still wins, including a deliberately blank draft whose Confirm stays disabled. Existing selection UUID/request identity/cancel guards and compact centered markers are retained. This accepts all *public MapKit-exposed* native kinds; it does not promise that every visible service label is represented by an interactive feature or returned by nearby search. New policy tests are read as source, not counted as executed XCTest or UI PASS.

Two actual R42 images independently viewed, with exact manifest association:

- `R42-attribution-attachments/EA58CF56-DDD8-43CD-BE5B-891947D65F4B.png`, `testNativeMapKitOnlyAttributionDiagnostic`, `WAYPOINT_NATIVE_MAPKIT_ONLY_SHANGHAI_ATTRIBUTION`: plain native Shanghai Map visibly contains the lower-right **高德地图** attribution. There is no Waypoint annotation/card/branding, demo banner, alert or private notification. Combined with the reviewed DEBUG probe source, this now supplies actual evidence that the attribution appears without app-authored map UI. Root reports this diagnostic1 PASS; it is not evidence that removing the mark would be supported.
- `R42-map-attachments/504245E4-CDFB-474D-9E29-63B24E26342B.png`, `testMapLongPlaceNamesChineseAndEnglishSubmitAndConfirmWithoutCoordinateChanges`, `WAYPOINT_zh-Hans_MAP_LONG_PLACE_NAME_KEYBOARD`: a populated multiline name draft and the Sogou keyboard are visibly present, including its orange **完成** key. Selected marker, coordinates and confirm/cancel card are visible above the keyboard. This supports a vendor-keyboard AX/query mismatch; it does not establish successful Done activation, confirmation, persistence or all other failing rename cases.

R42 overall **3 PASS/4 FAIL** remains the actual result conveyed by root. Three rename failures at `app.keyboards.exists` are being repaired in the test helper, not assumed to be product failures. The native BlueBottle case never reached an actual native-POI tap after remote results led to Hong Kong and the expected map label was unavailable; preserve its FAIL and do not conclude native gesture rejection from that run. R43 runtime, the revised public-Shanghai native identifier selection and keyboard helper are pending coordinated verification.

## R46 final arbitration source review — runtime/release still pending

Exact independently reviewed source:

- MapScreen `2c10ee6bd9f6cdd2ad933f30260fe054c8580bd15c7f3b62a215b8b9f5811a14`.
- MapTests `12f7787bca903bbe8345c5a21ddf010420a410e546c3c50bd4f047246d373f2a`.
- TaskEditor/App/en/zh hashes remain exactly `275e3cf…e0e1a` / `df3f5ff…10df` / `2be0491…026e1` / `83e6a566…93bd`, as recorded above.

**Source accepted for coordinated build; no new source blocker found.** No compile, test, device operation or product edit was performed by this reviewer. Do not approve Release from this source review.

Root reports R44 trace showed generic selection/card creation at150ms before the native callback around229ms, changing the map viewport; R45 changed only removal of the generic gesture and native3 cases passed. That single-variable probe supports the root's causal diagnosis; R45's native-only result is not an R46 full behavior PASS.

R46 generic SpatialTap captures touch-time coordinate/scale and schedules a UUID with monotonic `systemUptime` eligibility500ms later. During that wait it does not assign pendingSelection, resolvingLocation, position, marker or card content. `MapTapArbitration.consume` requires both the matching current UUID and elapsed deadline, then clears the token: replacement tokens cannot be consumed by old tasks, and one token cannot fire twice. Only successful consumption enters the normal nearby fallback and changes preview UI.

Valid native selection cancels both Task and arbitration token before beginning native selection. Saved-task preview, pan, pinch, exact long press, explicit cancel, new explicit selection and disappearance also invalidate delayed work through suppression/cancelLookup. Native acceptance retains all public kinds with coordinate validity rather than category filtering. Exact long press still bypasses nearby snapping.

Manual name getter/setter remain selection-UUID guarded; metadata merging preserves manual edits, including blank drafts that keep Confirm disabled. Native/nearby request identity and lookup UUID still reject late callbacks. Name-only editing does not change coordinate/time zone/title. Compact selected32/saved28 graphics remain centered within transparent44 frames and explicit center anchors; icon14/12 sizing, light/dark colors and native attribution are unchanged. The preview now includes a44pt identified Done button when name focus is active, avoiding dependence solely on vendor keyboard AX visibility. Readonly TaskEditor place names remain full wrapping Text.

New MapTests source meaningfully covers the observed229ms cancellation, pre500ms rejection, one-shot blank-tap fallback and replacement/movement cancellation. It is still test source, not executed-test evidence in this independent review.500ms addresses the observed timing; public MapKit does not acquire an unlimited callback latency guarantee from that constant. Native recognizer and layout behavior must be assessed on the actual R46 candidate.

Required next evidence before release approval: actual R46 logs and screenshots for native label selection/correct names and coordinates, generic blank-map fallback, exact hold plus pan/pinch, saved pins, normal/AX manual rename→Done→Confirm→saved/readonly full value. Previous R41 screenshots and R45 probe results cannot substitute for these changed R46 paths.

## R47 actual images and R48 layout-only source review

Root reports actual R47 results:18 unit PASS; strict UI8 PASS/1 FAIL. Native3 strict cases pass after the5.5s late-result observation window; rename, EN/ZH long-name persistence, pan/pinch/hold, generic blank fallback and existing-task preview pass. The remaining AX replacement failure is retained. This reviewer did not execute those tests.

Independently viewed four exact images under `R47-map-attachments/`, checked against their manifest. All are test/demo pictures, with no private notification; they are **not store screenshot selections**.

| Image | Actual visible result |
|---|---|
| `1BF8DBB6-4DA1-449A-A6B3-72C7CC0B0E1C.png` | 雅居乐国际广场,31.23616/121.47308; distinct compact selected marker, readable place/address, confirmation/cancel and tab separation. |
| `5A9FCE55-D173-4CB0-8B5C-1661B5DF778D.png` | 中财中心大厦,31.23817/121.47736; matching selected card, compact marker and intact actions. |
| `E165CC34-90D4-43C5-A368-A73B8C2079C1.png` | 人民公园,31.23213/121.47312; matching park card, marker and intact actions. |
| `1507BF70-6AFA-467C-8713-2D1808CEDC6F.png` | English AXXXL selected-place card nearly fills the map; Cancel selection visually truncates, and the locate icon overlaps the name field's right edge. This is actual layout evidence, not a missing keyboard/query assumption. |

Native selection proof is accepted within the three tested targets. In the AX failure, `A07AAC76-919B-40DC-B7A9-8B1EF0080047.txt` gives `map.surface={{0,292.3},{440,26.3}}`, confirming the main remaining P1: insufficient usable map area for replacing a selection. Locate button frame376/502.7/48/48 intersects the name field38/535.3/364/64. These details should also be checked in the corrected candidate; they do not make R47 a full PASS.

**R48 source reviewed, not runtime-approved:** MapScreen SHA256 `2a586d62c15168e86231de95564141ff6141ebff42121dfd5203a77618aed4c0`. Changes are presentation-only: AX heading becomes dynamic caption/semibold; duplicate visible Place name caption is removed while the TextField accessibility label remains; AX coordinates use a3-decimal caption2 visual summary while the exact5-decimal accessibility label and normal5-decimal presentation remain. Full-size dynamic name editing, multiline field,44pt Done/actions, selection IDs, callback guards and500ms arbitration remain.

No new source blocker found in this layout adjustment. Smaller secondary labels should recover map space, but **do not close the26.3pt failure until the new AX screenshot/hierarchy and actual replacement test pass**. Check locator clearance and Cancel label readability in that same frame. R47 unaffected logic results can remain scoped evidence; changed R48 layout needs its own results. No product source edit, build or device action was performed by this reviewer.

## R49 frozen source: locator relocation accepted, actual candidate pending

Root reports R48 affected5 tests PASS and map height92.7pt, but the locator overlap remained visually confirmed; R48 was therefore not approved as a complete release candidate.

R49 exact independently checked MapScreen SHA256 `5ad0e58299e63a1602b5efb06f054113478ea0b31d8cfc3ea6a224ca79a2af10`; UI test source `dccc2edd96234dd11fe4c2ad4a891ed528a6d4913b52346e8ca7d5ad3f624152`.

**No source blocker found.** The geometry-level trailing locator overlay is removed. The existing location-service Button is now in the search HStack, with fixed18pt glyph, transparent44×44 contentShape and explicit Button accessibility label/ID `location.fill`. This structurally separates it from the bottom selection card. Cancel uses the existing short localized `取消` / `Cancel`, keeping the same action and ID. Existing compact markers/name controls and R48 presentation remain.

The UI test helper executes in normal/AX selection replacement before and after the replacement; it checks locator enabled/hittable,44pt minimum frame, full window containment, and no frame intersection with name/Confirm/Cancel, while retaining hierarchy evidence. These are test source assertions, not executed R49 results in this review.

Await actual full9 UI/18 unit results and new screenshots before closing the visual defect or approving release. A genuine no-demo readonly gallery is acceptable when sandbox access has expired; choose5 actual updated store images and omit the old editable Editor hero rather than imply unavailable permissions or use a test bypass. No source edit/build/device action by this reviewer.
