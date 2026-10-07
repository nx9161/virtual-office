# Weather App — AppSec Security Review (War Room Phase 3)

**Reviewer:** AppSec Lead, Security & Compliance division · **Date:** 2026-10-06
**Scope:** Design review of `apps/weather_app/docs/{ARCHITECTURE.md, PRD.md, design-spec.md}` incl. §14 (Sloane's Phase 2 rulings, binding)
**Posture:** Assume breach. Client-only Flutter app, no backend, no app secrets, keyless Open-Meteo HTTPS APIs.
**Verdict:** **⛔ BLOCK** — design may not proceed to build until the conditions in §9 are cleared. All conditions are clearable; none require re-architecture.

---

## 1. OWASP Mobile Top 10 (2024) — verdicts

| # | Control | Applies? | Verdict |
|---|---|---|---|
| M1 | Improper Credential Usage | Partial | ✅ **Pass.** No credentials exist by construction (ADR-01). Only sanctioned secrets are release-pipeline items in the platform secret store (R-18). CI secret-scan gate required (DoD#9). |
| M2 | Inadequate Supply Chain Security | Yes | ⚠️ **Conditional.** `pubspec.lock`+`Podfile.lock` committed, `--enforce-lockfile` in CI, `--obfuscate` release builds (R-16) are good. Residual: `hive_ce` is a community fork (maintainer-abandonment risk), codegen deps (`riverpod_generator`, `build_runner`) widen the supply chain. Mitigations in §2. |
| M3 | Insecure Authentication/Authorization | No | ✅ **N/A.** No accounts, no auth, no privileged operations. Nothing to bypass. |
| M4 | Insufficient Input/Output Validation | Yes | ⚠️ **Conditional.** The §7 two-tier pipeline (R-1) is the strongest part of this design. Residual fail-open holes and type-confusion rules in §3 must be closed. |
| M5 | Insecure Communication | Yes | ✅ **Pass (R-6 confirmed, §5).** HTTPS-only, cleartext blocked (ATS / network security config). No pinning for v1 — concur, with revisit triggers. |
| M6 | Inadequate Privacy Controls | Yes | ⛔ **Block.** This is the flagship risk for this app. Consent-before-OS-prompt, 2-dp rounding, memory-only coords, on-device reverse-geocode primary are all correct — but **§4 documents residual coordinate leaks into logs/Sentry and a direct contradiction between PRD §9.3 ("zero coordinate values in persistent storage") and the cache-key design.** |
| M7 | Insufficient Binary Protections | Partial | ✅ **Acceptable residual.** `--obfuscate` + `--split-debug-info` (R-16). No root/jailbreak detection, no tamper detection specified — proportionate for a no-auth, no-secrets weather app; document as accepted residual. |
| M8 | Security Misconfiguration | Yes | ⚠️ **Conditional.** Flavors (`dev`/`prod` Sentry DSNs), crash-only Sentry, sanitized release logging are specified. Gaps: backup exclusions, Sentry envelope purge on opt-out, stale "40-char truncation" text contradicting R-2 — see §6. |
| M9 | Insecure Data Storage | Yes | ⛔ **Block.** Hive cache key **is** a coordinate pair; payload echoes lat/lon; no backup exclusions specified. See §6. SharedPreferences contents (consent, place name, unit prefs) are not sensitive — fine unencrypted. |
| M10 | Insufficient Cryptography | No | ✅ **N/A.** No crypto used, none needed — provided §6 mitigations (hashed keys / backup exclusion) are adopted instead of at-rest encryption. |

---

## 2. Findings

### 🔴 HIGH-1 — Cache key stores coordinates; contradicts PRD §9.3 and DoD#5
**Where:** ARCHITECTURE §6 — cache key `"${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}"`; PRD §9.3 "Zero coordinate values in persistent storage (automated test)"; DoD#5 requires an automated test asserting exactly that.
A 2-dp coordinate pair **is** a coordinate value in persistent storage. When the entry is device-location-sourced, the Hive box holds the user's coarse location history (~1.1 km, up to 20 entries, 24 h). Either the design or the PRD guarantee is wrong, and the DoD#5 test cannot pass as specified today.
**Mitigation (required):** Hash the cache key before persistence — `key = SHA-256("forecast:{lat_2dp}:{lon_2dp}")` hex, computed once at the repository boundary. Additionally strip the `latitude`/`longitude` echo fields from the stored `payloadJson` (they are redundant with the key). For R-13 revocation: keep the small in-memory list of device-sourced key hashes so revocation can delete them without the raw coords. Amend DoD#5: the automated test asserts *no plaintext coordinate values* in Hive/prefs (hashed keys permitted). Tech Law to confirm the hashed-key carve-out in the privacy notice.
**Also note:** `AppFailure.cacheCorrupted(key)` carries the raw key into logs/Sentry — log the key **hash** (or box name only), never the key. This is an R-2 violation as written.

### 🔴 HIGH-2 — Sentry/log exfiltration path for coordinates is unspecified
**Where:** ARCHITECTURE §3.2, §12; R-2; ADR-10.
R-2 mandates zero coordinates in logs/Sentry, but the design never specifies the enforcement mechanism, and two concrete leak paths exist:
1. **`DioException.requestOptions.uri`** contains the full query string (`latitude=…&longitude=…`). If a raw `DioException` is ever captured by Sentry (including via Sentry's own HTTP breadcrumb integration or a stray `captureException`), coordinates leave the device. The same applies to the BigDataCloud fallback request URI.
2. **Sentry breadcrumbs / `beforeSend`**: no scrubbing function is specified. Field-name-only breadcrumbs (FM-8) are fine, but nothing stops a future breadcrumb from embedding a URI.
**Mitigation (required):**
- Never call `Sentry.captureException` with a raw `DioException` — always map through `error_mapper.dart` to `AppFailure` first (already the design intent; make it a code-review gate).
- Implement `beforeSend` with a scrubber that redacts, in every string field of the event (exception values, breadcrumb messages/data, request URL): query strings in full (R-2 removed the 40-char truncation — redact the **entire** query string), plus regexes for `latitude=`, `longitude=`, `lat=`, `lon=` and bare `dd.dddd,dd.dddd` coordinate patterns in URLs.
- `SanitizedLoggingInterceptor` in release: log method + host + status + latency only — **no URI at all** (the §3.2 "truncated to 40 chars" text is stale post-R-2; fix the doc).
- Unit test: feed a synthetic event containing `?latitude=52.52&longitude=13.41` through `beforeSend`; assert zero coordinate substrings in the output.

### 🟠 MEDIUM-1 — BigDataCloud fallback response has no validation whitelist
**Where:** ADR-08; ARCHITECTURE §4.3, §7 tables.
The §7 whitelist tables cover Open-Meteo forecast + geocoding responses, but the BigDataCloud `reverse-geocode-client` fallback response is never specified. Its `city`/`locality` strings flow into the persisted place name and the home header. A malicious or malformed response could inject over-long or hostile strings into storage and UI.
**Mitigation (required):** Add a whitelist row set for the fallback: `city`/`locality` String, 1…100 chars (align with PRD geocoding `name` 1…200 — pick one, PRD wins per Sloane's rule → use PRD's bounds); `countryCode` exactly 2 chars optional; reject-and-fall-through to the "Current location" label on violation. Never persist the raw fallback payload. Note the existing inconsistency while here: PRD §7.3 allows `name` 1…200 chars, ARCHITECTURE §3.3 table says 1…100 — R-3 says numbers align to PRD; fix the architecture table to 200.

### 🟠 MEDIUM-2 — "Unknown keys ignored" (R-1) makes the CI contract test the sole drift detector
**Where:** R-1 (rewrites ADR-05); ARCHITECTURE §12 "Testing".
Ignoring unknown keys is the right call for robustness, but it removes the production schema-drift tripwire the old whitelist-rejection provided. Drift detection now depends entirely on (a) CI contract tests against recorded fixtures and (b) FM-8 breadcrumbs nobody may read.
**Mitigation (required):** Contract test fixtures must be **regenerated from the live API on a schedule** (e.g., weekly CI job) and diffed — a fixture frozen in 2026 will never catch 2027 drift. The regeneration job validates the fresh fixture against the whitelist first (so a poisoned fixture can't weaken the test), then commits it. Additionally, aggregate the FM-8 breadcrumb in Sentry (issue grouping on field name) so novel unknown keys page as a Sentry issue, not a dead breadcrumb.

### 🟠 MEDIUM-3 — Backup / at-rest exposure unspecified
**Where:** ARCHITECTURE §6, §12; ADR-13.
Hive boxes (`forecast_cache`, `recent_places`) and SharedPreferences are captured by Android Auto Backup and iCloud backup by default. Contents after HIGH-1 mitigation: hashed keys, public weather data, user-typed city names + their public coordinates (recent_places), consent state, unit prefs. Not catastrophic, but it is location-adjacent history leaving the device in backups, and it contradicts the "memory-only / nothing persisted" spirit of the privacy posture.
**Mitigation (required):** Android: `data_extraction_rules.xml` excluding the Hive boxes (`forecast_cache*`, `recent_places*`) from cloud backup; keep SharedPreferences (non-sensitive) backed up or exclude — decide and document. iOS: set `NSURLIsExcludedFromBackupKey` on the Hive box directory (cache is ephemeral by definition). Document the decision in ARCHITECTURE §12. At-rest encryption (Hive AES + Keystore/Keychain key) is **not** required after these mitigations — record that as a conscious decision, not an omission.

### 🟠 MEDIUM-4 — Dart JSON type-confusion rules are not pinned down
**Where:** R-1 two-tier pipeline; §7 tables (`is_day` ∈ {0,1}, `results[].id` integer ≥ 0, `utc_offset_seconds` integer).
`jsonDecode` yields `int` for `0` but `double` for `0.0`; a naive `value is int` check rejects a semantically-valid `0.0`, while `as int` throws. The tables say "integer" without defining the coercion rule — each hand-written DTO will invent its own.
**Mitigation (required):** Define canonical helpers in `validation/validators.dart` and mandate their use:
- `int? asInt(num v)` — accepts `int`, or `double` where `v == v.truncateToDouble()` (so `0.0`→`0`, `1e2`→`100`); else null → Tier 2 violation. Document that `1.5` for `is_day` is a violation, not a truncation.
- `double asDouble(num v)` — `v.toDouble()`; reject non-`num` before this point (Tier 2).
- Rule: **never `as`/`!` on network data** (already DoD#2 — extend the static review to ban `as int`/`as double` on `dynamic` from JSON; `custom_lint` rule if feasible).
- Unit tests per helper: `0`, `0.0`, `1`, `1.0`, `1.5`, `1e2`, `"1"`, `true`, `null`, `NaN` (JSON can't carry NaN — but a hostile body can carry the *string* "NaN"; ensure the decoder path never `double.parse`s it).
- Empty-array edge (fail-open hole): after truncation-to-shortest, **any Tier-1-relevant array with length 0 → `schemaViolation`** (unusable section). Truncation must produce equal-length lists *before* DTO construction — no `list[i]` on un-equalized arrays (RangeError → FM-20 crash path). Cross-field: `max ≥ min` else Tier 2 → entry-level "—" (PRD's swap-and-flag is struck by R-1's "field becomes null"; record the change).

### 🟡 LOW-1 — `outOfRange.value` must never carry coordinate echoes
The `AppFailure.outOfRange(field, value)` variant carries a `num value`. Route **all** latitude/longitude echo validation failures to `schemaViolation(field, reason)` (Tier 1 — they attest response identity, not weather data), never to `outOfRange`. The echo fields are not rendered, so Tier 1 fail-closed costs nothing in UX. (Consistent with the §3.3 table's existing `→ schemaViolation` for echo fields — keep it under R-1.)

### 🟡 LOW-2 — Rate-limit citizenship gaps
Client-side guards (300 ms debounce, 60 s per-query geocoding cache, 5 s in-flight dedupe, 10 min forecast TTL, retry budget 2, R-12 single scheduled retry on 429) are sufficient for PRD G-4. Two gaps:
1. **No `User-Agent` header.** Open-Meteo's fair-use policy asks clients to identify themselves; without it our traffic is indistinguishable from abuse, and per-IP 429s can't be attributed. **Required:** set `User-Agent: weather-app/<version> (<contact>)` on both Dio instances.
2. **Retry budget on the R-12 path.** R-12 moves the 429 retry to a controller-scheduled single retry — confirm the PRD §8.3 "max 2 retries" budget is enforced *across* the interceptor + scheduled-retry path (a 429 → scheduled retry → 429 → scheduled retry loop would violate it). Add jitter (±250 ms) to the 1 s→2 s backoff to avoid thundering-herd sync.
On "what stops a modified client from hammering": nothing on-device can — and nothing needs to. The API is keyless with per-IP fair use; Open-Meteo's 429 is the enforcement point, and a modified client burns its own IP. Our obligation is that *our* client is a good citizen (covered above) and that a server-side ban of an abusive IP cannot cascade to innocent users — it can't, limits are per-IP. Record this reasoning; no further action.

### 🟡 LOW-3 — Sentry opt-out must purge the on-disk envelope cache
R-17: opt-out "disables the already-initialized client." `sentry_flutter` persists envelopes to disk and retries them later — disabling the client does not delete already-queued envelopes, which may contain breadcrumbs from before opt-out. **Required:** on opt-out, call `Sentry.close()` **and** delete the Sentry cache directory (`SentryFlutter` cache). Test it.

### 🟡 LOW-4 — Doc hygiene (fix before build; not blocking alone)
- ARCHITECTURE §3.2 "query strings truncated to 40 chars" contradicts R-2 (truncation removed) — rewrite to full query redaction.
- §3.3 table still shows the pre-R-1 "unknown key → violation / no partial entity" language in places — reconcile fully with R-1 two-tier.
- Design spec §5.1a / §5.4 / §3.5 still say "~10 km" — R-4 corrected to "~1 km (rounded coordinates)"; the consent sheet, Settings precision row, and privacy notice must ship the corrected copy.
- `geocoding` response `name` length: align architecture table to PRD's 1…200 (R-3: PRD wins).

### 🟢 Accepted residuals (documented, no action)
- **R-6 no cert pinning — CONFIRMED.** Concur: no published pinset; pinning an undocumented cert risks brick-on-rotation; payload is unauthenticated public weather data; fail-closed validation neutralizes a MITM's ability to inject *accepted* malicious data (worst case: plausible-but-wrong in-range values — low impact, and severe-weather alerts are explicitly out of scope in PRD §3, which is the one feature that would change this calculus). **Revisit triggers (record in ADR):** (a) Open-Meteo publishes a pinset; (b) API becomes keyed/authenticated; (c) safety-critical features (alerts) enter scope. Ensure cleartext remains blocked (ATS / `usesCleartextTraffic=false`) — already specified.
- **M7:** no root/jailbreak or tamper detection — proportionate, no secrets/auth to protect.
- **M2 residual:** `hive_ce` community-fork risk — mitigate with version pinning + Dependabot/Renovate alerts (already planned); revisit if the fork stalls.
- Precise GPS fix exists transiently in memory before 2-dp rounding — unavoidable and acceptable (rounding at the datasource boundary, never serialized per ADR-07; `DevicePosition` has no `toJson`).

---

## 3. Zero-trust validation (R-1 two-tier) — fail-open audit

| Check | Result |
|---|---|
| Tier 1 structural → `schemaViolation`, fail closed (missing `current`, unparseable JSON, unusable hourly/daily, cross-field mismatch beyond truncation) | ✅ Correct posture |
| Tier 2 field-level → null/"—", entity still constructed | ✅ Correct; matches PRD §7.2 |
| Unknown keys ignored (not violations) | ✅ Safe (keys can't execute); drift detection moved to MEDIUM-2 mitigations |
| `current.time` unparseable → device clock fallback | ✅ Fail-safe, disclosed |
| `utc_offset_seconds` invalid → device timezone + label (FM-14) | ✅ Fail-safe, labeled |
| Unknown WMO code → "Unknown conditions", data kept (FM-10/13) | ✅ Degraded, correct |
| Array truncation to shortest | ⚠️ MEDIUM-4: pin the empty-array and equalization rules |
| `num` vs `int` vs `double` coercion | ⚠️ MEDIUM-4: canonical helpers required |
| Coordinate echo in `outOfRange.value` | ⚠️ LOW-1: route echo failures to `schemaViolation` |
| `is_day` wrong type (e.g. `true`) | → Tier 2, assume 1 per PRD — acceptable degraded default, logged |
| **Fail-open hole found:** none that render attacker-controlled data as trusted. The pipeline's residual risks are all in the MEDIUM/LOW items above (type coercion, empty arrays, drift detection), not in silent acceptance of bad data. |

**Note on an R-1/PRD tension:** PRD §7.2 says a structurally-bad `hourly`/`daily` block is dropped with a section note while the rest renders; R-1 says unusable hourly/daily → fail closed (`schemaViolation`, whole-screen error). R-1 is binding and is the safer posture — but it means one poisoned array blanks the screen. This is Sloane's call and it stands; QA's FM-diff (ARCHITECTURE §9 reconciliation note) must reflect R-1, not the PRD text.

---

## 4. Logging / PII — residual leak inventory

| Location | Leak? | Status |
|---|---|---|
| `SanitizedLoggingInterceptor` release (method/host/status/latency) | No coords | ✅ after doc fix (LOW-4: remove "40-char truncation" language) |
| Debug-verbose logging | Coords possible | ✅ acceptable — strictly `kDebugMode`/dev flavor; CI lint bans `debugPrint` with URIs; never ships |
| `DioException` URIs → Sentry | **Coords** | ⛔ HIGH-2: `beforeSend` scrubber + never capture raw |
| BigDataCloud fallback request failure | **Coords** | ⛔ HIGH-2: same scrubber covers it |
| `AppFailure.cacheCorrupted(key)` — key is coords | **Coords** | ⛔ HIGH-1: log key hash only |
| `outOfRange(field, value)` for echo fields | **Coords** | ⚠️ LOW-1: route to `schemaViolation` |
| FM-8 breadcrumb (field name + reason) | No | ✅ per R-2, sufficient diagnostics |
| `noResults(query)` — user-typed city, ≤50 chars escaped | No coords | ✅ acceptable (user-provided, truncated) |
| Home provenance strip / consent copy | No | ✅ ("precise location off", "~1 km" per R-4) |
| Sentry envelopes after opt-out | Stale breadcrumbs | ⚠️ LOW-3: purge cache on opt-out |

---

## 5. R-6 (no cert pinning) — security confirmation

**Confirmed.** Reasoning: (1) Open-Meteo publishes no pinset — pinning would be pinning an undocumented leaf/SPKI with brick-on-rotation risk exceeding the MITM risk for this data class; (2) data is unauthenticated public weather — there is no credential or PII in transit beyond 2-dp-rounded coordinates already disclosed to the API by design; (3) fail-closed §7 validation means a MITM cannot get *malicious* data accepted — worst case is plausible-but-wrong in-range values (low impact) or a broken payload (clean error state, FM-3); (4) no safety-critical features (alerts are a PRD non-goal). Revisit triggers recorded in §2. No action for v1 beyond keeping cleartext blocked.

---

## 6. Local storage — sensitivity register

| Store | Contents | Sensitive? | At-rest protection needed? |
|---|---|---|---|
| Hive `forecast_cache` | `CacheRecord{key, fetchedAtUtc, source, payloadJson}` | **Yes (pre-mitigation):** key = 2-dp coords; payload echoes lat/lon | ⛔ HIGH-1: hash keys, strip echo from payload. Then: no encryption needed; backup-excluded (MEDIUM-3) |
| Hive `recent_places` (≤10) | Name, country, admin1, 2-dp coords of *searched* places | No — public place data, user-typed (US-13 AC3) | Backup-excluded anyway (ephemeral); no encryption |
| SharedPreferences | `unit_system`, `consent_state`, `place_name`, `theme_mode` | No — prefs + city name (city-name persistence is by design, ADR-07, disclosed) | None; backup OK (document choice) |
| Memory only | `DevicePosition` (2-dp, no `toJson`), in-flight coords | Yes — must never serialize | ✅ enforced by type design; test per DoD#5 |

**Backup:** Android `data_extraction_rules.xml` must exclude both Hive boxes; iOS `NSURLIsExcludedFromBackupKey` on the Hive directory (MEDIUM-3). Rationale: backups are the only path by which coarse location history leaves the device outside the disclosed API calls.

---

## 7. Third-party data exposure

| Party | Data sent | Exposure assessment |
|---|---|---|
| **Open-Meteo** (forecast + geocoding) | 2-dp rounded coords; city search strings; `User-Agent` (to be added, LOW-2) | ✅ Minimal by design. Keyless, no account linkage. No SLA — handled via FM-2/FM-6 + honest staleness. Tech Law: confirm their privacy policy reference in the notice. |
| **BigDataCloud** (reverse-geocode fallback only) | 2-dp coarse coords, only when on-device geocoding fails | ⚠️ Disclosed in privacy notice (ADR-08) — verify the notice **names** BigDataCloud (design spec §5.4 currently doesn't). Response needs whitelist validation (MEDIUM-1). Failure URIs need scrubbing (HIGH-2). |
| **Sentry** (crash-only) | Stack traces, device/OS metadata, breadcrumbs, release/dist | ⚠️ `tracesSampleRate: 0`, replay off, PII scrubbing on, opt-out with cache purge (LOW-3) — then acceptable. **Zero coordinates** enforced via HIGH-2 `beforeSend`. Data residency (US vs EU DSN) — Tech Law decision pending (R-17); AppSec notes the scrubbing requirement is region-independent. |
| On-device (`geolocator`, `geocoding` pkg) | Precise fix (transient, pre-rounding); platform reverse-geocode | ✅ No network. Fine. |

No analytics, no ads, no attribution SDKs — verified absent from the package table. Keep it that way; any addition re-opens this review.

---

## 8. CI / build gates required (DoD hardening)

1. Secret scan (DoD#9) — keep green; covers R-18 pipeline secrets accidentally committed.
2. `flutter pub get --enforce-lockfile` (R-16) + Dependabot/Renovate for `hive_ce` fork staleness (M2).
3. `custom_lint`/`import_lint` layer rules (R-9) + ban on `as`/`!` casts of JSON `dynamic` (DoD#2, MEDIUM-4).
4. Contract test with **scheduled live-fixture regeneration** (MEDIUM-2).
5. DoD#5 storage test rewritten for hashed keys (HIGH-1).
6. `beforeSend` scrubber unit test with coordinate-bearing synthetic events (HIGH-2).
7. Single release build command with `--obfuscate --split-debug-info` (R-16); Sentry symbol upload in the release step only.

---

## 9. Verdict — ⛔ BLOCK

**The design is BLOCKED from proceeding to build until:**

1. **[HIGH-1]** Cache keys are SHA-256-hashed before Hive persistence; lat/lon echo stripped from stored payload; `cacheCorrupted` logs key-hash only; DoD#5 test amended to assert no *plaintext* coordinates at rest; R-13 revocation deletes by hash. (Needs Tech Law sign-off on the hashed-key carve-out in the privacy notice.)
2. **[HIGH-2]** Sentry `beforeSend` coordinate scrubber specified + unit-tested; raw `DioException` never captured; release logging = method/host/status/latency with **no URI** (fix the stale "40-char" text); BigDataCloud failure URIs covered by the same scrubber.
3. **[MEDIUM-1]** BigDataCloud fallback response whitelist added (name 1…200 per PRD, country_code 2 chars); violations fall through to "Current location"; never persist raw fallback payload.
4. **[MEDIUM-2]** Contract-test fixture regeneration cadence (weekly CI) + FM-8 breadcrumb aggregated as a Sentry issue.
5. **[MEDIUM-3]** Android backup rules exclude Hive boxes; iOS excludes Hive dir from backup; decision documented.
6. **[MEDIUM-4]** Canonical `asInt`/`asDouble` helpers mandated for all DTOs; empty-array → `schemaViolation`; equalization-before-indexing rule; unit tests for the coercion matrix.
7. **[LOW-1/2/3]** Echo failures → `schemaViolation` (no coords in `outOfRange.value`); `User-Agent` header set; 429 retry budget enforced across the R-12 scheduled-retry path (+ jitter); Sentry disk cache purged on opt-out.

**Dependencies on sibling reviews (not mine to clear):** Tech Law — Sentry DPA + US/EU DSN (R-17), privacy-notice copy (BigDataCloud naming, "~1 km" per R-4), hashed-key carve-out; QA — FM table 1:1 diff vs PRD reflecting R-1 (not PRD §7.2's drop-section language).

**What is confirmed and needs no further debate:** R-6 (no pinning) stands with recorded revisit triggers; M1/M3/M10 are N/A-by-construction; the two-tier validation posture (R-1) is sound with the MEDIUM-4/LOW-1 closures above; client-side rate limiting is sufficient given per-IP fair use + 429 enforcement, with the LOW-2 citizenship additions.

*— AppSec Lead. The block stands until every numbered condition above is cleared; re-review on the amended design docs.*
