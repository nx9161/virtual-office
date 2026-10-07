# virtual-office — project room

## Facts

- HQ repo: `nx9161/virtual-office` (private); local clone at `~/workspace/virtual-office/repo`.
- 11 roles in 4 divisions (Product & UX, Architecture & Code, Security & Compliance, Quality & Ops), led by Sloane (Chief Orchestrator).
- `main` is always deployable; all changes via PR; only the owner merges to `main`.
- Production deploys need explicit owner approval, every time.
- Workflow engine `agent()` calls return empty objects — playbooks run as procedures via subagent-per-step orchestration, not workflow scripts.
- gh CLI authed as `nx9161`; git identity "Virtual IT Office".
- Routines: daily triage ~09:43 ET, weekly report Monday ~09:43 ET, urgent-issue watcher hook every 5 minutes.

## Decisions

| Date | Decision | Owner |
|------|----------|-------|
| 2026-10-06 | Office founded: repo created, starter roster, routines installed | owner |
| 2026-10-06 | First mission PR #1 (CONTRIBUTING.md + issue/PR templates) reviewed and merged | owner |
| 2026-10-06 | Adopted Autonomous Virtual IT Office Specification: 11-role roster, War Room protocol, intake engine, deploy script, palace | owner |
| 2026-10-06 | Playbooks as procedure docs (`office/playbooks/*.md`) instead of workflow scripts | office-manager |
| 2026-10-06 | Memory simplified to flat `/memory/` + INDEX.md; `office/palace/` retired, content migrated here | owner |

## Events

- 2026-10-06: Repo created, cloned, seeded with handbook, staff files, playbooks.
- 2026-10-06: PR #1 opened by the office, QA-reviewed, merged into `main`.
- 2026-10-06: Spec re-architecture committed and pushed (11 roles, War Room, palace).
