# fruviacafe-audit — decisions.md

## ADRs

### [2026-10-06] War room convened for third-party QA audit (not a release gate)
- Context: owner wants a company-grade audit of fruviacafe.com to pitch the cafe owner as a client.
- Decision: ran war-room phases 1–3 adapted to audit (Phase 4 = synthesis/deliverables instead of build). Subagent-per-role-per-phase per playbook.
- Owner: Sloane (war-room coordinator).

### [2026-10-06] Audit verdict: site would be BLOCKED as a release candidate
- Context: AppSec found credentials/PII in query strings, no CSRF tokens, eval() on network output, zero security headers.
- Decision: record BLOCK-equivalent verdict as the audit's headline security posture (AppSec Lead). This is an assessment of a third party's site, not our release — verdict informs sales narrative only.
- Owner: AppSec Lead.

### [2026-10-06] AI red team explicitly N/A
- Context: no chatbot, LLM, AI search, RAG, or AI content features observed on the site.
- Decision: AI Red Teamer returned explicit N/A with justification rather than a perfunctory pass.
- Owner: AI Red Teamer.

### [2026-10-06] Vendor-position ruling: owner has no legal standing against the cafe
- Context: owner asked "what legal actions could I take."
- Decision (Tech Law): NONE — owner is a prospective vendor, not the site owner; no standing, no injury, no attorney-client relationship. Leverage is commercial (paid remediation/rebuild), not legal. Memo framed as sales intelligence, labeled not-legal-advice; pitch must never threaten or imply enforcement.
- Owner: Global Tech Law Lead.

### [2026-10-06] Privacy-policy correction: policy EXISTS; gap is notice at collection
- Context: initial brief assumed no privacy notice at all.
- Decision: record accurately — /Privacy-Policy exists (Sep 14, 2026, footer-linked); the defect is absence of notice/consent AT THE POINT OF COLLECTION on both forms. Pitch script and memo use the corrected framing.
- Owner: Product Owner / Tech Law.

### [2026-10-06] Pricing tiers grounded in 2026 market data
- Context: owner asked what to charge for a full rebuild.
- Decision: three tiers — T1 remediation sprint $2.5–4K (2–3 wks), T2 full rebuild $6.5–12K (6–10 wks, recommended lead), T3 premium $12–18K + $300–600/mo retainer. Anchored to published 2026 rates (restaurant sites $3–6K / $6–12K w/ ordering; SMB rebuilds $2.5–15K; maintenance 15–20%/yr).
- Owner: Sloane.

### [2026-10-06] War room RE-RUN with all 14 seats — "War Room Phase N — Project: fruviacafe-audit-rerun"
- Context: owner requested the full QA audit be re-run with the new 14-seat roster (GC + BA + Prompt Writer coverage).
- Decision: ran playbook war-room.md end-to-end, subagent-per-role-per-phase, all 13 role agents plus coordinator: Phase 0 Prompt Writer produced the perfected master prompt (broadcast verbatim to every role agent); Phase 1 PO/UX/BA; Phase 2 Architect → Backend/Frontend/DevOps debate; Phase 3 AppSec/RedTeam/TechLaw/GC; Phase 4 QA Manager gate + v2 deliverables. Working notes in `~/workspace/fruviacafe-audit/war-room-rerun/` (12 files).
- Owner: Sloane (war-room coordinator).

### [2026-10-06] Re-run verdict: site still BLOCKED as a release candidate
- Context: AppSec re-verified all Critical/High read-only (~23:05–23:10 EDT).
- Decision: BLOCKED stands — zero drift, zero remediations since the morning run. Disposition totals: 31 CONFIRMED, 5 corrected/drift (M11 count up, H10 label scope, L1 tel:-link, M9 dead social surface, H11 alt-quality), 0 downgraded, 7 NEW (N1 High focus-outline suppression, N2–N4/N7 Medium, N5–N6 Low), 0 fixed. Blocking findings: C1, C2, C3, C4, H1, H2, H3, H4, H12, M13. Red Team N/A re-confirmed explicitly.
- Owner: AppSec Lead.

