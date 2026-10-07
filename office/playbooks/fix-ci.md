# Playbook: fix-ci

Repeatable procedure for a failing CI on a branch. The orchestrator runs
it by spawning one subagent per step and reading each step's result.

Inputs: branch name, repo path (default `~/workspace/virtual-office/repo`),
failure summary (CI log excerpt or description).

## Step 1 — Diagnose (max 3 rounds)
Spawn a subagent as devops:
- Inspect the CI failure (logs via `gh run view`, or the failure summary)
  and the code on the branch. Find the root cause.
- Final response must be JSON only:
  `{"fixed": false, "retryable": true/false, "diagnosis": "..."}`
  (fixed is always false at this step; diagnosis is the root cause.)

## Step 2 — Fix
Spawn a subagent as developer:
- Apply the fix from the diagnosis, commit, and push the branch.
- Final response must be JSON only:
  `{"fixed": true/false, "retryable": true/false, "summary": "..."}`
- If `fixed` is false and `retryable` is true and fewer than 3 rounds
  have run: go back to Step 1 with the new failure info.
- If `fixed` is false and (`retryable` is false or 3 rounds exhausted):
  STOP. Report blocked with the summary. Escalate to the owner.

## Step 3 — Verify
Spawn a subagent as qa-engineer:
- Run the test suite on the branch and confirm green.
- Final response: brief plain-text confirmation.

Report the outcome to the owner: fixed (branch, summary) or blocked
with the diagnosis trail.
