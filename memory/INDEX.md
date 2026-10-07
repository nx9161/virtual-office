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

* [2026-10-06]: War room "fruviacafe-audit" complete — full read-only QA audit of https://fruviacafe.com (ASP.NET MVC 5.2 / PW Foods white-label). Verdict: site would be BLOCKED as a release candidate (passwords/PII in GET query strings, no CSRF, eval() on server output, no security headers, no privacy notice at collection). AI red team explicitly N/A. Key legal ruling: owner (prospective vendor) has NO standing to take legal action against the cafe — leverage is commercial, memo is sales intelligence not legal advice. Deliverables in ~/workspace/fruviacafe-audit/ (findings register: 4 Critical/12 High/14 Medium/6 Low; legal-actions memo; rebuild pricing T1 $2.5–4K / T2 $6.5–12K / T3 $12–18K+$300–600/mo; pitch script). Memory room: memory/wings/projects/fruviacafe-audit/.

* [2026-10-06]: Initialized Virtual Office architecture and MemPalace memory repo layout.
* [2026-10-06]: Adopted 11-role roster in 4 divisions; War Room protocol gates production work.
* [2026-10-06]: Playbooks run as procedure docs via subagent-per-step orchestration (workflow result channel non-functional).
* [2026-10-06]: Weather App Architecture v1.0 proposed (Enterprise Architect): client-only, Riverpod 3, 13 ADRs; doc at `apps/weather_app/docs/ARCHITECTURE.md`; open Qs: cert pinning, Sentry data residency, l10n scope, FM-table reconciliation.
* [2026-10-06]: AI Red Team Phase 3 abuse-case review for Weather App: CONDITIONAL CLEAR, no BLOCK. One Medium (array-bomb payloads — require max body-size gate before `jsonDecode`), six Low/Info with concrete clearing conditions. Verdict recorded in `memory/wings/projects/weather_app.md`; full report at `~/workspace/virtual-office/redteam/weather_app_phase3_abusecase_review.md`.
* [2026-10-06]: Tech Law Phase 3 ruling on Weather App: **CLEAR WITH CONDITIONS** (C1–C7). Consent basis (GDPR Art 6(1)(a)) valid; precision copy "~1 km (rounded coordinates)" legally material and gating pre-build (R-4); 30-day in-app re-prompt vs never-reprompt-after-OS-denial compliant; Sentry requires EU DSN + DPA confirmation + IP scrubbing; BigDataCloud must be named in privacy notice; owner = controller of transmitted coords (Open-Meteo independent controller); CCPA sale/sharing negative confirmed; EU AI Act out of scope. Counsel flags: DE default-on crash reporting, Sentry DPA evidence, BigDataCloud terms, re-review triggers. Full ruling: `apps/weather_app/docs/TECH_LAW_RULING_phase3.md`.
* [2026-10-06]: Weather App War Room complete — PR #3 (full Flutter app + QA-gate fixes) open, awaiting owner merge; intake issue #4. AppSec BLOCK cleared as B-1..B-7, Red Team conditional clear, Tech Law clear with C1–C7 (C3/F1–F4 = owner actions). Merge prerequisites: CI flutter analyze/test green, bootstrap + pubspec.lock, device runs for perf/a11y.
* [2026-10-06]: Added 12th role — General Counsel (Legal & Governance division), worldwide legal coverage with blocking authority.
