# War Room Protocol 🏢

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Validate](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml/badge.svg)](https://github.com/nx9161/war-room-protocol/actions/workflows/validate.yml)

> An autonomous AI-run software office. Say the phrase, and **Sloane** —
> Chief Orchestrator — boots 20 specialists across 6 divisions to design,
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

The office stays active until you say **"End War Room Protocol"** —
and while active, **every message you send goes through the War Room
loop** (full war room for big work, quick huddle for small stuff).

Full activation contract (exactly what the agent must do, step by step):
[`ACTIVATE.md`](ACTIVATE.md).

## 🔌 Install as a DeepSeek Harness plugin

Rather paste nothing at all? Install it once — then the trigger phrase
works from the first message of every new session. In the Harness
plugin screen, enter the GitHub address:

```
nx9161/war-room-protocol
```

or via CLI:

```bash
dsh plugin --profile web add github:nx9161/war-room-protocol
# local clone also works:
dsh plugin --profile web add /path/to/war-room-protocol
```

Then open a **new** session. The plugin injects the activation contract
on session start, so you can say the phrase immediately — no fetching,
no pasting.

The npm package name `dsh-plugin-war-room-protocol` is reserved for a
future publish; the GitHub address installs today. The plugin is
zero-build and zero-dependency, so `github:` installs just work.

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

**The seats — 20 roles, 6 divisions.**

| Division | Seats |
|---|---|
| Product & UX | Product Owner, UI/UX Designer, Business Analyst |
| Architecture & Code | Enterprise Architect, Lead Backend Dev, Lead Mobile/Frontend Dev |
| Security & Compliance | AppSec Lead, AI Red Teamer, Global Tech Law Lead |
| Quality & Ops | QA Manager, DevOps / SRE, Prompt Writer, Knowledge Wizard |
| Legal & Governance | General Counsel |
| Games | Game Architect, Gameplay Designer, Game UI/UX Designer, Console Platform Engineer, Game Producer |
| **Leadership** | **Sloane (Chief Orchestrator)** |

Six seats can **block** a release on their grounds: AppSec Lead,
AI Red Teamer, Global Tech Law Lead, General Counsel, QA Manager, and
Console Platform Engineer (certification/platform compliance).
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
  Analyst. Game projects add Gameplay Designer (pillars, core loop)
  and Game UI/UX Designer (player experience).
- **Phase 2 — Architectural debate:** Enterprise Architect vs. Backend,
  Frontend, DevOps. Game projects add Game Architect (engine, systems,
  performance) and Console Platform Engineer (PS5/Xbox/PC constraints).
- **Phase 3 — Security & legal challenge:** AppSec, AI Red Teamer,
  Tech Law, General Counsel. Game projects add the Console Platform
  Engineer's TRC/XR certification review (blocking).
- **Phase 4 — Build & QA sign-off:** branches, PRs, 100% pass gate.
  Game projects add the Game Producer's production gate.

**Live discussion** — seats don't file reports, they debate each other
through Sloane: positions, rebuttals, concessions, max 3 rounds per
question, then the gavel. Platforms without subagents get the same
debate as labeled tabletop dialogue in a single response.

**Phase regression** — phases aren't one-way. A finding that
invalidates earlier output loops the request back to that phase
(max 3 regressions per request, then Sloane escalates or terminates).

**"Discuss again"** — re-debates everything, original request plus all
prior topics, with previous conclusions as context and fresh research
on what's changed. New verdict references the prior ADR. No new
information, no theater — Sloane recommends instead.

**Sloane decides** — she monitors every phase gate with full
operational power: advance, loop back, re-scope, pause, escalate,
terminate. Money, production deploys, and external commitments still
need your explicit approval.

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
  Claude, or any agentic coding assistant). Agents without subagents
  (e.g. Gemini, DeepSeek chat) get the same debate as labeled tabletop
  dialogue instead.
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

### Option C — Codex global install (one-time)

Codex CLI auto-loads `~/.codex/AGENTS.md` at every session start.
Install this activation contract there — it stays dormant until you
say the phrase. Do **not** install the full `office/AGENTS.md`
globally: it loads the Sloane persona unconditionally and would turn
every coding session into Sloane.

```bash
mkdir -p ~/.codex
cat >> ~/.codex/AGENTS.md << 'EOF'
# War Room Protocol — activation contract (dormant until triggered)

When the user says they want to use "War Room Protocol" from nx9161's
GitHub (or similar phrasing):
1. Fetch https://github.com/nx9161/war-room-protocol — the exact URL.
   Never search for it, never substitute another repo.
2. Read ACTIVATE.md, then office/AGENTS.md, and follow them exactly:
   become Sloane, confirm with the activation line, and run the
   always-on War Room loop until the user says "End War Room Protocol".
3. If you cannot fetch the repo, ask the user to paste the contents
   of office/AGENTS.md.

Until a trigger phrase is spoken, behave normally — this contract is
dormant.
EOF
```

Verify with `codex status` in your next session. For the Codex IDE
extension or web app (where the global file may not apply), the
trigger phrase alone still works.

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
│   ├── staff/             # 20 employee profiles (one file per role)
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
