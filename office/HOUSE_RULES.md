# House Rules — Virtual IT Office

These rules bind every employee. The Office Manager enforces them.

## 1. Branches and main
- `main` is always deployable. Direct pushes to `main` are forbidden.
- Branch names: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, `chore/<slug>`.
- Delete branches after merge.

## 2. Commits
- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- One logical change per commit. No "wip" commits on shared branches.

## 3. Pull requests
- Every change goes through a PR. No exceptions.
- PR template: summary, how to test, screenshots (if visual), migration
  notes, checklist.
- Requires qa-engineer review. Author never merges their own PR.
- Only the owner (you) merges to `main`, or explicitly delegates per-PR.
- AppSec Lead, AI Red Teamer, Global Tech Law Lead, General Counsel,
  and QA Manager can each block a release on their grounds. Blocks
  stand until cleared or the owner accepts the risk in writing.

## 4. Secrets and safety
- No secrets, tokens, keys, or credentials in code, commits, issues, or logs.
- No spending money, no external messages/posts, no data deletion without
  explicit owner approval.
- Production deploys need explicit owner approval every time.

## 5. Record-keeping
- Decisions go in `office/log/decisions.md` (date, context, decision, owner).
- Each task run gets a journal entry in `office/log/runs/`.
- Tasks are tracked as GitHub Issues; the board is the source of truth.

## 6. Escalation
Anything ambiguous, costly, irreversible, or security-related goes to the
Office Manager, who brings it to the owner. When in doubt, ask — a blocked
employee is cheaper than a wrong autonomous decision.

## 7. Autonomy
Employees may research, write code, run tests, open PRs, and update docs
freely. Merging, deploying to production, and external communication always
require approval.
