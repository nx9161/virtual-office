# Weather App — project memory

Mission: production-grade Flutter weather app (Android minSdk 24, iOS 15.0+), Open-Meteo Forecast + Geocoding APIs, no key, no backend.

## Status
- 2026-10-06: PRD v1.0 + Design Spec v1.0 complete (Phase 1). Architecture v1.0 proposed by Enterprise Architect for War Room Phase 2 debate. Doc: `projects/weather-app/ARCHITECTURE.md`.

## Key decisions (see ARCHITECTURE.md §11 for full ADRs)
- Client-only: no backend server (ADR-01). No secrets exist structurally.
- Riverpod 3 + riverpod_generator: single state/DI mechanism (ADR-02). BLoC rejected (ceremony without payoff at 4-screen scale).
- Always request SI from Open-Meteo; convert client-side at presentation boundary; cache canonically in SI (ADR-04).
- Defensive validation: handwritten DTOs, per-field whitelist+range, fail closed (ADR-05).
- Two-tier cache: in-memory + Hive CE disk; TTLs 10min fresh / 60min SWR / 24h max offline; atomic write-through (ADR-06).
- Coordinates: 2 decimals (~1.1km), memory-only, never persisted; persist city name only (ADR-07). Design spec's ~10km rejected.
- Reverse geocode: on-device `geocoding` pkg primary (Open-Meteo has NO reverse endpoint — verified); BigDataCloud keyless fallback disclosed in privacy notice (ADR-08).
- °F mode: FULL conversion (°F, mph, in, inHg) client-side (ADR-09).
- Crash reporting: sentry_flutter crash-only (traces/replay off), opt-out in Settings (ADR-10). Firebase Crashlytics rejected.
- Dio ^5.11.1 with retry/rate-limit/sanitized-logging interceptors (ADR-11). No go_router v1 (ADR-12). Settings→SharedPreferences, blobs→Hive CE (ADR-13).
- All 20 failure modes map to sealed `AppFailure` union → one UI state each.

## Verified facts (web, Oct 2026)
- flutter_riverpod 3.4.3, dio 5.11.1 current. Open-Meteo geocoding API is forward-search only (no reverse endpoint).

## Open for Phase 2/3
- Cert pinning decision; Sentry data residency (US vs EU DSN — Tech Law); l10n scope (en-only v1?); WMO icon mapping ownership; QA to diff FM table 1:1 vs PRD numbering.

## Phase 3 — AppSec review (2026-10-06)
- **Verdict: BLOCK** (AppSec Lead). Full report: `apps/weather_app/docs/APPSEC_REVIEW.md`.
- HIGH-1: Hive cache key IS a coordinate pair — contradicts PRD §9.3 "zero coordinates in persistent storage" + DoD#5 test. Required: SHA-256-hash cache keys, strip lat/lon echo from stored payload, log key-hash only.
- HIGH-2: Sentry/log coordinate exfiltration path unspecified — `DioException.requestOptions.uri` carries lat/lon; required: `beforeSend` scrubber, never capture raw DioException, release logs carry no URI.
- MEDIUMs: BigDataCloud fallback response has no whitelist; unknown-keys-ignored (R-1) needs scheduled contract-fixture regeneration; backup exclusions unspecified (Android extraction rules / iOS excluded-from-backup); Dart num/int/double coercion rules unpinned.
- R-6 (no cert pinning) CONFIRMED with revisit triggers. M1/M3/M10 N/A by construction. Client-side rate limiting sufficient (per-IP fair use + 429); add User-Agent + enforce retry budget on R-12 path.
- Clearing conditions (7 items) in report §9; Tech Law deps: Sentry DPA/residency, privacy-notice copy (BigDataCloud naming, "~1 km"), hashed-key carve-out.

