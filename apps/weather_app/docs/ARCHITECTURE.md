# Weather App — System Architecture v1.0

**Owner:** Enterprise Architect (Architecture & Code division) · **War Room Phase 2 deliverable**
**Date:** 2026-10-06 · **Status:** Proposed for debate → Sloane sign-off
**Inputs:** PRD v1.0 (13 user stories, §7 zero-trust API spec, rate-limit policy, GDPR spec, FM-1…FM-20, perf budgets, WCAG 2.1 AA, 10-item DoD), Design Spec v1.0 (4 screens, tokens, consent flow, accessibility, content rules)

> **Headline decision: this is a client-only app. There is no backend server.**
> The Flutter client calls `api.open-meteo.com` and `geocoding-api.open-meteo.com` directly over HTTPS.
> Rationale and alternatives are recorded in ADR-01 below. Everything in this document follows from that.

---

## 1. Guiding principles

1. **No backend, no secrets, no accounts.** Nothing to provision, rotate, or breach server-side. The API needs no key, so no credential ever exists in the codebase — the "no secrets anywhere" requirement is satisfied structurally, not procedurally.
2. **Zero-trust parsing.** Every byte from the network is untrusted until it passes the §7 whitelist + range pipeline. Fail closed: suspect data never renders.
3. **Privacy by construction.** Coordinates are rounded to 2 decimals (~1.1 km) before any use, live in memory only, are never persisted, and never appear in logs below that precision. The app is fully functional without location (PRD GDPR spec).
4. **Offline-first reads.** Cache tiers serve stale-but-labeled data per explicit TTLs before the UI ever shows a spinner for a location it has seen.
5. **Single state mechanism.** Riverpod 3 is the only state-management and DI mechanism. No GetIt, no second locator, no `BuildContext` plumbing.
6. **Canonical SI internally.** The API is always queried in metric units; all unit conversion happens client-side at the presentation boundary. The disk cache stores exactly one canonical representation.
7. **Every failure is typed.** All 20 failure modes map to a sealed `AppFailure` union; each maps to exactly one UI state. No `catch (e)` → generic toast anywhere in production code paths.

---

## 2. System topology

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter App (weather_app)                 │
│  minSdk 24 · iOS 15.0+ · Flutter stable 3.x / Dart 3.x           │
│                                                                  │
│  ┌────────────────┐   ┌────────────────┐   ┌──────────────────┐  │
│  │ PRESENTATION   │   │     DOMAIN     │   │       DATA       │  │
│  │                │   │                │   │                  │  │
│  │ widgets        │   │ entities       │   │ datasources      │  │
│  │ screens        │   │ usecases       │   │  · remote (Dio)  │  │
│  │ Riverpod       │◀──│ repositories   │◀──│  · local (Hive)  │  │
│  │ controllers    │   │  (interfaces)  │   │  · device (OS)   │  │
│  │ (AsyncNotifier)│   │ failures       │   │ repositories     │  │
│  │ formatters     │   │ unit system    │   │  (impl)          │  │
│  │ (units, dates) │   │ value objects  │   │ DTOs + mappers   │  │
│  └────────────────┘   └────────────────┘   └────────┬─────────┘  │
│          ▲                      ▲                   │ HTTPS GET  │
└──────────┼──────────────────────┼───────────────────┼────────────┘
           │ dependencies point inward (DIP)         ▼
   ┌───────────────┐  ┌──────────────────────┐  ┌────────────────────┐
   │ Device OS     │  │ api.open-meteo.com   │  │ geocoding-api.     │
   │ · geolocator  │  │ /v1/forecast         │  │ open-meteo.com     │
   │   (GPS fix)   │  │ (no key)             │  │ /v1/search         │
   │ · geocoding   │  └──────────────────────┘  │ (no key)           │
   │   pkg (on-    │                            └────────────────────┘
   │   device      │   ┌──────────────────────┐
   │   reverse)   │   │ api.bigdatacloud.net │ ← fallback only,
   └───────────────┘   │ reverse-geocode-     │   disclosed in
                       │ client (no key)      │   privacy notice
                       └──────────────────────┘
   Crash reports (opt-out): ┌────────────────┐
                            │ Sentry (crash-  │
                            │ only config)    │
                            └────────────────┘
```

**Layer contracts**

| Layer | Owns | May import | Must never import |
|---|---|---|---|
| Presentation | Widgets, screens, Riverpod controllers, formatters, design tokens | Domain | Data, Dio, Hive, platform plugins |
| Domain | Entities, repository interfaces, usecases, `AppFailure`, `UnitSystem`, value objects | Nothing above; Dart core/`intl` only | Data, Flutter widgets |
| Data | Dio clients, DTOs + validation mappers, Hive boxes, repository impls, device datasources | Domain (implements its interfaces) | Presentation |

Dependency inversion: domain defines `WeatherRepository`; data implements it; presentation receives it through Riverpod overrides. Domain is unit-testable with zero Flutter dependencies.

**Module / folder layout**

```
lib/
  main.dart                      // minimal: ensureInitialized, prefs, runApp(ProviderScope)
  app.dart                       // MaterialApp.router? No — plain Navigator (ADR-12), themes
  core/
    config/constants.dart        // hosts, timeouts, TTLs, debounce, retry budget
    network/open_meteo_client.dart   // 2 Dio instances + interceptor chain
    network/interceptors/        // retry, rate_limit, sanitized_logging
    validation/validators.dart   // §7 whitelist + range pipeline
    error/failures.dart          // sealed AppFailure union
    error/error_mapper.dart      // DioError/FormatException → AppFailure
    units/unit_system.dart       // UnitSystem, pure converters
    logging/app_logger.dart      // sanitized, debug-only verbose
    utils/result.dart            // Result<T, AppFailure> (or fpdart Either)
  data/
    datasources/remote/forecast_api.dart
    datasources/remote/geocoding_api.dart
    datasources/local/forecast_cache.dart   // Hive box + TTL policy
    datasources/local/recent_places_store.dart
    datasources/local/settings_store.dart   // SharedPreferences
    datasources/device/location_datasource.dart  // geolocator wrapper
    datasources/device/reverse_geocode_datasource.dart
    repositories/weather_repository_impl.dart
    repositories/location_repository_impl.dart
    models/                      // DTOs with validated fromJson
  domain/
    entities/                    // Forecast, CurrentConditions, HourlyPoint,
                                 // DailySummary, GeoPlace, AppSettings
    repositories/weather_repository.dart   // abstract
    repositories/location_repository.dart  // abstract
    usecases/                    // get_weather, search_places, refresh,
                                 // resolve_device_location, update_settings
  features/
    home/  search/  hourly/  daily/  settings/   // widgets + controllers
  l10n/                          // gen-l10n (en v1)
