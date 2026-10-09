# ADRs — Student Benefits Catalogue: full-site audit + missing-links restore
War Room session: 2026-10-08. Chief Orchestrator: Sloane. Tabletop mode.
Scope: public site https://student-benefits-catalogue.vercel.app (8 hash-routed pages, single static file).

## ADR-1 — Root cause of missing outbound Apply links (P0)
- **Context:** Owner reported outbound links gone on GitHub Pack and all pack pages. Production HTML (218,761 bytes) holds 57 `<a>` anchors / 30 http hrefs for 205 benefits.
- **Finding:** Renderer builds Apply buttons via `APPLY[it.n] ? '<a class="apply-btn" href="..." target="_blank" rel="noopener">Apply ↗</a>' : ""`. The `APPLY` name→URL lookup holds **74 entries for 120 card-style benefits**; the 46 missing render as **empty string** (no button at all). All 74 keys match benefit names exactly — pure data gap, no key-mismatch. Pack page rows link via `PACK_ANCHORS` (81 entries) to `education.github.com/pack#anchor` — intact.
- **Decision:** Data loss occurred during the 8-page split rebuild (URLs never migrated into the APPLY map). Remediation = complete the map for all 120 + harden the fallback so it can never render empty again.
- **Owner:** Enterprise Architect + Lead Frontend. **Status:** spec issued to builder.

## ADR-2 — Renderer fallback hardening
- **Context:** Silent empty-string fallback is what made the link loss invisible until the owner noticed.
- **Decision:** Fallback must never be `""`. If no official apply URL exists after research, the button links the brand's official homepage/store locator (https only). Every card ships with an action.
- **Owner:** Lead Frontend.

## ADR-3 — Full-site audit verdict (10 standing items + personalization)
- **Pass (9):** tip hero top / single creator button bottom (2nd instagram href is JSON-LD metadata only); tip wording, zero donate/donation; crypto section + wallets; Ko-fi hidden, no CDN script; legal disclaimer footer; iPhone/mobile hardening (safe-area ×17, 44px ×17, 16px inputs, overflow-x guards); SEO/OG + JSON-LD; analytics client present (inlined as base64 data-URI by exporter — functional); graduation-freebies templates + Nike/Adidas honesty note; routing (all 8 hashes present); privacy boundary holds (only ko-fi handle `nx9161` in hidden hrefs — known standing state).
- **Fail (2):** P0 link coverage (46/120 card benefits without Apply URL); personalization notes absent on all 8 pages (new scope).
- **Owner:** QA Manager. **Status:** failures folded into remediation spec.

## ADR-4 — Per-page personalization notes (new scope)
- **Context:** Owner: "PERSONALIZE EVERY PAGE" — 2–3 line first-person intro per page, student-to-student tone.
- **Decision:** 8 notes drafted (exact copy in session report), placed directly under each page H1, quote-card styled. HARD PRIVACY BOUNDARY restated: name + "graduate student in Data Science at Rowan University" ONLY; zero mentions of projects, games, LifeOS, private repos, GitHub handle, tech stack.
- **Owner:** Product Owner + UI/UX Designer.

## ADR-5 — Outbound link safety (Phase 3)
- **Decision:** All 46 new URLs must be official brand/developer/verification domains, https only, verified HTTP 200 before ship. Keep `esc()` on URLs, `target="_blank"`, `rel="noopener"`. No aggregators, no affiliate links. No blocks: AppSec / Tech Law / GC all clear.
- **Owner:** AppSec Lead.

## ADR-6 — No-build-change items
- **Decision:** Analytics embedding (base64 data-URI) left as-is — verified functional client. QR codes: production (pre-polish) uses qrcodejs CDN; polished build inlines local QR images — builder to keep the polished-build approach. No action.
