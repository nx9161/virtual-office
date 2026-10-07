# AI Red Team — Weather App Abuse-Case Review (War Room Phase 3)

**Reviewer:** AI Red Teamer (Security & Compliance) · **Date:** 2026-10-06
**Scope:** Client-only Flutter app, Open-Meteo keyless HTTPS APIs, no prompt-injection surface.
**Inputs:** ARCHITECTURE.md v1.0 (+ §14 Sloane's Phase 2 rulings R-1…R-18), PRD.md v1.0, design-spec.md v1.0.

**Verdict: CONDITIONAL CLEAR — not a block.** No finding reaches High/Critical. One Medium and several Low/Info findings below; the Medium (AC-4b) has a cheap, concrete fix that becomes a **mandatory clearing condition**. If AC-4b is not implemented pre-release, this review re-escalates to **BLOCK**.

**Severity scale:** Critical / High / **Medium** / Low / Info. "Exploitability" assumes the cheapest realistic attacker (modified APK or hostile Wi-Fi), not nation-state.

---

## AC-1 — Mock / spoofed location (Android mock-location apps, iOS simulator)

**Verdict: NON-ISSUE (Info). No detection required.**

- geolocator's `Position` exposes mock status (Android `isMocked`), but there is **nothing worth gating**: no pricing, no region-locked content, no server-side trust decision, no fraud-adjacent action depends on location. A spoofer gets weather for a place they aren't — self-inflicted, user-visible, zero blast radius beyond their own screen.
- Cost bearer: none. Open-Meteo serves any coords; a fake fix costs one ordinary request.
- Spoofing cannot reach the consent sheet's promises: the OS permission dialog still gates a *real* fix; `isMocked` detection would add code for zero adversarial gain, and could annoy legitimate emulator/QA use.
- **Recommendation:** explicitly decline `isMock` detection; document the rationale in an ADR note so a future auditor doesn't "rediscover" it.

## AC-2 — API hammering with a modified client

**Verdict: LOW. Accepted residual — nothing client-side can bind a modified client.**

- The URL pattern is trivially extractable (binary strings, proxy logs); the API is keyless. Client-side guards (300 ms debounce, 5 s dedupe window, §8.3 retry budget) are **courtesy, not enforcement** — a patched APK ignores all of them.
- **Who bears the cost:** Open-Meteo (their fair-use enforcement, per-IP throttling). There is no API key to steal and no billing account to blow up — the "no secrets anywhere" posture is the strongest possible defense here. The app's own abuse cannot cost the business money.
- **Residual risk to us:** CGNAT/mobile-carrier NAT. A hostile actor behind the same egress IP as legitimate users could trigger IP-level 429s that also throttle our users. We cannot attribute, prevent, or detect this client-side; Open-Meteo's enforcement is opaque to us.
- **Already-mitigating:** 429 → `AppFailure.rateLimited` mapped immediately (R-12), countdown + single scheduled retry at the controller (no held-open Dio calls), 5xx exponential backoff 1 s→2 s, no retry on validation failures.
- **Required mitigations (clearing):**
  1. Telemetry on repeated 429s (Sentry breadcrumb + counter) so systemic throttling is *visible*; a silent user base behind a throttled NAT IP is the failure mode, not the throttle itself.
  2. Ensure the controller's single scheduled 429 retry is cancelled on dispose/navigation (R-12 says "single" — assert no stacked retries across screens for the same host).
  3. Document in the privacy/ops notes: "Open-Meteo fair-use is enforced by the provider; client rate limits are best-effort."

## AC-3 — Injection via city search input

**Verdict: LOW. No interpreting sink exists; one hygiene gap.**

Attack strings (`<script>`, SQL fragments, `%s`/`{}` format tokens, U+202E RTL overrides, 10k-char paste) land in four places:

| Sink | Interprets input? | Assessment |
|---|---|---|
| URL query (`?name=`) — percent-encoded by Dio | No | Safe. 100-char cap enforced before send (spec). |
| Release logs/Sentry | No | Safe by construction: R-2 scrubs query strings entirely; debug builds log host+status only. |
| Hive `recent_places` box | No | Opaque strings; no eval, no SQL (Hive CE ≠ SQLite). |
| UI text + accessibility labels (incl. FM-12 echo "No places found for '<query>'") | No | Flutter `Text` auto-escapes — no HTML/WebView sink. Dart has no printf-style format-string sink. |

- **Real gap (hygiene, not vuln):** control characters (`\n`, `\r`, `\u202E`, `\u0000`) in the query or in *server-supplied* place names (`name` 1…200 chars per PRD §7.3) can inject fake log lines into debug logs and visually scramble UI rows. Logs are local-only in v1, but cheap to fix.
- **Required mitigations (clearing):**
  1. Strip control characters (`\u0000–\u001F`, `\u007F`, plus lone surrogates) at the **string-ingestion boundary** — one function applied to the search query *and* all API string fields (`name`, `country`, `admin1`, `timezone`) before logging/UI/persistence.
  2. Enforce the 100-char cap in two layers: `TextField(maxLength: 100)` **and** the validation layer (never trust the widget).
  3. FM-12 UI echo must follow the PRD rule, not the design-spec shorthand: **≤50 chars, escaped** (design-spec §3.2's raw `{query}` echo is overridden by PRD FM-12).
- RTL override in *legitimate* city names (Arabic/Hebrew scripts) must **not** be stripped — cosmetic only, and stripping breaks real i18n. Strip control chars, keep bidi.

## AC-4 — Malicious API responses (MITM; R-6 accepted no pinning)

**Verdict: MEDIUM (one concrete gap) + LOW (accepted residual).**

### AC-4a — Schema-valid but *wrong* data
- R-1's two-tier validation is strong against malformed/out-of-range data, but **cannot detect plausible lies**: e.g. `temperature_2m: 59.9` in-range but false, or a `current.time` claiming fresh data for a stale model run. Fail-closed validation is orthogonal to data *truth*.
- Impact: user dresses wrong, plans badly — nuisance-class, no high-value decision in this app depends on it. Requires targeted MITM (public Wi-Fi attacker). HTTPS defeats the passive observer; the trust anchor is Open-Meteo itself.
- **Accepted residual (Low).** Note: the "Updated Xm ago" label derives from *fetch* time, so provenance labeling stays honest even when content lies — the design-spec honesty principle partially holds. No mitigation available client-side short of a second data source (out of scope, rejected: adds a new trust anchor and privacy surface for zero user story).

### AC-4b — Maximally-sized payloads / array bombs (THE finding)
- PRD §7.2 caps hourly arrays at 48 and daily at 7 **by truncation — which happens after `jsonDecode` parses the entire body** (`responseType: json`). A hostile MITM (or a compromised CDN edge) can serve 100k-entry hourly arrays: several MB of JSON fully materialized into Dart objects *before* any length check runs. Consequences: multi-MB transient allocation, main-isolate `jsonDecode` blocking → jank/ANR, and on low-end devices a plausible OOM kill. `Content-Length` cannot be trusted (chunked, or lies).
- This is the only finding where the attacker's cost (~one crafted response) is wildly asymmetric to the victim's (app freeze/crash loop on refresh).
- **Required mitigation (clearing, pre-release):** enforce a max body size **before** decode — e.g. decode via `responseType: bytes`, reject bodies > 512 KB with `AppFailure.schemaViolation('body','oversize')` (real payloads are 15–25 KB per arch §6; 512 KB is 20× headroom), then `jsonDecode` in a `try` (and ideally off the main isolate via `compute`). 5 lines, kills the whole class.
- Secondary: assert in CI contract tests that a 100k-entry fixture is rejected at the size gate without OOM.

## AC-5 — Cache tampering on-device

**Verdict: LOW. FM-18 covers corruption; forgery is local-only.**

- Hive boxes live in app-private storage; tampering needs root/jailbreak, physical access, or a privileged backup — at which point the attacker already owns the device and can do far worse (keystroke logging, screen capture).
- FM-18 (corruption → evict + cache-miss) handles *accidental* damage. A **schema-valid forged entry** (plausible temps, attacker-controlled `fetchedAtUtc` making a lie look fresh) is indistinguishable from legitimate data — the read path cannot re-validate what was never invalid. Impact is confined to the victim's own device and that cache key.
- **Recommended (not blocking):** HMAC-SHA256 each `CacheRecord` with a key in Android Keystore / iOS Keychain (e.g. `flutter_secure_storage`). Cheap, raises the bar from "anyone with file access" to "must compromise the keystore". If declined, record the explicit rationale: physical-access attacker is outside the v1 threat model.
- Note: cache keys are fixed-format (`"lat,lon"` 2dp) — no path/key traversal. Recent-places entries with out-of-range coords are purged on load (PRD FM-18) — good.

## AC-6 — BigDataCloud fallback as exfil path

**Verdict: INFO/LOW (privacy note for Tech Law, not a vuln).**

- Fallback only: on-device `geocoding` package first; BigDataCloud `reverse-geocode-client` receives coarse 2dp coords only when platform geocoding fails. HTTPS hides coords from a passive observer (SNI/DNS reveals only *that* BigDataCloud was contacted).
- A *network observer* gains nothing they don't already get from the Open-Meteo call itself. The "third party the user didn't choose" angle is a **consent/disclosure** matter, already handled: ADR-08 requires it in the privacy notice, and Tech Law re-reviews in Phase 3.
- **Ask of Tech Law (no code change):** confirm BigDataCloud's data-retention practice for keyless reverse-geocode hits and whether 2dp coords count as personal data under the target regime. Engineering note: keep the fallback last in the chain and never promote it to primary — current design already does this.

## AC-7 — Consent-flow bypass

**Verdict: NON-ISSUE (Low stakes, by design).**

- The sanctioned "Search instead" path reaches the forecast *without* the consent sheet — that is the PRD's full-function-without-location requirement (G-3), not a bypass.
- Actual bypass requires on-device state tampering (root → flip `ConsentState` in SharedPreferences). But the **real enforcement point is the OS permission dialog**, which the app cannot skip: `geolocator` returns no fix without an OS grant. Flipping the in-app flag only changes which sheet the user saw — no server-side trust decision exists to subvert, and the attacker can only lie to their own device.
- Revocation mid-flight is handled (R-13 generation counter cancels in-flight device requests; revocation wipes in-memory coords + device-keyed cache entries).
- **Clearing test (no code change):** assert that the device-location forecast path requires an OS-granted permission, not merely `ConsentState.granted` — i.e. a test that mocks `ConsentState.granted` + `geolocator.denied` must land in `AppFailure.locationDenied`, never in a forecast call.

---

## Clearing conditions (mandatory pre-release; QA to verify)

1. **AC-4b:** Max response-body size gate (≤512 KB suggested) *before* `jsonDecode`, for both Dio instances; oversize → `schemaViolation`. Prefer bytes→length-check→decode; `jsonDecode` in try / background isolate.
2. **AC-3:** Control-char stripper at the string-ingestion boundary (query + all API string fields); 100-char cap enforced at widget **and** validation layer; FM-12 echo ≤50 chars escaped per PRD (overrides design-spec shorthand).
3. **AC-2:** 429 telemetry (breadcrumb + counter); controller-level single scheduled retry cancellable on dispose; NAT shared-IP residual documented.
4. **AC-5:** HMAC cache records with Keystore/Keychain key — or a written, dated rationale declining it (physical-access outside v1 threat model).
5. **AC-7:** Test asserting device-location forecast requires OS grant, not just `ConsentState.granted`.
6. **AC-6:** Tech Law confirms BigDataCloud disclosure/DPA in the Phase 3 privacy review (already scheduled).

**Accepted residuals (no action):** AC-1 (no mock-location detection — documented non-issue); AC-2 modified-client hammering (unenforceable client-side); AC-4a plausible-but-false MITM data (R-6 accepted); AC-6 fallback exfil (disclosed, Tech Law reviewing).

*— AI Red Teamer, Security & Compliance. Phase 3 review complete. No BLOCK issued; CONDITIONAL CLEAR with the six conditions above.*
