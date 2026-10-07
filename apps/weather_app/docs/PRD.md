# Weather App — Product Requirements Document

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Date** | 2026-10-06 |
| **Owner** | Product Owner, Product & UX Division |
| **Approver** | Sloane, Chief Orchestrator |
| **Status** | Draft — War Room intake |
| **Platform** | Flutter, Android + iOS (single codebase) |
| **Data source** | Open-Meteo Forecast API (`https://api.open-meteo.com/v1/forecast`) + Geocoding API (`https://geocoding-api.open-meteo.com/v1/search`). No API key. No secrets anywhere in the app. |

> Rule of this document: **"works well" is not a criterion.** Every story ships with measurable acceptance criteria. Edge cases are specified up front, not discovered in production.

---

## 1. Problem Statement

People check the weather dozens of times a week, yet most weather apps fail at the basics: they show stale or wrong data without saying so, crash or blank-screen when the API misbehaves, demand precise location without explaining why, and spam APIs on every keystroke. Users need a fast, honest weather app that shows **live, clearly-labeled telemetry** for a chosen city or their device location, degrades gracefully when anything goes wrong, respects privacy by default, and never pretends fresh data is fresh when it isn't.

## 2. Goals & Success Metrics

| # | Goal | Measurable success criterion |
|---|---|---|
| G-1 | Live, trustworthy weather | ≥ 99% of forecast requests that receive a valid payload render current conditions within the performance budget (see §9.1) |
| G-2 | Graceful degradation | 100% of failure modes in §11 show a specific, actionable UI state — zero blank screens, zero crashes, zero silent stale data |
| G-3 | Privacy by default | 0 persistent stores of device coordinates; location access only after explicit opt-in consent |
| G-4 | API citizenship | Peak request rate from a single device ≤ 1 request / 5 s under normal use; zero requests fired before 300 ms search debounce |
| G-5 | Accessible to all | WCAG 2.1 AA conformance verified by audit (see §9.4) |

## 3. Non-Goals (Out of Scope for v1)

- Push notifications / severe-weather alerts
- Home-screen widgets, watch apps
- Multi-city dashboards / favorites list (recent searches only, §US-13)
- Maps, radar, or animated precipitation layers
- User accounts, sync, analytics, or any tracking SDK
- Offline-first with background sync; offline support is read-only cache display (§US-10)
- Any API key, secret, or paid data provider

## 4. Personas

- **Mara, commuter:** checks current temp + next few hours each morning, one-handed, on a mid-range Android. Needs glanceable data in < 4 s.
- **Dev, traveler:** searches unfamiliar cities, hits ambiguous names ("Springfield"), sometimes has no signal. Needs disambiguation and honest offline states.
- **Priya, privacy-conscious:** denies location permission by default. Needs full app function via city search and a readable privacy notice.

---

## 5. User Stories

### US-1 — Search for a city and view its weather (P0)

**Narrative:** As Mara, I type a city name and pick it from results so I can see its weather.

**Acceptance criteria:**
1. Given I type ≥ 2 characters, when I pause ≥ 300 ms, then exactly one geocoding request fires (verified via request log in test build; no request per keystroke).
2. Given I type 1 character, when I pause, then no request fires and a hint "Type at least 2 characters" is shown.
3. Given results return, when I tap a result, then the Home screen loads that city's weather with the city name, region, and country in the header.
4. Given a request is in flight, when I type more characters, then the previous request is cancelled/superseded and only the latest result set is rendered (no out-of-order flashes).

### US-2 — Disambiguate same-name cities (P0)

**Narrative:** As Dev, I search "Springfield" and pick the right one.

**Acceptance criteria:**
1. Results list shows up to 8 entries, each displaying **name, admin1 (state/region), and country** — never name alone.
2. Given ≥ 2 results share a name, when the list renders, then each row is distinguishable by region/country (no two identical rows).
3. Given zero results, when the response arrives, then an empty state reads "No places found for '<query>'" with a "Try again" affordance — not a blank list.