## Phase 3 — AI Red Team abuse-case review (2026-10-06)
- **Verdict: CONDITIONAL CLEAR (no BLOCK).** 7 abuse cases probed: AC-1 mock location = non-issue (nothing location-gated; no `isMock` detection); AC-2 modified-client API hammering = Low, unenforceable client-side (Open-Meteo bears cost; NAT-shared-IP residual); AC-3 search-input injection = Low, no interpreting sink (control-char stripper + 100-char dual-layer cap + FM-12 ≤50-char escaped echo required); AC-4a plausible-but-false MITM data = Low accepted residual (R-6); **AC-4b array-bomb payloads = MEDIUM — max body-size gate (~512 KB) BEFORE `jsonDecode` is a mandatory clearing condition** (truncation currently runs post-parse); AC-5 cache forgery = Low (HMAC with Keystore/Keychain key recommended); AC-6 BigDataCloud fallback = Info (Tech Law to confirm disclosure/DPA); AC-7 consent bypass = non-issue (OS prompt is the real gate). Full report: `~/workspace/virtual-office/redteam/weather_app_phase3_abusecase_review.md`.

## Phase 3 — Tech Law ruling (2026-10-06): CLEAR WITH CONDITIONS
- Ruling doc: `apps/weather_app/docs/TECH_LAW_RULING_phase3.md`. No BLOCK.
- Consent (GDPR Art 6(1)(a)) VALID: freely given (full function w/o location), specific, informed, unambiguous, withdrawable via Settings toggle (FM-16) + revocation wipes (R-13).
- R-4 elevated: "~10 km"→"~1 km (rounded coordinates)" in 4 design-spec spots is legally material (informed-consent basis collapses otherwise) — gating pre-build-sign-off (C1).
- 30-day in-app-decline suppression OK (EDPB allows re-request); OS-denied = never re-prompt (FM-7) — distinction compliant (C4).
- City name/recents = personal data (conservative, Breyer); coords memory-only; retention schedule required in notice (C2/C6).
- Sentry: EU DSN REQUIRED (Schrems II), DPA confirmation, IP-scrubbing on; default-on opt-out defensible on Art 6(1)(f) but highest-risk call — counsel flag F1 (DE strictness).
- BigDataCloud fallback covered by original consent (purpose-compatible) but must be NAMED in privacy notice — design §5.4 names only Open-Meteo (C2).
- Controller analysis corrected: owner = controller of transmitted coords (Art 4(7); no backend ≠ not a controller); Open-Meteo = independent controller; BFF would add server-side processing liability (C5).
- Privacy notice 12-section content spec issued (C2). CCPA: no sale/sharing confirmed. EU AI Act: out of scope v1.
- Real-counsel flags: F1 default-on crash reporting (DE), F2 Sentry DPA evidence, F3 BigDataCloud terms, F4 re-review triggers (analytics/ads/accounts/backend/AI/CCPA thresholds/children).

## Phase 4 — Build (2026-10-06/07, Lead Mobile/Frontend)
- Hand-written Riverpod providers (plain `Notifier`) instead of riverpod_generator codegen: generator stays in dev_deps for CI, but SDK unavailable on build VM so no codegen could be run. CI runs build_runner; code stays clean either way.
- `PlaceRepository` owns the search CancelToken so presentation never imports Dio (layer-lint enforced).
- Cache HMAC declined per AC-5's allowed alternative: written rationale in README (physical-access attacker outside v1 threat model; SHA-256 keys, coarse payloads).
- Precip probability <- hourly[0], UV index <- daily[0] (frontend MEDIUM-2/3); hourly capped at 24 points; recents store 10 / display 5; pressure follows temperature preset (R-11).
- Device-sourced saved place persists name only (ADR-07): `GeoPlace(0,0)` sentinel is never sent to the network; home boot re-resolves via OS when the saved place is device-sourced.
- Toggle OFF of "Use device location" revokes in-app immediately (US-3 AC3 / Tech Law Art 7(3)) — one-tap withdrawal overrides design §3.5's deep-link-only wording.
- `strict-casts: true`; zero `as`/`!` on JSON dynamic in the data layer.
- DoD privacy tests ship: no-plaintext-coords-in-storage, beforeSend scrubber, OS-grant-required (AC-7).
- `PlaceRepository.isSupersede(Object)` added: the FM-12 cancel/supersede check lives behind the repository interface so presentation never imports dio (layer lint bans it).
- `UnitSystem.fromLocale(Locale)` -> `fromLocaleCode(String?)`: domain_stays_pure bans dart:ui in domain.
- ConsentState gained `osDenied` (FM-7 never-reprompt); LocationRepository gained `recordOsDenied()` + `canPromptForConsent`.
- `WeatherRepository.clearCache()` added for the "Delete local data" erasure path.
- layer_lint `no_data_imports_in_presentation` refined: `data/di/**` (usecase providers, the sanctioned composition seam) is allowed in presentation; all other data/ imports still banned.
- Toggle OFF of "Use device location" revokes in-app immediately (one-tap withdrawal) — overrides design §3.5's deep-link-only wording per Tech Law Art 7(3).
- No pubspec.lock committed (no SDK on build VM) — owner must run `flutter pub get` once before first CI run (--enforce-lockfile).