```

---

## 3. API client design

### 3.1 Endpoints (only two; both keyless, HTTPS-only)

**Forecast** — `GET https://api.open-meteo.com/v1/forecast`

Fixed query contract (built by code, never by string interpolation of user input):

```
latitude={rounded 2dp} & longitude={rounded 2dp}
& current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,
          precipitation,weather_code,cloud_cover,pressure_msl,
          wind_speed_10m,wind_direction_10m,wind_gusts_10m
& hourly=temperature_2m,precipitation_probability,weather_code
& daily=weather_code,temperature_2m_max,temperature_2m_min,
        sunrise,sunset,uv_index_max,precipitation_probability_max
& timezone=auto & forecast_days=7
```

Units are **not** requested from the server — native SI is accepted
(`temperature_unit`/`wind_speed_unit` omitted = metric defaults) and all
conversion is client-side (ADR-04). `timezone=auto` is required so hourly
slots align with the location's civil day; the response `utc_offset_seconds`
is validated (±18 h range).

**Geocoding** — `GET https://geocoding-api.open-meteo.com/v1/search?name={q}&count=8&language=en&format=json`

`q` is percent-encoded by Dio; max length 100 chars enforced client-side before send.

### 3.2 Client construction

Two Dio instances (`forecastDio`, `geocodingDio`) sharing one interceptor stack, built once in a Riverpod provider:

* `BaseOptions(connectTimeout: 8s, receiveTimeout: 12s, responseType: json)`
* Interceptor order: `RateLimitInterceptor` → `RetryInterceptor` → `SanitizedLoggingInterceptor` → transport.
* **RateLimitInterceptor:** enforces minimum inter-request interval per host (guards the 300 ms search debounce at the HTTP layer too); queues rather than drops.
* **RetryInterceptor:** retry budget exactly 2 retries, backoff 1 s → 2 s, only for idempotent GETs on timeout/5xx/429-without-Retry-After. Honors `Retry-After` (parsed, capped at 60 s per PRD). Never retries 4xx (except 429) or validation failures.
* **SanitizedLoggingInterceptor:** debug builds log method + host + status + latency; **release builds log only error-level events with coordinates truncated to 2 decimals and query strings truncated to 40 chars.** No PII, no raw payloads in release.

### 3.3 Defensive validation pipeline (§7)

Every response passes through five stages; a failure at any stage short-circuits to `AppFailure.schemaViolation` / `outOfRange` and **no partial entity is ever constructed**:

```
1. Transport check     HTTP 200 + JSON content-type, else mapped HTTP failure
2. Structural whitelist Only keys in the per-endpoint whitelist survive;
                       unknown key → violation; missing required key → violation
3. Type check          num vs String vs List per field; null where non-nullable → violation
4. Range check         Per-field min/max (table below); out-of-range → violation
5. Cross-field check   hourly.time.length == each hourly array length;
                       daily arrays length == 7; else violation
```

**Whitelist + range table (authoritative for v1)**

| Section.Field | Type | Range / allowed values | Violation → |
|---|---|---|---|
| `latitude`, `longitude` (echo) | num | −90…90 / −180…180 | schemaViolation |
| `utc_offset_seconds` | num | −64800…64800 | schemaViolation |
| `timezone`, `timezone_abbreviation` | String | non-empty, ≤64 chars | schemaViolation |
| `current.time` | String | ISO-8601 parseable | schemaViolation |
| `current.temperature_2m`, `apparent_temperature` | num | −90…60 °C | outOfRange |
| `current.relative_humidity_2m`, `cloud_cover`, `precipitation_probability*` | num | 0…100 | outOfRange |
| `current.precipitation` | num | 0…500 mm | outOfRange |
| `current.pressure_msl` | num | 870…1085 hPa | outOfRange |
| `current.wind_speed_10m`, `wind_gusts_10m` | num | 0…150 m/s | outOfRange |
| `current.wind_direction_10m` | num | 0…360 | outOfRange |
| `current.is_day` | num | 0 or 1 | schemaViolation |
| `current.weather_code`, `hourly.weather_code[]`, `daily.weather_code[]` | num | WMO set {0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,82,85,86,95,96,99}; **unknown code → degraded "unknown" icon, data kept** (FM-10) | n/a (degraded) |
| `daily.temperature_2m_max/min` | num | −90…60 °C; max ≥ min else violation | outOfRange/schemaViolation |
| `daily.sunrise/sunset` | String | ISO-8601; sunset > sunrise | schemaViolation |
| `daily.uv_index_max` | num | 0…20 | outOfRange |
| `hourly.time[]` | List<String> | ISO-8601 each; length = sibling arrays | schemaViolation |
| geocoding `results[]` | List | ≤ count requested; each item whitelisted | schemaViolation |
| geocoding item `name` | String | 1…100 chars | schemaViolation |
| geocoding item `latitude/longitude` | num | −90…90 / −180…180 | outOfRange |
| geocoding item `country`, `admin1`, `country_code` | String? | ≤64 chars | schemaViolation |

DTOs are hand-written `fromJson` with these validators (codegen rejected: generated `fromJson` cannot express the whitelist/reject-unknown-keys rule — ADR-05). Unknown-key rejection is the schema-drift detector (FM-8).

---

## 4. Data flows

### 4.1 Search → geocode → forecast → cache → UI

