# arcade-suite — decisions (ADR log)

## ADR-2026-10-07-AS-01: Mission opened (Phase 0 complete)
- Owner wants an original arcade-loop game suite: 100% original expression,
  mechanics-only inspiration from ~35 golden-age/90s classics; publishable +
  monetizable with infringement claims meritless; one private repo per game;
  Vercel hosting; hub at maxtechlife.me.
- Perfected prompt locked (Prompt Writer): original games not copies; legal
  deliverable = meritless-claim IP framework (not a literal no-suit guarantee);
  monetization forces hosting off Hobby; PO picks 3–5 flagship slate.
- Knowledge Wizard dossier: ~/workspace/dossiers/arcade-suite-ip-hosting-dossier.md
  Key: US courts protect expression not loops (Tetris v Xio, Spry Fox v Lolapps,
  Atari v Philips, Data East v Epyx); trademark is the second minefield;
  clean-design rules documented. Hobby = noncommercial, at-will suspension;
  Pro $20/mo; Cloudflare Pages free + commercial OK = strongest free fit for a
  monetized static suite. Model-training opt-out still NOT flipped by owner
  (Team Settings → Data Preferences); already-ingested data can't be un-learned.

## ADR-2026-10-07-AS-02: Phase 1 locked — flagship slate + business model
- Slate (build order): ① BEACONFALL (fixed shooter; tidal lighthouse keeper,
  redemption scoring) ② MOONDRIFT (maze-chase; moon jellyfish, flooding maze,
  lanternfish hunters) ③ MARSHLIGHT (lane-crosser; firefly, light-as-fuel)
  ④ SEEDSTORM (arena physics; dandelion seed, no brakes, momentum only).
- Title hygiene: face-safe names; mandatory USPTO/app-store/web clearance per
  title at Phase 3 gate; rename-in-room if any needs lawyering.
- Roadmap: Batch 2 (brawler, run-and-gun, vertical shmup, digger), Batch 3
  (isometric hopper, flappy-combat, time-management, dungeon crawler, city
  smasher), Batch 4 (weapons fighter, platform climber, obstacle course,
  physics roller, masocore platformer). Revenue learning gates each batch.
- Monetization: Ko-fi tips/donations primary at launch (off-site links, zero
  hosting demand, zero ad-tech privacy cost); ads deferred till traffic
  justifies; pay-per-game rejected.
- Hosting: Cloudflare Pages ($0, unlimited bandwidth, commercial OK) at first
  dollar of revenue OR monetized launch, whichever first; Vercel Hobby stays
  as free staging until then. Launch cost $0 — no spend sign-off needed.
- Suite identity: "MaxTechLife Arcade" as hub-section brand (not stamped on
  games); independent trade dress per title (legal + aesthetic posture);
  maxtechlife.me Arcade wing with per-title cards; per-game cross-link footers.
- Overdue owner action: Vercel model-training opt-out (Team Settings → Data
  Preferences) — still not flipped.

## ADR-2026-10-07-AS-03: Phase 2 locked — repo template + deploy machine
- Template repo: private nx9161/arcade-template ("Use this template"), fully
  independent generated repos; improvements propagate as deliberate
  cherry-pick PRs, never silent. Tree: .gitignore/.vercelignore/_headers/
  BUILD.md/CHANGELOG.md/README.md/TEMPLATE.md, index.html (scaffold+sentinels),
  src/shared.js (frozen shared patterns) + src/game.js (100% original per
  title), tools/minify.sh (pinned terser) + tools/release-check.sh,
  vercel.json (six locked headers), .github/workflows/verify-build.yml (PR
  gate: committed index.html must equal clean rebuild).
- Shared code duplicated frozen per repo (no package/submodule — would break
  zero-config Vercel import or couple shipped builds). No game logic copied
  between titles, ever.
- FORBIDDEN in repos: third-party/IP assets, IP-homage easter eggs, public
  copy naming inspirations, secrets (even placeholders), readable source
  served, hand-edited bundle regions, analytics without Tech Law review.
- Topology: ONE Vercel project per game (deploy isolation, per-project
  rollback); production public, previews SSO-gated. New-title checklist ~15min.
- Cloudflare migration: trigger = first dollar OR monetized launch; per-game
  cutover ~1 day; _headers 1:1 with vercel.json; previews unguessable URLs
  (no SSO gating on free plan — accepted gap, same public-bytes posture);
  Vercel projects go DORMANT not deleted (warm rollback).
- Hub: Arcade wing in maxtechlife.me (section relabeled "Arcade"); card spec
  follows live GLOAM card; per-game #suiteFooter with hub link + Ko-fi tip
  link (off-site anchors only, zero widgets); KOFI-HANDLE token substituted
  per title (owner to supply handle — blocks final footer).
- Build sequencing: BEACONFALL → MOONDRIFT → MARSHLIGHT → SEEDSTORM, strictly
  sequential war rooms; HARD entry gate per title = Phase 3 IP sign-off;
  done-definition mirrors the GLOAM QA bar.
- Next: Prompt Writer perfects the template-bootstrap prompt; then
  BEACONFALL's Phase 3 IP gate.
