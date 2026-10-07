# Weather App — War Room Record

**Project:** Weather App (production-grade Flutter cross-platform, Open-Meteo APIs, no key)
**War Room:** 2026-10-06 · **Orchestrator:** Sloane, Chief Orchestrator
**Branch:** `feat/weather-app` · **Status:** Build phase (this record covers Phases 1–3)

---

## Phase 1 — Intake & PRD (parallel)

- **Product Owner → `docs/PRD.md` v1.0.** Problem statement, 13 user stories (US-1…US-13, P0/P1) with measurable acceptance criteria, 4 screens, zero-trust API spec with per-field whitelist/range/violation tables (forecast + geocoding), rate limiting (300 ms debounce, 10-min forecast TTL, retry budget), GDPR privacy spec, NFRs (perf budgets, WCAG 2.1 AA), 20 failure modes (FM-1…FM-20), 10-item Definition of Done.
- **UI/UX Designer → `docs/design-spec.md` v1.0.** 4 screens with loading/empty/error/offline states, design tokens (light+dark), location-consent flow (in-app sheet BEFORE OS dialog), accessibility notes, content rules. *(Amended post-Phase 3: precision copy "~10 km" → "~1 km (rounded coordinates)" per C1.)*

## Phase 2 — Architectural Debate

- **Enterprise Architect → `docs/ARCHITECTURE.md` v1.0** (client-only, Riverpod 3, clean-architecture layering, Dio interceptors, two-tier Hive cache, sealed `AppFailure`, 13 ADRs) + **§14 — Sloane's rulings (binding on build):**
  - **R-1** Validation two-tier: Tier 1 structural → fail closed; Tier 2 field-level → "—", entity kept (PRD wins over "no partial entity").
  - **R-2** Zero coordinates in logs/Sentry; full query-string redaction.
  - **R-3** Numbers align to PRD (timeout 10 s, fix 15 s, utc_offset ±50400, pressure 800–1100, recents 10, hourly 24).
  - **R-4** Consent copy "~1 km (rounded coordinates)".
  - **R-5** `uv_index_max` param approved. **R-6** No cert pinning v1.
  - **R-7** Release topology: store tracks for release; `deploy_target.sh` = inner-loop dev/QA.
  - **R-8** Sealed screen-state unions, plain `Notifier` (new ADR-14); staleness is a data property.
  - **R-9** DI composition rule: abstract providers in domain, impls via `ProviderScope` overrides; `import_lint` in CI.
  - **R-10** `PlaceRepository` added. **R-11** `UnitSystem` independent axes; locale-based °F default.
  - **R-12** 429 → immediate `rateLimited(retryAfter)`; countdown at controller.
  - **R-13** `CacheRecord.source` (deviceLocation|search); revocation deletes by source, cancels in-flight.
  - **R-14** `AppFailure.locationTimeout` added. **R-15** A11y implementation spec (new ADR-15).
  - **R-16** Reproducibility: `.fvmrc`, locks committed, `--enforce-lockfile`, canonical release command.
  - **R-17** Sentry crash-only, EU DSN pending, opt-out disables initialized client, first-run disclosure.
  - **R-18** Sanctioned secrets: Android keystore, iOS certs, Sentry auth token — platform secret store only.
- **Critiques:** `docs/BACKEND_REVIEW_phase2.md`, `docs/FRONTEND_REVIEW_phase2.md`, DevOps review (delivered in War Room; release-topology P0, `deploy_target.sh` fixes, size-gate, signing).

## Phase 3 — Security & Legal Challenge

