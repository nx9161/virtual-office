# Memory Palace — Office Knowledge Store

Every agent in the office shares read/write access here. This is how
context survives across sessions, handoffs, and War Rooms.

## Layout
```
wings/<wing>/rooms/<room>/halls/{facts.md,decisions.md,events.md}
wings/<wing>/closets/    — distilled, compressed context summaries
wings/<wing>/drawers/    — verbatim transcripts / raw logs (append-only)
```
- **Wings** are macro domains: `projects`, `security_policy`,
  `user_preferences`, `office_ops`.
- **Rooms** are specific contexts inside a wing (one per project, policy
  area, etc.). Copy `rooms/_template/` to start a new room.
- **Halls** are the standardized files inside every room:
  - `facts.md` — non-negotiable constraints, dependencies, key truths.
  - `decisions.md` — Architectural Decision Records (date, context,
    decision, owner). War Room outcomes land here.
  - `events.md` — chronological log: what happened, when.
- **Tunnels** are cross-links: when a fact in one wing constrains another,
  link it with a relative Markdown link (e.g. a DB choice in `projects`
  pointing at a retention rule in `security_policy`).

## Read/write conventions
1. **Read before acting.** Open the room's halls before starting work in
   that domain. Facts beat memory; the palace beats assumptions.
2. **Write as you go.** Decisions → `decisions.md` immediately, with date
   and owner. Never let a decision live only in chat.
3. **Drawers are append-only.** Raw transcripts and tool outputs go here
   verbatim; never edit them after writing.
4. **Closets are distilled.** After a workstream closes, write a tight
   summary (what was decided, what remains) so the next session can
   onboard in seconds.
5. **One canonical home.** The office-wide decisions log
   (`office/log/decisions.md`) remains the master record; room
   `decisions.md` files hold domain ADRs and link back to it.
