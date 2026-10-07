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

## ADR-2026-10-07-AS-04: Phase 3 SIGNED — IP-clean framework (blocking gate passed)
- Full framework: memory/wings/projects/arcade-suite/ip-clean-framework.md
- Seats: AppSec Lead, Global Tech Law Lead, General Counsel — all
  CONDITIONAL SIGN-OFF, zero blocks raised, zero regression rounds used.
- Clean-design rules (§1): 13 numbered imperatives — may borrow loops/rules/
  genres/scènes à faire (with Data East limiting principle: borrow loops not
  lineups) vs. must originate titles/art/music/story/layouts/UI copy/total
  concept & feel; Tetris "could you have expressed it differently?" test as
  working standard; "if it needs a lawyer to argue, redesign"; mandatory
  clean-room discipline; never market as a clone of a named work.
- Per-title clearance gate (§2): trademark screen + original-expression
  inventory + trade-dress/UI-identity line item (GC-required) + never-do
  verification; BOTH Tech Law and GC signatures required — a title does not
  enter build until both sign. Standing block triggers: non-flagship titles
  blocked by default until cleared; build drift triggers re-review.
- Trademark process (§3): owner does not self-clear; TESS + app stores + web
  + phonetic/visual/meaning variants; store-search confusion test kills a
  name; rename-in-room, re-screen same day.
- MOONDRIFT (§4): flood-maze/no-fixed-layout/no-dot-grid sufficient ONLY
  with 5 extra guardrails (non-4 pursuer count w/ lanternfish-derived AI,
  no dot-clear goal, biology-based character distance, no signature layouts
  + load-bearing flood, original soundscape) + documented Atari-v-Philips
  differentiation analysis before build completes.
- AppSec annex (§6): strict CSP (zero inline scripts/styles/handlers in
  template — diverges from GLOAM precedent, flagged for template phase),
  reproducible builds, 404 probes, preview-gating verification, cache
  headers, per-project-per-title, shared.js version-stamp + fleet drift
  control, CI secret scanning, Ko-fi single-constant + rel=noopener,
  client-side hygiene bans, fleet runbook. HARD PRE-DEPLOY CONDITION:
  Vercel AI-training opt-out flipped + verified before first production
  deploy of any title (still not flipped by owner).
- GC residual risk (§7): JP/EU posture unresearched (geofence or brief
  before targeting), total-concept-and-feel fuzziness, trade dress,
  deterrents-are-not-shields. Honest promise: meritless claims, not a
  no-filing guarantee.
- NON-WAIVABLE monetized-launch gate (§8): licensed counsel reviews before
  ANY monetized step (Ko-fi links going live counts). Building permit vs
  occupancy certificate — framework signs blueprints, counsel clears opening.
- Next: BEACONFALL enters build under this framework (per-title §2 gate
  first); template-bootstrap prompt next.

## ADR-2026-10-07-AS-05: Mission complete — all acceptance criteria met
- Phase 4 QA gate (document mission): verified — 4 ADRs + ip-clean-framework.md
  all present and coherent; flagship slate recorded; framework carries
  conditional sign-offs from AppSec, Tech Law, GC; hosting/monetization
  resolved at $0 launch cost (no owner spend approval required); no secrets
  in any repo file.
- Mission deliverables: (1) flagship slate BEACONFALL → MOONDRIFT → MARSHLIGHT
  → SEEDSTORM + 3 sequenced batches; (2) IP-clean framework (10-section doc,
  per-title clearance gate, trademark process, MOONDRIFT high-heat guardrails,
  AppSec annex, honest residual-risk statement); (3) architecture: one private
  repo per game from arcade-template, one Vercel project per game (staging),
  Cloudflare Pages at first dollar, hub Arcade wing, Ko-fi tips.
- Gates now in force: per-title Phase 3 IP clearance (both signatures) before
  any build; AppSec hard pre-deploy condition = Vercel AI-training opt-out
  flipped; NON-WAIVABLE licensed-counsel review before any monetized step
  (Ko-fi links going live counts).
- Standing owner actions: (a) flip Vercel model-training opt-out (Team
  Settings → Data Preferences) — overdue, blocks first production deploy;
  (b) supply Ko-fi handle before first title's footer ships.
- Next: Prompt Writer perfects the arcade-template bootstrap prompt, then
  BEACONFALL enters its Phase 3 per-title IP gate. Per-title builds are
  follow-on workstreams.

## ADR-2026-10-07-AS-06: Owner decisions — opt-out waived, Ko-fi deferred, migratability locked
- 2026-10-07: owner was briefed on the Vercel AI model-training opt-out (what
  it is, Hobby-default ingestion, irreversibility) and chose to SKIP it.
  AppSec's hard pre-deploy condition (§6.6) is WAIVED by owner decision;
  deploys continue under Hobby defaults with training ingestion possible.
  Recorded as informed risk acceptance, not an oversight.
