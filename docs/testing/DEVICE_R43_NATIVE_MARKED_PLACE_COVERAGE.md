# R43 native marked-place coverage

## Final R43 source revision after R42 evidence

The preparation below is superseded by actual R42 evidence. R42's seven focused cases finished 3 PASS / 4 FAIL: the three rename/name cases stopped only at the helper's false standard-Keyboard existence assumption. The actual screenshot showed the user's Sogou keyboard with 完成. The helper now uses an actual hittable app Done/完成 button when exposed, otherwise field Return. It retains exact full text, no added newline, usable Cancel/valid Confirm (or disabled blank Confirm), all coordinate and persistence assertions, and full AX plus screenshot before and after. It does not change the user's keyboard or claim dismissal from standard-Keyboard absence.

R42's Blue Bottle SF request yielded Hong Kong map features. That failure remains historical evidence and is not converted into a SF pass. The next source instead exercises three public Shanghai labels actually present in `R42-attribution-attachments/FBFEF706-9E82-4980-A3B4-D94908A5E4DC.txt`: 雅居乐国际广场, 商店; 中财中心大厦; 人民公园. Each requires a real matching search result and Shanghai coordinates, cancels the preview, then taps a real hittable `VKPointFeature` with the expected label. This is an accessibility locator observed in the real runtime, not a private API or fake registry. After the native tap, the selected name, Shanghai coordinates, confirmation and editor coordinates remain strict. Wrong city, missing native feature or wrong selection is FAIL; the new category cases no longer skip unavailable results.

Final identifiers:

- `WaypointUITests.testLiveNativeShanghaiCommercialPlazaMarkedPlaceSelection`
- `WaypointUITests.testLiveNativeShanghaiPublicParkMarkedPlaceSelection`
- `WaypointUITests.testLiveNativeShanghaiPublicOfficeLandmarkSelection`

Final source SHA-256: `02621319bd557bb86f587c7e85da795c38f9e333b5305b5b79e9fc183a9214b3`. Parse and diff check exit 0; no build or device run performed by this agent. At least two different native scenarios still need actual PASS. Residential complex and charging station automation remains NOT_RUN, and no assertion of all MapKit registry types is made.

## Earlier preparation (superseded, retained for provenance)

Status: test source prepared and parsed; no R43 build or device execution performed by this agent.

The existing strict Blue Bottle Coffee Ferry Building case remains unchanged. Two independent scenarios are added for Union Square, San Francisco (public square) and Salesforce Tower, San Francisco (public office landmark). These are public place-name scenarios, not assertions about an undocumented MapKit registry category. Each uses real search only to move the map to the landmark, cancels that search preview, and then requires an actual hittable native accessibility feature inside `map.surface`. No guessed coordinate, custom pin, search result, private residence, or typed fake registry replaces the native feature.

Each new case retains the full pre-tap accessibility hierarchy and screenshot. No live matching result or native accessibility feature yields an explicit coverage-unavailable skip. That skip does not satisfy the minimum of two automated native categories. Once a native feature is present and tapped, missing selection, wrong name, disabled/unreachable confirmation, or coordinate mismatch is a failure. The existing Blue Bottle case continues to fail when its expected native feature is unavailable.

Release coverage must report actual per-case results. At least two different native place scenarios must pass before claiming the minimum automated coverage. Even those passes do not prove every MapKit feature kind. Public residential-complex and charging-station native taps remain NOT_RUN until real visible labels can be exercised; search acceptance alone is insufficient. The new broad feature-kind policy must also have separate logic evidence, supplied by the map owner/root. The pure MapKit Shanghai attribution diagnostic is already a separate R42 visual check and is not duplicated here.

Prepared identifiers:

- `WaypointUITests.testLiveNativePublicSquareMarkedPlaceSelection`
- `WaypointUITests.testLiveNativePublicOfficeLandmarkSelection`

UITest source SHA-256: `6cd3cd58c323140889bf3bf8543f47e467875be0af32530888ac58bfb6c68008`.

Verification: `swiftc -frontend -parse` and `git diff --check` exit 0. This confirms syntax/patch hygiene only; SDK type checking and real native feature availability remain pending the root-run candidate.
