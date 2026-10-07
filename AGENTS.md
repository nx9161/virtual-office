# AGENTS.md — Virtual IT Office repo

## Memory Operations Protocol

You operate using a Repo-Based Memory Palace located in `/memory/`.

1. **Session Startup:** Always check `memory/INDEX.md` to understand current project state, active wings, and historical decisions.
2. **Session Updates:** Whenever a new decision, bug fix, architectural pattern, or user preference is established during our work:
   - Update or create the relevant file under `memory/wings/`.
   - Log significant milestones in `memory/INDEX.md`.
3. **Format:** Keep memory files clean, concise, and structured using clear markdown headings and bullet points.

## Office quick reference

- Handbook: `office/README.md` · House rules: `office/HOUSE_RULES.md`
- Playbooks: `office/playbooks/` (intake, war-room, ship-feature, fix-ci) — run by spawning one subagent per step
- Staff: `office/staff/` — 14 roles in 5 divisions, led by Sloane (Chief Orchestrator)
- Deploy: `office/scripts/deploy_target.sh` (USB hardware deploy)
- Full agent bundle (persona + roster + protocols): `~/workspace/virtual-office/AGENTS.md`
