# War Room Protocol 🏢

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Validate](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml/badge.svg)](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml)

An AI-run software office led by Sloane, Chief Orchestrator. Employees
are agent profiles (`office/staff/`); work is dispatched by Sloane,
debated in the War Room for production changes, verified by QA, and
shipped as pull requests.

## ⚡ Activate this office

Paste this to any AI agent:

> I want to use War Room Protocol from nx9161's github public repo.

The office stays active until you say **"End War Room Protocol"**.

Full activation contract (what the agent must do, step by step):
[`ACTIVATE.md`](ACTIVATE.md).

## Employees (15 seats, 5 divisions)
- **Product & UX** — Product Owner, UI/UX Designer, Business Analyst
- **Architecture & Code** — Enterprise Architect, Lead Backend Dev,
  Lead Mobile/Frontend Dev
- **Security & Compliance** — AppSec Lead, AI Red Teamer,
  Global Tech Law Lead
- **Quality & Ops** — QA Manager, DevOps / SRE, Prompt Writer,
  Knowledge Wizard
- **Legal & Governance** — General Counsel
- **Leadership** — Sloane (Chief Orchestrator)

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
