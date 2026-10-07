# Decisions Log

| Date | Decision | Owner |
|------|----------|-------|
| 2026-10-06 | Office founded. Private repo `nx9161/virtual-office` is HQ. Starter roster: backend-dev, frontend-dev, qa-engineer, devops, tech-writer. | owner |
| 2026-10-06 | Authority default: employees work on branches and open PRs; only the owner merges to `main`; production deploys need explicit approval every time. | owner |
| 2026-10-06 | Playbooks v1 registered: `ship-feature` (implement→verify→review→PR with repair loop), `fix-ci` (diagnose→fix→verify). | office-manager |
| 2026-10-06 | Routines v1: daily triage 09:00 ET, weekly report Monday 09:00 ET, new-issue watcher hook. | office-manager |
| 2026-10-06 | Fixed ship-feature playbook result parsing: agent results arrive wrapped in a {status, result} envelope (sometimes as JSON strings). Added lenient parsing + envelope unwrapping, verified with local tests. | office-manager |
| 2026-10-06 | Playbooks moved from saved workflow scripts to procedure docs (office/playbooks/*.md). Root cause, verified by probe: the workflow runtime returns empty objects from agent() calls, so script-driven branching on step results is impossible. Procedures run via subagent-per-step orchestration instead — same steps and roles, strictly more reliable. | office-manager |
| 2026-10-06 | Adopted owner's Autonomous Virtual IT Office Specification | Replaced 5-person starter roster with 11 roles in 4 divisions (Product & UX, Architecture & Code, Security & Compliance, Quality & Ops); added War Room protocol, intake engine, deploy_target.sh, and Memory Palace knowledge store (office/palace). Sloane persona already live as assistant identity. | owner |
| 2026-10-06 | Simplified memory to flat /memory/ + INDEX.md | Retired office/palace/ (wings/rooms/halls); content migrated to memory/wings/. Memory Operations Protocol adopted in repo AGENTS.md and assistant operating manual. | owner |
| 2026-10-06 | AppSec BLOCK on Weather App → cleared as build requirements | AppSec blocked the build (HIGH-1/2, MEDIUM-1..4, LOW-1/2/3). Sloane ruled: block converts to 7 binding build requirements B-1..B-7 (no re-architecture, no owner input needed for technical items); cleared when build implements + QA verifies. Red Team conditional clear, Tech Law clear-with-conditions (C1-C7; C3/F1-F4 = owner actions). Record: apps/weather_app/docs/WAR_ROOM_RECORD.md. | sloane |
| 2026-10-06 | War Room closed for Project: Weather App; PR #3 opened, not merged | Full 4-phase war room done; PR #3 delivers complete app + QA fixes; issue #4 intake. Parent committed partial mid-build snapshot to main (38a7a53) during the run — flagged. Repo now public (MIT) — owner to confirm intended. Stale feat/weather-app branch superseded. | sloane |
| 2026-10-06 | Added 12th role: General Counsel (Legal & Governance) | Worldwide legal coverage, tech & non-tech; jurisdiction matrix, contracts/IP/corporate/employment; blocking authority on legal grounds; must escalate to licensed local counsel for binding advice. War Room Phase 3 and house-rule blockers updated. | owner |
| 2026-10-06 | Added 13th role: Business Analyst (Product & UX) | Commercial brain — business P&L, service pricing/margins, worldwide IT pricing intelligence, business tips; joins War Room Phase 1 with the business case. Advisory (no block). Business profile stub at memory/wings/business/profile.md awaiting owner details. | owner |
| 2026-10-06 | Added 14th role: Prompt Writer (Quality & Ops) | Forges raw prompts into perfected prompts; every agent works from the perfected version; closed-loop until done — bounded retries (max 3, each changes something), then escalates. Front door of intake pipeline. | owner |

## 2026-10-07 — Knowledge Wizard joins as 15th seat; War Room Phase 0 gate
- **Context:** Owner ordered both offices to have a Prompt Writer and a
  Knowledge Wizard as subagents. IT office had the Writer; added the Wizard.
- **Decision:** New seat `knowledge-wizard` (Quality & Ops). Split is clean:
  Prompt Writer perfects the *ask*, Knowledge Wizard gathers the *knowledge*.
  War Room gains mandatory Phase 0: Writer perfects the prompt → Wizard parses
  every word, searches each term, reads all related official docs in full,
  injects a per-seat dossier → no seat speaks before the dossier lands.
- **Owner:** Naman

## 2026-10-07 — Activation contract: trigger phrase boots the office
- **Context:** Owner wants the phrase "I want to use War Room Protocol
  from nx9161's github public repo" to activate the Sloane office in any
  agent session.
- **Decision:** Added `ACTIVATE.md` (agent-agnostic activation contract:
  fetch repo → read office/AGENTS.md → adopt Sloane → load memory →
  confirm with the exact activation line) and an "Activate this office"
  section in the README with the copy-paste trigger phrase.
- **Owner:** Naman

## 2026-10-07 — Skill Hunt: Wizard finds/vets/installs skills from the whole internet
- **Context:** Owner ordered that the Knowledge Wizard find every
  existing skill (GitHub public repos, Hugging Face, registries, open
  web), install it, wire up all required tools, and go down the rabbit
  hole until the task is executable.
- **Decision:** New `skill-hunt` playbook (define → hunt → vet →
  install → wire tools recursively → test → record); skills live in
  `office/skills/<slug>/SKILL.md` with a registry; Wizard owns it, any
  seat can request a hunt. Guardrails: provenance recorded, no blind
  installs, no exfiltration/phone-home without owner approval,
  secrets/keys/accounts stop the hunt and escalate. House rules §8.
- **Owner:** Naman
| 2026-10-07 | Weather App project removed per owner request | PR #3 closed unmerged, issue #4 closed, feat/weather-app-qa-fixes branch deleted, apps/weather_app/ code, CI workflow, and palace room removed. All recoverable from git history. | owner |
