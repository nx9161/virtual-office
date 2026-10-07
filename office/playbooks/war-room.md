# Playbook: war-room

The synchronous consensus loop. Runs BEFORE any production code is
committed for a significant feature or release. The orchestrator
(Sloane) runs it by spawning one subagent per role per phase and
synthesizing the outcome. Each phase's conclusion is recorded as an ADR
in the palace (`office/palace/wings/<wing>/rooms/<room>/halls/decisions.md`).

## Phase 1 — Intake & PRD
Spawn Product Owner and UI/UX Designer (in parallel):
- Product Owner: convert the request into a PRD — problem, user stories,
  acceptance criteria, edge cases.
- UI/UX Designer: produce wireframes/interaction specs; interpret any
  attached screenshots or mockups.
- Output: PRD document + design specs, stored in the palace room.

## Phase 2 — Architectural Debate
Spawn Enterprise Architect first:
- Presents system topology: services, API specs, DB schemas, data flows.
Then spawn Lead Backend, Lead Frontend, and DevOps/SRE (in parallel)
to debate it:
- Challenge bottlenecks, state management, scaling limits, deployability.
- Output: agreed topology + ADRs. Unresolved disputes go to Sloane.

## Phase 3 — Security & Legal Challenge
Spawn AppSec Lead, AI Red Teamer, Global Tech Law Lead, and General
Counsel (in parallel):
- AppSec: OWASP Top 10 review, auth/crypto/rate-limiting assessment.
- AI Red Teamer: prompt injection, jailbreak, data poisoning probes
  against any AI-facing surface.
- Tech Law: GDPR/CCPA/NIS2/HIPAA/EU AI Act applicability, data mapping.
- General Counsel: contracts/ToS/licensing, jurisdiction matrix for
  target markets, corporate/IP/employment exposure; escalates to
  licensed local counsel where binding advice is needed.
- Any of the four can BLOCK. Blocks stand until cleared or Sloane
  rules with owner input.

## Phase 4 — Build, QA Sign-off & Execution
- Build proceeds per the `ship-feature` procedure (branch → verify →
  review → PR).
- QA Manager enforces the gate: 100% pass on the release suite, no open
  blockers, then sign-off.
- Sloane synthesizes the War Room record, authorizes the release, and
  reports to the owner.

## Rules
- Skipping the War Room for production changes requires Sloane's
  explicit waiver, recorded as an ADR.
- Small, well-defined fixes may use `ship-feature` directly; anything
  touching architecture, auth, payments, personal data, or AI behavior
  goes through the War Room.