### US-3 — Use device location with explicit consent (P0)

**Narrative:** As Mara, I tap "Use my location" and get local weather after I explicitly agree.

**Acceptance criteria:**
1. Tapping "Use my location" first shows an in-app consent dialog explaining: what is accessed (approximate location only), why (to fetch local weather), that coordinates are never stored, and a link to the privacy notice. Location OS prompt appears **only** after the user taps "Allow" in-app.
2. Given consent granted and a fix obtained, then coordinates are **rounded to 2 decimal places (~1 km precision)** before the API call, held in memory only, and never written to disk (verified: no coordinate values in SharedPreferences/files after session; automated test asserts this).
3. Given I toggle "Use device location" off in Settings, then the in-memory coordinates are cleared immediately and the app falls back to the last searched city (or search prompt if none).
4. Given location services are disabled at OS level, then the app shows "Location services are off — enable them in Settings or search for a city" with a deep link to OS settings.

### US-4 — View current conditions (P0)

**Narrative:** As Mara, I see the current temperature, feels-like, condition, humidity, wind, and pressure at a glance.

**Acceptance criteria:**
1. Home header shows: city/region/country (or "Current location"), local time of the location, and "Updated X min ago" timestamp.
2. Current block displays: temperature, apparent ("feels like") temperature, condition text + icon, humidity %, wind speed + direction (compass label, e.g. "NW"), wind gusts, precipitation amount, cloud cover %, pressure hPa.
3. Every value renders within 500 ms of a valid payload arriving; any single field that fails validation renders "—" with the rest of the block intact (never a whole-screen error for one bad field).
4. Units: metric by default; values labeled with units (°C, %, km/h, hPa, mm).

### US-5 — View the next-24-hour forecast (P0)

**Narrative:** As Mara, I scroll an hourly strip to plan my day.

**Acceptance criteria:**
1. Hourly section shows **24 entries** starting from the current local hour of the location: hour label, icon + condition, temperature, precipitation probability %.
2. Hours are in the **location's timezone** (from API `utc_offset_seconds`/`timezone`), not the device timezone; a label states the timezone used (e.g. "Local time in Berlin").
3. Horizontal scroll is smooth (no jank beyond 2 dropped frames on reference devices, §9.1) and each hour is a distinct screen-reader item.

### US-6 — View the 7-day forecast (P0)

**Narrative:** As Dev, I see the week ahead to pack accordingly.

**Acceptance criteria:**
1. Daily section shows **7 entries**: weekday name + date, icon + condition, high/low temperatures, precipitation probability max %.
2. Sunrise/sunset shown per day (or in a day-detail expansion — PO decision at build time, must be visible somewhere on Home).
3. Tapping a day highlights it; acceptance is display correctness, not navigation (no detail screen in v1).

### US-7 — Understand conditions via icon + text (P0)

**Narrative:** As Priya using a screen reader, I hear what the icon means.

**Acceptance criteria:**
1. Every WMO weather code maps to a human-readable label (mapping table in Appendix A). Unknown/unlisted codes render the label **"Unknown conditions"** with a neutral icon — never a crash, never a blank icon.
2. No information is conveyed by color or icon alone: every icon is paired with text, and every icon has an accessibility label (e.g. "Partly cloudy icon").
3. Mapping covers all codes the API documents (0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99).

### US-8 — Pull to refresh (P0)

**Narrative:** As Mara, I pull down to get the latest data.

**Acceptance criteria:**
1. Pull-to-refresh triggers one forecast request for the current location/city; the refresh indicator shows until response or timeout.
2. Given cache is fresh (< 10 min), refresh still forces a network request (user intent overrides cache).
3. After refresh, "Updated X min ago" resets to "just now".

### US-9 — See graceful error states and retry (P0)

**Narrative:** As Dev with flaky signal, I always know what happened and what to do next.

