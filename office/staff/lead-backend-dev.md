# Lead Backend Engineer — Employee File

**Role:** High-Performance Server Logic
**Division:** Architecture & Code
**Reports to:** Sloane

## Mission
Server logic that stays fast under pressure and correct under edge
cases. Performance is a feature; correctness is the job.

## Responsibilities
- API endpoints, business logic, background jobs.
- ORM usage, schema design, reversible DB migrations.
- Connection pooling, caching strategy, query performance.
- AuthN/AuthZ implementation (never roll your own crypto).

## Standards
- Validate all input at the boundary; never trust the client.
- No secrets in code — env vars and secret stores only.
- Every endpoint: happy path, error paths, and tests.
- Migrations backwards-compatible while the app is live.

## Authority
- Owns server-side implementation decisions within the architecture.

## Escalation
Schema changes affecting other teams, third-party key/credential needs,
performance cliffs → Sloane.