### [2026-10-06] Tech Law BLOCK on legal memo v2 → CLEARED
- Context: Phase 3 Tech Law review of v1 memo found 5 material defects.
- Decision: BLOCK issued, then cleared by applying all 5 in legal-actions-memo-v2.md — B1: NJPDPA 30-day cure period sunset (~Jul 15/16 2026; window stated, no date picked) sharpens exposure framing; B2: log-purge reworded to advisory "cooperate or document" (purge is not a verifiable deliverable); B3: "sensitive personal data" → "highest-sensitivity data on the site (business framing)" + statutory question flagged for counsel; B4: P0 completed with the consent-persistence half (flag travels with the submission record; PW Foods schema change); B5: 2026 GA4/consent enforcement-posture note added. No-standing ruling re-confirmed (NJPDPA AG-exclusive, no private right of action).
- Owner: Global Tech Law Lead.

### [2026-10-06] GC BLOCK on pitch/proposal language → partially cleared
- Context: first full General Counsel review of our own deliverables + NJ jurisdiction matrix.
- Decision: BLOCK issued on 4 items; B-1 (close reworded: "we address the specific items set out in the written scope we agree on together"), B-2 ("designed from day one using modern privacy and security practices" + "designed to reduce compliance risk; no outcome guarantees"), B-4 (finding ④ reworded: "personal data that privacy laws treat with heightened care" — no enforcement prediction) applied in v2. **B-3 stands as a permanent pre-send gate: licensed NJ counsel must draft/review the Tier 1 contract before ANY client-facing send** (deposit characterization, liability cap, IP-on-platform-code, deemed acceptance, governing law/venue, warranty scope). New: NJ CFA exposure direction = OURS (cafe owner as B2B buyer = ascertainable-loss/treble-damages plaintiff) — legal spine for the no-guarantee rules. Jurisdiction matrix filed in phase3-gc-review.md (NJPDPA thresholds, cure sunset, 2026 A-5017 amendments, proposed NJDPA rules, NJ-REG registration note).
- Owner: General Counsel.

### [2026-10-06] Pricing re-validated by BA against 10 fresh 2026 sources
- Context: Phase 1 BA pricing validation.
- Decision: T1 $3,500 fixed / $2,800 conditional — HOLD (CONFIRMED); T2 $6,500–12,000 — HOLD + new $8,000 floor guardrail (only for tightly-scoped template-assisted ≤7-page builds; custom/ordering starts at $8,000); T3 $12,000–18,000 — HOLD + retainer productized ($300/mo Care, $500–600/mo Growth); new $150/hr hourly fallback floor. 50/25/25 milestones — HOLD. All bands CONFIRMED, zero numeric changes vs v1.
- Owner: Business Analyst.

### [2026-10-06] Architecture: tenant/platform split + ADR-001–004
- Context: Phase 2 debate produced the engagement's load-bearing constraint analysis.
- Decision: per-SOW-item dispositions — C1–C3 = tenant-JS (a) + platform-controller (b) split with ADR-003 sequencing (platform POST acceptance + JSON-contract preservation BEFORE any tenant JS flip; dual-accept rejected); C4 = platform-wide anti-forgery (implausible per-tenant — drives the SLA ask); H2 = (a) clean tenant win (with (b)-side content-type hardening request); H4 = Cloudflare Transform Rules (Free-plan OK) per ADR-002 half-correction (error body needs origin `<customErrors>` or Worker — Transform Rules cannot fix bodies); H12 split accordingly. ADR-001: fix-on-tenant only with written PW Foods cooperation statement; otherwise $2,800 limited-access sprint or walk away. 5-item written PW Foods cooperation question is the GO/NO-GO gate. SOW grew to 35 items (29 + N1/N2/N7 + 2 safe M10 removals + consent-gate spec).
- Owner: Enterprise Architect.

### [2026-10-06] Tier 1 charging model
- Context: 2nd focused war room (PO, QA Manager, Tech Law, DevOps) on how to charge for the Tier 1 remediation sprint.
- Decision: fixed-price $3,500 for full Tier 1 (conditional $2,800 limited-access variant if PW Foods denies code access); 50% non-refundable deposit triggers clock, 25%/25% milestones; SOW = 29 line items mapped to finding IDs with explicit exclusions and "cooperate or document" rule for PW Foods-dependent items; sign-off gate per-finding (security + privacy findings are hard blockers, zero FAILs); 30-day warranty covers regressions of fixed findings only (P1 security regression = 4h response). GO/NO-GO gate: written PW Foods cooperation statement before signing — without a path to change form-handling code, C1–C4 cannot be fixed and Tier 1 becomes report-only advisory. Upsell bridge: Tier 1 stops the bleeding; the aging MVC 5.2/PW Foods platform ceiling is the Tier 2 rebuild argument. Tech Law checklist = general information, not legal advice; counsel drafts the contract.
- Owner: Sloane (war-room coordinator).
