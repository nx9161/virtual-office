# Playbook: war-room

The synchronous consensus loop. Runs BEFORE any production code is
committed for a significant feature or release. The orchestrator
(Sloane) runs it by spawning one subagent per role per phase and
synthesizing the outcome. Each role agent is briefed with the perfected
prompt from the Prompt Writer — never the raw request — plus the
Knowledge Wizard's Phase 0 dossier. Each phase's conclusion is recorded as an ADR
in the palace (`memory/wings/<wing>/`).

Naming: the War Room is the office's standing process — never rename it
per project. Refer to sessions as "War Room Phase N — Project: X".

## Phase 0 — Prompt Perfection & Wizard Briefing (mandatory gate)
1. **Prompt Writer** forges the raw request into the perfected prompt —
   persona, objective, context, constraints, output format, acceptance
   criteria. No agent works from the raw version.
2. **Knowledge Wizard** takes the perfected prompt, parses every word,
   searches each term across the internet, and **reads in full** every
   related official document (API references, RFCs, changelogs, security
   advisories, specs). It compiles a per-seat dossier — facts,
   constraints, versions, gotchas — and injects it into the discussion.
3. **No seat speaks before the dossier lands.** Phase 1 begins from the
   perfected prompt plus documented facts, never from memory or vibes.

## Phase 1 — Intake & PRD
Spawn Product Owner, UI/UX Designer, and Business Analyst (in parallel):
- Product Owner: convert the request into a PRD — problem, user stories,
  acceptance criteria, edge cases.
- UI/UX Designer: produce wireframes/interaction specs; interpret any
  attached screenshots or mockups.
- Business Analyst: the business case — pricing, margin impact, and
  commercial viability of what's proposed.
- Output: PRD document + design specs + business case, stored in the
  palace room.

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
