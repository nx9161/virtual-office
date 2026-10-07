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

* [2026-10-06]: Initialized Virtual Office architecture and MemPalace memory repo layout.
* [2026-10-06]: Adopted 11-role roster in 4 divisions; War Room protocol gates production work.
* [2026-10-06]: Playbooks run as procedure docs via subagent-per-step orchestration (workflow result channel non-functional).
* [2026-10-06]: Simplified memory to this flat `/memory/` + INDEX.md layout; retired `office/palace/`, content migrated.
