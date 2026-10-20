# OpenAI: ChatGPT subscription first, API Key retained

> **CANCELED BY USER — HISTORICAL ONLY (2026-10-11).** The user withdrew the ChatGPT subscription/OAuth request. This design/inquiry will not be implemented or submitted. The commercial application was never submitted; no client registration or authentication implementation occurred. The current release keeps GLM, Qwen, DeepSeek and OpenAI API Key access. Content below preserves the abandoned proposal and is not a current release gate.


Date: 2026-10-11. Design for user review. Implementation not started; provider eligibility and native callback support are not yet established. Supersedes API-key-only OpenAI design, not other providers.

## Agreed product intent

The user explicitly requests that OpenAI prefer ChatGPT subscription use, recommend that route in the app, and retain API Key access when necessary. GLM, Qwen and DeepSeek keep their current key flows. Gemini remains unavailable. Waypoint remains a paid native iOS app intended for App Store distribution, with its own USD 9.99 annual subscription and eligible seven-day trial.

## Proposed experience

- Under OpenAI, present “ChatGPT subscription · Recommended” and “API Key · Separate API billing”. A connection is established through OpenAI's own authorization page; the app never asks for a ChatGPT password or copies the desktop Codex session.
- Once connected and authorized, prefer the subscription connection and show the selected account and its returned model catalog. Provide reconnect, disconnect and usage-management actions only with documented destinations.
- Preserve existing API credentials. Existing API users keep a working explicit selection until they connect or choose subscription mode. New users see the subscription recommendation first. A recommendation is not a claim that the account or this commercial app is eligible.
- Subscription expiry, denial, revocation, exhausted limits or unavailable service do not automatically trigger API billing. Offer a deliberate “Use API Key instead” choice, explain separate provider charges, and show the chosen mode again in the existing pre-send consent screen.
- Keep Waypoint's subscription, ChatGPT's plan and API billing clearly distinct. Local planning continues to need no AI account.
- Do not ship a nonfunctional login button. Commercial eligibility and a verified native callback are release gates for enabling this route; no approved client identifier or redirect URI will be invented.

## Architecture

1. `OpenAIAuthMode` separates ChatGPT-plan and API-key credentials, model selection, cached catalogs and request snapshots. Provider enum compatibility is preserved.
2. A dedicated OAuth session store owns authorization state, nonce, PKCE S256, the issued client ID, validated identity, granted scopes and rotating tokens. Credentials use device-only Keychain storage. Secrets and callback codes never enter logs, defaults, source, exports, screenshots or telemetry.
3. Validate state, exact callback, issuer, JWKS signature, audience, expiry and nonce before accepting a session. Require the granted ChatGPT-plan scope; a successful identity login alone is insufficient. A canceled/failed new login cannot replace an existing valid account.
4. Serialize refresh operations per connection; atomically replace access token, refresh token, expiry and scopes. Disconnect cancels in-flight operations and clears only the selected connection. Account/mode changes invalidate model refreshes and pending generation results.
5. Keep the existing OpenAI API-key route. Add a distinct subscription transport using the public `https://api.openai.com/v1` endpoints and the authorized OAuth bearer token. Never use ChatGPT backend-api routes or a borrowed Codex client ID.
6. Subscription models come from `models[]`, retaining server order, `slug`, `display_name` and `visibility == list`. API-key models continue to use `data[].id`. Do not combine catalogs or reuse a model selected under another identity/mode without validation.
7. Subscription Responses requests require an input array, `store:false` and `stream:true`; omit unsupported fields, including `max_output_tokens`. Parse bounded SSE events and require `response.completed`; failed, incomplete and interrupted streams never become successful plans. Bound input tasks, response bytes, time and cancellation; a byte/time bound is not a token-cost cap.
8. Reuse temporary task identifiers, strict JSON validation, fixed-appointment constraints, global collision checks and local route/weather validation before any plan can be applied.

## External gates

The official overview directs paid or remotely hosted applications to the commercial interest form. Waypoint is a paid commercial distribution even though tasks are stored locally. The published open-source registration flow requires an HTTP loopback callback on `127.0.0.1`; only its port may vary on later sign-ins. These documents do not establish a commercial native iOS callback contract. An iOS custom scheme or Universal Link cannot simply be substituted.

Prepare a commercial inquiry using the attached draft. Obtain OpenAI's approval and supported native-client registration/callback requirements before enabling production login. A development proof using a loopback listener, if permitted, must not be presented as commercial approval.

## Migration, privacy and store material

- Do not delete or transmit an existing API Key during migration. Keep API support available and clearly labeled.
- Review the additional account identity data and actual OpenAI plan policies before updating the now-published privacy label and website. Existing API privacy answers do not automatically cover new OAuth handling.
- Update English and Simplified Chinese strings, accessibility labels, provider consent, store descriptions, reviewer notes and the public support page after functionality and eligibility are established. Do not publish subscription-support claims in advance.

## Verification

- Unit: PKCE/state/nonce; expired or wrong-audience identity; denied/missing scopes; rotating refresh concurrency; canceled/superseded login; separate account/mode catalogs and credentials; no automatic paid fallback; existing API migration.
- Transport: fragmented SSE, multiline events, byte/time limits, interrupted stream, incomplete/failed terminal event, quota failure after output, only completed output accepted, secret-safe errors.
- UI: recommendation, three other providers unchanged, API entry retained, connect/cancel/disconnect, wrong-account protection, manual fallback disclosure, dynamic text, English/Chinese and light/dark appearance.
- Device: genuine authorized account login, account-specific models and synthetic planning response on supported iOS callback; existing API and non-OpenAI regression. Mock tests do not establish provider approval or real subscription entitlement.
- Resource: one guarded build/test at a time, internal Swift `-j1`, early stop at 75% estimated system memory, no parallel simulator job. Preserve historical results as evidence of their actual candidates.

## Official sources reviewed

- https://developers.openai.com/siwc/quickstart
- https://developers.openai.com/siwc/token-sharing-open-source
- https://developers.openai.com/siwc/token-sharing-open-source/sign-in
- https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference
- https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations
- https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions
- https://openai.com/form/sign-in-with-chatgpt-interest/
