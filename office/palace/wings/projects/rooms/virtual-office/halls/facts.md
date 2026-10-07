# facts.md — virtual-office

| Fact | Source / Date |
|------|---------------|
| HQ repo is `nx9161/virtual-office` (private); local clone at `~/workspace/virtual-office/repo` | 2026-10-06 |
| 11 roles in 4 divisions; Sloane (Chief Orchestrator) dispatches and signs off | office spec, 2026-10-06 |
| `main` is always deployable; all changes via PR; only the owner merges to `main` | HOUSE_RULES.md |
| Production deploys need explicit owner approval, every time | HOUSE_RULES.md |
| Workflow engine `agent()` result channel is non-functional (returns `{}`); playbooks run as procedures via subagent-per-step orchestration | probe, 2026-10-06 |
| gh CLI authed as `nx9161`; git identity "Virtual IT Office" | 2026-10-06 |
