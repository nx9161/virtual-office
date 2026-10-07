# Decisions — War Room "vercel-gloam-deploy" (2026-10-07)

Move GLOAM from GitHub Pages (TLS cert unprovisionable for gloam.maxtechlife.me)
to Vercel Hobby on a free *.vercel.app domain. War Room Protocol already active;
new workstream under the always-on loop.

## ADR-2026-10-07-VG-01: Migrate now, don't wait on GitHub (BA)
Game is DOWN (cert error / blank page in real browsers); GitHub's queue is
unbounded and opaque. Vercel Hobby = $0, ~1hr work, instant certs, near-zero
exit cost (single static file). Split posture stands: hub stays on Pages
(healthy); move only what's broken.

## ADR-2026-10-07-VG-02: Deploy path = GitHub import (recommended), CLI fallback
Import nx9161/gloam via vercel.com/new (preset Other, no build command);
pushes to main auto-redeploy. Fallback: CLI with owner-supplied VERCEL_TOKEN
via Secure Vault. Auth is the owner's call — blocks deployment until answered.

## ADR-2026-10-07-VG-03: Deploy only index.html + vercel.json
.vercelignore excludes src/, tools/, BUILD.md, CNAME (owner IP posture:
play-online-only, no readable source served). PR #4 (chore/vercel-deploy-config)
holds .vercelignore + vercel.json; merged only on owner go-ahead.

## ADR-2026-10-07-VG-04: Security headers per AppSec review
HSTS max-age=31536000 (NO preload — un-actionable on vercel.app),
X-Content-Type-Options nosniff, X-Frame-Options DENY + CSP frame-ancestors
'none', Referrer-Policy no-referrer, Permissions-Policy restrictive.
NO script-src/default-src CSP (breaks inline game script). Post-deploy 404
verification on excluded paths required before sign-off.

## ADR-2026-10-07-VG-05: GC condition — opt out of Vercel model training
Hobby ToS permits Vercel to use deployed content for AI model training unless
opted out in account settings. Owner must flip the opt-out before deploying —
it contradicts his IP posture otherwise. With opt-out: PASS.

## ADR-2026-10-07-VG-06: Merge permission does NOT carry over
The audit workstream's merge+redeploy grant is scoped to that workstream.
Vercel project creation and the hub link PR merge each need explicit owner
approval. Hub PR must not be authored until the live Vercel URL is verified.

## ADR-2026-10-07-VG-07: Old subdomain untouched; future option noted
gloam.maxtechlife.me stays as-is (cert watcher goal still owns it). Future
option (NOT this workstream): point the subdomain at Vercel as a custom
domain — free on Hobby, instant certs, kills the Pages saga permanently.

## Open items
1. Owner: Vercel account? (create at vercel.com, ~2 min)
2. Owner: auth path — GitHub import (recommended) vs CLI token
3. Owner: merge PR #4 (vercel config) — safe to merge anytime (inert until a Vercel project links the repo)
4. After deploy: verify URL, 404-checks, headers, real-browser render, then hub link PR + explicit merge approval

## ADR-2026-10-07-VG-08: Deployed 2026-10-07 ~15:47 EDT (all verifications PASS)
- Project "gloam" (prj_OOxhlLS2UbE8nmDq5SezidQQq0bd) created via Vercel MCP
  `create_git_project`, linked to nx9161/gloam, production branch main.
- Production URL: https://gloam-nx9161s-projects.vercel.app (aliases:
  gloam-pi.vercel.app, gloam-git-main-nx9161s-projects.vercel.app).
- Team-default SSO Deployment Protection was ON (public 302 to sso-api) —
  fixed via update_project: ssoProtection deploymentType "preview"
  (production public, previews gated).
- Verification: 200, valid TLS, all 6 AppSec headers, /src/gloam.js,
  /tools/minify.sh, /BUILD.md, /CNAME all 404, served bytes byte-identical
  to repo main. Real-browser: title renders, click starts run, HUD/score/
  combo/timer live, pause/mute work, no errors.
- Hub PR #2 (one-line href swap) open — merge gated on explicit owner approval.
- GC condition outstanding: owner must flip the AI model-training opt-out in
  Vercel team settings.

## ADR-2026-10-07-VG-09: Hub cutover merged 2026-10-07 ~15:55 EDT
- Owner approved merge ("Merge it"). PR #2 merged: GLOAM card href →
  https://gloam-nx9161s-projects.vercel.app. Pages build "built"; live bytes
  verified (200, new href present).
- Follow-up: card's visible url-line label still showed the old subdomain —
  fixed in PR #3 (one-line text change), open pending owner merge.
- GC condition outstanding: owner flips AI model-training opt-out in Vercel
  team settings (manual, dashboard).

## ADR-2026-10-07-VG-10: CLOSED 2026-10-07 ~15:58 EDT — final results
- Owner: "Get EVerything done" — PR #3 merged (label fix). Pages built; live
  bytes verified: url-line label AND card href both
  gloam-nx9161s-projects.vercel.app.
- Mission complete: GLOAM serves over valid HTTPS from Vercel free tier,
  all security headers, excluded paths 404, bytes identical to repo,
  real-browser play verified. Hub links to it. Zero spend. Old GitHub Pages
  deployment untouched (watcher goal still owns the cert issue).
- Sole remaining action (owner, manual): Vercel AI model-training opt-out in
  team settings — account privacy control I cannot flip for him.

## ADR-2026-10-07-VG-11: Keyboard + difficulty shipped 2026-10-07 ~16:47 EDT
- Standing owner order: "Merge everything into main when its done dont wait
  for permission" — merges no longer gated per-PR for this game workstream.
- PR #5 keyboard steering (arrows/WASD, same velocity-easing model as
  pointer): 21/21 headless checks + 9/9 real-browser QA pass. Merged
  20:36:23Z; production verified serving the build.
- PR #6 difficulty select + hunter retreat (war room: Prompt Writer spec,
  PO+UI/UX locked design): mode select (arcade/calm) → difficulty select
  (ember/lantern/wildfire, per-mode prompts + flavor text) → run. Hunter
  reworked to 40s duty cycle (present/absent 10/30 ember, 20/20 lantern,
  30/10 wildfire) with telegraphed returns; calm difficulty tunes engagement
  only (mote density/pacing), never threats. 72/72 headless checks + 8/8
  real-browser QA pass (preview deployment, gating relaxed for QA then
  restored to preview-only SSO).
- PR #6 was stacked on the keyboard branch; rebased onto main after #5
  merged, base retargeted, merged 20:46:39Z. Production verified live
  (57,127 bytes, difficulty markers present).
- Security posture intact: headers live, excluded paths 404, minified-only
  servings, previews gated, production public.
