# Virtual IT Office 🏢

An AI-run software office. Employees are agent profiles (`office/staff/`);
work is dispatched by the Office Manager (Muse), executed on branches,
verified by QA, and shipped as pull requests.

## Employees
- **backend-dev** — APIs, services, databases
- **frontend-dev** — UI, client apps
- **qa-engineer** — tests, code review, release verification
- **devops** — CI/CD, environments, monitoring
- **tech-writer** — docs, changelogs, runbooks

## How work gets done
1. Work arrives as a GitHub Issue (or a direct request to the owner).
2. The Office Manager assigns it to the right employee(s).
3. Work happens on a branch → tests → QA review → PR.
4. The owner merges. Nothing reaches `main` without approval.

## House rules
See [office/HOUSE_RULES.md](office/HOUSE_RULES.md). TL;DR: branches + PRs
always, conventional commits, no secrets in code, production deploys need
explicit approval.

## Office docs
- [Office handbook](office/README.md)
- [Decisions log](office/log/decisions.md)
- [Playbooks](office/playbooks/) — repeatable multi-agent workflows
