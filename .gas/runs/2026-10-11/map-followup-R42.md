# R42 map follow-up — /root

User requests: investigate native Amap attribution; improve nearest shop/landmark selection, compact map markers and manual place-name editing. Existing autonomous fixes/tests/submission authority remains. Submitted build3 is waiting for review and is not the modified product. Do not withdraw it until replacement candidate is validated.

Existing native agents reused: map_tasks implements MapScreen/MapTests; ui_design independently reviews design/source/images; device_tests owns focused UITest additions; root owns TaskEditor, localization, builds/device runs, integration and distribution. No new agents, no parallel heavy operations. User revoked 80% cap; sample memory only. Current budget/cost not measurable.

Root investigation: project uses native MapKit, no Amap SDK or app-authored Amap text. Apple Developer Program License Agreement Attachment6 covers Amap services in China and prohibits removing/obscuring partners' supplied marks. Keep native attribution while simplifying app-authored navigation wording.

Chosen implementation: native MapFeature POI identification first (iOS17 public API), bounded request with generation/cancellation, generic nearby query60..300m distinct from acceptance <=200m and captured48pt. Longpress stays exact; preserve pan/pinch camera ownership. Graphic saved28pt/selected32pt inside44pt targets, no oversized coordinate offset. New-place preview permits rename; editing/late lookup must preserve manual names. TaskEditor existing manual name gets clearer multiline editable row; save trims whitespace. No AI calls or purchases.

Validation pending: policy regressions against prior source then fixed source, signed build, targeted nativePOI/fallback/exact/panpinch/replace/cancel/rename persistence UI tests, EN/ZH/light/dark visual review. Record actual outcomes and do not carry build3 evidence into modified map scope.
