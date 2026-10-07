# Lead Mobile/Frontend Engineer — Presentation/Client Layer Critique
**War Room Phase 2 — Project: Weather App** · 2026-10-06 · Reports to Sloane

I read all three docs end-to-end (ARCHITECTURE.md v1.0, PRD v1.0, design-spec v1.0) and cross-checked every claim against the other two. Verdict up front: the architecture is strong and I can build on it — **but there are two build-blocking contradictions between the docs, one false "1:1 mapping" claim at the heart of the UI contract, and a layering rule that is unenforceable as written.** Details below.

---

## (a) Endorsements

1. **Riverpod 3 + riverpod_generator as the single mechanism (ADR-02): yes, I buy the BLoC rejection.** The trade-off table is honest. For a 4-screen app, BLoC's event/state ceremony would roughly double feature code for an audit trail nobody required (PRD has no compliance event-logging need). Riverpod's `autoDispose`, compile-time-safe provider graph, and `ProviderContainer` test overrides are the right tools for exactly this shape of problem: mostly-async, mostly-read, small team. `riverpod_lint` is the right companion.
2. **Canonical SI internally + conversion at the presentation boundary (ADR-04/09): yes.** This is the decision that makes US-12 AC2 ("re-render within 500 ms without a new network request") trivially satisfiable and keeps one cache form. Correct call, and the Open-Meteo-has-no-inHg argument is decisive.
3. **Sealed `AppFailure` with exhaustive `switch`:** excellent. This is the single best idea in the doc for frontend quality — it turns "every failure maps to a distinct user-facing state" (PRD G-2) into a compiler-checked property.
4. **Interceptor chain (retry / rate-limit / sanitized logging) over `package:http` (ADR-11):** right. Retry budgets and `Retry-After` honoring scattered across call sites would rot within a month.
5. **Consent-before-OS-prompt sequencing (§4.3):** correct GDPR construction, and "the app never blocks on location" is the right product posture.
6. **Skeleton-first loading, stale-while-revalidate, honest staleness labeling:** matches the design spec's "honest data" principle well.
7. **No-backend / no-secrets posture (ADR-01):** satisfies "no hardcoded API URLs or secrets" structurally. Hosts live in `core/config/constants.dart` — fine for keyless public endpoints.
8. **Atomic write-through cache + self-healing corruption (FM-18):** sound; "cache must never crash the app" is the right invariant.

---

## (b) Challenges, by severity

### 🔴 BLOCKER-1 — Field-level "—" vs. fail-closed whole-screen error: the docs directly contradict each other

This is the single most important dispute in the package, and it determines how I write every DTO and mapper.

- **PRD §7.2** is explicit: wrong-typed or out-of-range fields are "discarded at field level (render '—'), never crash the app." The table says `current.temperature_2m` out of range → `"—"`. PRD FM-3 adds: "**Field-level violations do NOT trigger FM-3** — they render '—' per §7.2." PRD US-4 AC3: "any single field that fails validation renders '—' with the rest of the block intact (**never a whole-screen error for one bad field**)."
- **Architecture §3.3** says the opposite: "a failure at any stage short-circuits to `AppFailure.schemaViolation` / `outOfRange` and **no partial entity is ever constructed**." §9 FM-9: "Fail closed: **error card, never render suspect value**."

Both cannot be true. As the engineer who owns this code, I side with the **PRD** (it carries measurable acceptance criteria; the architecture is the derived document), with one refinement:

**Concrete fix:** two-tier validation, and this must be written into ADR-05:
- **Tier 1 — structural (fail closed, whole-screen error):** `current` block missing/non-object, `hourly`/`daily` structurally unusable, JSON unparseable, cross-field length mismatch that can't be truncated per PRD array rules → `AppFailure.schemaViolation`. This matches PRD FM-3.
- **Tier 2 — field-level (degrade to "—", keep the entity):** any single scalar out of range or wrong type → that field becomes `null`/sentinel in the entity; the entity is still constructed; the formatter renders "—". Unknown WMO code → already degraded per FM-10.
- Entities therefore carry **nullable fields** for every Tier-2-validated scalar (or a small `FieldStatus` wrapper). The "never render suspect data" principle is preserved — we render *nothing* for the suspect field, not the suspect value.

Without this resolution I cannot write the DTOs: "no partial entity is ever constructed" and "render '—' with the rest of the block intact" produce opposite code.

### 🔴 BLOCKER-2 — The "1:1" UI state contract is false; `AsyncValue` cannot express it