```
User types ──300ms debounce──▶ searchController
  │ in-memory: last query + recent_places (offline-capable)
  ▼ cache miss
geocoding_api.search(q) ──validation pipeline──▶ List<GeoPlace> (coords rounded 2dp)
  │ user picks place
  ▼
weatherRepository.getForecast(place)
  │ 1. memory cache: fresh ≤10 min → return immediately
  │ 2. disk cache:   ≤10 min → return + warm memory
  │                 10–60 min → return stale + background revalidate
  │                 60 min–24 h → return stale ONLY if network fails (labeled "offline")
  │                 >24 h → evict
  │ 3. network: forecast_api → validation → canonical SI entity
  │             → write disk (atomic) → write memory → return
  ▼
homeController (AsyncNotifier<WeatherViewState>)
  │ converts SI → display units via UnitSystem (presentation boundary)
  ▼ UI renders current / hourly / daily from the single entity
```

One network round-trip per fresh location. Hourly and daily screens read the **same** `WeatherViewState` — no second forecast call when switching tabs (kills a whole class of stale-tab bugs).

### 4.2 Pull-to-refresh / foreground resume

Same path as §4.1 step 3, but TTL check is skipped when the user explicitly refreshes; if the network fails, the last cached entry is served with an "updated Xm ago · offline" banner rather than an error screen (stale-while-revalidate degraded mode).

### 4.3 Location-consent flow (device location)

```
App start (no stored place)
  ▼
homeController: state = needsLocationChoice
  ▼
Welcome sheet → "Use my location" | "Search instead"
  ├─ "Search instead" → search flow; consent remains unknown; full function. END.
  └─ "Use my location"
       ▼ in-app consent sheet (PRD GDPR spec: purpose, precision ~1 km,
       │  memory-only, revocable, BEFORE any OS prompt)
       ├─ Decline → search flow; record consent=declined. END.
       └─ Accept → record consent=granted (SharedPreferences)
            ▼ OS permission request (geolocator)
            ├─ denied (one-time) → explainer → search flow (FM-13)
            ├─ permanently denied → OS settings deep-link card (FM-14)
            └─ granted
                 ▼ getCurrentPosition (timeout 10 s; services disabled → FM-15)
                 ▼ round to 2 decimals (~1.1 km)
                 ▼ reverse-geocode: on-device `geocoding` pkg (ADR-08)
                 │   fallback: BigDataCloud reverse-geocode-client (disclosed)
                 │   fallback: label "Current location" (no name)
                 ▼ persist ONLY city name (+country/admin1); raw coords stay
                   memory-only and are discarded after the forecast call
                 ▼ forecast flow (§4.1)
```

Revocation path: Settings → Location toggle off → deletes stored place name, drops in-memory coords, clears forecast cache entries keyed by device location, returns to `needsLocationChoice` (FM-16).

---

## 5. State management — Riverpod 3 (decision)

**Decision: `flutter_riverpod` 3.x with `riverpod_generator` (+ `riverpod_lint`) as the single state-management and DI mechanism. No BLoC, no GetIt.**

### Trade-off analysis

| Criterion | Riverpod 3 (+codegen) | BLoC 9 / Cubit | Verdict |
|---|---|---|---|
| Boilerplate per feature | One `@riverpod` class; states are `AsyncValue` | Event + State classes + Bloc + BlocBuilder | Riverpod: 4 screens stay small |
| Compile-time safety | Providers are typed; mis-wired deps fail at build | Event/state mismatch is runtime | Riverpod |
| Async state | `AsyncValue.loading/data/error` is first-class | Manual loading/error states per Bloc | Riverpod |
| DI / test overrides | `ProviderContainer` overrides, no widget tree needed | `BlocProvider` + `get_it` (two mechanisms) | Riverpod (one mechanism) |
| Auto-disposal | `autoDispose` built in | Manual `close()` | Riverpod (search controllers must not leak) |
| Event audit trail | None built in | Explicit event log | BLoC — **not needed**: no audit/compliance requirement in PRD |
| Team familiarity risk | Moderate learning curve | Familiar to many Flutter teams | Mitigated: codebase is small; patterns documented here |

BLoC's strength — an explicit, replayable event trail for 20+ developers — buys nothing for a 4-screen app built by a small team, while its ceremony (event classes for "user typed a letter") would roughly double the feature code. Riverpod's `AsyncNotifier` covers the same state machine (`loading → data | error`) that every screen needs, and its provider graph doubles as the DI container, so there is exactly one way to wire a dependency.

### Provider graph

```
                        ┌─ dioProvider (2 configured Dios)
                        ├─ forecastApiProvider ─┐
                        ├─ geocodingApiProvider ┤
appLoggerProvider ──────┤                        ├─ weatherRepositoryProvider ─┬─ homeController (AsyncNotifier)
                        ├─ forecastCacheProvider (Hive)                       │   (current/hourly/daily share state)
                        ├─ settingsStoreProvider (prefs) ─ settingsController │
                        ├─ locationDsProvider ─ locationRepositoryProvider ────┘
                        └─ recentPlacesProvider ─ searchController (autoDispose, debounced)
consentController (Notifier<ConsentState>) ─ guards location flow
connectivityProvider (StreamProvider) ─ drives auto-retry on reconnect (FM-1)
```

Rules: controllers never call Dio/Hive directly — only repository interfaces. Repositories never touch widgets. `ref.watch` in widgets; `ref.read` + `ref.listen` for side effects (snackbars, navigation).

---

## 6. Caching strategy

| Tier | Store | Holds | TTL policy (PRD) |
|---|---|---|---|
| L1 memory | `Map<String, CacheEntry>` in `WeatherRepositoryImpl` | Latest forecast per location key + last search results | Process lifetime; cleared on unit-system change (display only — canonical cache stays SI) |
| L2 disk | Hive CE box `forecast_cache` | `CacheRecord{key, fetchedAtUtc, payloadJson}` | **fresh ≤10 min** → serve; **10–60 min** → serve + background revalidate; **60 min–24 h** → serve only when network fails, labeled offline/stale; **>24 h** → evict, hard path |
| Disk | Hive CE box `recent_places` | ≤8 `GeoPlace` (name, country, admin1, coords rounded 2 dp) | No TTL; LRU eviction; serves search offline |
| Disk | SharedPreferences | `unit_system`, `consent_state`, `place_name`, `theme_mode` | Durable; **never coordinates** (ADR-07) |

