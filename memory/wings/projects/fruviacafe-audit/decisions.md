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
