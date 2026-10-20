# R49 / R50 independent UI release review

Reviewed 2026-10-12. **ACCEPT within the reviewed UI and screenshot scope.** All ten selected R49 store PNGs were individually viewed. R50 actual normal/AX replacement evidence was then independently viewed and its passed result read. No new product UI release blocker was found. The earlier condition requiring R50 actual geometry PASS is satisfied; this is not a claim that every app feature or subscription lifecycle was tested.

## Candidate and source boundary

Product source remains the R49 freeze; R50 changes only the test's 44 pt width/height comparison by a 0.000001 pt rounding tolerance. Enabled/hittable, within-window, and no-intersection assertions remain. No app source, image, build, simulator or device operation was performed in this review.

Verified current SHA256:

| File | SHA256 |
| --- | --- |
| MapScreen.swift | `5ad0e58299e63a1602b5efb06f054113478ea0b31d8cfc3ea6a224ca79a2af10` |
| TaskEditorView.swift | `275e3cf27000a59efde1d51c3d7faa5cbddc9a5c22a344883a153ba38afe0e1a` |
| MapToDoApp.swift | `df3f5ff233ceae14ae27e36d7b2020784a4f6f2d7c785abdbca09dff6bfe10df` |
| en Localizable.strings | `2be0491bb4629dc31e18ba3d3e7d5a04f342c92cb77b07d88fb47e80fd4026e1` |
| zh-Hans Localizable.strings | `83e6a56655c7ef7cd478fcf0000fc656e7cee6ca70131a5b1c56a673b5e493bd` |
| R50 WaypointUITests.swift | `27aa79164e879417e3dc3196086af715563e95f034ed981a59fa8799bcb22f24` |

Earlier source review found no blocker in compact saved/selected marker rendering, centered coordinate anchor, UUID-guarded name editing, cancellation, or delayed native/generic tap arbitration. Current source hash is unchanged. Actual evidence below supplies the previously missing AX overlap closure.

## Selected store images

Source directory: `docs/testing/DEVICE_EVIDENCE/R49-gallery-retry1-attachments/`.
Destination: `docs/release/screenshots/build4/{en-US,zh-Hans}/`.
Source test: `WaypointUITests/testReleaseReadOnlyGalleryChineseAndEnglishWithoutDemoBanner()`; configuration `R49gallery`.
Source manifest SHA256: `9df84364df21463bf69f6eb7f2d2c6d77e2cfcac8aac8f0da455e4841e434726`.

All ten source/destination pairs were independently checked for identical bytes, manifest SHA256, and PNG dimensions **1320 × 2868**. They are unedited actual PNGs. The existing provenance JSON remains root-owned; its pending review field can now be updated by the release owner.

| Locale | Destination | Exact source PNG | Source = destination SHA256 |
| --- | --- | --- | --- |
| en-US | 01-map.png | `C2297173-CCCE-4156-9E93-BBA2648992DF.png` | `31be2a91dcbb151b070ceb1f20ba5fbe864a85a2dca52776e6daf595e919093e` |
| en-US | 02-today.png | `A7007706-9806-4446-98AC-0D7520659219.png` | `b35fadc546816a60fb18b0a591825d3748ae3db6b2ce606a81e0723515a48d6f` |
| en-US | 03-planning.png | `568C6A5C-D097-4787-B5A9-D0F445E69F4F.png` | `cb2f02c260c6abfc7efc39314f5bc762eba2565593d23de6a85c62189a3daf18` |
| en-US | 04-ai.png | `F1E2469D-C315-4648-B1F2-BE97F57BE2C2.png` | `ba16aaca126079ec95371a8a3352d394429a3cbc563bc2032bec8d19a8450413` |
| en-US | 05-export.png | `3471B20E-DA2E-4EF1-BE7C-5B04D019B7BD.png` | `b57bda5caa4865eaf2a27323684d9ee87e24e033e087ea99266e7a89503628be` |
| zh-Hans | 01-map.png | `5FB2A07B-E2F8-4B23-A671-73479F7B965A.png` | `efd88329670577e289540000974b4d47e0ac33ccca4f99c351705c9b7ddaacbd` |
| zh-Hans | 02-today.png | `88AEDEB8-12B6-4CE2-8374-BB1B0EC8E7A6.png` | `4135044ec728a3854929f49953fcddbe941ec2bbb18d92325272bc40c397db2f` |
| zh-Hans | 03-planning.png | `B04AB3A9-9693-4A1E-8724-9FBC8340E275.png` | `39e27f1fe67dad5d18a875823e95113c94f0f4f67c349542e3273ff692ea5dc9` |
| zh-Hans | 04-ai.png | `03E9459B-23AF-409B-B010-58BEDD204391.png` | `68dafebd40e74fce3695f74a20c469d2f5327f3b889c2093014a3f8c3adb49f8` |
| zh-Hans | 05-export.png | `3925530C-615A-4C50-8FFA-4588157417E9.png` | `0987987a239b551d8616a9997abb909f6fce426653bc2a02b2dfd0e15f46df9d` |