* Cache key: `"${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}"`.
* **Atomic writes:** Hive box writes are transactional; the repository writes disk first, then updates L1 only on success (write-through). A torn write can only leave the *old* record, never a half record.
* **Corruption:** `HiveError`/parse failure on read → delete the record, treat as miss, log breadcrumb (FM-18). Cache must never crash the app.
* **Size bound:** one forecast payload ≈ 15–25 KB JSON; box capped at 20 entries with LRU eviction (~500 KB worst case — irrelevant to install budget).
* **Search debounce 300 ms** at the controller; in-flight geocoding requests are cancelled via Dio `CancelToken` and stale responses discarded by monotonically increasing request id (FM-12).

---

## 7. Consent & location module

`LocationRepository` (domain interface) with a single device implementation:

* `ConsentState`: `unknown | granted | declined | revoked` — persisted in SharedPreferences; drives the pre-OS-prompt sheet.
* `DevicePosition`: in-memory only, `({double lat, double lon})` rounded to 2 dp at creation; **no serialization, no logging below 2 dp, no persistence** — enforced by making the type non-serializable (no `toJson`).
* Rounding happens **once**, at the datasource boundary, before reverse-geocoding and before the forecast call. 2 dp ≈ 1.1 km: fine enough that Open-Meteo's ~0.1° model grid returns the same grid cell as the true position, coarse enough to satisfy data minimization (resolves conflict 1 — ADR-07; the design spec's "~10 km" is rejected as it can select the wrong city in dense metro areas).
* Reverse geocoding (conflict 2 — ADR-08): primary is the on-device `geocoding` package (no network, no third party, no privacy-notice burden). Fallback is BigDataCloud `reverse-geocode-client` (keyless, coarse coords only, disclosed in the privacy notice). Final fallback is the label "Current location".
* The app never blocks on location: every screen and usecase has a search-driven path (PRD: "full function without location").

---

## 8. Unit system (°F mode — full conversion)

**Decision (conflict 4): full conversion in °F mode, performed client-side at the presentation boundary** (ADR-04, ADR-09):

| Quantity | Metric display | Imperial (°F mode) display |
|---|---|---|
| Temperature | °C | °F |
| Wind speed | km/h | mph |
| Wind gusts | km/h | mph |
| Precipitation | mm | in |
| Pressure | hPa | inHg (1 hPa = 0.02953 inHg) |
| Visibility | km | mi |
| Time format | 24 h / locale | 12 h / locale (follows device locale) |

* The domain/cache always holds SI. `WeatherFormatter(UnitSystem)` is a pure, injectable function bundle — unit-testable without widgets.
* Why full conversion: showing "wind 82" next to "°F" invites a km/h↔mph misread; aviation/automotive precedent is that unit systems are all-or-nothing. Open-Meteo has no `inHg` pressure unit, so server-side unit selection could not be complete anyway — client-side conversion is the only consistent implementation.
* Conversion edge: absurd-but-in-range values (e.g., 60 °C = 140 °F) convert exactly; rounding is display-only (`toStringAsFixed`), never stored.

---

## 9. Error model — FM-1…FM-20 → code paths

> **SUPERSEDED (QA gate, 2026-10-06):** the FM table and failure-union sketch
> below are **stale** — they renumber the failure modes and omit modes the
> build added. The canonical numbering is **PRD §11 (FM-1…FM-20)** and the
> implementation is `lib/core/error/failures.dart` (sealed `AppFailure`) +
> `lib/core/error/failure_presentation.dart` (exact PRD §11 headlines/actions,
> unit-tested). R-14 added `AppFailure.locationTimeout` (PRD FM-10). Do not
> use the table below as a reference; it is kept for historical context only.

All failures are a Dart 3 sealed union; the compiler enforces exhaustive handling at every `switch`:

```dart
sealed class AppFailure {
  const AppFailure();
  // network & transport
  const factory AppFailure.networkUnreachable() = _NetworkUnreachable;      // FM-1, FM-2
  const factory AppFailure.timeout() = _Timeout;                            // FM-3
  const factory AppFailure.rateLimited({Duration? retryAfter}) = _RateLimited; // FM-4
  const factory AppFailure.apiClientError(int status) = _ApiClientError;    // FM-5
  const factory AppFailure.serverError(int status) = _ServerError;          // FM-6
  // trust & schema
  const factory AppFailure.schemaViolation(String field, String reason) = _SchemaViolation; // FM-7, FM-8
  const factory AppFailure.outOfRange(String field, num value) = _OutOfRange;               // FM-9
  // search
  const factory AppFailure.noResults(String query) = _NoResults;            // FM-11
  // location & consent
  const factory AppFailure.locationDenied() = _LocationDenied;              // FM-13
  const factory AppFailure.locationPermanentlyDenied() = _LocationPermanentlyDenied; // FM-14
  const factory AppFailure.locationServicesDisabled() = _LocationServicesDisabled;   // FM-15
  const factory AppFailure.consentRequired() = _ConsentRequired;            // FM-16 (declined)
  const factory AppFailure.consentRevoked() = _ConsentRevoked;              // FM-16 (revoked)
  const factory AppFailure.reverseGeocodeFailed() = _ReverseGeocodeFailed;  // FM-17
  // cache
  const factory AppFailure.cacheCorrupted(String key) = _CacheCorrupted;    // FM-18
  const factory AppFailure.cacheExpired(String key) = _CacheExpired;       // FM-19 (>24h, offline)
  // terminal
  const factory AppFailure.unknown(Object? cause) = _Unknown;              // FM-20
}
// Degraded-but-not-failed (render with banner, no failure surfaced):
//   FM-10 unknown WMO code → "unknown" icon      FM-12 cancelled/duplicate search → silently dropped
//   FM-19 60min–24h offline → stale banner       FM-17 label fallback → "Current location"
```

