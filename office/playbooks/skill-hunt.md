# Playbook: Skill Hunt

The Knowledge Wizard's standing capability: when a task needs a skill
the office doesn't have, the Wizard hunts it down across the whole
internet, installs it, wires up every tool it needs, and goes down the
rabbit hole until the task is fully executable.

## Trigger
Any task where the Wizard — or any seat — identifies a missing
capability: "we don't have a skill for X."

## Procedure (Wizard runs as subagent, spawns hunters per step)

1. **Define the need.** One sharp sentence: what must the office be able
   to do? Plus acceptance criteria: how will we know the skill works?

2. **Hunt.** Search GitHub public repos, Hugging Face (spaces, models,
   datasets), package registries (npm, PyPI), and the open web for
   existing skills, tools, and implementations. Rank candidates by:
   solves the need, maintained, licensed for our use, documented.

3. **Vet.** Read the top candidate's code/docs — no blind installs.
   Reject: obfuscated code, credential harvesting, miners, unlicensed
   copypasta, dead projects with no viable fork. Record provenance:
   source URL, commit/tag, license, date.

4. **Install.** Add it as `office/skills/<slug>/` with a `SKILL.md`
   (frontmatter: name, description, version, source URL, license,
   installed date; body: how to use). Keep the original license file
   alongside.

5. **Wire the tools — down the rabbit hole.** List everything the skill
   needs to run: CLIs, packages, data files, models, MCP servers, API
   access. For each:
   - Already have it? Done.
   - Publicly installable? Install it — user-space preferred (`pipx`,
     workspace-local binaries, `npm` into workspace paths). No
     system-wide changes, no `sudo`.
   - Needs a secret, key, or paid account? **Stop.** Record exactly
     what's needed and escalate to the owner. Never invent, hardcode,
     or commit credentials.
   - Each newly added tool gets the same vetting, and its own
     dependencies recurse through steps 2–5. That's the rabbit hole —
     it ends when the acceptance criteria from step 1 pass.

6. **Test.** Run the skill against the acceptance criteria in isolation.
   Fails → diagnose: fix, try the next candidate, or escalate.

7. **Record.** Register the skill in `office/skills/README.md`, journal
   the run in `office/log/runs/`, note the decision in
   `office/log/decisions.md`.

## Rules
- Provenance or it didn't happen: source, version, license, date — in
  the skill file, every time.
- No skill may exfiltrate office data or phone home without owner
  approval.
- Prefer a vetted skill over building from scratch; prefer building over
  a skill that fails vetting.
- The Wizard owns the registry; any seat can request a hunt.
