# Contributing

Welcome to the Virtual IT Office. Every contributor — human or agent —
works the same way.

## Ground rules

The binding source of truth is
[office/HOUSE_RULES.md](office/HOUSE_RULES.md). The short version:

- **Branch first, always.** `main` is deployable at all times; direct
  pushes are forbidden. Branch names: `feat/<slug>`, `fix/<slug>`,
  `docs/<slug>`, `chore/<slug>`.
- **Conventional Commits.** `feat:`, `fix:`, `docs:`, `chore:`,
  `refactor:`, `test:`. One logical change per commit.
- **Everything goes through a PR.** No exceptions. The PR template
  covers summary, how to test, screenshots, migration notes, checklist.
- **Never merge your own PR.** QA review is required, and only the owner
  merges to `main`.

## Workflow

1. Pick up work from a GitHub Issue (or get assigned one). Issues are the
   source of truth for the task board.
2. Create a branch from `main` with the right prefix.
3. Do the work, run the tests, commit with a conventional message.
4. Open a PR from your branch to `main`. Fill out the PR template.
5. Request qa-engineer review. Address feedback. Wait for the owner to merge.

## Safety

- Never commit secrets, tokens, keys, or credentials — in code, issues,
  or logs.
- No spending money, no external messages/posts, no data deletion, and no
  production deploys without explicit owner approval.
- Record decisions in `office/log/decisions.md` (date, context, decision,
  owner).

## If you're stuck

Escalate ambiguity, cost, irreversible actions, or anything
security-related to the Office Manager. A blocked employee is cheaper
than a wrong autonomous decision.
