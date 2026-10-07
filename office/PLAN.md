# Virtual IT Office — Plan (draft)

Owner's intent: a virtual IT office where each "employee" is an AI agent.
When a new employee is hired, a new subagent profile is created. Work is
done in a GitHub repo (the office's shared workspace), and routine work
runs on its own once the office is set up.

## How it actually works (honest architecture)

Subagents are not always-on employees — they spin up per task, do the
work, and report back. So the office is built from four durable parts:

1. **Employee files** (`~/workspace/virtual-office/staff/<name>.md`)
   Each employee's standing profile: role, responsibilities, tech stack,
   coding standards, authority limits, escalation rules. Hiring = writing
   a new file. When a task comes in, the Office Manager instantiates that
   employee as a subagent with the file as its brief.

2. **Office Manager** (Muse, your assistant)
   Dispatches tasks to employees, reviews their output, handles approvals
   that employees are not authorized to take, and reports back to you.

3. **Routines** (scheduled + event-driven autonomy)
   - Crons: daily standup triage, dependency/security patrol, stale-PR
     nudges, weekly office report to you.
   - Hooks: lightweight watchers that poll for triggers (new GitHub issue
     labeled `ready`, new PR comment, CI failure) and wake an agent.

4. **Playbooks** (saved, named multi-agent workflows)
   Repeatable pipelines with verifier-repair loops, e.g. "ship a feature":
   implement → test → review → PR. Launchable by name, any time.

The GitHub repo holds: code, task board (Issues/Projects), docs, and an
`office/` folder with decisions log and run journals.

## Proposed starter roster (v1)

1. **backend-dev** — APIs, services, databases.
2. **frontend-dev** — UI, web artifacts, client apps.
3. **qa-engineer** — tests, code review, release verification.
4. **devops** — CI/CD, deployments, environments, monitoring.
5. **tech-writer** — docs, READMEs, changelogs, runbooks.

Optional later: security-reviewer, data-analyst, support-triage.

## House rules (default authority levels — adjustable)

- Employees work on branches, open PRs, never push to `main` or merge
  without approval.
- No spending money, no external messages/posts, no credential handling,
  no deletions without explicit approval.
- Every decision and run outcome is logged in the repo (`office/log/`).
- Escalation: anything ambiguous, costly, or irreversible comes to you
  via the Office Manager.

## Build phases

1. **Foundation**: connect GitHub (`gh auth login`), clone repo, lay out
   `office/` folder, write employee files + house rules.
2. **Playbooks**: create the first saved workflows (ship-feature, review-
   PR, fix-CI-failure).
3. **Routines**: install crons (daily triage, weekly report) and hooks
   (new-issue watcher).
4. **First mission**: give the office a real task end-to-end to prove the
   loop: assign → build → verify → PR → report.
5. **Hiring loop**: document how to add a new employee so it is one
   command/conversation going forward.

## Open questions for the owner

1. GitHub repo URL (new or existing?) + run `gh auth login` (device flow).
2. Confirm/adjust the starter roster.
3. Authority level: default above, or do you want employees able to merge
   after your one-tap review?
4. First mission: what should the office build first (or decide later)?