- Owner may change deployment strategy later: migratability is now a standing
  requirement — static output only, zero Vercel-specific code in game repos,
  headers mirrored in vercel.json + _headers (1:1), Cloudflare Pages cutover
  plan on file, Vercel projects go dormant-not-deleted on migration.
- Ko-fi: DEFERRED until first title nears launch. KOFI-HANDLE token stays a
  blocking release-gate item; owner supplies handle when ready.

## ADR-2026-10-07-AS-07: Full 36-title concept slate locked
- War room (PO + UI/UX + Growth, Chief presiding): 31 new original concepts
  locked + 4 flagships = 35 inspirations mapped (Ms. Pac-Man shares the
  maze-chase loop family with a differentiated concept).
- PO killed 3 drafts in-room (Centipede caterpillar-shooter: expressive rhyme;
  Paperboy drone-delivery: lazy reskin; Mortal Kombat bone-golem: gore rhyme)
  and replaced with DEWLINE, POSTWING, STRAWFALL.
- Every concept carries: genuine mechanical twist (one load-bearing twist
  each), viral mechanic, UI scheme (≤2 simultaneous inputs), retention hook.
- Suite-wide systems: share cards everywhere, rotating daily suite challenge
  (one title/day, fixed seed + dev par), rival hooks via anonymous codes,
  clutch detection, personal-best leaderboards until post-revenue.
- Suite-wide UI law: one verb, zero-text tutorial (first 15s teaches), thumb
  + key parity.
- Formal trademark screening runs per title at build gates (not at concept).
  No title builds before its Phase 3 per-title IP gate.

## ADR-2026-10-07-AS-08: arcade-template v1.0.0 built and verified
- Repo: private nx9161/arcade-template, template flag ON, branch main.
- Locked decision (Prompt Writer, Chief ratified): externalize bundle to
  game.min.js + strict CSP (choice b) — honors signed AppSec annex over the
  older GLOAM single-file precedent. Zero inline <script>, zero on*= handlers.
  vercel.json holds strict CSP (script-src 'self'); style-src 'unsafe-inline'
  deliberate (dynamic HUD styling, no script-execution risk).
- Commits: 6e7add2 scaffold · ade428c src/shared.js frozen · a367815 stub
  · 3fc51c4 tooling + game.min.js · 6131164 CI.
- Terser pinned 5.51.2, three-way agreement machine-checked in CI.
- All 5 verification checks pass (minify round-trip, local release-check,
  CI YAML parse, forbidden grep, pin agreement).
- Notes: gh repo create --template is a source-template flag; is_template set
  via gh api. <TITLE> HTML-escaped in index.html; release grep covers both.
  CI also asserts terser-pin agreement.
- Next: BEACONFALL per-title Phase 3 IP gate, then "Use this template".

## ADR-2026-10-07-AS-09: BEAMTIDE clears the first per-title IP gate (BEACONFALL killed)
- 2026-10-07: first per-title Phase 3 gate ran (Tech Law Lead + General
  Counsel + AppSec, Chief presiding). The screen KILLED the working title
  BEACONFALL: identical mark in commercial use — "BEACONFALL" (Steam,
  released 17 Jul 2026, Game Dynasty), a strategy game whose theme is
  "defend an island settlement, lighthouse holds back the darkness" —
  overlapping theme as well as identical mark. Additional identical-mark uses
  on itch.io. No argument available; retirement is a compliance instruction.
- Four replacement candidates screened and killed in-gate (WICKLIGHT,
  TIDEWARDEN, SEAWICK, STORMWARDEN — existing uses / crowded terms /
  phonetic fights). Selected: BEAMTIDE — coined word, zero game-title hits
  across Steam / App Store / Google Play / itch.io / web; only low-risk near
  neighbors documented (Beamrider 1983 — different coined mark).
- USPTO limitation stated in the clearance record: no TESS records surfaced
  via web search, but no direct TESS query was run in-gate — formal TESS +
  common-law search by licensed counsel required before any monetized step.
- Original-expression inventory + trade-dress review + clean-design check
  all pass; §3 design commitments (no row formations, no fixed descent
  cadence, no barriers, organic weather-driven dives) are BINDING on the
  build; drift triggers fresh Phase 3 review.
- Verdict: PASS (conditional), dual-signed. Repo shall be nx9161/beamtide.
- Suite slate updated: BEACONFALL -> BEAMTIDE everywhere. This is the gate
  working as designed — a screen that kills is a screen that works.