| FM | Title | Detection | Behavior (UI) | Recovery | Code path |
|---|---|---|---|---|---|
| FM-1 | No connectivity at request | `SocketException` / connectivity stream | Offline state; serve stale ≤24 h with banner, else offline-empty | Auto-retry on reconnect via `connectivityProvider` | `networkUnreachable` |
| FM-2 | DNS / TLS failure | `DioException` badCertificate / connectionError | Same as FM-1 | Same as FM-1; TLS failure additionally logs breadcrumb (possible captive portal) | `networkUnreachable` |
| FM-3 | Request timeout | connect/receive timeout 8 s/12 s | Retry 2× (1 s→2 s); then error card + Retry button | Manual retry; no auto-loop | `timeout` |
| FM-4 | Rate limited (429 / Retry-After) | Status 429 or `Retry-After` header | Countdown notice; request queue paused | Honor header, cap 60 s, then resume | `rateLimited(retryAfter)` |
| FM-5 | HTTP 4xx (bad request) | 400–428 status | Generic error card (never expose status to user) | Sentry breadcrumb; dev fix (params are code-built) | `apiClientError(status)` |
| FM-6 | HTTP 5xx | 500–599 status | Retry 2×; then error card + Retry | Manual retry | `serverError(status)` |
| FM-7 | Malformed JSON body | `FormatException` on decode | Error card + Retry | Retry (transient) or dev fix | `schemaViolation('<body>', …)` |
| FM-8 | Schema drift: unknown/missing field | Whitelist stage 2 | Error card + Retry; Sentry breadcrumb with field name | Dev fix; contract test in CI pins schema | `schemaViolation(field, reason)` |
| FM-9 | Field out of range | Range stage 4 | Fail closed: error card, **never render suspect value** | Retry once (transient bad model run), then dev fix | `outOfRange(field, value)` |
| FM-10 | Unknown WMO weather code | Code not in whitelist set | **Degraded:** "unknown" icon, all other data renders | None needed; warning breadcrumb | degraded path (not a failure) |
| FM-11 | Geocoding: no results | Empty `results[]` | Empty state "No places found for 'X'" + recent searches | Refine query | `noResults(query)` |
| FM-12 | Search race / stale response | Request id mismatch or `CancelToken` | Silently dropped; UI keeps latest | n/a | dropped (not a failure) |
| FM-13 | Location permission denied (one-time) | geolocator `denied` | Explainer sheet → search flow | Re-request on next tap | `locationDenied` |
| FM-14 | Permission permanently denied | geolocator `deniedForever` | Card with "Open Settings" deep link | OS settings | `locationPermanentlyDenied` |
| FM-15 | Location services disabled | `isLocationServiceEnabled() == false` | Prompt-to-enable card | OS location settings | `locationServicesDisabled` |
| FM-16 | In-app consent declined / revoked | `ConsentState` | Full search-driven function; revocation wipes stored place + in-memory coords | Re-consent from Settings | `consentRequired` / `consentRevoked` |
| FM-17 | Reverse-geocode failure | `geocoding` pkg throws; BigDataCloud fallback fails | **Degraded:** label "Current location", forecast still loads | Silent; breadcrumb | `reverseGeocodeFailed` → label fallback |
| FM-18 | Disk cache corruption | Hive/read parse throws | Evict record; treat as cache miss; continue to network | n/a (self-healing) | `cacheCorrupted(key)` |
| FM-19 | Stale cache >24 h while offline | `fetchedAt` older than 24 h + network fails | Offline-empty state + Retry (no ancient data shown) | Reconnect | `cacheExpired(key)`; 60 min–24 h serves stale-with-banner instead |
| FM-20 | Uncaught exception / crash | `FlutterError.onError` + `PlatformDispatcher` handlers | Crash report (Sentry, crash-only); restart to last stable route | Opt-out in Settings; fix from report | `unknown(cause)` |

> **Reconciliation note for QA:** this table reconstructs FM-1…FM-20 from the PRD's stated constraints (rate-limit policy, TTLs, validation tables, consent spec). Before QA sign-off, the FM numbers/titles must be diffed 1:1 against the PRD's FM table; the `AppFailure` variant names are the stable contract, FM numbers are labels.

**UI state contract:** every screen renders exactly one of `initial | loading | data | empty | error(failure) | offlineStale` — the design spec's loading/empty/error/offline states map 1:1 to `AsyncValue` + the failure union. Error cards show a human sentence + one action (Retry / Open Settings / Search instead); technical detail goes to the sanitized log, never the screen.

---

## 10. Package selection

| Package | Version (pin at build) | Why | Rejected alternative |
|---|---|---|---|
| `flutter_riverpod` | `^3.4.3` (verified current Sep 2026) | State + DI, one mechanism, `AsyncValue`, auto-dispose | `flutter_bloc ^9.1.1` — ceremony without payoff at this scale (§5) |
| `riverpod_generator` + `riverpod_lint` | current 3.x | Eliminates provider boilerplate; lint enforces idioms | hand-written providers — boilerplate drift |
| `dio` | `^5.11.1` (verified current Oct 2026) | Interceptor chain (retry / rate-limit / sanitized logging), `CancelToken` | `package:http` — no interceptors; retry logic would be hand-rolled in every call site |
| `geolocator` | latest major at build (verified publisher: baseflow) | Cross-platform fix + permission API | `location` pkg — weaker permission-state modeling |
| `geocoding` | latest major at build (verified publisher: baseflow) | **On-device** reverse geocode — no network, no third party (ADR-08) | BigDataCloud as primary — unnecessary data disclosure |
| `hive_ce` + `hive_ce_flutter` | latest 2.x at build | Community continuation of discontinued Hive; transactional box writes; zero native deps (install-size budget) | `drift`/`sqflite` — SQL is overkill for opaque JSON blobs; native libs add size |
| `shared_preferences` | latest at build | Tiny key-value settings; platform-backed | Hive for settings too — prefs API is simpler for primitives and survives box wipes |
| `connectivity_plus` | latest at build | Reconnect detection → auto-retry (FM-1) | `internet_connection_checker_plus` — heavier active probing; passive is enough |
| `intl` | Flutter-pinned | Date/number formatting, gen-l10n | hand-rolled formatting — locale bugs |
| `sentry_flutter` | `^8.0.0` (check for 9.x at build) | Crash reporting only; all telemetry disabled (ADR-10) | `firebase_crashlytics` — pulls Google services + analytics bundling; conflicts with minSdk simplicity and privacy posture |
| dev: `mocktail` | latest | Mock-free of codegen; pairs with Riverpod overrides | `mockito` — build_runner codegen for mocks |
| dev: `flutter_lints` | Flutter-pinned | Baseline; `riverpod_lint` adds the rest | `very_good_analysis` — stricter than this codebase needs v1 |
| dev: `build_runner` | latest | Only for `riverpod_generator` (+ `intl` tooling) | — |