Each selected image passed the visible privacy/presentation review: no private notification content, real API credential, keyboard, modal alert, demo banner, or blocking layout truncation. Seeded task/location/notes content is fictional public sample data. Chinese task names on English screens are user content rather than untranslated controls. A system return-to-app breadcrumb on some Chinese images is not notification content. Native MapKit attribution is retained without additional app-authored map-provider branding.

Visible findings by pair:

- **Map:** compact markers and labels remain legible; locator is in the search header, separate from bottom task content. The map is the dominant surface.
- **Today:** heading and all displayed task cards remain readable; the full Add button is visible above the floating tab bar in both chosen images.
- **Planning:** actual service/model and actionable controls remain concise; removed explanatory paragraphs do not reappear. AI generation is disabled consistently with no selected tasks.
- **AI:** both export-yourself and own-API-key analysis paths are readable; provider/model are visible and secure entry has no key. Ordinary lower scroll content at the viewport/tab boundary does not hide the primary explanation in the selected screenshots.
- **Export:** date/format/task selection and preview are readable; no account/private credential content appears.

Settings and the older editable TaskEditor hero are deliberately excluded from this five-image set. These screenshots show the actual no-demo readonly flow and do not assert paid editing entitlement or transactional purchase verification.

## R50 actual normal and AXXXL closure

Exact directory: `docs/testing/DEVICE_EVIDENCE/R50-map-attachments/`.

Individually viewed:

| Scope | PNG | Associated hierarchy |
| --- | --- | --- |
| Normal first selection | `30C18023-83E0-49A5-B144-4EDED73EB61B.png` | `6FAAAD83-4547-4B71-B7C4-1DDF9C61A18A.txt` |
| Normal replacement | `25C21A10-B9B4-4754-BB27-A517ED38E17B.png` | `8F8002C5-1065-4913-9C4E-CF8C5AFD84F6.txt` |
| AXXXL first selection | `D3613571-816F-456C-9C67-7DA39AA5B3FE.png` | `BBBB005E-05D5-4E6C-A068-8FDB545058C5.txt` |
| AXXXL replacement | `8E46297A-B865-4FB2-9734-33AA9A910E98.png` | `178173FA-1483-42D4-AF47-46734DA256A3.txt` |
| Clean AXXXL replacement final view | `91BBEADD-DDEF-4F21-B30A-C5F8787E309E.png` | Replacement geometry above |

Normal map band is 382 pt. AXXXL map band is **154.7 pt**, up from the earlier collapsed state, and shows a distinct selected marker above the card. In the AX hierarchy, locator is `x364/y214.3/w44/h44`; location name is `x38/y534.3/w364/h64`; Cancel is `x32/y712.3/w165.7/h63.7`; Confirm is `x32/y780/w356.3/h63.3`. These controls do not intersect. AX Cancel and Confirm place display complete words on separate rows, card actions stay above the tabs, and the locator no longer covers the selection card. The clean final AX image visibly confirms this arrangement.

Two intermediate AX debug captures contain a system notification over the demo header. They are internal diagnostic evidence only, must not be embedded or uploaded as store media, and their private content is not transcribed here. They do not obscure the map/header locator/name/action geometry under review. The final AX image is clean. All R50 images are demo test evidence, not selected store screenshots.

## Actual result boundary

The following result summaries were read, not rerun by this agent:

| Summary | PASS | FAIL | SKIP |
| --- | --- | --- | --- |
| `R49-unit-retry1-summary.json` | 18 | 0 | 0 |
| `R49-map-retry1-summary.json` | 8 | 1 | 0 |
| `R49-gallery-retry1-summary.json` | 1 | 0 | 0 |
| `R50-map-summary.json` | 1 | 0 | 0 |

Final map acceptance comprises eight passing scenarios from the R49 full run plus the previously failed normal/AX replacement scenario passing in the isolated R50 rerun. It is not described as one nine-case all-green execution. R50 summary SHA256: `f5d6772b88438e0736d627baacedf83e5778f70e879e461ab51650cb590c4bf2`; R50 attachment manifest SHA256: `f1b5c44cd1727a14938766fbe7cc255e95ae7179655ac539f81d4663dd2370d9`.

**Recommendation:** accept the reviewed final R49 product/R50 test candidate and these ten exact store images for the release owner's next steps. No further UI redesign or screenshot alteration is required for this reviewed scope. Archive/IPA integrity, upload processing, review submission and commercial lifecycle checks remain the release owner's evidence, not this visual-review claim.
