# Lead Backend Engineer — Data/Network Layer Review
**War Room Phase 2 · Weather App · 2026-10-06**
**Reviewer:** Lead Backend Engineer (Architecture & Code) · **Scope:** ADR-01, §3 validation pipeline, Dio interceptors, cache tiers, `AppFailure` model
**Docs compared:** `ARCHITECTURE.md` v1.0 (Enterprise Architect) vs `PRD.md` v1.0 (Product Owner) vs `design-spec.md` v1.0

> Method: every validation rule, TTL, timeout, retry number, and failure mapping in the architecture was traced line-by-line against the PRD's §7 tables, §8 rate-limit policy, §9 privacy spec, and §11 FM table. Anything in the arch doc that cannot be traced to the PRD is flagged as such. The architect's own reconciliation note (§9: "this table reconstructs FM-1…FM-20 from the PRD's stated constraints… must be diffed 1:1") confirms this diff was still outstanding — this review performs it for the data layer.

---

## (a) What I endorse

1. **ADR-01 (client-only, no backend) — confirmed.** I challenged it against every PRD requirement and found nothing that genuinely needs a server:
   - *Key hiding:* n/a — Open-Meteo is keyless; there is no secret to proxy.
   - *Aggregation / fan-out:* the app makes exactly two GETs (forecast + geocoding); no join, no enrichment, no multi-source merge exists in the PRD.
   - *Push notifications / alerts:* explicitly out of scope (PRD §3 non-goals).
   - *Analytics / tracking:* explicitly out of scope (PRD §3); crash-only Sentry is configured client-side, no backend needed.
   - *Rate limiting:* PRD §8 enforcement is client-side budgets (debounce, dedupe, TTLs, retry cap). A BFF would not improve this — it would make it **worse**: Open-Meteo's fair-use enforcement is effectively per source IP, so a proxy would concentrate all users behind a handful of egress IPs and *increase* the probability of 429s while destroying per-device attribution. Client-direct is strictly better for quota.
   - *GDPR:* a proxy would make us a data controller/processor for location-bearing requests; direct calls keep Open-Meteo as the sole (disclosed) recipient. Data minimization favors no middleman.
   - *SLA risk* (PRD §14: no SLA on a free API) is not solvable by a proxy — FM-2/FM-6 handling is the mitigation, and it's client-side either way.
   
   **Verdict: ADR-01 stands.** Recommend strengthening its rationale with the per-IP quota-aggregation and GDPR-controller arguments above, so a future "let's add a BFF" is not relitigated.

2. **Dio over `package:http` (ADR-11)** — correct call; retry/rate-limit/sanitized-logging as interceptors keeps the policy in one testable place instead of scattered at call sites.

3. **Canonical-SI caching (ADR-04)** — one canonical representation on disk, conversion at the presentation boundary. This is the right backend-minded decision; it also makes the cache key's dropped `:units` segment (vs PRD §8.2's `forecast:{lat}:{lon}:{units}`) internally consistent.

4. **Two-tier cache shape (ADR-06)** — L1 memory + Hive CE, disk-first write-through ordering (disk write succeeds → then L1 update) is the correct order; a torn write can only leave the *old* record. TTL ladder (10 min fresh / 60 min SWR / 24 h max offline) matches the PRD.

5. **Sealed `AppFailure` union** — the right shape. Exhaustive `switch` enforcement is exactly how you get "zero generic toasts" (US-9 AC1).

6. **Search supersede machinery** — 300 ms debounce + `CancelToken` + monotonic request id (FM-12) is the correct trio; any two without the third leaves a race.

