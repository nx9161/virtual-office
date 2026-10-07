# War Room Protocol 🏢

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Validate](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml/badge.svg)](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml)

> An autonomous AI-run software office. Say the phrase, and **Sloane** —
> Chief Orchestrator — boots 15 specialists across 5 divisions to design,
> build, secure, and ship software through a four-phase War Room.

## ⚡ Activate this office

Paste this to any AI agent:

> I want to use War Room Protocol from nx9161's github public repo.

For maximum reliability (some AIs can't browse or search fresh repos),
paste this full block instead:

> I want to use War Room Protocol from nx9161's github public repo.
> Fetch this exact URL — do not web-search for it:
> https://github.com/nx9161/war-room-protocol
> If you cannot fetch it, ask me to paste office/AGENTS.md and I will.

The office stays active until you say **"End War Room Protocol"**.

Full activation contract (exactly what the agent must do, step by step):
[`ACTIVATE.md`](ACTIVATE.md).

## What this is

A complete software team as agent profiles. Product, architecture,
engineering, security, QA, DevOps, legal, and business analysis —
coordinated by Sloane, debated in the War Room before anything ships,
with every decision recorded. Built for owners who want senior-level
execution without managing a team.

Sister project: **[Seller Protocol](https://github.com/nx9161/seller-protocol)** —
the same operating model for Amazon FBA / DTC e-commerce, led by Mercer.

## How it works

**The Chief.** Sloane takes your request, dispatches specialists,
runs the War Room, and reports back status, numbers, and decisions
needed. One voice upward; zero fluff.

**The seats — 15 roles, 5 divisions.**

| Division | Seats |
|---|---|
| Product & UX | Product Owner, UI/UX Designer, Business Analyst |
| Architecture & Code | Enterprise Architect, Lead Backend Dev, Lead Mobile/Frontend Dev |
| Security & Compliance | AppSec Lead, AI Red Teamer, Global Tech Law Lead |
| Quality & Ops | QA Manager, DevOps / SRE, Prompt Writer, Knowledge Wizard |
| Legal & Governance | General Counsel |
| **Leadership** | **Sloane (Chief Orchestrator)** |

Four seats can **block** a release on their grounds: AppSec Lead,
AI Red Teamer, Global Tech Law Lead, General Counsel, and QA Manager.
Blocks stand until cleared or the owner accepts the risk in writing.

**Playbooks** (`office/playbooks/`) — repeatable procedures, each run as
one subagent per step: `intake`, `war-room`, `ship-feature`, `fix-ci`,
`skill-hunt`.

**The War Room** — runs before any significant build:

- **Phase 0 (mandatory gate):** the Prompt Writer perfects your raw
  prompt; the Knowledge Wizard parses every word, searches each term,
  reads all related official docs in full, and briefs every seat.
  No seat speaks before the dossier lands.
- **Phase 1 — Intake & PRD:** Product Owner, UI/UX Designer, Business
  Analyst.
- **Phase 2 — Architectural debate:** Enterprise Architect vs. Backend,
  Frontend, DevOps.
- **Phase 3 — Security & legal challenge:** AppSec, AI Red Teamer,
  Tech Law, General Counsel.
- **Phase 4 — Build & QA sign-off:** branches, PRs, 100% pass gate.

**Memory** (`memory/`) — the office's working memory: project notes,
decisions/ADRs, security policies, and your preferences. The office
reads it before acting and writes back every decision. See [Privacy](#-privacy--read-before-you-commit)
— this matters on a public repo.

**Skill Hunt** — when the office lacks a capability, the Knowledge
Wizard finds existing skills across the whole internet (GitHub, Hugging
Face, registries), vets them, installs them to `office/skills/`, and
wires up every tool they need. See `office/playbooks/skill-hunt.md`.

## Getting started — connect it to your system

Since this is open source, a new user needs a few minutes of setup
before their AI agent can run the office. Two paths:

### What you need

- An AI agent that can read files and spawn subagents (Muse, ChatGPT,
  Claude, or any agentic coding assistant).
- `git` — only if you want the local-integration path below.

### Option A — trigger phrase (30 seconds, zero setup)

Paste the activation phrase from [above](#-activate-this-office) into
any AI agent. It fetches this repo, loads the office bundle
(`office/AGENTS.md`), becomes Sloane, and confirms activation. Nothing
to install.

### Option B — local integration (recommended for daily use)

1. **Clone the repo:**
   `git clone https://github.com/nx9161/war-room-protocol && cd war-room-protocol`
2. **Give your agent the office.** Either:
   - Open the clone as your agent's working directory, or
   - Drop `office/AGENTS.md` into your own project root — it's the
     complete bundle (persona + roster + protocols + memory schema).
3. **Let it load memory.** The agent reads `memory/INDEX.md` first
   (Memory Operations Protocol, repo-root `AGENTS.md`), so it starts
   every session with full context.
4. **(Optional but recommended) connect GitHub:** run `gh auth login`.
   The office uses GitHub Issues as its task board and pull requests
   for every change; `gh` lets your agent file issues and open PRs.
5. **Talk to Sloane.** Give it work in plain language — text,
   screenshots, or voice notes (the intake playbook handles all three).
   End the session with **"End War Room Protocol"**.

### What the agent needs from your machine

| Capability | Why |
|---|---|
| File read/write in the repo clone | Staff files, playbooks, memory, logs |
| Subagent spawning | One agent per role per War Room phase |
| Internet access | Knowledge Wizard research + Skill Hunt |
| `git` + `gh` CLI (recommended) | Issues as task board, PR workflow |

## Repository map

```
├── ACTIVATE.md            # trigger-phrase activation contract
├── AGENTS.md              # repo operating manual (memory protocol)
├── office/
│   ├── AGENTS.md          # full agent bundle: persona + roster + protocols
│   ├── HOUSE_RULES.md     # binding rules for every employee
│   ├── PLAN.md            # founding plan
│   ├── README.md          # office handbook
│   ├── staff/             # 15 employee profiles (one file per role)
│   ├── playbooks/         # intake, war-room, ship-feature, fix-ci, skill-hunt
│   ├── skills/            # Wizard-installed skills (registry in README)
│   ├── scripts/           # automation (deploy, repo validation)
│   └── log/               # decisions.md + per-run journals
├── memory/                # working memory: projects, security, preferences
├── apps/                  # office-built applications
└── .github/               # issue/PR templates, CODEOWNERS, CI
```

CI runs `office/scripts/validate_repo.py` on every push and PR —
required files, reference integrity, hygiene.

## 🔒 Privacy — read before you commit

The office **records everything**: decisions and ADRs go to
`office/log/decisions.md` and `memory/`; your preferences live in
`memory/wings/user_preferences.md`. On a **public** repo or fork, all
of that is public — it reveals what you asked, what you decided, and
who you are.

**What's in this repo's memory right now:** a real client-project audit
(`memory/wings/projects/fruviacafe-audit/` — a real business, findings,
and the owner's commercial decisions) and the owner's identity in
`user_preferences.md`. Treat it as the example it is — then make your
own choice:

- **Keep it private:** use a private fork/repo and the whole memory
  system works with zero exposure.
- **Stay public:** fine for non-sensitive work — just know your ADRs
  are public writing.
- **Already published something sensitive?** Assume it's been copied;
  git history keeps it even if you delete the files. A history rewrite
  (`git filter-repo` + force-push) hides it from the repo going
  forward, but cannot un-publish what was already fetched.

Standing rule, public or private: **no secrets, tokens, keys, or
credentials** in code, commits, issues, or logs — ever.

## External dependencies

| Dependency | Required? | Notes |
|---|---|---|
| None | — | This repo is fully self-contained. No external git repos, no packages, no services needed to run the office. |
| MemPalace MCP (`mempalace-mcp`) | Optional | If you run a local MemPalace server, the file-based `memory/` can be mirrored into a vector store (`mempalace mine <repo>`). The office works fully without it. |

## Contributing, security, changelog

- [Contributing](CONTRIBUTING.md) — branch, PR, and safety rules
- [Security policy](SECURITY.md) — how to report vulnerabilities
- [Code of conduct](CODE_OF_CONDUCT.md)
- [Changelog](CHANGELOG.md)
- License: [MIT](LICENSE)
