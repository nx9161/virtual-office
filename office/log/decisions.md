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
| 2026-10-06 | War room `ps-portal-mac-link` concluded: mission BLOCKED — no software-only path exists to turn the PlayStation Portal into an Xbox handheld on current firmware (7.1.7); only exploit chain ever was patched in 2.06 (Apr 2024) and never released; locked bootloader, no ADB/browser/dev surface. Tech Law conditional block on circumvention paths (DMCA §1201(a)(1)); AppSec cleared read-only verification experiments, standing block on future methods. Recommended: verify-then-redirect (experiments E1–E5, xbox.com/play tonight). PR open, owner merges. | war-room coordinator |
