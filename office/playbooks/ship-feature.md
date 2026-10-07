# Playbook: ship-feature

Repeatable procedure for small, well-defined tasks. The orchestrator
(Office Manager, triage worker, or hook worker) runs it by spawning one
subagent per step and reading each step's result before proceeding.

Inputs: task description, branch name (default `feat/<slug>`),
repo path (default `~/workspace/virtual-office/repo`).

## Step 1 — Implement
Spawn a subagent as office developer (brief it with the matching file
from `office/staff/`):
- Create the branch from `main` (check out and reuse it if it exists).
- Implement the task following `office/HOUSE_RULES.md`.
- Commit with conventional commits. Do NOT push. Do NOT open a PR.
- Final response must be JSON only:
  `{"branch": "...", "files_changed": [...], "summary": "...", "test_command": "..."}`

## Step 2 — Verify
Spawn a subagent as qa-engineer:
- Run the test suite and lint using the `test_command` from Step 1
  (or the repo's standard command).
- If tests fail and the fix is obvious and small, fix and re-run
  (max 2 rounds here); otherwise stop and report the failure.
- Final response: brief plain-text report of what ran and pass/fail.

## Step 3 — Review (repair loop, max 3 rounds)
Spawn a subagent as qa-engineer (fresh context preferred):
- Review the diff of the branch against `main`: correctness, edge cases,
  security issues, test coverage.
- Final response must be JSON only:
  `{"passed": true/false, "retryable": true/false, "feedback": "..."}`
- If `passed` is false and `retryable` is true and fewer than 3 review
  rounds have run: spawn the developer to address the feedback, commit
  the fixes, then re-review with a fresh reviewer. Repeat.
- If `passed` is false and (`retryable` is false or 3 rounds are
  exhausted): STOP. Do not open a PR. Report blocked with the feedback.

## Step 4 — Open PR
Spawn a subagent (tech-writer/devops brief):
- Push the branch and open a PR against `main` with a clear title and
  description: summary, how to test, screenshots if visual, migration
  notes, checklist.
- Final response: the PR URL as plain text.
- Hand the PR URL to the owner. Merging requires the owner's explicit
  approval (a standing pre-approval for a specific PR counts).