§9 claims every screen renders exactly one of `initial | loading | data | empty | error(failure) | offlineStale`, "mapped 1:1 to `AsyncValue` + the failure union." `AsyncValue` has exactly three states: loading/data/error. The six-state contract does not fit, and the design spec demands states the contract can't name:

| Design-spec/PRD state | Fits the 6-state contract? |
|---|---|
| Home **refresh loading** (content stays, thin progress bar, metrics dimmed) vs **first-load skeleton** | No — both are "loading" but render completely differently. Collapsing them guarantees a bug where pull-to-refresh flashes a full skeleton. |
| Home **error banner over cached data** ("Couldn't refresh — showing data from 1h ago. Retry.") | No — this is `data` + `error` simultaneously. US-9 AC3 *requires* preserving last good data under the error. A single `error(failure)` state that replaces the screen violates the PRD. |
| Stale-while-revalidate (10–60 min: render immediately, background refresh, silent update) | No — it's `data` with a background `loading` that must not show any spinner. |
| **Offline banner over cached data** (design §3.1) | `offlineStale` covers it only if it carries the data — so it's not a distinct state from `data`, it's `data(staleness: stale, source: cache)`. |
| Search **loading with previous results retained** (FM-4: "Previous results retained") | No — composite again. |
| Search **hint** "Type at least 2 characters" (US-1 AC2, query < 2 chars) | Not in the contract at all (arguably `initial`, but the design spec's empty-no-query state is a real designed screen). |
| `needsLocationChoice` (welcome screen, §4.3) | Not a home-screen state — it's a **routing** decision. Forcing it into the home controller's state machine is a category error. |
| Consent sheets, OS-settings deep-link cards, snackbars | These are **side effects / overlays**, not screen render states. `consentRequired` → navigate to search sheet; `locationPermanentlyDenied` → card with deep link. The contract needs a side-effect policy, not just states. |
| Rate-limited countdown (FM-6: Retry enabled only after `Retry-After` elapses) | `error(rateLimited)` needs a ticking countdown — a state with a timer, or it degrades to a dead Retry button. |

**Concrete fix — replace the contract with a sealed screen-state union, not `AsyncValue`:**

```dart
// One per screen; example for home. Plain Notifier, NOT AsyncNotifier.
sealed class HomeScreenState {
  const HomeScreenState();
  const factory HomeScreenState.firstLoad() = _FirstLoad;          // skeleton
  const factory HomeScreenState.ready({
    required ForecastView view,        // already converted to display units
    required Staleness staleness,      // fresh | stale(Duration age) | offlineStale(Duration age)
    required bool isRefreshing,        // pull-to-refresh / SWR in flight: thin bar, no skeleton
    AppFailure? bannerFailure,         // non-blocking: banner over data + Retry
  }) = _Ready;
  const factory HomeScreenState.empty() = _Empty;                  // no location chosen (routes to welcome)
  const factory HomeScreenState.failure(AppFailure failure) = _Failure; // full-screen error card, no data
}
```

Notes for implementation:
- `Staleness` carries the age → drives "Updated X min ago", warning color >30 min (design §3.1), and the offline banner copy. `offlineStale` as a separate top-level state was the wrong factorization; staleness is a *property of data*.
- Full-screen error card only when there is **no data at all** (first load failure, cache >24 h). Otherwise errors are banners. This is exactly US-9 AC3 + US-10.
- Side effects (`ref.listen` → snackbar, navigation, sheet, assertive SR announcement) get a **named policy**: failures that require user action beyond the current screen (`consentRequired`, `locationPermanentlyDenied`, `consentRevoked` mid-session) produce one-shot side effects; everything else renders inline. I'll document the failure→{inline state | side effect} table in Phase 4.
- Search gets its own union: `idle(queryHint) | loading(previousResults?) | results | noResults(query) | searchFailed(query, previousResults?)`. The "silently dropped stale response" (FM-12) is not a state — it's controller logic.
- This also answers question 1's sub-question: Riverpod handles this fine — but via `Notifier<SealedState>`, not `AsyncNotifier`. The architecture's "AsyncValue is first-class, therefore AsyncNotifier everywhere" reasoning is the wrong conclusion from the right premise.

### 🔴 BLOCKER-3 — Layer discipline is unenforceable as specified, and the provider graph violates it

Two problems:

**Problem A — the graph contradicts the table.** §5's provider graph has `homeController` (presentation) depending on `weatherRepositoryProvider`, and the natural riverpod_generator layout puts `weatherRepositoryProvider` next to `WeatherRepositoryImpl` in `data/`. The moment a `features/home/` controller file does `import 'package:weather_app/data/repositories/weather_repository_impl.dart';` (or even the provider file that lives beside it), presentation imports data — violating the doc's own "Must never import" column. With codegen, providers are co-located with implementations, so this violation is the *default* outcome, not an edge case.

**Concrete fix (DI composition rule — needs an ADR, see below):**
- Repository *provider declarations* (abstract types) live in **domain** (e.g. `domain/repositories/weather_repository.provider.dart` — a hand-written `@Riverpod(keepAlive: true) WeatherRepository weatherRepository(Ref ref) => throw UnimplementedError();`), or in a `lib/di/` composition root that domain owns.
- Data-layer impls are bound via `ProviderScope(overrides: [...])` in `main.dart` (prod) and in tests. Presentation imports only domain.
- This keeps "controllers talk only to repository interfaces" literally true at the import level, and Riverpod overrides remain the single DI mechanism.

**Problem B — no lint enforces any of it.** `flutter_lints` + `riverpod_lint` cannot express "presentation may not import Dio/Hive/platform plugins." **Concrete fix:** add `import_lint` (or `custom_lint` with `riverpod_lint` + layer rules) with a `lint_config.yaml`:

```yaml
import_lint:
  rules:
    - name: no_data_imports_in_presentation
      target: lib/features/**, lib/core/units/**, lib/core/error/**
      deny: lib/data/**, package:dio/**, package:hive_ce/**, package:geolocator/**, package:connectivity_plus/**
    - name: domain_stays_pure
      target: lib/domain/**
      deny: package:flutter/**, lib/data/**, lib/features/**
    - name: no_platform_io_in_presentation
      target: lib/features/**
      deny: dart:io, dart:ffi
```

Wire it into CI (`dart run import_lint` or analyzer plugin). Without this, the layer table is a wish.

Also: §2's folder layout has **no `PlaceRepository`** — geocoding search results are cached "in `WeatherRepositoryImpl`" (§6 L1). A weather repository holding search results is a layering smell and muddies the consent story (search results are public place data; device coords are not — they must never share a cache path that could be wiped/persisted together). **Concrete fix:** add `domain/repositories/place_repository.dart` (`searchPlaces`, in-memory 60 s query cache per PRD §8.1) + `data/repositories/place_repository_impl.dart`. The search controller talks to it, not to the weather repo.

### 🔴 BLOCKER-4 — Design-spec consent copy states "~10 km"; ADR-07 decided ~1.1 km (2 dp)

ADR-07 explicitly rejected the design spec's "~10 km" and chose 2 decimals (~1.1 km). But the design spec still says, in three places: consent sheet body "coarse precision only (**about 10 km**)", Settings "Location precision" row read-only value "**Coarse — ~10 km**", privacy notice "approximate area (**coarse, ~10 km**)". The consent sheet is a **legal surface** — misstating precision there by an order of magnitude is a Tech Law blocker, not a copy nit.

**Concrete fix:** design spec must be amended to "~1 km (rounded coordinates)" everywhere before build sign-off; Tech Law (Phase 3) re-reviews the consent sheet and privacy notice text. Also note: with 2 dp the app can select the right Open-Meteo grid cell — the architecture's reasoning is sound, the copy just didn't follow the decision.

### 🔴 BLOCKER-5 — Search debounce + cancel has no concrete provider design, and the obvious Riverpod implementation has a footgun

§6 says "300 ms debounce at the controller; in-flight requests cancelled via Dio `CancelToken`; stale responses discarded by monotonic request id." That's a spec, not a design. The details that will bite in Phase 4:

- `Timer` created in a provider's `build()` is the classic Riverpod leak — it must be created in Notifier event methods and cancelled in `ref.onDispose`. With `autoDispose`, navigating away mid-debounce must cancel both the timer and the `CancelToken`.
- `CancelToken` lifecycle: one per request, stored on the Notifier, cancelled on new keystroke *and* on dispose. A cancelled token must never be reused (Dio throws).
- Monotonic request id vs `CancelToken`: both are listed; pick **CancelToken as primary** (actually aborts the socket — matters for the §8.4 rate ceiling), request id as the belt-and-braces guard for the race where cancellation arrives after response parsing started.
- The 60 s in-memory per-query cache (PRD §8.1) lives in `PlaceRepositoryImpl` (data), keyed by normalized query; "identical queries within 5 s reuse the in-flight result" → the impl holds a `Map<String, Future>` of in-flight searches.
- US-1 AC1 ("exactly one geocoding request fires" per pause) needs the debounce to also suppress the request when the query is unchanged — check `if (query == _lastFiredQuery) return;` after the timer.

**Concrete fix:** I'll write `SearchController extends _$SearchController` (autoDispose) with this exact lifecycle in Phase 4, plus unit tests for: debounce fires once, keystroke cancels in-flight (assert via mock adapter request count), out-of-order responses dropped, dispose cancels timer+token. This is all very doable in Riverpod — debounced search is a *good* fit, not a poor one — but it needs the design written down, because the naive implementation leaks.

To directly answer question 1: **no feature is a poor fit for Riverpod** — debounce/cancel (above), consent flow (`Notifier<ConsentState>` state machine with persisted state — good fit), unit conversion (pure functions + `settingsController` — trivially good fit). My objection is narrower: `AsyncNotifier`/`AsyncValue` is the wrong state *representation* for screens (Blocker-2), and the BLoC-rejection table should acknowledge the one real BLoC advantage it dismisses too fast — replayable event logs are genuinely useful for debugging the search race (FM-12). Mitigation, not a reason to switch: keep the monotonic request id + sanitized breadcrumb logging so races are diagnosable without an event bus.

---

### 🟠 HIGH-1 — Offline/consent race conditions

1. **Revocation wipe can't find device-keyed cache entries.** §4.3: "clears forecast cache entries keyed by device location" — but the cache key is `"lat,lon"` and after wiping in-memory coords we no longer know which keys were device-derived. **Fix:** tag every `CacheRecord` with `source: deviceLocation | search` at write time (ADR-06 amendment). Revocation deletes `source == deviceLocation` entries. Without this the wipe is unimplementable.
2. **Revocation mid-flight.** If a forecast request for device coords is in flight when the user toggles location off, the response must not repopulate the cache or state afterward. **Fix:** `LocationRepository` (or the home controller) owns a `CancelToken`/generation counter for device-location-driven requests; revocation cancels in-flight device requests and bumps the generation; late responses are dropped by generation check. Same pattern as search.
3. **Auto-retry on reconnect needs guards or it becomes a retry loop.** `connectivity_plus` emits on VPN toggles, captive-portal flaps, and airplane-mode toggles — not just real reconnects. PRD says "single attempt per reconnect, debounced 2 s." **Fix:** `connectivityProvider` maps to a debounced `bool isOnline`; the home controller keeps `lastFailure`; on `false→true` transition, retry **only if** `lastFailure` was `networkUnreachable`/`timeout`, and only once per transition (latch until next failure). Never auto-retry `apiClientError`/`schemaViolation` — those aren't connectivity.
4. **Consent flow vs. app backgrounding.** In-app sheet → OS dialog → user backgrounds the app at the OS dialog → returns hours later. `ConsentState` is persisted, but "sheet shown, awaiting OS result" is not. **Fix:** persist a `consentFlowStep` (`idle | sheetShown | osPromptPending`); on foreground, if `osPromptPending` and permission is now granted, continue the flow (get fix → reverse-geocode) rather than stranding the user.
5. **30-day declined re-prompt suppression** (design §5.1: "remember 'declined' so we don't re-prompt for 30 days") is missing from the architecture's consent model entirely. **Fix:** persist `consentDeclinedAt`; `consentController.canPrompt` returns false within 30 days. PRD FM-7 ("never re-prompt from the app after denial") is stricter than 30 days for the *OS-denied* case — distinguish in-app-decline (30-day suppression) from OS-denied (never re-prompt; settings deep-link only). This distinction needs to be explicit or I'll build the wrong behavior.
6. **Permission-state nuance:** geolocator `denied` vs `deniedForever` requires the Android `shouldShowRequestRationale` check to implement "never re-prompt after denial" correctly. Name it in the location datasource contract.

### 🟠 HIGH-2 — Unit-system modeling conflict: independent wind control vs. all-or-nothing °F mode

- PRD §13 open question 1 asks exactly this: "convert to mph/inHg, or keep km/h/hPa with labels?"
- Architecture ADR-09 decides: full conversion, all-or-nothing, tied to °F mode.
- **Design spec §3.5 Settings shows two independent segmented controls: Temperature (°C/°F) AND Wind (km/h, mph, m/s).** That is not all-or-nothing — it's a per-quantity unit preference, and it contradicts ADR-09.

**Fix:** model `UnitSystem` as independent axes from the start — it's cheaper now than migrating later:

```dart
enum TempUnit { celsius, fahrenheit }
enum WindUnit { kmh, mph, ms }
enum PressureUnit { hpa, inhg }
// UnitSystem{temp, wind, pressure}; °F-mode preset = (fahrenheit, mph, inhg)
```

If Sloane/PO decide all-or-nothing, the preset collapses to a single toggle and the model still works. If they keep the design spec's segmented controls, we're already correct. Either way the formatter takes the full `UnitSystem`. **This is a dispute for Sloane**, but the data model should not preempt the decision.

### 🟠 HIGH-3 — Formatter precision/rounding/locale is underspecified (ADR-04/09)

"Rounding is display-only (`toStringAsFixed`)" is not a spec. What's missing:

| Gap | Fix |
|---|---|
| Per-quantity precision | Temp 0 dp ("21°"), feels-like 0 dp, wind 0 dp, gusts 0 dp, precip mm 1 dp / in 2 dp ("0.04 in"), pressure hPa 0 dp / inHg 2 dp ("29.92 inHg"), humidity/cloud/UV/probability 0 dp + "%". Write the table into ADR-09. |
| Negative zero | −0.4 °C → `toStringAsFixed(0)` = "-0°". Normalize: `if (v == 0) v = 0` / add 0.0. Test it. |
| Rounding mode | Dart `toStringAsFixed` is round-half-away; document it so °F boundaries (e.g. 21.5 °C → 71 °F) are deterministic. |
| Locale | `toStringAsFixed` always emits `.` — wrong for de-DE ("21,5"). Formatters must use `intl NumberFormat` with the app locale for the decimal separator, while unit *symbols* stay per spec. `WeatherFormatter` takes `(UnitSystem, Locale)`. |
| A11y labels differ from visual | Visual "21°" vs SR "21 degrees Celsius" (design §6, arch §12). Formatter returns a small `FormattedValue(display, semanticLabel)` or exposes `formatTempA11y`. Don't make widgets string-munge. |
| Clock injection | "Updated X min ago" and the provenance strip's "updated 12:04" (in the **location's** timezone, not the device's — the formatter needs the location `utcOffset`) must take a `now` parameter for testability. |
| Compass | Wind direction degrees → 16-point compass ("NW") + arrow rotation — pure function in the formatter bundle, unit-tested. |

Testability is otherwise genuinely good — pure functions, no widgets — provided the signature is `(SI value, UnitSystem, Locale, {Clock now}) → FormattedValue`.

### 🟠 HIGH-4 — Retry-After must surface immediately, not hold the request

§3.2: RetryInterceptor "honors `Retry-After` (parsed, capped at 60 s)". If the interceptor literally waits up to 60 s before returning, the UI hangs on a spinner for a minute with no countdown — violating FM-6 ("Retry enabled only after Retry-After elapses" implies the user *sees* the countdown). **Fix (ADR-11 amendment):** on 429, the interceptor immediately throws/maps to `AppFailure.rateLimited(retryAfter)`; the controller shows the countdown notice and schedules one automatic retry when the countdown elapses (or enables the Retry button then). "Request queue paused" happens at the UI/controller layer, not by blocking a Dio call.

### 🟠 HIGH-5 — Accessibility: the architecture under-supports the design spec

The design spec's §6 is genuinely thorough; the architecture's §12 paragraph doesn't give me enough to implement it. Gaps and fixes:

1. **Focus order & traps.** Design spec: "modal sheet traps focus until dismissed; consent sheet focus starts on title." Flutter's `showModalBottomSheet` does not guarantee SR focus trapping or initial focus placement. **Fix:** explicit `FocusScope` + `Semantics(sortKey:)` ordering on the search sheet and consent sheet; autofocus the sheet title's `FocusNode` on open; verify with TalkBack/VoiceOver linear nav in the audit.
2. **Skeleton semantics.** Six shimmering skeleton cards will each be SR-focusable noise. **Fix:** wrap skeleton groups in `ExcludeSemantics` + a single `Semantics(label: "Loading weather", liveRegion: true)`; announce once (design spec: "loading states announce once, not per-skeleton").
3. **Decorative icons.** Weather icons marked decorative (`ExcludeSemantics`), condition conveyed in adjacent text — needs a lint/review checklist item, it's per-widget work.
4. **Headings & lists.** "Headings use semantic heading levels; lists announced as lists with counts" → use `Semantics(header: true)` and wrap hourly/daily in `Semantics` with explicit count labels. Not mentioned in arch — add to the widget guidelines.
5. **200% text scaling.** Arch says "type scale in sp" — in Flutter, `sp` *is* the default unit and scales automatically, so the real work is *layout survival*: hero `display-xl` at 200% must wrap, not overflow. **Fix:** golden/widget tests at `textScaler: TextScaler.linear(2.0)` for home/search/settings; `FittedBox`/`AutoSizeText`-style fallbacks where the designer approves; no `overflow: clip` on text containers.
6. **Keyboard operability.** Design spec: "full app operable without touch — Tab/Shift+Tab, Enter/Space, Esc dismisses." Architecture: silent. **Fix:** `FocusTraversalGroup` with numeric sort keys on home; Esc handling on sheets/dialogs (`PopScope`); visible 3 px focus ring from tokens (add a `FocusRing` widget using `focus-ring` token).
7. **Reduced motion mechanics.** "Respect prefers-reduced-motion" → in Flutter that's `MediaQuery.disableAnimations`. **Fix:** a `MotionTokens` helper: shimmer (1200 ms cycle) ↔ static placeholder, sheet slide 250 ms ↔ instant, all gated on one `isReducedMotion(context)` check. Name it so every widget does it the same way.
8. **Tabular figures.** Design spec §2.1 requires tabular nums for temperature; architecture doesn't mention. **Fix:** `fontFeatures: [FontFeature.tabularFigures()]` in the numeric text styles in the theme.
9. **Touch target vs PRD.** PRD §10.4 says ≥44×44 dp; design spec §2.3 and arch §12 say ≥48. 48 satisfies both — **record 48 dp as the standard** and note the PRD as superseded, so QA doesn't test to 44.
10. **Live regions.** Offline banner "announces via live region" (design §4); error states "assertive live region" (design §6). **Fix:** a single `Announcer` helper wrapping `SemanticsService.announce` with `assertiveness` parameter, called from the `ref.listen` side-effect layer — not scattered `announce` calls in widgets.

### 🟠 HIGH-6 — Cross-document number mismatches (needs a single source of truth)

These are individually small, collectively a QA nightmare. Recommending the architecture's constants table as canonical and PRD/design-spec amended to reference it:

| Item | PRD | Architecture | Design spec | Recommendation |
|---|---|---|---|---|
| Request timeout | 10 s (FM-1, §8.3) | 8 s connect / 12 s receive | — | **Align to PRD 10 s** (single `requestTimeout`); arch's split timeouts contradict the PRD's test-assertable budget |
| Location fix timeout | 15 s (FM-10) | 10 s (§4.3) | — | **15 s per PRD** (it's the specified FM behavior) |
| `utc_offset_seconds` range | ±50400 (§7.2) | ±64800 (§3.3) | — | ±64800 is the true physical range (±18 h is wrong; real max is ±14 h = ±50400 — PRD is actually right; some zones are +14:00). **Use ±50400** and fix arch table |
| Pressure range | 800–1100 (§7.2) | 870–1085 (§3.3) | — | PRD's 800–1100 (record low 870 is inside it; arch range would false-positive a valid 871 hPa reading… wait, 871 is inside 870–1085 too. The risk is reversed: arch *rejects* 869, PRD accepts. Pick **PRD 800–1100** — wider is safer for fail-open field-level "—" anyway) |
| Recent searches max | 10 (US-13) | 8 (§6) | 5 (§3.2) | **PO decision needed** (dispute) |
| Hourly entries | 24 (US-5) | cap 48 (§7) | 48 (§3.3 "next 48 hours") | **PO decision needed** (dispute); note home preview shows 8 — consistent either way |
| Touch target | 44 dp (§10.4) | 48 dp (§12) | 44 dp (§10.4) | **48** (above) |
| Debounce | 300 ms | 300 ms | 300 ms | ✓ consistent |
| Cache TTLs | 10 min / 60 s search | same | — | ✓ consistent |

---

### 🟡 MEDIUM — implementation-shaping items (all fixable in Phase 4, flagged now so they don't surprise)

1. **Failure→UI copy mapper.** §9 says "human sentence + one action" but names no component. **Fix:** `FailurePresentationMapper` (presentation, pure): `AppFailure → (headline, body, primaryAction, secondaryAction?)`. Unit-tested against PRD §11's exact headlines ("No connection", "Weather service is down", …). This is where "Generic 'Something went wrong' appears in zero states" (US-9 AC1) gets enforced.
2. **Precipitation-probability sourcing for the home metrics grid.** Design §3.1 shows "Precipitation probability" as a key metric, but the API `current=` block doesn't request it (only `precipitation` amount). **Fix:** source it from `hourly[0].precipitation_probability` (current hour) and document the sourcing in the entity mapping. Don't silently use `daily` max — that's a different number.
3. **UV index sourcing** — same: home grid shows UV; API has only `daily.uv_index_max`. Source from `daily[0]`, document it.
4. **Search offline.** Design §3.2: "search field disabled with caption 'Search needs a connection'." Architecture doesn't wire connectivity into the search controller. **Fix:** `searchController` watches `connectivityProvider`; offline → state carries `isOffline` → field disabled + caption. (Recent searches still tappable — they use cache.)
5. **Pull-to-refresh offline.** Design §3.1: "refresh disabled with explanation on tap." `RefreshIndicator.onRefresh` should check connectivity first and show the explanatory snackbar instead of spinning. Name this behavior.
6. **`ref.watch` + `select` discipline.** Home's hero, metrics grid, hourly preview, and daily forecast all read one `WeatherViewState`. Without `select`, every tick of "Updated X ago" rebuilds everything. **Fix:** document `ref.watch(homeControllerProvider.select((s) => ...))` per widget region in the widget guidelines; the "updated ago" ticker is its own tiny provider.
7. **Provider lifecycles.** Recommend: `homeController` keepAlive (root screen, survives tab switches), `settingsController` keepAlive, `searchController` **autoDispose** (sheet-scoped), `consentController` keepAlive (flow survives sheet rebuilds). Write the rule down — the wrong choice here causes the "state lost on rotation/sheet reopen" class of bugs.
8. **Settings toggle indeterminate shimmer.** Design §3.5: "If OS permission query pending → toggle shows indeterminate shimmer max 1s." Cap it: fall back to a disabled toggle after 1 s (a stuck shimmer is worse than a disabled control).
9. **L1 "cleared on unit-system change" is wrong.** §6: "cleared on unit-system change (display only — canonical cache stays SI)." If conversion is display-only at render, there is nothing to clear — the cache holds SI and the formatter re-runs. **Fix:** delete that clause; unit toggle triggers zero cache operations (this is also what makes US-12 AC2's 500 ms budget trivially safe).
10. **WMO code → label/icon mapping home.** Arch §13 Q4 asks; my answer: it lives in **presentation** (`features/common/weather_code_mapper.dart` — icons are presentation assets), labels via the en `arb` file so the l10n migration path is clean, unknown → FM-10 degraded path. One file, unit-tested against Appendix A's 29 codes.
11. **Landscape/tablet.** PRD §10.5 requires landscape without breakage; design spec gives 720 dp max width + 24 dp tablet margins. **Fix:** a `ResponsiveScaffold(maxWidth: 720)` wrapper used by every screen; home in landscape puts hero + metrics in a two-column `LayoutBuilder` branch. Name it now or every screen invents its own.
12. **In-flight dedupe ("identical request within 5 s attaches to the same future," PRD §8.2).** The repository impl needs a `Map<cacheKey, Future>` — and must remove the entry on completion to avoid leaking completed futures. Small, but write it in the impl contract.
13. **Consent sheet "Not now" vs OS "denied" vs "deniedForever"** — three distinct states with three distinct follow-ups (sheet dismisses / explainer sheet / settings deep-link card). The `ConsentState` enum covers it; ensure the controller maps all three, tested.
14. **`geocoding` package on-device reverse-geocode** actually uses the platform `Geocoder`, which on some Android devices requires network — FM-17's fallback chain covers it, but the "no network, no third party" claim in ADR-08 should say "no *app-level* network dependency; platform geocoder may use network per OS behavior." Precision of language matters for the privacy notice.
15. **Snackbar Undo (5 s) for device-city replacement** (design §5.2) — Undo must restore the previous saved city *and* its cached forecast; design the undo as "re-select previous place" through the normal selection path, not a special case.

---

## (c) ADR change requests

| ADR | Change requested |
|---|---|
| **ADR-02 (Riverpod)** | Amend: state *representation* is sealed screen-state unions via plain `Notifier`, not `AsyncNotifier` everywhere; `AsyncValue` used only where it genuinely fits (e.g. one-shot futures). Add provider lifecycle rules (keepAlive vs autoDispose per controller), `select` guidance, the `ref.listen` side-effect policy, and the debounce/`CancelToken`/`ref.onDispose` pattern as the canonical async-input recipe. |
| **ADR-03 (layering)** | Amend with the **DI composition rule**: abstract repository providers declared in domain (or domain-owned `lib/di/`), implementations bound via `ProviderScope` overrides in `main.dart`; presentation never imports `data/`. Add the `import_lint`/`custom_lint` layered rules to CI. Add `PlaceRepository` to the domain interface list. |
| **ADR-04/09 (units)** | Amend with the **formatter specification**: per-quantity precision table, round-half-away, negative-zero normalization, `intl`-locale decimal separators, `(UnitSystem, Locale, Clock)` signature, `FormattedValue(display, semanticLabel)`, compass + relative-time + location-timezone provenance rules. Model `UnitSystem` as independent axes (temp/wind/pressure) pending Sloane's decision on the segmented-control dispute. |
| **ADR-05 (validation)** | Amend with **two-tier validation**: Tier 1 structural → `AppFailure.schemaViolation` (fail closed); Tier 2 field-level → field becomes null/"—", entity still constructed (per PRD §7.2 / US-4 AC3 / FM-3 note). Entities carry nullable Tier-2 fields. This supersedes "no partial entity is ever constructed." |
| **ADR-06 (cache)** | Amend: `CacheRecord` gains `source: deviceLocation \| search` for the revocation wipe. Remove "L1 cleared on unit-system change." Add the in-flight-dedupe `Map<key, Future>` lifecycle rule. |
| **ADR-07 (precision)** | No change — but design-spec copy ("~10 km" ×3) must be corrected to "~1 km" before build; flag for Tech Law. |
| **ADR-08 (reverse geocode)** | Amend the "no network, no third party" claim → "no *app-level* network dependency; platform geocoder may use network per OS behavior." |
| **ADR-11 (Dio)** | Amend: 429 → **immediately** map to `AppFailure.rateLimited(retryAfter)`; countdown + single scheduled retry at the controller layer; never hold a Dio call open for `Retry-After`. Per-host minimum intervals in `RateLimitInterceptor` encode PRD §8.4 ceilings (1 forecast/5 s, 1 geocoding/300 ms). |
| **New: ADR-14 (UI state & side effects)** | The sealed screen-state unions per screen; staleness-as-property; banner-vs-fullscreen error rule (error is fullscreen only with no data); the failure→{inline, side-effect} table; `FailurePresentationMapper`; the `Announcer` for assertive/polite SR announcements. |
| **New: ADR-15 (accessibility implementation)** | Focus order/trap mechanics, skeleton `ExcludeSemantics` + single announcement, decorative-icon exclusion, heading/list semantics, 200%-scaling test plan, keyboard traversal + focus-ring widget, `MotionTokens` reduced-motion gate, tabular figures. |

---

## (d) Disputes for Sloane

1. **Field-level "—" vs. fail-closed error (BLOCKER-1).** PRD and architecture contradict. My recommendation: PRD wins with the two-tier refinement above — but the Enterprise Architect's "no partial entity" was a deliberate zero-trust stance, so this needs explicit sign-off, not silent drift. **Nothing in Phase 4 starts until this is decided**; it determines every DTO.
2. **Wind/pressure units in °F mode (PRD §13 Q1).** ADR-09 says all-or-nothing; design-spec Settings shows independent Temperature + Wind segmented controls. Product decision required. My recommendation: keep the independent-axes data model regardless (it's decision-proof), ship whichever UX the PO picks.
3. **Hourly count: 24 (PRD US-5) vs 48 (design spec §3.3).** PO call. (Implementation note: the API returns 168 hourly points for 7 days; either is a truncation choice.)
4. **Recent searches max: 10 (PRD US-13) vs 8 (arch §6) vs 5 (design §3.2).** PO call; my default is PRD's 10.
5. **Consent-sheet precision copy.** Must read "~1 km" per ADR-07, not "~10 km". Needs Tech Law eyes in Phase 3 regardless — it's a consent surface.
6. **Single source of truth for numeric constants** (timeouts, ranges, TTLs). I recommend the architecture's constants table as canonical with PRD/design-spec referencing it; QA's FM-reconciliation (arch §13 Q5) should fold these in.
7. **Cert pinning (arch §13 Q1)** — from the frontend seat: pinning adds an operational fragility (rotation runbook, emergency releases when Open-Meteo rotates) for a weather app with no secrets or PII in transit beyond coarse coords. I'd accept the residual risk and skip pinning for v1, with the decision recorded. AppSec's call in Phase 3.

**What I'd need from Phase 4 kickoff:** decisions on disputes 1–4, the corrected design-spec copy for dispute 5, and the amended ADRs above — after which the presentation layer is buildable without rework. The sealed-state unions, the DI composition rule, and the formatter spec are the three load-bearing pieces; everything else is craftsmanship.

— *Lead Mobile/Frontend Dev, Architecture & Code division*
