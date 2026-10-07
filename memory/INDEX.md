# Memory Palace Index

## Active Wings & Rooms

* **`memory/wings/projects/virtual-office.md`**: The office itself — HQ repo, roster, routines, platform constraints, decisions, events.
* **`memory/wings/projects/weather_app.md`**: Weather App mission — PRD/Design done, Architecture v1.0 proposed, key ADRs, open Phase 2/3 questions.
* **`memory/wings/security/auth_policies.md`**: Security directives, OWASP rules, and compliance posture.
* **`memory/wings/user_preferences.md`**: Owner preferences, approval norms, deployment targets.

## How this works

- **Session startup:** read this file first, then open the wings relevant to the task.
- **Session updates:** whenever a new decision, bug fix, architectural pattern, or user preference is established — update or create the relevant file under `memory/wings/`, and log significant milestones below.
- **Format:** clean, concise markdown — clear headings and bullet points.

## Recent Architectural Decisions (ADRs)

* [2026-10-06]: Initialized Virtual Office architecture and MemPalace memory repo layout.
* [2026-10-06]: Adopted 11-role roster in 4 divisions; War Room protocol gates production work.
* [2026-10-06]: Playbooks run as procedure docs via subagent-per-step orchestration (workflow result channel non-functional).
* [2026-10-06]: Weather App Architecture v1.0 proposed (Enterprise Architect): client-only, Riverpod 3, 13 ADRs; doc at `apps/weather_app/docs/ARCHITECTURE.md`; open Qs: cert pinning, Sentry data residency, l10n scope, FM-table reconciliation.
* [2026-10-06]: AI Red Team Phase 3 abuse-case review for Weather App: CONDITIONAL CLEAR, no BLOCK. One Medium (array-bomb payloads — require max body-size gate before `jsonDecode`), six Low/Info with concrete clearing conditions. Verdict recorded in `memory/wings/projects/weather_app.md`; full report at `~/workspace/virtual-office/redteam/weather_app_phase3_abusecase_review.md`.
* [2026-10-06]: Weather App QA final-gate REQUEST CHANGES fixes (Lead Mobile/Frontend): B1 hourly slice from current local hour + FM-17 note; B2 full US-4 AC2 metrics grid; B3 daily accordion with sunrise/sunset; B4 FM-12 headline single-sourced to the mapper; parameterized FM headline/action sweep + weather_code_mapper tests; ARCHITECTURE.md §9 superseded note; tool/bootstrap.sh (idempotent, SDK bootstrap, backup-rules checksum guard) + README manual platform steps (Android manifest, iOS backup exclusion). No SDK on VM — CI is the verification gate; not committed (Sloane commits after QA).
* [2026-10-06]: Weather App Phase 4 BUILD complete (Lead Mobile/Frontend): full Flutter app at `apps/weather_app/` — presentation layer (home/search/hourly/daily/settings/consent/privacy), l10n, main.dart/app.dart, 163 test assertions across unit/widget/contract/privacy, tool/build.sh, fixture regen, CI workflow, README, Android backup rules. Not committed (Sloane commits after QA). `flutter analyze/test/build` not run here (no SDK); CI is the verification gate.
* [2026-10-06]: Tech Law Phase 3 ruling on Weather App: **CLEAR WITH CONDITIONS** (C1–C7). Consent basis (GDPR Art 6(1)(a)) valid; precision copy "~1 km (rounded coordinates)" legally material and gating pre-build (R-4); 30-day in-app re-prompt vs never-reprompt-after-OS-denial compliant; Sentry requires EU DSN + DPA confirmation + IP scrubbing; BigDataCloud must be named in privacy notice; owner = controller of transmitted coords (Open-Meteo independent controller); CCPA sale/sharing negative confirmed; EU AI Act out of scope. Counsel flags: DE default-on crash reporting, Sentry DPA evidence, BigDataCloud terms, re-review triggers. Full ruling: `apps/weather_app/docs/TECH_LAW_RULING_phase3.md`.