7. **Handwritten DTOs over codegen (ADR-05's mechanism, not its policy)** — rejecting `json_serializable` for the whitelist requirement is sound; generated `fromJson` cannot express reject-unknown-keys.

8. **Crash-only Sentry, no Firebase (ADR-10)** — correct privacy/size trade.

---

## (b) Challenges, ordered by severity

### 🔴 C-1 (Critical) — The §3.3 validation pipeline contradicts the PRD's §7 validation contract

This is the single largest finding. The PRD's §7 principle is explicit:

> "Unknown fields are **ignored**. Wrong-typed or out-of-range fields are **discarded at field level (render '—')**, never crash the app."

The architecture's §3.3 instead implements **entity-level fail-closed**: any unknown key, any missing key, any range violation → `schemaViolation`/`outOfRange` → the *entire payload* is rejected and **"no partial entity is ever constructed."** These two philosophies produce opposite behavior on the same inputs, and the PRD's per-field "On violation" column decides against the architect in nearly every row. Concrete contradictions:

| PRD §7.2 rule | PRD "On violation" | Arch §3.3 behavior |
|---|---|---|
| Unknown fields | **Ignored** (§7 principle) | Stage 2: unknown key → `schemaViolation` (whole payload fails) |
| `current.time` unparseable | Fall back to device clock; log warning | `schemaViolation` → whole payload fails |
| `current.is_day` ∉ {0,1} | **Assume 1**; log | `schemaViolation` → whole payload fails |
| `hourly.time[]` unparseable entries | **Drop unparseable entries** | `schemaViolation` → whole payload fails |
| Any hourly field out of range | **Entry-level "—"** | `outOfRange` → whole payload fails |
| `daily.temperature_2m_max < min` | **Swap-and-flag** | `schemaViolation` → whole payload fails |
| `daily.sunrise/sunset` unparseable | **Omit if invalid** | `schemaViolation` → whole payload fails |
| `utc_offset_seconds` invalid | **Fall back to device tz + label** (PRD FM-14) | `schemaViolation` → whole payload fails |
| `hourly.*` length mismatch | **Truncate all to shortest; cap 48** (FM-17: render available + "Some hours unavailable" note) | Stage 5: length equality else `schemaViolation` → whole payload fails |
| `daily.*` length mismatch | **Truncate to shortest; cap 7** | Stage 5: `daily` arrays length == 7 else `schemaViolation` |
| Missing `hourly`/`daily` section | **Drop section**, show "unavailable" note, rest intact | Missing required key → `schemaViolation` |
| Geocoding: any bad `results[]` entry (name/lat/lon/country/…) | **Drop entry / omit / default "—"** | `schemaViolation`/`outOfRange` → **entire 8-result list fails** |

Three of these are also direct violations of named acceptance criteria / failure modes:
- **US-4 AC3:** "any single field that fails validation renders '—' with the rest of the block intact (**never a whole-screen error for one bad field**)." The arch pipeline produces a whole-screen error for one bad field.
- **PRD FM-3 note:** "Field-level violations do NOT trigger FM-3 — they render '—' per §7.2."
- **PRD FM-17:** partial data must render with truncation + note, "Never pad with fabricated values."

The unknown-key hard-fail is additionally a **robustness inversion**: Open-Meteo evolves its API (it has added fields before). Under the arch's rule, a benign new field the API adds on a Tuesday becomes a **full outage for every user** until an app update ships through review. The PRD's "ignore unknown fields" is the correct robustness posture for a client you don't control.

**Proposed fix:** Rewrite §3.3 as a two-severity pipeline that implements the PRD literally:
- **Structural failures → reject payload** (map to `schemaViolation`): unparseable JSON; `current` missing or non-object; non-array where an array is expected *for `current`* (PRD: "Non-array where array expected → FM-3 for `current`"). HTTP status mapping must precede body decode in the error mapper (see C-11).
- **Field-level violations → degrade per the PRD's "On violation" column**: "—" for scalars, drop-entry for bad geocoding results / unparseable time entries, omit-if-invalid for sunrise/sunset/admin1/country_code, default "—" for country, assume-1 for is_day, device-clock fallback for `current.time`, device-tz fallback + label for bad `utc_offset_seconds`, swap-and-flag for max<min, truncate-to-shortest + cap 48/7 for arrays with the FM-17 section note.
- **Unknown keys → ignore + Sentry breadcrumb** (field path only, no values). Schema-drift *detection* moves to the CI contract test (recorded responses replayed; whitelist violations fail the build) — detection without user harm.
- Pragmatic guard worth adding (not in PRD, flag as judgment call): if **all** `current` fields fail validation, treat as malformed payload rather than rendering an all-"—" block — an all-dash current is a broken payload wearing a valid one's clothes.

### 🔴 C-2 (High) — Validation ranges the architect invented that cannot be traced to the PRD

Per the task brief, anything not traceable to the PRD is flagged. The arch table is *stricter* than the PRD in ways that can reject **real** weather:

| Field | PRD §7.2 range | Arch §3.3 range | Problem |
|---|---|---|---|
| `current.precipitation` | ≥ 0 (no upper bound) | 0…500 mm | Invented cap. (1825 mm/day has been recorded; an extreme event shouldn't fail validation.) |
| `current.pressure_msl` | 800…1100 | 870…1085 | Narrowed beyond PRD. (1085.7 hPa recorded, Mongolia 2001 — the arch's own ceiling would reject a real reading.) |
| `current.wind_speed_10m`, `wind_gusts_10m` | ≥ 0 (no upper bound) | 0…150 m/s | Invented cap. |
| `utc_offset_seconds` | integer, −50400…50400 (±14 h — correct; Kiritimati is +14) | −64800…64800 (±18 h) | **Widened and wrong**: no timezone on Earth is ±18 h. The PRD's ±14 h is the correct envelope. |
| geocoding `results[].name` | 1…200 chars | 1…100 chars | Halved without basis. |
| geocoding `results[].country`, `admin1` | ≤ 100 chars | ≤ 64 chars | Narrowed without basis. |
| `daily.sunrise/sunset` | parseable ISO; omit if invalid | adds "sunset > sunrise" cross-check | Invented check (polar day/night edge cases make naive sunset>sunrise assertions risky anyway). |
| `daily.temperature_2m_max/min` | max ≥ min → **swap-and-flag** | max ≥ min else violation | Changed the specified remediation. |
| geocoding `results[].country_code` | **exactly 2 chars**, optional | ≤ 64 chars | Weakened *and* changed handling (omit-if-invalid → whole-list failure). |

**Proposed fix:** Adopt the PRD's ranges verbatim as the v1 validation table. Any bound stricter than the PRD requires a recorded rationale + PO sign-off, not an architect's unilateral tightening — especially for fail-closed rules, where a too-tight bound converts real extreme weather into an error screen.

### 🔴 C-3 (High) — Fields missing from the arch validation table entirely

- **`daily.precipitation_probability_max`** — in the PRD §7.1 request set *and* the PRD §7.2 table ("each 0…100 → entry-level '—'"), **absent** from the arch §3.3 table. The day-detail expansion (design §3.4) shows precip % — with no validation row, the DTO author has no rule to implement.
- **`daily.time[]`** — PRD §7.2 row exists ("each parseable ISO date → drop unparseable entries"); absent from arch table. The 7-day list needs weekday/date labels from somewhere.
- **Geocoding `results[].id`** — PRD §7.3 row exists ("integer ≥ 0 → drop entry"); absent from arch table. Worse: under the arch's own stage-2 "unknown key → violation" rule, `id` (a legitimate, PRD-whitelisted field) would *fail validation* because it's not in the arch's whitelist. The whitelist is self-inconsistent.

**Proposed fix:** Add the three rows per the PRD before any DTO is written; add a CI check that every PRD §7.2/§7.3 row has a corresponding validator test (PRD §7.4.3 already requires "one test per whitelist row's violation path" — the missing rows would currently have zero tests).

### 🔴 C-4 (High) — Release log sanitization leaks coordinates; contradicts PRD §9.7

Two compounding problems in §3.2's `SanitizedLoggingInterceptor`:

1. **"Query strings truncated to 40 chars" is not sanitization.** The forecast query string begins `latitude=52.5234051&longitude=13.4113999&current=…`. The first 40 characters are `latitude=52.5234051&longitude=13.41139` — i.e., **full-precision latitude and most of longitude, written to the release log**. Truncation preserves exactly the prefix where the coordinates live. This is a fail-open privacy leak, and it also violates PRD §7.4.2 ("never raw user location") and §9.7 ("no coordinates… in logs or crash reports").
2. **PRD §9.7 says "no coordinates" in logs, full stop.** The arch permits "coordinates truncated to 2 decimals" in release logs. 2 dp is still location (~1.1 km); the PRD's rule is stricter and unambiguous. The arch is looser than the PRD it claims to implement.

Related: `AppFailure.outOfRange(String field, num value)` will carry coordinate *values* when the lat/lon echo fails range checks, and any stringified `DioException` embeds `requestOptions.uri` — which contains full-precision lat/lon. If `unknown(cause)` or an error message reaches a release log or Sentry breadcrumb unscrubbed, coordinates leak through the error path even if the happy path is clean.

**Proposed fix:**
- Replace truncation with **redaction**: a `sanitizeUri()` applied at the logging boundary that replaces `latitude=`/`longitude=` values with `<redacted>` (keep param *names* for debuggability). Never log raw query strings on the forecast host.
- Align to PRD §9.7: **zero coordinate digits in release logs** — not even 2 dp. (Debug builds should also redact to 2 dp; devs paste debug logs into bug reports.)
- The release logger must serialize failures as *variant name + field path + reason + value **type*** (per PRD §7.4.2), never raw values for coordinate fields.
- Sentry: `sendDefaultPii: false`, breadcrumbs carry the same sanitized shape; assert in a unit test that a `DioException` with a coordinate-bearing URI never emits digits matching a lat/lon pattern after sanitization.

### 🟠 C-5 (Medium) — `uv_index_max` requested without the PO approval PRD §7.1 requires

- PRD §7.1: "**fixed parameter set — no other params without PO approval**." Its `daily=` list is `weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max` — **no `uv_index_max`**.
- Arch §3.1 adds `uv_index_max` to the daily params and §3.3 adds a validation row (0…20) that has no PRD §7.2 counterpart.
- Meanwhile the design spec's Home key-metrics grid (§3.1) shows a **UV index card** and a **precipitation-probability card** — the latter isn't in the `current=` param set either (precip *probability* is only requested for hourly/daily). So the design assumes data the PRD's fixed param set doesn't fetch.

**Proposed fix (needs PO decision, escalated as dispute D-2):** either (a) PO approves adding `uv_index_max` (+ `precipitation_probability` to `current=` if the card needs it) with corresponding §7.2 whitelist rows, or (b) the design drops/changes the UV card. The arch must not unilaterally expand the fixed param set — §7.1's approval gate exists precisely for this.

### 🟠 C-6 (Medium) — PRD FM-10 (location timeout / no fix) has no `AppFailure` variant

PRD FM-10: "No fix within 15 s" → headline "**Couldn't get your location**" with **[Retry] [Search]** actions. The arch's union has `locationDenied` (FM-13), `locationPermanentlyDenied` (FM-14), `locationServicesDisabled` (FM-15) — but a fix timeout would fall into the generic `timeout()`, whose UI copy and single-Retry action are modeled on *network* timeouts. The user gets the wrong headline and loses the [Search instead] escape hatch. Additionally, arch §4.3 sets the fix timeout to **10 s** while PRD FM-10 specifies **15 s**.

**Proposed fix:** add `AppFailure.locationTimeout()` mapping to the FM-10 headline + dual actions; align the `getCurrentPosition` timeout to the PRD's 15 s (or record a deliberate deviation with rationale).

### 🟠 C-7 (Medium) — Revocation cannot identify device-location cache entries to purge

§4.3 revocation path: "clears forecast cache entries keyed by device location." But §6 cache keys are `"${lat},${lon}"` with **no origin tag**, and revocation *also* drops the in-memory coordinates — so at purge time, the repository no longer knows which keys were device-derived. The specified purge is unimplementable as written; stale device-location entries would survive revocation, contradicting the GDPR "revocation wipes" requirement (§4.3, PRD §9.5).

**Proposed fix:** tag it at write time — either a `origin: device|search` field on `CacheRecord`, or the repository retains `lastDeviceLocationKey` in memory (cleared on revoke *after* the purge). Add a test: grant → fetch → revoke → assert no cache entry keyed by the device coords remains.

### 🟠 C-8 (Medium) — `RateLimitInterceptor` queue is unbounded and never supersedes

"Enforces minimum inter-request interval per host… queues rather than drops." Holes:

1. **No interval values specified.** PRD §8.4's ceilings (≤1 forecast/5 s, ≤1 geocoding/300 ms) are enforced by TTL/dedupe/debounce, not by queueing. If the interceptor enforced a 5 s minimum interval on the forecast host, **pull-to-refresh** (PRD US-8: "triggers one forecast request"; refresh indicator implies prompt dispatch) after a 2 s-old auto-refresh would stall ~3 s in queue. Recommend: geocoding host 300 ms (matches debounce), forecast host 1 s as a safety net only — TTL + in-flight dedupe do the real work.
2. **Unbounded queue + no supersede.** During a `Retry-After` pause (up to 60 s, §3.2: "request queue paused"), user actions accumulate; on resume they fire as a **burst** — the exact behavior that re-triggers 429s. And a queued geocoding request for "Springf" will still dispatch ahead of the newer "Springfield" request.
3. **Cancelled-while-queued requests still dispatch.** §6 relies on `CancelToken` for FM-12, but if the interceptor doesn't consult the token before dequeue, a superseded keystroke's request fires anyway (wasted quota; render is saved only by the request-id discard downstream).

**Proposed fix:** per-host queue with **per-key coalescing (newest wins, older dropped)**, **bounded depth** (e.g., 10, overflow drops oldest), **cancellation check at dispatch**, and **paced drain** after a rate-limit pause (respect the minimum interval on release, don't burst). Specify the two interval values in `constants.dart`.

### 🟡 C-9 (Low) — Timeout values don't match the PRD; error-mapper ordering unspecified

- PRD §8.3: "**Timeout per request: 10 s** → treated as network failure (FM-1)." Arch: `connectTimeout: 8 s, receiveTimeout: 12 s`. The 12 s receive timeout exceeds the PRD budget; a user on a stalled connection waits 12 s (plus retry backoff) before the FM-1 "No connection" state, and DoD §12.4 tests assert the §8.3 budget. Recommend `receiveTimeout: 10 s` (keep `connectTimeout: 8 s`; add `sendTimeout` for completeness).
- The error mapper must apply **HTTP-status mapping before body-decode mapping**: a 5xx with a Cloudflare HTML error page under `responseType: json` throws `FormatException` — if decode errors are mapped first, FM-2 (serverError) is misreported as FM-3 (schemaViolation). Specify the order: status → transport → decode → validation.

### 🟡 C-10 (Low) — Cache spec gaps (all fixable in one pass over §6)

1. **Search result cache**: PRD §8.1 requires "in-memory result cache per normalized query (trimmed, lowercased), TTL 60 s"; arch §4.1 caches only "last query". Implement per-query, 60 s TTL (also covers "identical queries within 5 s reuse the in-flight/fresh result").
2. **Forecast in-flight dedupe** (PRD §8.2: "identical request within 5 s attaches to the same future") is not stated in the arch — add an in-flight map keyed by cache key to `WeatherRepositoryImpl`, and use it to prevent SWR stampedes (10–60 min path: concurrent callers share one background revalidate).
3. **LRU mechanics unspecified**: Hive has no native LRU. Specify access-order tracking (e.g., update a `lastAccessUtc` on read, evict min) or the "cap 20" is aspirational.
4. **Box-level corruption**: FM-18 covers record-level; add open-failure recovery (catch `HiveError` on box open → delete box file → recreate empty → breadcrumb). Otherwise a corrupt box is a startup crash, violating "Cache must never crash the app."
5. **Schema versioning**: add `schemaVersion` to `CacheRecord`; on app upgrade, version mismatch → treat as miss (cleaner than relying on parse failure to self-heal).
6. **Unnecessary L1 clear on unit-system change** (§6): the cache is canonical SI and conversion is display-only — clearing L1 on toggle contradicts ADR-04's own rationale ("changing °C→°F would [not] require cache invalidation"). Remove the clear; it's pure waste.
7. **Offline fast-path for 60 min–24 h stale**: §4.1 serves that tier "ONLY if network fails" — but the flow tries the network first, so an offline user waits out the full 10 s timeout before seeing labeled stale data. If `connectivityProvider` reports offline, skip the network attempt and serve stale immediately (PRD US-10 AC1 implies prompt rendering).
8. **Clock skew**: clamp computed age ≥ 0; a `fetchedAtUtc` in the future must not be evicted as ">24 h".
9. **Key normalization**: `toStringAsFixed(2)` yields `"-0.00"` for small negative values vs `"0.00"` — normalize negative zero (or key on integer hundredths) to avoid phantom misses. Use PRD §8.2's `forecast:` prefix for namespacing.
10. **"Delete local data"** (design §3.5) must clear both Hive boxes + prefs — name it in §6 so implementation doesn't miss a store.
11. **Recent-places count**: PRD US-13 says **10**, arch §6 says **8**, design §3.2 displays 5. Recommend: store 10 (PRD wins), display 5 (design), and specify "corrupt recents entries purged on load" as the PRD FM-18 code path (currently unnamed in the arch).

### 🟡 C-11 (Low) — Retry and request hygiene nits

- **Add jitter** to the 1 s → 2 s backoff (±250 ms): without it, every device that hits an Open-Meteo blip retries on the same grid — a self-inflicted thundering herd against a free API we're trying to be good citizens of (PRD G-4).
- **`Retry-After` parsing**: the header may be delta-seconds *or* an HTTP-date; implement both, then cap at 60 s per PRD §8.3.
- **Set a descriptive `User-Agent`** (`weather-app/<version>`) — Open-Meteo requests identification for fair-use; it's the cheapest API-citizenship win available and currently absent from §3.2.
- **Integer-ness**: PRD requires integer for `is_day`, `weather_code` members, and `utc_offset_seconds`; the arch table types them as `num` with no integer check. A `3.5` weather code should not pass the WMO-set test on truncation — specify explicit integer validation.
- **Debug-build logging** should also redact coordinates to 2 dp — developers paste debug logs into issues and screenshots.

---

## (c) Requested ADR changes

| ADR | Change |
|---|---|
| **ADR-01** | **Keep.** Strengthen rationale: add (i) per-source-IP fair-use aggregation argument — a proxy concentrates quota and *increases* 429 risk; (ii) GDPR controller/processor argument — direct calls keep Open-Meteo as the sole disclosed recipient. |
| **ADR-05** | **Rewrite the policy half.** Keep handwritten DTOs; replace "unknown key → violation, no partial entity" with the PRD's two-severity model: structural failures reject the payload; field-level violations degrade per the PRD's "On violation" column; unknown keys are ignored + breadcrumbed; schema-drift detection lives in the CI contract test. Adopt PRD ranges verbatim (C-2). |
| **ADR-06** | **Amend:** origin-tagged `CacheRecord` (C-7); explicit LRU mechanics; box-level corruption recovery; `schemaVersion`; remove L1-clear-on-unit-toggle; offline fast-path for the 60–24 h tier; per-query 60 s search cache; 5 s in-flight dedupe map. |
| **ADR-07** | **Keep.** Note for the UI/UX Designer: design-spec §3.5 ("Coarse — ~10 km") and §5.1 consent copy ("about 10 km") still say ~10 km — they must be updated to ~1.1 km to match this ADR, or the consent text misstates what the app does. |
| **ADR-11 / §3.2** | **Amend:** logging redaction policy → zero coordinate digits in release logs, `sanitizeUri()` at the boundary (C-4); specified per-host minimum intervals; queue coalescing/bounds/paced drain (C-8); backoff jitter; `Retry-After` date parsing; `User-Agent` header; error-mapper status-before-decode ordering (C-9). |
| (new) | **Param-set governance:** record that any `daily=`/`current=`/`hourly=` expansion (e.g., `uv_index_max`) needs the PRD §7.1 PO approval + a §7.2 whitelist row before the query contract changes (C-5). |

No changes requested to ADR-02, ADR-03, ADR-04, ADR-08, ADR-09, ADR-10, ADR-12, ADR-13.

---

## (d) Disputes for Sloane

**D-1 — Validation philosophy (PRD vs architect). Needs a ruling before DTOs are written.**
The PRD (PO-owned, approved requirements baseline) specifies field-level degrade with an explicit per-field table; the architect specifies entity-level fail-closed. These cannot coexist, and the architect's version breaks US-4 AC3, FM-14, and FM-17 as written. My recommendation as backend reviewer: **the PRD wins** — it is the more carefully specified contract, it degrades gracefully (the app's core promise, PRD §1: "never pretends… degrades gracefully"), and fail-closed-on-unknown-keys turns benign API evolution into user-facing outages. Compromise available: implement PRD semantics *plus* unknown-key Sentry breadcrumbs and the CI contract test as the drift detector — you keep the architect's early-warning goal without punishing users. If Sloane rules the other way, the PRD's §7, US-4 AC3, FM-14, and FM-17 must be rewritten to match, since the DoD (§12.2–12.3) tests assert the PRD's version.

**D-2 — `uv_index_max` / current-block precip probability (PO decision required).**
The design's Home metrics grid assumes UV index (and precip probability in the current block); the PRD's §7.1 fixed param set doesn't fetch them; the arch fetches one of them without the required PO approval. PO to choose: (a) approve param additions + whitelist rows, or (b) redesign the metric cards. Nothing in the data layer should be built until this is decided — it changes the query contract, the whitelist table, and the DTOs.

**D-3 — Log redaction strictness.**
PRD §9.7: zero coordinates in logs. Arch §3.2: 2 dp coords permitted in release logs. I recommend the PRD's stricter rule (C-4 shows the current scheme actively leaks full-precision coords via query-string truncation). Tech Law / AppSec to confirm in Phase 3, but the engineering rule should be set now: *no coordinate digits in any log or breadcrumb, any build*.

**D-4 — Number alignment (minor, batch ruling).**
PRD says 10 s request timeout / 15 s location-fix timeout / 10 recent searches; arch says 8 s+12 s / 10 s / 8. Recommend aligning to the PRD in all three (with `receiveTimeout: 10 s` satisfying §8.3 exactly). If the architect wants different numbers, they need recorded rationale — timeouts are DoD-tested (§12.4).

**D-5 — Precision copy.**
ADR-07 settled 2 dp (~1.1 km), but the design spec still promises "~10 km" in Settings and the consent sheet. That's a consent-accuracy issue, not just copy polish — the consent text must describe what the app actually does. UI/UX Designer to update before build.

---

### Traceability note

Every C-item above cites the PRD section it diverges from. Per the architect's own §9 reconciliation note, the FM table still needs a 1:1 diff against the PRD — the mapping audit in this review found: **one PRD failure mode with no `AppFailure` variant** (FM-10 location timeout → C-6), **two PRD modes mismapped to whole-payload failure instead of their specified graceful behavior** (FM-14 timezone fallback, FM-17 partial data → both fold into C-1), **no double-mappings**, and **two arch variants with no PRD FM counterpart** (`consentRequired`/`consentRevoked` — reasonable additions for US-3 AC3's toggle-off state; `reverseGeocodeFailed` → "Current location" label — reasonable addition; both fine, just unnumbered). After C-1/C-6 are resolved, the union covers FM-1…FM-20 completely.

### Suggested Phase-3 handoffs

- **AppSec:** cert-pinning decision (arch §13 Q1, unchanged); review the `sanitizeUri()` implementation and Sentry scrubbing config once written.
- **Tech Law:** confirm the zero-coordinates-in-logs rule and the Sentry DPA/data-residency question (arch §13 Q2).
- **QA:** the DoD §12.2/§12.3 test plan must be written against the *PRD's* §7 "On violation" column (field-level cases), not the arch's §3.3 stages — otherwise tests will enshrine the wrong behavior.

*End of review — Lead Backend Engineer. The architecture's shape is right (client-only, Dio interceptors, two-tier cache, sealed failures); its validation policy and several of its numbers are not yet faithful to the PRD. Fix C-1 through C-4 and get Sloane's rulings on D-1/D-2 before DTO work begins.*