## Phase 3 — AppSec BLOCK ruling by Sloane (2026-10-06)
- **Ruling:** block converted to 7 binding build requirements (B-1…B-7): hashed cache keys + stripped echo (HIGH-1), `beforeSend` coordinate scrubber + no raw DioException capture (HIGH-2), BigDataCloud whitelist (MEDIUM-1), weekly live-fixture contract regen (MEDIUM-2), backup exclusions (MEDIUM-3), `asInt`/`asDouble` coercion helpers (MEDIUM-4), echo→schemaViolation + User-Agent + 429 budget + Sentry purge on opt-out (LOW-1/2/3).
- Red Team: CONDITIONAL CLEAR — body-size gate ≤512 KB before `jsonDecode` mandatory (AC-4b); control-char stripping; 429 telemetry; cache HMAC or rationale; OS-grant test.
- Tech Law: CLEAR WITH CONDITIONS C1–C7 — C1 closed (design-spec "~1 km" copy fixed); C2 privacy notice 12-section spec; C3 Sentry EU DSN + DPA = owner action; C5 controller = owner (not Open-Meteo); F1–F4 real-counsel flags = owner action.
- Full record: `apps/weather_app/docs/WAR_ROOM_RECORD.md`. Build entry criteria all met; build phase started.

## QA final gate — REQUEST CHANGES fixes (2026-10-06, Lead Mobile/Frontend)
- B1: hourly DTO now parses up to 48 (`hourlyApiParseCap`); `ForecastViewMapper.toView` slices 24 from the current local hour (location tz via `utc_offset_seconds`, device-tz fallback per FM-14) and sets `hourlyPartial` → "Some hours unavailable" note in home preview + full hourly screen (FM-17, never padded). Precip probability stays sourced from the sliced hourly[0].
- B2: metrics grid extended to all US-4 AC2 metrics — wind gusts, precipitation amount, cloud cover %, pressure hPa added (view model gained `cloudCover`); l10n keys windGusts/precipAmount/cloudCover/pressure/humidity/uvIndexLabel.
- B3: daily screen is now a single-open accordion (design §3.4); expansion shows sunrise/sunset (US-6 AC2), UV max, precip probability max. Design's "wind max"/"precip sum" not added — not in the fixed API param set (needs PO approval).
- B4: search sheet empty state uses `FailurePresentationMapper` FM-12 headline verbatim ("No places found for '<query>'") — single source of truth; widget test updated.
- Tests: B1 slice/partial DTO + mapper suites; parameterized PRD §11 FM headline/action sweep (FM-2/3/5/6+countdown/7/8/9/10/13/14/16/17 + consent states); `weather_code_mapper` over the 28 PRD Appendix-A codes (QA's "29" doesn't match the PRD table — flagged) + unknown → neutral icon.
- ARCHITECTURE.md §9 carries a superseding note: PRD §11 + failures.dart/failure_presentation.dart are canonical; the old FM table is historical.
- B5/B6: `tool/bootstrap.sh` (idempotent) — requires Flutter SDK, `flutter create` only for missing scaffolds, checksums/restores `data_extraction_rules.xml` (B-5), runs `flutter pub get`, prints manual steps; `pubspec.lock` committed by first operator run (CI `--enforce-lockfile` unchanged; `.github/workflows/weather_app.yml` references all-existing paths — untouched).
- B7: README "Setup" step 0 = bootstrap; new "Manual platform steps" section (Android manifest `usesCleartextTraffic=false` + `dataExtractionRules`; iOS `NSURLIsExcludedFromBackupKey` on the Documents dir = hive_ce_flutter's `initFlutter()` directory, in AppDelegate before plugin registration).
- No SDK on this VM — `flutter analyze/test` not run; CI is the verification gate. Not committed (Sloane commits after QA).
