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
