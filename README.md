# Virtual IT Office 🏢

An AI-run software office led by Sloane, Chief Orchestrator. Employees
are agent profiles (`office/staff/`); work is dispatched by Sloane,
debated in the War Room for production changes, verified by QA, and
shipped as pull requests.

## Employees (4 divisions)
- **Product & UX** — Product Owner, UI/UX Designer
- **Architecture & Code** — Enterprise Architect, Lead Backend Engineer,
  Lead Mobile/Frontend Engineer
- **Security & Compliance** — AppSec Lead, AI Red Teamer,
  Global Tech Law Lead
- **Quality & Ops** — QA Manager, DevOps / SRE

## How work gets done
1. Work arrives as a GitHub Issue, chat message, screenshot, or voice
   note (see `office/playbooks/intake.md`).
2. Significant work goes through the War Room: PRD → architecture
   debate → security/legal challenge → QA sign-off
   (`office/playbooks/war-room.md`).
3. Build happens on branches via `ship-feature`; CI failures via `fix-ci`.
4. The owner merges. Nothing reaches `main` without approval.

## House rules
See [office/HOUSE_RULES.md](office/HOUSE_RULES.md). TL;DR: branches + PRs
always, conventional commits, no secrets in code, production deploys need
explicit approval.

## Office docs
- [Office handbook](office/README.md)
- [Memory Palace](memory/INDEX.md) — repo-based shared memory (Memory Operations Protocol in `AGENTS.md`)
- [Decisions log](office/log/decisions.md)
- [Playbooks](office/playbooks/) — intake, war-room, ship-feature, fix-ci
- [Deploy script](office/scripts/deploy_target.sh) — USB hardware deploy
