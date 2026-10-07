# Decisions — War Room "maxtechlife-audit" (2026-10-07)

End-to-end audit + fix of maxtechlife.me (hub) and gloam.maxtechlife.me (GLOAM game).
Full war room: Prompt Writer → Knowledge Wizard (Phase 0) → PO/UI-UX/BA (Phase 1)
→ Architect/Frontend/DevOps (Phase 2) → AppSec/RedTeamer/TechLaw/GC (Phase 3)
→ build + merge + redeploy (Phase 4). Owner authorizations this workstream:
commit-to-git always; merge to main + production redeploy explicitly granted;
no spend. No blocks issued in Phase 3.

## ADR-2026-10-07-MLA-01: Audit verdict — hub PASS, game CONDITIONAL PASS
Hub (nx9161/maxtechlife): PASS. Game (nx9161/gloam): CONDITIONAL PASS —
condition = TLS cert provisioned for gloam.maxtechlife.me + Enforce HTTPS
flipped once it exists (AppSec). Real-browser check 2026-10-07 ~14:43 EDT:
game subdomain serves NOTHING (HTTPS blocked by cert error, HTTP blank error
page). Hub healthy: valid HTTPS, HTTP→301→HTTPS.

## ADR-2026-10-07-MLA-02: Enforce HTTPS enabled on hub via Pages API
DevOps seat enabled `https_enforced` on nx9161/maxtechlife via
`PUT /repos/{o}/{r}/pages {"https_enforced":true}` (PATCH unsupported; form-encoded
422s — raw JSON body required). Verified live: http://maxtechlife.me → 301 →
https. Gloam flip attempted, API 404 "certificate does not exist yet" — will
flip the moment a cert exists.

## ADR-2026-10-07-MLA-03: Gloam TLS cert genuinely unprovisioned (platform/DNS lever)
Pages API: `https_certificate: null` for gloam (hub: approved, exp 2027-01-05).
Retrigger build queued 18:41 UTC 2026-10-07; cert still null after. Owner-side
checklist (registrar panel): `gloam` CNAME → nx9161.github.io; no CAA record
blocking Let's Encrypt; www forward target https://maxtechlife.me. If no cert
~24h after trigger → GitHub Support. Existing goal
gloam-subdomain-https-certificate watcher continues to own this.

## ADR-2026-10-07-MLA-04: Pinch-zoom compromise (maximum-scale=5)
GLOAM viewport was maximum-scale=1, user-scalable=no (WCAG 1.4.4 failure,
Tech Law conditional pass). Architect ruling: relax to maximum-scale=5, drop
user-scalable=no, keep touch-action:none on canvas only (moved off #frame —
also fixes F2-1 touch scroll trap on overlay screens). iOS ignores
touch-action for pinch, so the meta cap is the guard.

## ADR-2026-10-07-MLA-05: Fixes shipped (4 PRs, all merged 2026-10-07)
- gloam#1 `fix/gloam-frontend-a11y-input`: M1 viewport, M2+F2-2 keyboard HUD
  (click handlers + keydown target guard + documented shortcuts), M3 44px hit
  areas, L1 canvas role/label, L2 aria-live, L3 theme-color+description,
  L4 :focus-visible, F2-1 touch-action scoping, F2-4 pad overlap, F2-5
  safe-area insets, <noscript>, P1 hub back-link on title screen.
- gloam#2 `fix/gloam-share-download`: F2-3 iOS fallback — feature-detect
  `download` attr; absent → open blob in new tab + "long-press to save" hint;
  toBlob missing → explanatory status text. Never navigates game tab away.
- gloam#3 `fix/gloam-minify`: game JS minified (59KB→36KB) as copy deterrent;
  readable source at src/gloam.js; tools/minify.sh rebuilds; BUILD.md documents
  edit→rebuild→commit. Owner requirement: play-online-only, repos stay private.
  Honest limit recorded: view-source/curl can always fetch served bytes.
- maxtechlife#1 `fix/hub-theme-color`: L3 theme-color metas (hub otherwise clean).

## ADR-2026-10-07-MLA-06: Architecture unchanged (single-file retained)
All fixes are in-file edits or settings toggles; topology invariant. Offline
support challenged as out-of-scope enhancement (needs service worker). Security
headers unfixable on GitHub Pages — accepted platform limitation, documented.
Cache: CDN purges on deploy; ~2 min build + ≤10 min edge staleness after merge.

## ADR-2026-10-07-MLA-07: Compliance & IP posture
Tech Law CONDITIONAL PASS (viewport fix = the condition, shipped). GC PASS:
all assets original/procedural, no ToS/privacy-policy trigger (zero collection),
no consent banner required (ePrivacy Art 5(3) exemption for functional
localStorage), share-card flow clean, "coming soon" cards are puffery.
Red Team: N/A (no AI surface). Watch-notes: "Gloam" name has prior indie uses
— USPTO clearance before brand investment; ToS/privacy needed only if
monetization/accounts/UGC ever arrive.

## Open items
1. Gloam TLS cert — owner DNS/CAA checklist (§MLA-03); watcher goal owns it.
2. Post-merge QA re-verification after CDN settles (~12 min post-merge).
3. Real-device spot-checks (iOS share fallback, touch play) — recommended,
   needs owner's device or a device lab.