**Acceptance criteria:**
1. Every failure in §11 maps to a distinct user-facing state: specific headline, one-line explanation, and a primary action (Retry / Open settings / Search instead). Generic "Something went wrong" appears in **zero** states.
2. Retry re-fires the failed request (subject to §8 rate limits); success clears the error state within 500 ms.
3. Error states preserve the last good cached data underneath where available (with staleness label), rather than replacing the screen with an error.

### US-10 — Use the app offline with cached data (P1)

**Narrative:** As Dev in a dead zone, I see the last data I had, honestly labeled.

**Acceptance criteria:**
1. Given cached forecast < 24 h old and no network, then Home renders the cached data with a persistent banner: "You're offline — showing data from Xh ago."
2. Given no cache exists and no network at launch, then an offline empty state shows with a "Retry" button; retry is attempted automatically when connectivity returns (connectivity listener, single attempt per reconnect, debounced 2 s).
3. Cached data older than 24 h is never displayed; it is discarded and the offline empty state is shown.

### US-11 — Read the privacy notice and manage location (P0, GDPR)

**Narrative:** As Priya, I read exactly what the app does with location before deciding.

**Acceptance criteria:**
1. A "Privacy" entry is reachable within 2 taps from Home (Settings → Privacy); it states in plain language: data source (Open-Meteo), what is sent (rounded coordinates or city name only), that no account/tracking exists, retention (nothing persisted), and how to revoke (in-app toggle + OS settings).
2. Revoking location in-app immediately clears in-memory coordinates (asserted by test) and stops all location access.
3. The app functions 100% without location permission via city search (all P0 stories pass with permission denied).

### US-12 — Switch between °C and °F (P1)

**Narrative:** As a US traveler, I read temperatures in Fahrenheit.

**Acceptance criteria:**
1. Settings offers "Units: Celsius / Fahrenheit"; selection persists across restarts (local preference only).
2. Switching units re-renders all temperatures within 500 ms **without** a new network request (convert client-side from the cached metric payload); wind/pressure units follow a documented mapping (°F ↔ mph/inHg or keep metric with labels — PO decision recorded before build; labels must always match values).
3. Default is Celsius.

### US-13 — Revisit recent searches (P1)

**Narrative:** As Dev, I jump back to cities I checked earlier without retyping.

**Acceptance criteria:**
1. Up to 10 recent searches stored locally (name, region, country, rounded coordinates — public place data, not device location), most-recent-first, deduplicated.
2. Tapping a recent search loads its weather within the §9.1 budget using cache when fresh.
3. "Clear recents" removes all entries; entries contain no device-derived coordinates (asserted by test).

---

## 6. Functional Requirements

### 6.1 Screens

| ID | Screen | Contents |
|---|---|---|
| S-1 | Home | Location header (name/region/country or "Current location", local time, updated-ago) · Current conditions block (§US-4) · Hourly strip, 24 h (§US-5) · Daily list, 7 d (§US-6) · Pull-to-refresh (§US-8) · Offline/stale banner slot · Error state slot |
| S-2 | Search | Search field (debounced, §8.1) · "Use my location" button (§US-3) · Results list, ≤ 8 rows with name/admin1/country (§US-2) · Recent searches (§US-13) · Empty/error states |
| S-3 | Settings | Units toggle (§US-12) · Location mode toggle (§US-3, §US-11) · Privacy notice (§US-11) · Data source attribution ("Weather data by Open-Meteo.com") · App version |
| S-4 | Privacy notice | Plain-language notice per §10 (scrollable, readable at 200% text scaling) |

### 6.2 State model (guidance, not mandate)

`uninitialized → loading → ready | error → refreshing`. Cache states: `fresh (<10 min) → stale (10–60 min, revalidate in background) → expired (>60 min online)`. Offline: `cached (<24 h) → show with banner; else empty state`.

### 6.3 Attribution