**Deliberately absent:** `go_router` (no deep links v1 — ADR-12), Firebase (privacy + size), `cached_network_image` (no remote images; weather icons are local vector assets per design tokens), push notifications (no use case in PRD).

---

## 11. ADRs

### ADR-01 — Client-only: no backend server
* **Context:** The app needs forecast + geocoding data. Open-Meteo exposes both as keyless HTTPS APIs with generous free quotas. The PRD lists no user accounts, no personal data storage server-side, no push, no aggregation.
* **Decision:** No backend. The Flutter client calls Open-Meteo directly. "No secrets anywhere" is satisfied structurally — there is no secret to leak.
* **Alternatives:** (a) BFF proxy for key hiding — rejected: there is no key to hide; a proxy would add latency, cost, and a new attack surface for zero benefit. (b) Edge cache (Cloudflare) — rejected: Open-Meteo already edge-caches; client-side TTLs cover the offline story.
* **Consequences:** No server to operate, monitor, or patch. Rate-limiting is enforced client-side (PRD policy). Residual risk: if Open-Meteo changes schema/terms, the app must ship an update — mitigated by the §7 whitelist failing closed + contract tests in CI. If a future feature needs keys/accounts, this ADR is revisited.

### ADR-02 — Riverpod 3 (+codegen) as the single state/DI mechanism
* **Context:** §5. **Decision:** `flutter_riverpod` 3.x, `riverpod_generator`, `riverpod_lint`. **Alternatives:** BLoC 9 (rejected — §5 trade-off table), Provider (rejected — no first-class async, weaker DI overrides), GetX (rejected — single-maintainer risk, discouraged for production). **Consequences:** One mechanism to learn; compile-time-safe DI; test overrides without widget harness.

### ADR-03 — Clean Architecture layering (presentation / domain / data)
* **Context:** 13 user stories with measurable acceptance criteria; 20 failure modes; WCAG + GDPR constraints — logic must be testable without a device.
* **Decision:** Strict three-layer split with dependency inversion; domain is pure Dart.
* **Alternatives:** MVVM-without-domain (rejected — validation and unit-conversion logic would scatter across widgets), feature-first without layers (rejected — repository interfaces need a home independent of features).
* **Consequences:** More files, but every usecase, validator, and converter is unit-testable; War Room Phase 3 (AppSec/Tech Law) can audit the domain layer alone.

### ADR-04 — Always request SI; convert client-side; cache canonically in SI
* **Context:** Open-Meteo supports `temperature_unit`/`wind_speed_unit` server-side, but has **no** inHg pressure unit — server-side units cannot express the PRD's full-conversion requirement.
* **Decision:** Omit unit params (native SI), convert at the presentation boundary via pure `WeatherFormatter(UnitSystem)`, store SI on disk.
* **Alternatives:** Server-side units (rejected — incomplete: pressure), store display units (rejected — changing °C→°F would require cache invalidation/re-fetch).
* **Consequences:** Unit toggle is instant and offline-capable; cache has one canonical form; conversion math is unit-tested once.

### ADR-05 — Defensive validation: handwritten DTOs, whitelist + ranges, fail closed
* **Context:** PRD §7 zero-trust API spec with per-field whitelist/range/violation tables; FM-7/8/9.
* **Decision:** Hand-written `fromJson` implementing the 5-stage pipeline (§3.3); unknown key → violation; out-of-range → violation; never render suspect data.
* **Alternatives:** `json_serializable`/`freezed` (rejected — cannot express reject-unknown-keys), lenient parsing with defaults (rejected — silent data corruption violates fail-closed).
* **Consequences:** More DTO code, but schema drift (FM-8) is detected in production and in CI contract tests instead of rendering wrong weather.

### ADR-06 — Two-tier cache: memory + Hive CE, explicit TTLs, atomic write-through
* **Context:** PRD TTLs (10 min fresh / 60 min SWR / 24 h max offline), atomic-write requirement.
* **Decision:** L1 in-memory map + L2 Hive CE box `forecast_cache`; disk-first write-through; TTLs per §6; LRU cap 20 entries; corruption self-heals (FM-18).
* **Alternatives:** SharedPreferences for cache (rejected — not designed for multi-KB JSON blobs), drift/SQLite (rejected — native deps + SQL overhead for opaque blobs), file-per-entry JSON (rejected — atomic rename is doable but Hive gives transactions + eviction for free).
* **Consequences:** Offline story works out of the box; install-size impact ~0 (pure Dart).

