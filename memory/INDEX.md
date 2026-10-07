# Memory Palace Index

## Active Wings & Rooms

* **`memory/wings/projects/virtual-office.md`**: The office itself — HQ repo, roster, routines, platform constraints, decisions, events.
* **`memory/wings/security/auth_policies.md`**: Security directives, OWASP rules, and compliance posture.
* **`memory/wings/user_preferences.md`**: Owner preferences, approval norms, deployment targets.

## How this works

- **Session startup:** read this file first, then open the wings relevant to the task.
- **Session updates:** whenever a new decision, bug fix, architectural pattern, or user preference is established — update or create the relevant file under `memory/wings/`, and log significant milestones below.
- **Format:** clean, concise markdown — clear headings and bullet points.

## Recent Architectural Decisions (ADRs)

* [2026-10-07]: War Room Phase 3 "arcade-suite" SIGNED (conditional, zero blocks) — IP-clean framework for the ~35-title original arcade-loop suite. Seats: AppSec Lead, Global Tech Law Lead, General Counsel (all conditional sign-off). Framework: 13 clean-design rules (borrow loops not lineups; Tetris "express differently" test; "if it needs a lawyer to argue, redesign"; mandatory clean-room; never market as clones), per-title clearance gate requiring BOTH Tech Law + GC signatures (incl. trade-dress line item), trademark-screening process (owner does not self-clear; rename-in-room), MOONDRIFT 5 extra guardrails + Atari-v-Philips analysis, AppSec annex (strict CSP w/ zero inline scripts, reproducible builds, 404 probes, preview gating, hard pre-deploy condition: Vercel AI-training opt-out flipped — still not done by owner), GC residual risk (JP/EU unresearched; meritless≠costless). NON-WAIVABLE: licensed counsel review before ANY monetized step (Ko-fi links going live counts). Build gate OPEN under conditions. Framework: memory/wings/projects/arcade-suite/ip-clean-framework.md; ADRs: memory/wings/projects/arcade-suite/decisions.md.

* [2026-10-07]: War Room "maxtechlife-audit" complete — full E2E audit + fix of maxtechlife.me (hub) and gloam.maxtechlife.me (GLOAM). Verdict: hub PASS; game CONDITIONAL PASS (TLS cert unprovisioned — platform/DNS lever, owner checklist issued). Shipped 4 merged PRs: keyboard-operable HUD + 44px targets + safe-area + a11y (gloam#1), iOS share-download fallback (gloam#2), JS minified as copy deterrent w/ readable src/gloam.js (gloam#3), hub theme-color (maxtechlife#1). Enforce HTTPS enabled on hub via Pages API. Phase 3: no blocks (AppSec conditional, Tech Law conditional on viewport fix — shipped, GC pass, Red Team N/A). ADRs: memory/wings/projects/maxtechlife-audit/decisions.md. Open: gloam cert (watcher goal owns it), post-merge QA re-verify, real-device spot-checks.

* [2026-10-06]: War room RE-RUN "fruviacafe-audit-rerun" complete — all 14 seats, subagent-per-role-per-phase (Phase 0 Prompt Writer perfected master prompt). Verdict: site still **BLOCKED** as release candidate (zero drift, zero remediations): 31 CONFIRMED / 5 drift-corrected / 7 NEW (N1–N7) / 0 fixed. Tech Law BLOCK cleared (B1–B5: cure-period sunset, log-purge advisory, consent-persistence); GC BLOCK partially cleared (B-1/B-2/B-4 reworded; **B-3 standing pre-send gate: licensed NJ counsel must draft/review Tier 1 contract before any client-facing send**). Pricing CONFIRMED (T1 $3,500/$2,800; T2 $6.5–12K + $8K floor guardrail; T3 $12–18K + $300/mo Care / $500–600/mo Growth; $150/hr floor). v2 deliverables shipped in ~/workspace/fruviacafe-audit/ (findings-register-v2.md, legal-actions-memo-v2.md, rebuild-proposal-pricing-v2.md, pitch-script-v2.md, tier1-charging-playbook-v2.md — 35-item SOW). Open: parent's live browser re-verification (15-item FLAGGED list). ADRs in memory/wings/projects/fruviacafe-audit/decisions.md; working notes in fruviacafe-audit/war-room-rerun/.

* [2026-10-06]: Tier 1 charging model set by 2nd focused war room — fixed-price **$3,500** (conditional **$2,800** limited-access variant if PW Foods denies code access); 50% deposit / 25%+25% milestones; 29-item SOW mapped to finding IDs; per-finding sign-off gate (security+privacy = hard blockers); 30-day warranty on regressions only; GO/NO-GO requires written PW Foods cooperation statement before signing. ADR in memory/wings/projects/fruviacafe-audit/decisions.md.

* [2026-10-06]: War room "fruviacafe-audit" complete — full read-only QA audit of https://fruviacafe.com (ASP.NET MVC 5.2 / PW Foods white-label). Verdict: site would be BLOCKED as a release candidate (passwords/PII in GET query strings, no CSRF, eval() on server output, no security headers, no privacy notice at collection). AI red team explicitly N/A. Key legal ruling: owner (prospective vendor) has NO standing to take legal action against the cafe — leverage is commercial, memo is sales intelligence not legal advice. Deliverables in ~/workspace/fruviacafe-audit/ (findings register: 4 Critical/12 High/14 Medium/6 Low; legal-actions memo; rebuild pricing T1 $2.5–4K / T2 $6.5–12K / T3 $12–18K+$300–600/mo; pitch script). Memory room: memory/wings/projects/fruviacafe-audit/.

* [2026-10-06]: Initialized Virtual Office architecture and MemPalace memory repo layout.
* [2026-10-06]: Adopted 11-role roster in 4 divisions; War Room protocol gates production work.
* [2026-10-06]: Playbooks run as procedure docs via subagent-per-step orchestration (workflow result channel non-functional).
* [2026-10-06]: Added 12th role — General Counsel (Legal & Governance division), worldwide legal coverage with blocking authority.
* [2026-10-06]: Added 13th role — Business Analyst (Product & UX), commercial P&L + pricing intelligence; joins War Room Phase 1.
* [2026-10-06]: Added 14th role — Prompt Writer (Quality & Ops): prompt refiner + closed-loop finisher; intake pipeline now starts with perfect-then-parse.
---
- 2026-10-07: Knowledge Wizard added as 15th seat (Quality & Ops); War Room Phase 0 gate — Prompt Writer perfects prompt, Wizard briefs every seat from fully-read docs before anyone speaks.
* [2026-10-07]: Weather App project removed per owner request — PR #3 closed unmerged, issue #4 closed, branch deleted, app code and palace room removed.