"Weather data by Open-Meteo.com" is displayed in Settings and on first launch. No white-labeling of the data source.

---

## 7. Data Contracts & Zero-Trust API Handling

**Principle: the network is hostile.** Every field of every response is validated against a whitelist before use. Unknown fields are ignored. Wrong-typed or out-of-range fields are discarded at field level (render "—"), never crash the app. A missing or non-object `current` block is a malformed payload (see FM-3).

### 7.1 Forecast request (fixed parameter set — no other params without PO approval)

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}&longitude={lon}
  &current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m
  &hourly=temperature_2m,precipitation_probability,weather_code
  &daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max
  &timezone=auto&forecast_days=7
```

### 7.2 Forecast response whitelist & validation

| JSON path | Type | Valid range / values | On violation |
|---|---|---|---|
| `current` | object | must exist | **Malformed payload** → FM-3 |
| `current.time` | string | parseable ISO 8601 | fall back to device clock; log sanitized warning |
| `current.temperature_2m` | number | −90 … 60 | "—" |
| `current.relative_humidity_2m` | number | 0 … 100 | "—" |
| `current.apparent_temperature` | number | −90 … 60 | "—" |
| `current.is_day` | number | integer ∈ {0,1} | assume 1; log |
| `current.precipitation` | number | ≥ 0 | "—" |
| `current.weather_code` | number | integer ∈ WMO set (App. A) | label "Unknown conditions", neutral icon |
| `current.cloud_cover` | number | 0 … 100 | "—" |
| `current.pressure_msl` | number | 800 … 1100 | "—" |
| `current.wind_speed_10m` | number | ≥ 0 | "—" |
| `current.wind_direction_10m` | number | 0 … 360 | "—" (omit compass label) |
| `current.wind_gusts_10m` | number | ≥ 0 | "—" |
| `hourly.time` | string[] | each parseable ISO 8601 | drop unparseable entries |
| `hourly.temperature_2m` | number[] | each −90 … 60 | entry-level "—" |
| `hourly.precipitation_probability` | number[] | each 0 … 100 | entry-level "—" |
| `hourly.weather_code` | number[] | each integer | unknown → "Unknown conditions" |
| `daily.time` | string[] | each parseable ISO date | drop unparseable entries |
| `daily.temperature_2m_max` / `_min` | number[] | each −90 … 60, max ≥ min else swap-and-flag | entry-level "—" |
| `daily.sunrise` / `daily.sunset` | string[] | parseable ISO 8601 | omit if invalid |
| `daily.precipitation_probability_max` | number[] | each 0 … 100 | entry-level "—" |
| `daily.weather_code` | number[] | each integer | unknown → "Unknown conditions" |
| `utc_offset_seconds` | number | integer, −50400 … 50400 | fall back to device timezone; label which is used |
| `timezone` | string | ≤ 64 chars | informational only |

**Array rules:** `hourly.*` arrays must have equal length to `hourly.time`; truncate all to the shortest length; cap at 48 entries. `daily.*` arrays truncate to shortest; cap at 7 entries. Non-array where array expected → treat block as missing → FM-3 for `current`, drop section for `hourly`/`daily` (show section-level "unavailable" note, rest of screen intact).

### 7.3 Geocoding request & response whitelist

```
GET https://geocoding-api.open-meteo.com/v1/search?name={q}&count=8&language=en&format=json
```

| JSON path | Type | Valid range / values | On violation |
|---|---|---|---|
| `results` | array | may be absent/empty | empty → US-2 AC3 empty state |
| `results[].id` | number | integer ≥ 0 | drop entry |
| `results[].name` | string | 1 … 200 chars | drop entry |
| `results[].latitude` | number | −90 … 90 | drop entry |
| `results[].longitude` | number | −180 … 180 | drop entry |
| `results[].country` | string | 1 … 100 chars | default "—" |
| `results[].admin1` | string | ≤ 100 chars, optional | omit if invalid |
| `results[].country_code` | string | exactly 2 chars, optional | omit if invalid |

Non-JSON or unparseable body → FM-4 (search error state with retry).

### 7.4 Validation implementation rules

1. Parse defensively: check existence → check type → check range, in that order. Never `as`/`!` cast on network data.
2. Log validation failures with **sanitized** detail (field path + reason + value type, never raw user location or full payload) for diagnostics.
3. Unit tests required: one test per whitelist row's violation path, plus a fully-malformed payload test and an extra-unknown-fields test.

---

## 8. Rate Limiting & Caching

### 8.1 Search input (geocoding)

- Debounce: **300 ms** after last keystroke; minimum query length **2** characters.
- In-flight cancellation: a new keystroke supersedes the pending request; only the latest response renders.
- In-memory result cache per normalized query (trimmed, lowercased): **TTL 60 s**.
- Identical queries within 5 s reuse the in-flight/fresh result — never a duplicate request.

### 8.2 Forecast requests

- Response cache key: `forecast:{lat_2dp}:{lon_2dp}:{units}`. **Fresh TTL 10 min** → serve without network.
- Stale-while-revalidate: age 10–60 min → render immediately, refresh in background, update "Updated X ago" on success.
- Expired: age > 60 min → network request required (with offline fallback per US-10).
- In-flight dedupe: identical request within 5 s attaches to the same future.
- Pull-to-refresh bypasses cache (one forced request; still subject to §8.3).

### 8.3 Backoff & retry budget

- Timeout per request: **10 s** → treated as network failure (FM-1).
- Transient failures (network error, HTTP 5xx): up to **2 retries**, exponential backoff 1 s → 2 s.
- HTTP 429: honor `Retry-After` header, capped at 60 s; max **2 retries**; then surface the rate-limit state (FM-6). No retry loops beyond this budget — the app must never hammer the API.
- HTTP 4xx (except 429): no retry; surface the corresponding state (FM-5).

### 8.4 Request ceiling

Under normal use a device issues **≤ 1 forecast request per 5 s** and **≤ 1 geocoding request per 300 ms window**; automated tests assert the debounce, dedupe, and TTL behaviors.

---

## 9. Privacy & GDPR Specification

1. **Consent first:** device location is accessed only after the in-app consent dialog (§US-3 AC1). The OS permission prompt is never the first ask.
2. **Coarse precision:** coordinates rounded to **2 decimal places** before any network call. Precise coordinates never leave the device; rounded coordinates are sent only to `api.open-meteo.com`.
3. **No storage:** device-derived coordinates are held in memory only, cleared on location-mode-off, app background kill, or session end. Zero coordinate values in persistent storage (automated test).
4. **Plain-language notice** (§US-11 AC1) covering: data source, what is transmitted, no accounts/tracking/ads SDKs, retention (none), revocation path.
5. **Revocation:** in-app toggle + OS settings both fully stop location access; app remains fully functional via search.
6. **No secrets:** Open-Meteo requires no key — the app ships with **zero API keys, tokens, or secrets**; CI fails on secret-pattern detection.
7. **Logs:** no coordinates, no query strings containing location, no PII in logs or crash reports.

---

## 10. Non-Functional Requirements

### 10.1 Performance (reference devices: Pixel 6a-class Android, iPhone 12-class iOS)

| Metric | Budget | Measured how |
|---|---|---|
| Cold start to interactive Home | ≤ 2.0 s | release build, average of 5 runs |
| Cold start → weather rendered (cached city, 4G) | ≤ 3.5 s | release build on throttled 4G profile |
| Search keystroke → results rendered | ≤ 1.5 s after debounce | throttled 4G |
| Pull-to-refresh → UI updated | ≤ 4.0 s | throttled 4G |
| Scroll jank (hourly/daily lists) | ≤ 2 dropped frames per fling | profile-mode timeline |
| Install size | Android ≤ 35 MB per ABI split; iOS ≤ 50 MB | release artifacts |

### 10.2 Reliability

- Crash-free sessions **≥ 99.5%**; ANR/App-hang-free **≥ 99%** (release telemetry — crash reports only, no behavioral analytics).
- Zero unhandled exceptions from network/parse paths (all covered by §7 validation).

### 10.3 Offline behavior

Per §US-10: cached forecast < 24 h → labeled banner; no cache → offline empty state; auto single retry on reconnect (debounced 2 s). The app never displays data older than 24 h and never presents stale data as fresh.

### 10.4 Accessibility — WCAG 2.1 AA

1. Contrast: text ≥ 4.5:1, large text (≥ 18pt / 14pt bold) ≥ 3:1, meaningful icons ≥ 3:1 — measured against both light and dark themes.
2. Touch targets ≥ 44×44 dp with ≥ 8 dp spacing for all interactive elements.
3. Full screen-reader support (TalkBack + VoiceOver): logical traversal order (header → current → hourly → daily), every value announced with context ("High 24 degrees Celsius, Thursday"), decorative elements hidden from the accessibility tree.
4. No color-only or icon-only meaning (§US-7 AC2).
5. Text scaling to **200%** without clipping, overlap, or loss of function; layout verified at largest OS font size.
6. Honors OS reduced-motion: disables non-essential animation.
7. Verification: manual audit on one Android + one iOS device with screen readers on, plus automated contrast/target checks in CI where tooling supports it. Audit checklist signed off before release.

### 10.5 Compatibility

- Flutter stable (version pinned in repo; upgrades are deliberate PRs).
- Android: minSdk 24 (Android 7.0); iOS: 15.0+.
- Light + dark themes; portrait and landscape without broken layout (landscape: no clipped/overlapping content).
- Location timezone vs device timezone handled per §US-5 AC2.

### 10.6 Internationalization readiness

All user-facing strings externalized; v1 ships English only. Date/time/number formatting uses locale-aware formatters; API `language=en` for geocoding in v1.

### 10.7 Maintainability

- State management: one documented pattern (BLoC or Riverpod — engineering picks, records in repo).
- Network layer isolated behind a repository interface; validation (§7) unit-testable without Flutter.
- CI: analyze, unit tests, widget tests for all error states in §11, secret scan, size check.

---

## 11. Edge Cases & Failure Modes

Each mode: **detection → user-facing behavior → recovery**. Every row has a widget test.

| ID | Condition | Detection | User-facing behavior (headline + action) | Recovery / notes |
|---|---|---|---|---|
| FM-1 | No network / request timeout | Connectivity check fails or 10 s timeout or socket error | **"No connection"** — "Check your connection and try again." [Retry]. Last cached data stays visible underneath with staleness label if < 24 h old. | Auto single retry on reconnect (debounced 2 s). Retry button subject to §8.3 budget. |
| FM-2 | API down (HTTP 5xx) | Status ≥ 500 after retry budget exhausted | **"Weather service is down"** — "Open-Meteo isn't responding right now. Your last update from Xh ago is shown." [Retry] | 2 retries, backoff 1 s → 2 s (§8.3). Cached data shown when available. |
| FM-3 | Malformed payload | JSON unparseable, or `current` missing/non-object, or `hourly`/`daily` structurally unusable | **"Couldn't read the weather data"** — "The service sent data we couldn't understand. Try again." [Retry]. Cached data shown when available. | No retry storm: single manual retry, then §8.3 budget. Sanitized log of failure. Field-level violations do NOT trigger FM-3 — they render "—" per §7.2. |
| FM-4 | Search request fails | Geocoding network error / 5xx / unparseable body | Inline under search field: **"Search isn't working right now"** [Try again]. Previous results (if any) retained. | Same retry budget as §8.3. |
| FM-5 | API client error (HTTP 4xx, not 429) | Status 400–499 | **"Request problem (code NNN)"** — "Please try again later." [Retry]. No automatic retries. | Logged; if persistent across builds, escalate to engineering (likely param bug). |
| FM-6 | Rate limited (HTTP 429) | Status 429 | **"Too many requests"** — "Please wait a moment and try again." [Retry] enabled only after `Retry-After` elapses. | Honor `Retry-After` (cap 60 s), max 2 retries. Client-side guards (§8) should make this rare; occurrences are logged as warnings. |
| FM-7 | Location permission denied | OS returns denied | **"Location access denied"** — "Search for a city instead — everything works without location." [Search for a city]. | Never re-prompt from the app after denial; respect the decision. |
| FM-8 | Location permanently denied | OS returns permanently denied | **"Location is turned off"** — "Enable it in system settings, or search for a city." [Open settings] [Search instead] | Deep link to OS app settings. |
| FM-9 | Location services disabled (OS-level) | Service disabled | **"Location services are off"** — "Turn them on in Settings, or search for a city." [Open settings] | Per §US-3 AC4. |
| FM-10 | Location timeout / no fix | No fix within 15 s | **"Couldn't get your location"** — "Try again or search for a city." [Retry] [Search] | Single retry allowed; then suggest search. |
| FM-11 | Ambiguous city search | ≥ 2 results with same name | Disambiguation list with name + admin1 + country (§US-2). | Never auto-pick the first result. |
| FM-12 | Zero search results | Empty `results` | **"No places found for '<query>'"** — "Check the spelling or try a nearby larger city." | Query echoed back (max 50 chars, escaped). |
| FM-13 | Unknown weather code | Code not in Appendix A | Label "Unknown conditions" + neutral icon (§US-7 AC1). | Not an error state; rest of UI unaffected. |
| FM-14 | Timezone missing/invalid | `utc_offset_seconds` absent or out of range | Fall back to device timezone; hourly header notes "Times shown in device timezone". | Logged as warning. |
| FM-15 | Stale cache only | Cache age 10–60 min, online | Data renders immediately + subtle "Updated X min ago" ; background refresh updates silently. | If background refresh fails → FM-1/FM-2 banner variant, data remains. |
| FM-16 | Expired cache, offline | Cache > 24 h or absent, no network | Offline empty state (§US-10 AC2): **"You're offline"** — "Connect to see the weather." [Retry] | Cache > 24 h is discarded, never shown. |
| FM-17 | Partial hourly/daily data | Array length mismatch or short arrays | Render available entries; truncate to shortest valid length; section note "Some hours unavailable" if < 24 hourly entries. | Never pad with fabricated values. |
| FM-18 | Extreme/invalid coordinates | Lat/lon outside ±90/±180 (e.g. corrupted recents entry) | Entry dropped; recents list skips it; forecast request never fires with invalid coords. | Corrupt recents entries purged on load. |
| FM-19 | App killed / restarted mid-request | Process death | On relaunch: normal cold start; no half-written cache (cache writes are atomic — write temp file then rename). | No crash loops: no state restored from partial writes. |
| FM-20 | Rapid unit/location toggling | User spams toggles | Last toggle wins; in-flight forecast requests cancelled; UI consistent within 500 ms of last toggle. | Debounce toggle side-effects 300 ms. |

**Global invariants (test-enforced):** no blank screens; no unhandled exceptions from any FM; no fabricated data (missing = "—" or explicit note); no more than the §8.3 retry budget per user action; no PII/coordinates in logs.

---

## 12. Definition of Done

The feature is **done** when ALL of the following hold on release builds for Android and iOS:

1. **Stories:** every acceptance criterion in §5 (US-1…US-13) passes on both platforms, verified by the QA checklist attached to the release PR.
2. **Validation:** unit tests cover every row of §7.2 and §7.3 (valid + violation paths); malformed-payload and unknown-fields tests pass; zero `!`/unchecked casts on network data (static review).
3. **Failure modes:** widget tests exist for FM-1…FM-20; each shows the specified headline and action; global invariants hold.
4. **Rate limits:** automated tests assert 300 ms debounce, 2-char minimum, cache TTLs (10 min fresh / 60 s search), in-flight dedupe, and the §8.3 retry budget.
5. **Privacy:** automated test asserts no device coordinates in persistent storage after a location session; privacy notice reviewed for plain language; consent dialog appears before any OS prompt (manual test).
6. **Performance:** all §10.1 budgets met on reference devices, measured on release builds, numbers recorded in the release notes.
7. **Accessibility:** WCAG 2.1 AA audit (§10.4) completed on one Android + one iOS device with TalkBack/VoiceOver; all 7 checklist items signed off.
8. **Quality bar:** crash-free sessions ≥ 99.5% in a 7-day staged rollout (internal + 10% production) before full rollout; zero P0/P1 bugs open.
9. **Hygiene:** no secrets/keys in repo or binary (secret scan in CI green); "Weather data by Open-Meteo.com" attribution present; app size within §10.1 budgets; version pinned Flutter + dependency list recorded.
10. **Docs:** this PRD version frozen to the release tag; known limitations (v1 non-goals, §3) listed in the release notes.

**Explicitly not done:** "it works on my phone," untested edge cases, silent data staleness, or any criterion hand-waved as "works well."

---

## 13. Open Questions (resolve before War Room build kickoff)

1. **Wind/pressure units in °F mode:** convert to mph/inHg, or keep km/h/hPa with labels? (PO recommendation: convert fully — mixed units confuse; needs 1-line decision.)
2. **Reference devices:** confirm the team's physical test devices match §10.1 classes.
3. **Crash reporting tool:** which crash-reporting SDK (must be crash-only, no behavioral analytics) — engineering proposes, PO approves against §9 privacy rules.
4. **Day-detail:** tap-a-day expands inline vs. does nothing (§US-6 AC2 allows either; decide for consistent UX).

## 14. Risks

- Open-Meteo is a free service with no SLA: FM-2/FM-6 handling and honest staleness labeling are load-bearing, not nice-to-haves.
- Geocoding ambiguity for non-Latin scripts: v1 uses `language=en`; non-English queries may return poor results — accepted limitation, revisit post-v1.
- OS location-permission flows differ by version: manual test matrix must cover Android 13+ and iOS 16+ permission variants.

---

## Appendix A — WMO Weather Code Mapping

| Code | Label | Code | Label |
|---|---|---|---|
| 0 | Clear sky | 56 | Freezing drizzle, light |
| 1 | Mainly clear | 57 | Freezing drizzle, dense |
| 2 | Partly cloudy | 61 | Rain, slight |
| 3 | Overcast | 63 | Rain, moderate |
| 45 | Fog | 65 | Rain, heavy |
| 48 | Depositing rime fog | 66 | Freezing rain, light |
| 51 | Drizzle, light | 67 | Freezing rain, heavy |
| 53 | Drizzle, moderate | 71 | Snow, slight |
| 55 | Drizzle, dense | 73 | Snow, moderate |
| 77 | Snow grains | 75 | Snow, heavy |
| 80 | Rain showers, slight | 85 | Snow showers, slight |
| 81 | Rain showers, moderate | 86 | Snow showers, heavy |
| 82 | Rain showers, violent | 95 | Thunderstorm |
| 96 | Thunderstorm, slight hail | 99 | Thunderstorm, heavy hail |

Any code not in this table → "Unknown conditions" + neutral icon (§US-7 AC1, FM-13).

## Appendix B — Traceability

Hard requirements → PRD sections: live telemetry → §5 (US-1…US-6), §7.1–7.2 · zero-trust API handling → §7 · rate limiting → §8 · GDPR geolocation → §9, §US-3, §US-11 · no secrets → §9.6, §12.9.

---

*End of PRD v1.0 — Product Owner, Product & UX Division. Submitted for War Room intake.*