- **AppSec → `docs/APPSEC_REVIEW.md` — ⛔ BLOCK**, cleared by Sloane's ruling below. OWASP Mobile Top 10 reviewed. 7 clearing conditions → all converted to binding build requirements (B-1…B-7).
- **AI Red Teamer → `docs/REDTEAM_review_phase3.md` — CONDITIONAL CLEAR.** 7 abuse cases; mandatory: max response-body gate (~512 KB) BEFORE `jsonDecode` (AC-4b); plus control-char stripping, 429 telemetry, cache-HMAC-or-rationale, OS-grant test, BigDataCloud disclosure.
- **Tech Law → `docs/TECH_LAW_RULING_phase3.md` — CLEAR WITH CONDITIONS (C1–C7).** Consent valid (GDPR Art. 6(1)(a)); EU DSN required (Schrems II); DPA confirmation = owner action; BigDataCloud must be named in notice; owner is data controller (not Open-Meteo); CCPA negative; EU AI Act N/A. Real-counsel flags F1–F4 → owner.

## Sloane's ruling on the AppSec BLOCK (2026-10-06)

The block stands as **7 binding build requirements**; it is cleared when the build implements them and QA verifies each. No re-architecture needed; no owner input needed for the technical conditions (all are code-level). Owner-input items are separately tracked (Sentry DPA + EU DSN confirmation, F1–F4 counsel flags).

| # | Requirement (from APPSEC_REVIEW.md §9) | Maps to |
|---|---|---|
| B-1 | SHA-256-hashed cache keys; lat/lon echo stripped from stored payload; `cacheCorrupted` logs key-hash only; DoD#5 asserts no *plaintext* coords at rest; revocation deletes by hash | HIGH-1 |
| B-2 | `beforeSend` coordinate scrubber (full query redaction + lat/lon regexes), unit-tested; raw `DioException` never captured by Sentry; release logs carry no URI | HIGH-2 |
| B-3 | BigDataCloud response whitelist (name 1…200, country_code 2 chars); violations → "Current location"; never persist raw | MEDIUM-1 |
| B-4 | Weekly CI contract-fixture regeneration from live API; FM-8 breadcrumbs aggregated as Sentry issues | MEDIUM-2 |
| B-5 | Android backup rules exclude Hive boxes; iOS excludes Hive dir from backup; documented | MEDIUM-3 |
| B-6 | Canonical `asInt`/`asDouble` coercion helpers mandated; empty Tier-1 array → `schemaViolation`; equalize-before-index; coercion unit tests | MEDIUM-4 |
| B-7 | Echo failures → `schemaViolation`; `User-Agent: weather-app/<version>` set; 429 budget enforced across R-12 path + jitter; Sentry envelope cache purged on opt-out | LOW-1/2/3 |

**Red-team build requirements:** body-size gate ≤512 KB before decode (both Dio instances); control-char stripper at string-ingestion boundary (query + API string fields); 100-char cap at widget AND validation layer; FM-12 echo ≤50 chars escaped; 429 breadcrumb + counter; controller 429-retry cancellable on dispose; cache HMAC (Keystore/Keychain) or written rationale; test: device-location forecast requires OS grant, not just `ConsentState.granted`.

**Tech-Law build requirements:** C1 done (design-spec copy fixed); C2 privacy notice per 12-section spec (BigDataCloud named, retention rule, controller identity); C4 neutral 30-day re-prompt; C6 retention schedule + "Delete local data" verified; C7 DoD privacy gates (no-coords-in-storage test, no-coords-in-logs test, consent-before-OS manual test). **Owner actions:** C3 (Sentry EU DSN + DPA confirmation + IP scrubbing), F1–F4 counsel flags.

---

## Build phase entry criteria — ALL MET

- [x] PRD v1.0 + design spec v1.0 (C1 copy fix applied)
- [x] Architecture v1.0 + §14 rulings (binding)
- [x] Phase 3 verdicts: AppSec BLOCK → converted to B-1…B-7 (cleared by implementation + QA); Red Team conditional clear; Tech Law clear with conditions
- [x] No outstanding disputes (all Phase 2 disputes ruled; Phase 3 conditions scheduled)
- [ ] Owner actions (tracked, non-blocking for build): Sentry DPA + EU DSN confirmation; F1–F4 counsel review