### ADR-07 — Coordinate precision: 2 decimals, city-name persistence (resolves conflict 1)
* **Context:** PRD says 2 decimals (~1.1 km); design spec says ~10 km (1 decimal).
* **Decision:** **2 decimals.** Round once at the datasource boundary; persist only the city name (+country/admin1); raw coords are memory-only, never serialized.
* **Alternatives:** 1 decimal/~10 km (rejected — can select the wrong Open-Meteo grid cell / wrong city in dense metros; precision loss with no privacy gain since city name is persisted anyway), full precision (rejected — violates data minimization; Open-Meteo's ~0.1° grid cannot use it).
* **Consequences:** Forecast accuracy identical to full precision (same model grid cell); GDPR minimization satisfied; logs safe by construction.

### ADR-08 — Reverse geocoding: on-device primary, disclosed network fallback (resolves conflict 2)
* **Context:** Open-Meteo's geocoding API has **no reverse-geocode endpoint** (verified against live API behavior and maintainer issue tracker — it is forward-search only).
* **Decision:** Primary: `geocoding` package (platform on-device reverse geocode — no network, no third party). Fallback: BigDataCloud `reverse-geocode-client` (keyless; coarse 2-dp coords only; disclosed in privacy notice). Final fallback: label "Current location".
* **Alternatives:** BigDataCloud primary (rejected — unnecessary third-party disclosure when the OS can do it locally), Open-Meteo (rejected — capability does not exist).
* **Consequences:** Best privacy posture; one extra disclosed fallback keeps the feature working when platform geocoding fails (FM-17).

### ADR-09 — °F mode converts everything: °F, mph, in, inHg (resolves conflict 4)
* **Context:** PRD recommends full conversion in °F mode.
* **Decision:** Full conversion per §8 table, client-side, at the presentation boundary.
* **Alternatives:** Temperature-only conversion (rejected — "wind 82" beside "°F" is a misread hazard; unit systems are all-or-nothing).
* **Consequences:** Deterministic, offline-capable, unit-tested conversion; no reliance on server unit params.

### ADR-10 — Crash reporting: `sentry_flutter`, crash-only, opt-out (resolves conflict 6)
* **Context:** Need crash visibility (FM-20) with "crash-only, no behavioral analytics" per privacy rules.
* **Decision:** `sentry_flutter` with `tracesSampleRate: 0`, `profilesSampleRate: 0`, session replay disabled, performance monitoring disabled; PII scrubbing on; opt-out toggle in Settings (default on, disclosed in privacy notice).
* **Alternatives:** Firebase Crashlytics (rejected — Google-services dependency, analytics bundling, larger binary), no crash reporting (rejected — FM-20 would be undetectable in production), self-hosted Sentry (deferred — revisit if data-residency requirements tighten; EU DSN option noted).
* **Consequences:** Crash-only telemetry; release logging stays sanitized (§3.2); Tech Law to confirm Sentry DPA covers the deployment region in Phase 3.

### ADR-11 — Dio over `package:http`
* **Context:** Retry budget (2 retries, 1 s→2 s), Retry-After honoring, per-host rate limiting, sanitized logging, request cancellation — all required by the PRD.
* **Decision:** `dio ^5.11.1` with the interceptor chain in §3.2.
* **Alternatives:** `package:http` + hand-rolled retry (rejected — retry/cancel/logging logic would be duplicated at every call site; interceptors centralize it and keep it testable).
* **Consequences:** One HTTP dependency; interceptors unit-tested with a mock adapter.

### ADR-12 — No navigation package in v1
* **Context:** 4 screens, no deep links, search as a modal sheet (design spec).
* **Decision:** Plain `Navigator` 1.0 + `showModalBottomSheet`; routes as constants.
* **Alternatives:** `go_router` (rejected — deep-linking/router state buys nothing v1; +~1 MB and API surface).
* **Consequences:** Smaller binary (install budget); revisit if deep links / web ever enter scope.

### ADR-13 — Settings in SharedPreferences; structured data in Hive CE (resolves conflict 5)
* **Context:** Need durable settings, forecast cache, recent places — with atomic writes.
* **Decision:** SharedPreferences for primitives (unit system, consent, theme, place name); Hive CE boxes for forecast cache + recent places.
* **Alternatives:** Everything in Hive (rejected — prefs API is simpler and survives box wipes), everything in SharedPreferences (rejected — wrong tool for multi-KB JSON), SQLite files (rejected — ADR-06).
* **Consequences:** Clear rule — "primitives → prefs, blobs/lists → Hive" — no future debate about where a new persisted value goes.

---

## 12. Cross-cutting concerns

**Performance (PRD budgets):** cold start ≤2 s — `main()` awaits only SharedPreferences; Hive boxes open lazily on first repository use; no network on start unless a stored place exists (then memory/disk cache serves instantly). Search ≤1.5 s — 300 ms debounce + geocoding typically <800 ms; recent-places served synchronously offline. Install ≤35 MB Android / ≤50 MB iOS — no Firebase, no go_router, no native DB libs; release builds with R8/tree-shaking, `--split-debug-info`, vector weather icons (no PNG sets).

**Accessibility (WCAG 2.1 AA):** semantic labels on all weather values ("72 degrees Fahrenheit" not "72°"); error/empty/offline states announced via `SemanticsService`; touch targets ≥48 dp; color-independent weather signaling (icon + text, never color alone); dynamic type respected (type scale in `sp`); contrast tokens per design spec palettes.

**Security:** HTTPS-only (cleartext blocked via network security config / ATS); no cert pinning v1 — Open-Meteo publishes no pinset; residual risk noted for Phase 3 AppSec review. No secrets, no WebViews, no JS bridges. Sanitized logging (§3.2). Sentry scrubbing strips query strings. Dependency pinning via `pubspec.lock` committed; `dependabot`/renovate for updates.

**Privacy (GDPR):** consent-before-OS-prompt flow (§4.3); 2-dp rounding; memory-only coords; city-name-only persistence; revocation wipes; privacy notice screen; full function without location; crash reports opt-out; BigDataCloud fallback disclosed. Tech Law (Phase 3) to validate the notice text and Sentry DPA.

**Testing → DoD mapping:** unit — validators (§3.3 table as parameterized cases), converters (§8), TTL policy (§6), debounce/cancel (FM-12); widget — each screen's 4 states (loading/empty/error/offline) driven by `AppFailure` fixtures; integration — airplane-mode flows (FM-1/19), consent grant/deny/revoke (FM-13/14/16), schema-drift fixture (FM-8). Contract test: recorded Open-Meteo responses replayed in CI; whitelist violations fail the build.

**Build/release:** flavors `dev`/`prod` (different Sentry DSN; dev enables verbose logging); GitHub Actions: analyze + test + contract test + build APK/AAB/IPA; deploy via `office/scripts/deploy_target.sh` (USB) — owner approval required for production per house rules.

---

## 13. Open questions for War Room Phase 2 debate

1. **Cert pinning:** accept the residual MITM risk on public Wi-Fi, or pin Open-Meteo's leaf/SPKI with a documented rotation runbook? (Security vs. operational fragility.)
2. **Sentry data residency:** US vs. EU DSN — needs Tech Law input before prod (ADR-10 flagged).
3. **l10n scope:** English-only v1 keeps `intl` minimal; confirm no launch locale beyond `en`.
4. **Weather icon mapping:** confirm the WMO-code → icon/token mapping lives with design tokens (design spec) and unknown codes use the FM-10 degraded path.
5. **FM reconciliation:** QA to diff the §9 FM table 1:1 against the PRD FM-1…FM-20 table before sign-off (numbering is the PRD's; `AppFailure` variants are this doc's stable contract).

---

*End of Architecture v1.0 — Enterprise Architect. Presented for War Room Phase 2 debate; disputes → Sloane.*

---

## 14. Phase 2 debate — Sloane's rulings (2026-10-06)

War Room Phase 2 debate complete. Backend, Frontend, and DevOps critiques synthesized. The PRD is the approved baseline: where the architecture contradicted it, the PRD wins unless noted. Amendments are binding on Phase 4.

**R-1 — Validation: two-tier (PRD wins).** Tier 1 structural (missing `current`, unparseable JSON, unusable hourly/daily, cross-field mismatch beyond PRD truncation rules) → fail closed to `AppFailure.schemaViolation`. Tier 2 field-level (wrong type / out of range per PRD §7 tables) → field becomes null/"—", entity still constructed (PRD §7.2, US-4 AC3, FM-3 note). ADR-05 is rewritten; "no partial entity is ever constructed" is struck. Unknown keys are *ignored* (not violations); schema drift is detected via breadcrumb + CI contract test.
**R-2 — Zero coordinates in logs/Sentry (PRD §9.7 wins).** Full coordinate scrubbing from all Sentry payloads and logs — field names + reason codes are sufficient diagnostics. `sanitizeUri()` redacts query strings (a 40-char truncation preserves `latitude=…`; it is removed). `DioException` URIs and `outOfRange.value` must never carry raw coords. Tech Law to confirm in Phase 3.
**R-3 — Numbers align to PRD.** Single `requestTimeout` = 10 s; location fix timeout = 15 s (FM-10); `utc_offset_seconds` ±50400 (PRD correct; ±18 h does not exist); pressure 800–1100 hPa; recent searches max 10; hourly screen shows 24 entries (home preview 8 unchanged). Architecture constants table is the canonical source; PRD/design-spec reference it.
**R-4 — Consent copy corrected.** "~10 km" → "~1 km (rounded coordinates)" in the consent sheet, Settings precision row, and privacy notice, per ADR-07. Tech Law re-reviews consent surfaces in Phase 3.
**R-5 — `uv_index_max` param approved.** Read-only additive param; the design's UV card requires it; no privacy impact.
**R-6 — No certificate pinning for v1.** Open-Meteo publishes no pinset; pinning an undocumented cert creates brick-on-rotation outage risk worse than the MITM risk for unauthenticated public weather data. Fail-closed §7 validation neutralizes malicious payloads. Revisit only if a pinset is published.
**R-7 — Release topology decided.** Store tracks are the release path (Play internal → 10% → production; TestFlight → phased release); `deploy_target.sh` is the inner-loop dev/QA path. Production releases go through a GitHub Actions workflow with a `production-release` environment requiring owner approval. PRD §12.8's staged-rollout gate is measured via Sentry Release Health.
**R-8 — UI state = sealed screen-state unions (new ADR-14).** The "1:1 AsyncValue" claim is struck. Each screen gets a sealed union (e.g. `firstLoad | ready(view, staleness, isRefreshing, bannerFailure?) | empty | failure(AppFailure)`); staleness is a property of data, not a state. Plain `Notifier`, not `AsyncNotifier`. Side effects (navigation, sheets, SR announcements) via a named `ref.listen` policy + `FailurePresentationMapper` + `Announcer` helper.
**R-9 — DI composition rule (ADR-03 amended).** Abstract repository providers are declared in domain (or domain-owned `lib/di/`); data-layer impls bind via `ProviderScope` overrides in `main.dart` and tests. Presentation never imports `data/`. Enforced by `import_lint`/`custom_lint` layer rules in CI.
**R-10 — `PlaceRepository` added.** Search/geocoding gets its own domain interface + impl (60 s per-query cache, in-flight dedupe); `WeatherRepository` no longer holds search results.
**R-11 — Units: independent axes.** `UnitSystem{temp, wind, pressure}`; ship the design spec's segmented controls (Temperature °C/°F, Wind km/h·mph·m/s); pressure follows the temperature preset (hPa metric / inHg imperial). °F default follows device locale (US/Liberia/Myanmar → °F, else °C). Formatter spec per frontend HIGH-3 (precision table, negative-zero normalization, round-half-away, `intl` locale separators, `FormattedValue(display, semanticLabel)`, compass, clock injection).
**R-12 — 429 handling.** Interceptor immediately maps 429 → `AppFailure.rateLimited(retryAfter)`; countdown + single scheduled retry at the controller layer; never hold a Dio call open for `Retry-After`.
**R-13 — Cache revocation.** `CacheRecord` gains `source: deviceLocation | search`; revocation deletes device-location entries. Revocation cancels in-flight device requests via generation counter.
**R-14 — `AppFailure.locationTimeout` added** (PRD FM-10 was unmapped).
**R-15 — Accessibility implementation spec (new ADR-15).** FocusScope traps + initial focus, skeleton `ExcludeSemantics` + single announcement, decorative-icon exclusion, heading/list semantics, 200%-scaling tests, keyboard traversal + focus-ring widget, `MotionTokens` reduced-motion gate, tabular figures, `Announcer` live regions. 48 dp touch targets recorded as the standard (supersedes PRD's 44).
**R-16 — Reproducibility.** Flutter pinned via `.fvmrc`; `pubspec.lock` + `Podfile.lock` committed; CI runs `flutter pub get --enforce-lockfile`; one canonical release build command (`--split-per-abi --split-debug-info --obfuscate`); Sentry symbol upload in the release step.
**R-17 — Sentry posture.** Crash-only (`tracesSampleRate: 0`, replay off), PII scrubbing on, Settings opt-out that disables the already-initialized client; first-run privacy notice discloses crash reporting before first report; Release Health wired (release+dist stamped, ANR threshold set for the 99% bar); Tech Law confirms DPA + data residency (US vs EU DSN) in Phase 3.
**R-18 — Sanctioned secrets.** "No secrets anywhere" covers *app* secrets (none exist by construction). The only sanctioned secrets are release-pipeline items in the platform secret store: Android upload keystore + passwords, iOS distribution cert/provisioning (or fastlane match passphrase), Sentry auth token for symbol upload. Never in the repo.

*Disputes resolved; none outstanding. Phase 3 (security & legal) may still block.*
