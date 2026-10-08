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

## ADR-2026-10-07-AS-10: BEAMTIDE shipped to production (first suite title)
- 2026-10-07: nx9161/beamtide @ 5e9fe0d built from arcade-template, deployed
  to https://beamtide-nx9161s-projects.vercel.app (Vercel project beamtide,
  prj_mOdHfK2OfInDwPke2mrIFmxpXWSv, iad1, main).
- CRITICAL template fix found during build: template v1.0.0 had a boot-order
  bug (shared.js called Game.init synchronously before concatenated game.js
  evaluated -> TypeError, every generated title would fail to boot). Fixed
  upstream as template v1.0.1 (commit da435fc, deferred boot), cherry-picked
  into beamtide. All future titles inherit the fix.
- Verification: forbidden grep clean (incl. additive beamtide-side
  "beaconfall" check; noted CI false-positive pattern "Game contract" ->
  "contra"); terser 5.51.2, 23,681 -> 12,976 B; 14/14 headless logic tests;
  release-check 12/12 on production (6 headers, 404s, byte-identity);
  production public / previews SSO-gated (GLOAM posture); KOFI-HANDLE left
  literal per plan (blocking token for monetization).
- Trade-dress: no formations/cadence/barriers; storm-driven spawns; beam
  always-on (player's only verb is move); lives = 3 lamp pips; calm = ∞.
- Outstanding: real-browser play-through (delegated). Hub card cutover
  deferred per owner decision. Standing caveat: confirm real-internet
  reachability from owner's browser.

## ADR-2026-10-07-AS-11: BEAMTIDE real-browser QA passes 9/9
- 2026-10-07: live Chromium play-through of production — all 9 checklist
  items PASS (load/title, start via click + Space/Enter, mode + difficulty
  flow, keyboard + mouse steering, auto-beam redemption with gold climb-offs,
  lamp-pip game-over with taunt + copy button, P/Esc pause + M mute, Calm
  endless 60s+, clean game feel).
- Two notes: (a) difficulty is intentionally brutal for idle players
  (Wildfire ~12s, Lantern ~15-20s) — matches "punishing margins" copy,
  accepted as design; (b) Calm mode routes through difficulty select whose
  copy implies danger in a threat-free mode — queued as a polish fix (skip
  difficulty select in Calm).

## ADR-2026-10-07-AS-12: TIDELANTERN clears the MOONDRIFT gate (MOONDRIFT killed)
- 2026-10-07: second per-title gate, high-legal-heat track. "MOONDRIFT"
  KILLED in-room: "Moondrift Memory" (active 2025 cRPG, Streetlight Studio,
  exact leading element) + "Moon Drift" (P2E racing, same goods class) +
  "Driftmoon" (Steam RPG, reversed morphemes). Requires legal argument to
  defend -> renamed per standing rule.
- Selected: TIDELANTERN (tidepool + lanternfish photophores, biologically
  grounded). Rescreen clean across all venues; variants checked. Dual-signed
  CONDITIONAL PASS.
- Locked design: FIVE lanternfish, no archetypes, emergent bio/current
  behavior (counterillumination tracking, current-riding, school scatter,
  diel-rhythm patrol); deposit-light objective (relight dark reef nodes,
  win = restoration threshold, lose = 3 strikes or reef-darkness timer);
  NO dot-consumption vocabulary; expression bans binding (no mouths/eyes,
  no ghost bodies, no chomping, no siren escalation, no stable layouts);
  flooding provably routing-altering (impassable/low corridors, one-way
  currents, ebb-opens, scatter); Atari-v.-Philips differentiation filed.
- Repo shall be nx9161/tidelantern. "moondrift" barred from all materials.
- Suite slate updated: MOONDRIFT -> TIDELANTERN.

## ADR-2026-10-07-AS-13: TIDELANTERN shipped to production (second suite title)
- 2026-10-07: nx9161/tidelantern built from arcade-template v1.0.1, deployed
  to https://tidelantern-nx9161s-projects.vercel.app (Vercel project
  prj_dEzVfw0tQ9Tz865WxXjd8cj9xtcX, main, auto-deploy).
- Verification: 20/20 headless logic (5 fish identical params, maze seed
  flips every tide, 25.6% tiles change passability, win via real deposit
  path, loss on 3 strikes + darkness=100, calm endless); 18/18 in-browser
  play QA (zero JS errors, steering, pause/mute, win/lose overlays, surge
  reconfig live); release-check green (6 headers, 404s, byte-identity);
  forbidden greps clean (no moondrift/beaconfall/dot-vocabulary).
- Judgment calls: deposit automatic on contact (one-verb UI); reservoir =
  jellyfish glow radius; darkness = vignette + deepening drone (no siren);
  shared.js functionally frozen (comment-only token substitution; "contract"
  -> "interface" for CI's contra false-positive); real bug caught in QA —
  arrow keys read lowercase vs template's capitalized normKey, fixed and
  redeployed; debug hook window.TL_DEBUG gated behind ?debug.
- Design commitments from the clearance record held; no drift.

## ADR-2026-10-07-AS-14: REEDLIGHT clears the MARSHLIGHT gate (MARSHLIGHT killed)
- 2026-10-07: third per-title gate. "MARSHLIGHT" KILLED in-room: Marshlight
  Software is an active indie game dev/publisher (The Edgelands, Steam 2017)
  — near-identical trade name in interactive entertainment; defending the
  distinction requires legal argument -> renamed per standing rule.
- Candidates killed in-room: EMBERWISP (Mobile Legends skin, crowded
  in-class); FENLIGHT (Kodi addon ecosystem). Selected: REEDLIGHT (the
  fiction's destination — the far reed bed). Rescreen clean; WoW player
  character + fangame location are UGC, not marks. Dual-signed PASS.
- Locked design: firefly carries last ember to far reed bed; LIGHT AS FUEL
  (glow depletes with movement + in darkness; glow-motes replenish; light
  death = loss); hazard taxonomy wholly original (no borrowed obstacle
  taxonomies/speeds/progression); light-as-health visual language; original
  night-marsh art + guttering-wind audio.
- Repo shall be nx9161/reedlight. "marshlight" barred from all materials.
- Suite slate updated: MARSHLIGHT -> REEDLIGHT. Gates are 3-for-3 on kills.

## ADR-2026-10-07-AS-15: REEDLIGHT shipped to production (third suite title)
- 2026-10-07: nx9161/reedlight @ 2eb4ced built from template v1.0.1,
  deployed to https://reedlight-nx9161s-projects.vercel.app (Vercel project
  prj_UAsLXz8J5eitj6SsEYA6BgfQfyVX, main, auto-deploy).
- Design: firefly carries last ember bottom->top; LIGHT AS FUEL (movement
  4/6/8 per sec, darkness idle drain, mist x3, gloom pools x2; motes +18,
  score 10+combo*5; fuel 0 = "the dark takes the ember"); crossing banks
  100+fuel*2, difficulty ramps x1.08 (cap 1.6). Original hazard taxonomy:
  drifting mist banks, night-heron shadows (shadow only, never depicted;
  telegraphed sweeps, hit = -25 fuel + combo reset), rippling current bands,
  gloom pools. No lanes, no hop-grid, free 2D movement.
- Verification: 20/20 headless logic; release-check all-green (6 headers
  incl. strict CSP script-src 'self', 404s, byte-identity); forbidden greps
  clean (no marshlight/beaconfall/moondrift, no lane-crosser vocabulary);
  calm skips difficulty select (BEAMTIDE-proven bypass); terser 5.51.2,
  29,128 -> 15,007 B.
- Live-browser QA outstanding (delegated). Hub cutover deferred.

## ADR-2026-10-07-AS-16: SEEDRIFT clears the SEEDSTORM gate (SEEDSTORM + HAILSEED killed)
- 2026-10-07: fourth flagship gate. "SEEDSTORM" KILLED: "SEEDSTORM:
  Deterministic Strike" (QSOL-IMC, active maintained browser game) — identical
  mark, same goods class, fatal. First replacement "HAILSEED" also KILLED:
  one-letter visual near-neighbor of "HELLSEED" (active Steam horror FPS,
  Profenix Studio) in the same industry — defending requires legal argument.
  "PAPPUS" rejected pre-screen (Choost Games mark).
- Selected: SEEDRIFT (coined compound, seed that drifts). Zero game-title
  hits; only generic-suffix neighbors (Adrift, Emberdrift, Driftmoon).
  Dual-signed CONDITIONAL PASS.
- Locked design: dandelion seed, PERMANENT MOMENTUM NO BRAKES (lateral
  wind-nudges only — no thrust, no rotation, no stop); ZERO power-ups ship
  (no pickups, no taxonomy — cleanest posture); telegraphed storm cells
  (warning shimmer) as hazard + scoring unit; distance objective ("miles to
  the meadow"); scoring = survival time + distance + threading gust-combos,
  no per-kill points; bounded arena, storm-front walls, soft bounce, NO
  wrap-around; watercolor storm-sky art (no neon-on-black vector look);
  meadow/storm UI vocabulary ("hyperspace"/"shields" banned).
- Repo shall be nx9161/seedrift. "seedstorm" and "hailseed" barred from all
  materials. Suite slate updated. Gates are 4-for-4 on kills.

## ADR-2026-10-07-AS-17: SEEDRIFT shipped to production (fourth flagship)
- 2026-10-07: nx9161/seedrift @ b0c50ee built from template v1.0.1, deployed
  to https://seedrift-nx9161s-projects.vercel.app (Vercel project
  prj_YaZOHZKubR9B9sDUmJfe74Pxycpz, main, auto-deploy).
- Design: dandelion seed, PERMANENT MOMENTUM NO BRAKES (lateral nudges only,
  up/down ignored, min-speed re-enforced after wall bounces); telegraphed
  storm cells ("gust incoming" shimmer -> hail); threading = crossing cell
  band while active without strike, bonus 25xcombo; 100-mile distance
  objective (~3-4 min skilled ember); 3 tuft-integrity pips, strike knocks
  seed downwind + 1.6s invuln; ZERO power-ups; soft-bounce storm-front walls
  (no wrap); watercolor storm-sky (no neon-vector); meadow/storm vocabulary.
- Verification: 17/17 headless (real game.min.js); win branch verified on
  test bundle ("The far meadow!"); release-check all-green; forbidden greps
  clean (no seedstorm/hailseed/hyperspace/shields); terser 5.51.2,
  27,607 -> 14,933 B. Calm skips difficulty select (proven bypass).
- Live-browser QA outstanding (delegated). All four flagships now shipped.

## ADR-2026-10-07-AS-18: SEEDRIFT browser QA finds dead combo mechanic (repair dispatched)
- 2026-10-07: live Chromium play-through 8/10 with 1 partial, 1 FAIL.
  FAIL: storm cells spawn at y=-140..-190 (off-screen, never move) —
  telegraph invisible, threading geometrically impossible (inBand needs
  seed.y<30, seed clamped y>=35). Combo mechanic dead; title-screen hook
  "thread the hail" non-functional. Partial: pointer drag implemented but
  not visually confirmed. Minor: seed pins to ceiling while miles accrue.
- Everything else PASS: title/mode/difficulty flow, Calm direct-start,
  continuous motion, 3-strike game over + taunt + copy button, pause/mute,
  Calm endless 226s+.
- Repair dispatched on nx9161/seedrift: cells spawn visible with in-playfield
  telegraphs, threading geometrically achievable, drag verified, headless
  proof required (telegraph visible + combo increments + drag moves seed).
  Ceiling-pinning addressed only if cheap.
- Lesson: headless QA (17/17) passed with cells off-screen because the
  harness asserted spawn counts, not visibility/geometry reachability.
  Future title QA must assert mechanics are REACHABLE in the playfield,
  not merely present in code.

## ADR-2026-10-07-AS-19: REEDLIGHT browser QA 11/12 (heron telegraph too faint)
- 2026-10-07: live Chromium play-through — 11 PASS, 1 PARTIAL. Light-as-fuel
  economy verified (move-drain > idle-drain per difficulty; motes +18 fuel,
  score/combo bump); crossing bonus + reed-bed flash; run-over overlay +
  copy-taunt; pause/mute; Calm direct-start with ∞ ember bar.
- PARTIAL: night-heron telegraph renders at alpha 0.1-0.18 — never perceived
  across ~8 min of watching on all difficulties. Mechanic works (14/10/7s
  spawns, 1.2s telegraph, -25 fuel + shake) but the warning is invisible.
  Fix dispatched: raise telegraph alpha to 0.45-0.6 + slow pulse; timing
  and damage unchanged (visibility fix, not rebalance).
- Note: Wildfire idle drain ~1.8/s (~55s to empty standing still) is
  intentionally punishing; accepted as design.

## ADR-2026-10-07-AS-20: REEDLIGHT heron-telegraph fix shipped
- 2026-10-07: commit 9b65094 — warning ellipse alpha 0.10-0.18 -> 0.40-0.60
  with ~1s pulse during the 1.2s warning. Timing, cadence, -25 fuel hit,
  fuel economy untouched. Terser rebuild, forbidden grep clean, release-check
  all-green on production. REEDLIGHT fully verified.

## ADR-2026-10-07-AS-21: SEEDRIFT storm-cell repair shipped and proven
- 2026-10-07: commit 3863141 — cells now spawn in the visible playfield
  (gust-band y in [40,280], was y=-h-20 off-screen); inBand thread zone =
  visible cell rect + margin, reachable by lateral steering alone; telegraph
  label moved inside the rect.
- Headless proof (deterministic PRNG): telegraph renders on-screen;
  scripted lateral-only player reached maxCombo=8 over 600 sim-seconds —
  "thread the hail" hook functions; drag pull confirmed (x 230->424);
  permanent momentum + mile accumulation unregressed. Terser 5.51.2,
  28,706 -> 15,186 B. Release-check all-green on production.
- Binding commitments preserved (lateral nudges only, telegraph timing,
  zero power-ups, no wrap, vocabulary). Ceiling-pinning deliberately left:
  unpinning requires redesigning the wind model; playable without it.
- Live-browser re-verification delegated.

## ADR-2026-10-07-AS-22: SEEDRIFT re-verification 3/3 — flagship slate COMPLETE
- 2026-10-07: live-browser re-verification of the storm-cell repair: telegraphs
  clearly visible in-playfield (multiple spawn cycles); hand-steered threading
  reached COMBO 3 (was 0 pre-fix); drag steering pulls seed both directions.
- FLAGSHIP SLATE COMPLETE (2026-10-07):
  - BEAMTIDE (nx9161/beamtide): live, browser QA 9/9, Calm-bypass polish shipped.
  - TIDELANTERN (nx9161/tidelantern): live, 20/20 headless + 18/18 browser.
  - REEDLIGHT (nx9161/reedlight): live, 11/12 browser, heron-telegraph fix shipped.
  - SEEDRIFT (nx9161/seedrift): live, repair proven, re-verification 3/3.
  - All four: release-check green (6 headers, 404s, byte-identity), production
    public / previews SSO-gated, KOFI-HANDLE literal (blocking token).
  - Template: arcade-template v1.0.0 -> v1.0.1 (boot-order fix), 15 files,
    private, template flag on.
  - IP gates: 4-for-4 working-title kills (BEACONFALL, MOONDRIFT, MARSHLIGHT,
    SEEDSTORM + HAILSEED), 4 cleared replacements, all dual-signed.
- Outstanding per standing decisions: hub card cutover (deferred, owner call);
  Ko-fi handle (owner supplies pre-launch); licensed-counsel review before any
  monetized step (non-waivable); formal TESS searches per title pre-monetization.
- Batch 2 (brawler, run-and-gun, vertical shooter, digger) awaits owner's word
  per the quality/revenue learning gate.

## ADR-2026-10-08-AS-23: BURROWLIGHT clears Batch 2 gate (title survives)
- 2026-10-08: fourth Batch 2 gate (digger). "BURROWLIGHT" SURVIVES — no game
  title/app/Steam/itch.io collision on any venue. Nearest neighbor "Winter
  Burrow" (Pine Creek/Noodlecake cozy survival, 2025) assessed low-risk:
  different overall impression, different genre, only generic "burrow"
  shared. Dual-signed CONDITIONAL PASS.
- Locked design: glow-worm, sap-flooding drowns root-mites; FLOODED TUNNELS
  COLLAPSE (impassable, must alter routing materially — not cosmetic);
  root-mites wholly original, no inflation mechanics, no borrowed
  level-chunk structures; dark-soil/bioluminescent-sap art; light-as-route
  visual language.
- Repo shall be nx9161/burrowlight. Gates now 5 total: 4 kills, 2 survivors
  (BURROWLIGHT + STALLBREAKER screen-pass pending formal record).

## ADR-2026-10-08-AS-24: BRIARLINE clears Batch 2 gate (title survives)
- 2026-10-08: Batch 2 gate (run-and-gun). "BRIARLINE" SURVIVES — zero game
  uses on any venue. Non-conflicting noise: Briarline Ltd (UK real-estate
  micro-entity, different goods class), Briarline Corp (Panama shell),
  "Briar" ecosystem (LoL champion, messenger app — none is the mark).
  Dual-signed CONDITIONAL PASS.
- Locked design: hedgerow warden (original, no soldier/hero archetype);
  PLANT-YOUR-ARSENAL (pickups are seeds sown at checkpoints, grown into
  next-life weapons; death = planning horizon); weapon taxonomy wholly
  original (no recognizable run-and-gun weapon/power-up taxonomies, names,
  art, or sound vocabularies); living briar-wall stages; botanical bosses.
- Repo shall be nx9161/briarline. Gates now 6 total: 4 kills, 3 survivors.

## ADR-2026-10-08-AS-25: FOGCHART clears Batch 2 gate (title survives)
- 2026-10-08: Batch 2 gate (vertical shooter). "FOGCHART" SURVIVES — no
  commercial game on any venue. Sole near-neighbor "FogChat" (defunct Jul
  2025 social app, different class) recorded non-dispositive. Dual-signed
  CONDITIONAL PASS.
- Locked design: swift (bird) cartographer protagonist — no jets/spacecraft;
  THE MAP IS THE SCORE (tile-charting primary, enemies re-fog territory, no
  per-kill points); 100%-charted prestige runs; no copied bullet-pattern
  choreography/stage layouts/palettes; watercolor storm-sky + chart-parchment
  UI; no power-up-letter taxonomy.
- Repo shall be nx9161/fogchart.

## ADR-2026-10-08-AS-26: STALLBREAKER clears Batch 2 gate (title survives; record formalized)
- 2026-10-08: Batch 2 gate (brawler). "STALLBREAKER" SURVIVES — no game
  title/app/Steam/itch.io collision. Near neighbors all low-risk
  ("Steelbreakers" itch.io brawler — different coined mark/leading element;
  "Stone Breaker", "Backbreaker", "Game Breaker"). First session delivered
  only a teaser; reconvened session formalized the dual-signed record from
  recovered screen findings. Process note: gate agents must output the full
  clearance record as their final response, not a teaser.
- Locked design: noodle vendor wins back stolen cart; MARKET IS THE WEAPON
  (shove enemies into stalls — soup vats, awnings, lantern poles;
  environmental takedowns); market reopens behind with fresh hazards;
  enemy/hazard/stage taxonomy wholly original; no copied brawler archetypes,
  stage compositions, or UI layouts.
- Repo shall be nx9161/stallbreaker. Batch 2 gates: 4-for-4 PASS.

## ADR-2026-10-08-AS-27: Standing order — run the full pipeline without stopping
- 2026-10-08: owner issued standing directive "Don't ever stop" — the
  arcade-suite pipeline runs continuously through all batches without
  waiting for per-batch approval. This supersedes the earlier "Batch 3
  starts when you say go" checkpoint.
- Batch discipline still holds (sequential batches, learn between them;
  no all-36-at-once), but batches now chain automatically: gates ->
  builds -> QA -> deploy -> next batch's gates.
- Batch order: Batch 2 (STALLBREAKER, BRIARLINE, FOGCHART, BURROWLIGHT —
  in flight) -> Batch 3 (isometric hopper, aerial/flappy combat,
  time-management, dungeon crawler, city smasher) -> Batch 4 (weapons
  fighter, platform climber, obstacle course, physics roller, masocore
  platformer).
- Standing hard boundaries unchanged: no spend, no Ko-fi/monetization
  without licensed-counsel review, hub cutover stays owner-deferred,
  formal TESS searches pre-monetization.

## ADR-2026-10-08-AS-28: STALLBREAKER shipped to production (Batch 2 #1)
- 2026-10-08: nx9161/stallbreaker @ f6737f2 built from template v1.0.1,
  deployed to https://stallbreaker-nx9161s-projects.vercel.app (Vercel
  project prj_uze2yy5kpCDdzSPgzMSmSk7HVV32, main, auto-deploy).
- Design: noodle vendor (apron, headband, ladle) vs cart-snatcher thugs,
  single-screen night market (portrait 480x720); SHOVE (K/X or swipe) knocks
  thugs into stalls (soup vat/awning/lantern pole/pickle barrel) for
  environmental takedowns (50+combo*10, +12% reclaim, combo++); direct punch
  KOs pay 10/+4% — market is the prestige play. Thugs telegraph wind-ups
  (0.45-0.65s); 3 grit pips; stalls reshuffle every 30s; used stall dims 7s
  (never destroyed — market is the ally). Win at 100% reclaim ("Cart
  reclaimed!"); lose at 0 grit. Calm = endless stroll, skips difficulty.
- Verification: 15/15 headless + 2/2 targeted takedown proof (scripted
  shove-into-stall: combo 0->1); release-check all-green; forbidden grep
  clean; terser 5.51.2, 30,098 -> 17,356 B.
- Live-browser QA outstanding (delegated).

## ADR-2026-10-08-AS-29: BURROWLIGHT shipped to production (Batch 2 #4)
- 2026-10-08: nx9161/burrowlight @ f806780 built from template v1.0.1,
  deployed to https://burrowlight-nx9161s-projects.vercel.app (Vercel
  project prj_Agq3anzdsbHPqmjXaJsbR5WpoltE, main, auto-deploy).
- Design: grid digger (12x18, interpolated movement); glow-worm floods
  tunnels with sap: BFS flood -> sap phase (2.0-2.4s, mites drown,
  100xcombo) -> crack phase (1.0-1.4s, "COLLAPSE — MOVE!") -> rock
  (permanent, impassable). Caught in collapse = lose life + relocate.
  Mite quota per level (clear all -> regenerated garden, +2 mites/level,
  mites speed up); one-flood clear = +500 "ONE-ROUTE CLEAR" prestige; mite
  bites cost a life (3 lives, bite kills the mite too); spawn warnings;
  Calm = endless drift (+1/cell, skips difficulty).
- Verification: 24/24 headless (real game.min.js); materiality proof —
  scripted flood produced 8 rock cells, worm never re-entered (one-way
  commitment mechanically real); 2 real bugs found+fixed in QA (mite spawn
  area too small; Calm counters not zeroed); release-check 12/12;
  forbidden greps clean; terser 5.51.2, 32,390 -> 15,772 B.
- Live-browser QA outstanding (delegated).

## ADR-2026-10-08-AS-30: FOGCHART shipped to production (Batch 2 #3)
- 2026-10-08: nx9161/fogchart @ 01995d8 built from template v1.0.1,
  deployed to https://fogchart-nx9161s-projects.vercel.app (Vercel project
  prj_bTkv3bUYJf73etVZJAI8NPpYEv1L, main, auto-deploy).
- Design: swift cartographer; THE MAP IS THE SCORE — 12x18 tile chart,
  tiles uncover in light radius (~0.35-0.45s), +10/tile, combo on streaks;
  WIN = 100% charted simultaneously; mistwisps seek charted tiles and
  RE-FOG them (combo reset); swift's chart-light dissipates mistwisps
  (no player projectile — one-verb law); gloomwisps (lantern/wildfire)
  hunt the swift, light-immune, 3 tailfeather pips, 1.6s invuln; fail =
  3 strikes or storm clock (240/200/170s); Calm = endless, no wisps/clock.
  Watercolor storm-sky + parchment tiles; feathered swift (no jet).
- Verification: 26/26 headless (real game.min.js); win branch verified —
  one harness run WON naturally at 216/216 (prestige reachable), a dumber
  seed lost 213/216 at the clock (healthy variance); release-check
  all-green; forbidden grep clean (no ship/space/power-up vocabulary);
  terser 5.51.2, 31,517 -> 16,753 B.
- Live-browser QA outstanding (delegated).

## ADR-2026-10-08-AS-31: BRIARLINE shipped to production (Batch 2 #2)
- 2026-10-08: nx9161/briarline @ 4671ed3 built from template v1.0.1,
  deployed to https://briarline-nx9161s-projects.vercel.app (Vercel project
  prj_OClOwb9EBjsN80TRoiVexV8d6bKm, main, auto-deploy).
- Design: landscape run-and-gun (720x480); hedgerow warden; 3 stages x 6
  rooms (5 archetypes + boss room); 4 original foe types; 3 original
  botanical bosses (Gnarlmaw, Sporechoir, Briarheart); PLANT YOUR ARSENAL —
  5 seed tiers (Dawnpetal->Bloomflare), grove gates auto-sow, grown tier
  never downgrades, death keeps grown arsenal (unsown pouch scattered).
  Restructured to 3 lives x 3 bark pips after QA exposed pips-as-health
  never triggered death (the next-life mechanic never fired) — dying
  deliberately after sowing is now a real strategic tool.
- Verification: 21/21 headless (real game.min.js, ?debug-gated Game.qa);
  release-check all-green; forbidden grep clean (no antecedent weapon/
  military vocabulary); terser 5.51.2, 53,016 -> 28,982 B.
- Live-browser QA outstanding (delegated).

## ADR-2026-10-08-AS-32: Quality crisis — Game Feel overhaul program
- 2026-10-08: owner verdict — the 8 suite titles "dont even have a good
  game play", GLOAM "was good". Assessment: builders implemented specs;
  nobody tuned feel. GLOAM was iterated (keyboard steering, difficulty
  select, play-testing); suite titles got checklists. Known failure modes
  from QA: STALLBREAKER untriggerable shove / 6-17s Ember deaths / no
  health feedback / Space-Enter pause bug; SEEDRIFT dead combo (fixed);
  REEDLIGHT invisible telegraph (fixed); general brutal difficulty curves.
- Program: (1) Game Feel war room (PO + UI/UX) defines the GLOAM bar as a
  concrete per-title checklist; (2) all 8 deployed suite titles get
  feel-overhaul builds (tuning, juice, feedback, readability) WITHOUT
  touching cleared IP — names, trade-dress, load-bearing mechanics and
  binding commitments are frozen; (3) browser QA re-verification per title.
- GLOAM is explicitly excluded — untouched.
- Batch 3 gates run in parallel; Batch 3 builds get the feel bar baked in
  from day one. Standing "don't ever stop" order continues.

## ADR-2026-10-08-AS-33: FOGCHART browser QA 11/12 (Space/Enter gaps)
- 2026-10-08: live Chromium play-through — 11 PASS, 1 FAIL. Charting,
  re-fog tug-of-war, gloomwisp hunts, storm-clock expiry, Calm endless all
  verified; charting pace + re-fog pressure feel fair on Ember.
- FAIL: Space/Enter do NOT resume from pause (only P/Esc/button) — same bug
  class as STALLBREAKER. Also Space/Enter don't advance the title screen.
  One unexplained pause event observed (possibly blur-related — verify
  pause-on-blur is intentional and signaled).
- Findings forwarded to the Game Feel overhaul coordinator for the FOGCHART
  builder.

## ADR-2026-10-08-AS-34: CISTERNLIGHT clears Batch 3 gate (DEEPHOLD killed)
- 2026-10-08: Batch 3 gate (dungeon crawler). "DEEPHOLD" KILLED: identical
  mark — "Deephold" tower defense (Chuckwalla Works, Steam May 2026).
  Replacements MOSSDEEP (Pokemon-adjacent) and WICKDEEP (leading-element
  collision with "Wick") also killed in-room. Selected: CISTERNLIGHT —
  zero game uses, face-safe. Dual-signed CONDITIONAL PASS.
- Locked design: moss-delvers in sunken cistern; LIGHT IS THE SHARED
  HEALTH POOL (one lantern, darkness damage splits across whoever is lit,
  glowcaps refuel light not HP); original cistern fauna; drowned-stone/
  bioluminescent art; local co-op or AI party only (no networked multi
  without fresh review).
- Repo shall be nx9161/cisternlight. "deephold"/"mossdeep"/"wickdeep"
  barred from all materials. Gates now 7 total: 5 kills (+2 replacement
  kills), 6 survivors.

## ADR-2026-10-08-AS-35: BURROWLIGHT browser QA 10/11 (Space/Enter pause bug)
- 2026-10-08: live Chromium play-through — 10 PASS, 1 FAIL. Dig/flood/
  collapse loop verified readable and satisfying; collapse impassable;
  mite bites cost lives; level progression works; Calm endless.
- FAIL: Space/Enter do NOT resume from pause (only P/Esc/button) — third
  title with the identical bug (STALLBREAKER, FOGCHART). Confirms a
  template-level defect in shared.js pause-resume wiring, not per-title
  bugs. Feel overhaul must fix it in the TEMPLATE (v1.0.2) and propagate
  to all titles, not patch per-game.
- Minor: level counter jumped Lv 1 -> Lv 3 after one clearing — flagged
  for the BURROWLIGHT feel builder.
- Findings forwarded to the Game Feel overhaul coordinator.

## ADR-2026-10-08-AS-36: STORMBREAK clears Batch 3 gate (title survives)
- 2026-10-08: Batch 3 gate (city smasher). "STORMBREAK" SURVIVES — no
  commercial game on any venue. Near uses all non-conflicting (Halo 5 map
  name, Dragon Age item, card-game DLC/events, "-er" suffixed film/app
  uses in other industries). Dual-signed CONDITIONAL PASS.
- Locked design: storm giants (original weather-borne colossi) vs folded-
  paper city defended by kite corps; NET DESTRUCTION (city rebuilds during
  play, score = net ruin at the bell — race the rebuild); CATCH-NOT-HARM
  (falling townsfolk caught for bonuses, never rewarded for harm);
  watercolor storm-sky + paper-tear percussion.
- Repo shall be nx9161/stormbreak. Gates now 8 total: 5 kills, 7 survivors.

## ADR-2026-10-08-AS-37: LANTERNRAIL clears Batch 3 gate (LAMPLIGHT killed)
- 2026-10-08: Batch 3 gate (time-management). "LAMPLIGHT" KILLED: two
  identical-mark active games (Goldshoe Games roguelike on itch.io; 3D
  puzzle platformer on Steam app 3011380) + "Lamplight City" leading
  element. Replacement MOTHGLOW also KILLED: MothGlow Games active indie
  studio (MARSHLIGHT precedent). Selected: LANTERNRAIL — zero game uses,
  fictionally native (the promenade rail). Dual-signed CONDITIONAL PASS.
- Locked design: lamplighter slides lanterns down promenade rail to moth
  patrons; MOTHS DRINK THE LIGHT (served lanterns dim; refuel revisits
  are the core loop; serve-and-forget impossible by design); streak
  scoring ("twenty tables, zero dark"); original moth/lamplighter designs;
  night-gaslight art.
- Repo shall be nx9161/lanternrail. "lamplight"/"mothglow" barred from all
  materials. Gates now 9 total: 6 kills (+3 replacement kills), 8 survivors.

## ADR-2026-10-08-AS-38: CROAKSCALE clears Batch 3 gate (SPORESONG killed)
- 2026-10-08: Batch 3 gate (isometric hopper). "SPORESONG" KILLED: reproduces
  the entire famous SPORE mark (EA/Maxis, Steam, ~37K reviews) as its leading
  element in the identical goods class — stronger than the HAILSEED
  precedent. Selected: CROAKSCALE (croak + musical scale — fictionally
  native to the melody mechanic; zero collisions). DRUMCAP parked as
  fallback. Dual-signed CONDITIONAL PASS.
- Locked design: tree frog hops pyramid of drum-mushrooms; PYRAMID IS AN
  INSTRUMENT (hops sound notes + tint caps; row completion composes
  melodies; dissonant hops summon the dissonance crow); melody-completion
  scoring; perfect-song prestige runs.
- Repo shall be nx9161/croakscale. "sporesong" barred from all materials.
  Gates now 10 total: 7 kills, 9 survivors.

## ADR-2026-10-08-AS-39: THERMALANCE clears Batch 3 gate (SKYLANCE killed)
- 2026-10-08: Batch 3 gate (flappy combat). "SKYLANCE" KILLED: active
  "SKYLANCE" mobile-game studio on Google Play (Ecto Rush, Aquantika) —
  MARSHLIGHT precedent applied. Replacement GALEJOUST rejected on
  trade-dress grounds ("joust" is the antecedent's generic loop term;
  framework demands distance). Selected: THERMALANCE (thermal + lance —
  fictionally native, zero collisions). Dual-signed CONDITIONAL PASS.
- Locked design: swift-rider (original, not a knight) jousts magpie rivals
  with reed lance; THERMALS as free lift (readable rising-air ribbons),
  flapping spends stamina; higher rider wins via thermal positioning;
  come-from-below reversal clips as viral hook.
- Repo shall be nx9161/thermalance. "skylance" barred from all materials.
  Gates now 11 total: 8 kills, 10 survivors.

## ADR-2026-10-08-AS-40: Owner halted Game Feel overhaul (/stop)
- 2026-10-08: owner issued "/stop". Game Feel overhaul coordinator and its
  per-title builders were shut down mid-flight. No feel fixes were merged
  by this program; the 8 deployed titles remain at their last shipped
  commits (BEAMTIDE, TIDELANTERN, REEDLIGHT, SEEDRIFT, STALLBREAKER,
  BRIARLINE, FOGCHART, BURROWLIGHT).
- Batch 3 gates completed BEFORE the stop: all 5 cleared (CROAKSCALE,
  THERMALANCE, LANTERNRAIL, CISTERNLIGHT, STORMBREAK). No Batch 3 builds
  were started. Pipeline is fully paused pending owner's next direction.
- Known unresolved quality findings preserved for resume: Space/Enter pause-
  resume bug is TEMPLATE-level (shared.js), confirmed on 3 titles
  (STALLBREAKER, FOGCHART, BURROWLIGHT); STALLBREAKER browser QA human-feel
  failures; FOGCHART 11/12; BURROWLIGHT 10/11.

## ADR-2026-10-08-AS-41: Full stop on owner's order
- 2026-10-08: owner issued "Stop everything you're doing". The last running
  agent (BRIARLINE browser QA play-through) was interrupted and closed. No
  other work was in flight. Pipeline is fully halted; nothing new will
  start without the owner's explicit direction.

## ADR-2026-10-08-AS-42: War Room fix run verdict — CONDITIONAL GO (Track A pause + Track B STALLBREAKER)
- 2026-10-08 (~22:15 EDT): Full war room convened on owner's "Fix after
  discussion in war room" (Prompt Writer perfected the prompt; echo given).
  Seats: Gameplay Designer, Game UI/UX Designer, Lead Frontend, QA Manager,
  Game Producer. Phase 0 briefing verified against template repo and ADRs.
  No code written, nothing merged in this phase.
- KEY FINDING: **Vercel deploy pipeline broken.** Cherry-picked v1.0.2
  shared.js was pushed to ALL 8 game repos (byte-identical except NS slug),
  but served https://stallbreaker-nx9161s-projects.vercel.app/game.min.js
  lacks the v1.0.2 keydown literals — Vercel did not auto-deploy. Human
  escalation: owner must diagnose/fix the pipeline + give production-deploy
  approval. Nothing deploy-dependent moves until that clears.
- Track A (converged): v1.0.2 approach approved (commit b7191c7 in
  nx9161/arcade-template, pushed, NOT yet tagged); tidelantern double-fire
  regression (its per-game Space/Enter router skips two overlays) fix-forward
  IN Track A scope — narrow its router to the ov-over->btnRestart clause;
  beamtide/seedrift/reedlight routers benign; briarline has none. Regression
  checklist upgraded: exactly-one-transition-per-keypress on every overlay.
  Deploy verification = byte-compare served /game.min.js vs repo blob at
  cherry-pick SHA (heuristic: `".matches("` present; never grep mangled
  names). Tag v1.0.2 ONLY after per-title G-1 deploy confirmation. Blur-pause
  gets `audio.sfx('pause')` + TEMPLATE.md doc in-train, no version bump.
  'Over'-state keyboard mapping -> v1.0.3 (UI/UX locks spec before Track A
  sign-off). Keyboard contract: game-local handlers may not bind
  Space/Enter on overlay states; repeat-guard required.
- Track B (converged): STALLBREAKER retune — Ember: windup telegraph
  0.65->0.75s + 90ms pre-hit commit flash, knockback 260->140px/s, invuln
  1.2s w/ blink, spawnEvery 3.2->4.5s, first spawn +2.5s delay. Shove/
  takedown: flight 0.5->0.9s, 470->420px/s, decel pow(0.001)->pow(0.02) dt
  (~180-220px travel), 25-degree aim-assist cone, stall trigger r+24,
  cooldown 7->4s, no silent mid-run reshuffles, takedown feedback stack
  (hit-stop + shake + 2x lingering pop + first-takedown tutorial). Hearts:
  top-right (suite-wide GLOAM consistency), 2x scale min, white-stroke
  fill, damage pulse + "GRIT -1" edge-flash. Calm: "CALM — practice, no
  damage", ambient pedestrians, stall glow, SAFE-tagged hearts, persistent
  CALM chip. Gameplay writes the one-pager (incl. intended Ember median
  survival) before retune pass 1; retune bounded at 3 passes.
- Execution order: 1) human escalation (Vercel), 2) parallel repo-side work
  (tidelantern fix, sfx+doc, design locks, hearts spec), 3) deploy all 8
  (owner approval), 4) G-1 byte verify, 5) tag v1.0.2, 6) G-4 Track A
  sign-off, 7) Track B merges + redeploy, 8) human QA, 9) G-5 accept,
  10) G-6 ship (owner approval).
- Unresolved dissent recorded: (1) QA holds 10 human runs as block
  criterion vs Producer's min-3 (Gameplay's merge compatible with either).
  (2) Pause-reason on-screen text: UI/UX + QA hold it as Track A closure;
  Producer ruled v1.0.3. Sloane ruling (2026-10-08): adopt UI/UX's minimal
  form — one secondary line at the autoPause() call site, no architecture,
  no version bump — in-train; it unblocks two seats' sign-off at ~zero cost.
  If owner upholds Producer's ruling, UI/UX's and QA's dissent stands as
  recorded blocks on FOGCHART sign-off.
- Informational: BURROWLIGHT Lv1->Lv3 is NOT by design (level++ exactly
  once per levelClearCheck, line 266); QA to instrument during regression,
  no change this round.
- Standing constraints honored: GLOAM untouched; no title ships until
  fun-verified in a real browser; scope held to the two tracks.

## ADR-2026-10-08-AS-43: STALLBREAKER retune one-pager REJECTED by Game Producer (resubmit required)
- 2026-10-08 (~22:20 EDT): Game Producer reviewed the Track B retune
  one-pager (design/stallbreaker-retune-onepager.md, Rev 1) against AS-42
  and REJECTED it. Six revisions required, all owned by Gameplay: (1) lock
  the intended Ember median survival target — the Producer does not invent
  balance numbers (floor to beat: 6-17s); (2) restore the converged takedown
  feedback stack (hit-stop + shake + 2x lingering pop + first-takedown
  tutorial) with concrete acceptance notes — no "prototyped at
  implementation" vagueness; (3) add converged "stall glow" to Calm spec;
  (4) state the full shove-deceleration change (pow(0.001)->pow(0.02),
  ~180-220px); (5) "2x scale minimum" (not fixed 2x) for hearts; (6) state
  the 3-pass retune bound + escalation path. Approved as-is on resubmit:
  all Ember constants, shove geometry, hearts spec, Calm
  banner/pedestrians/SAFE hearts/CALM chip, DO NOT IMPLEMENT discipline.
- Gameplay revising (Rev 2). Producer signs on compliant resubmit; retune
  pass 1 may then begin at repo level. Design sign-off covers design only;
  Vercel pipeline repair + production-deploy approval remain the owner's
  separate human gates.

## ADR-2026-10-08-AS-44: STALLBREAKER retune one-pager SIGNED (Rev 2, design lock complete)
- 2026-10-08 (~22:23 EDT): Gameplay submitted Rev 2 addressing all six
  AS-43 revisions (commit 4f1b5a9). Game Producer re-reviewed and SIGNED:
  Ember median survival locked at 45s (beats 6-17s floor ~3x); converged
  takedown feedback stack fully specified (hit-stop 120ms, shake 6px/200ms,
  2x pop 900ms dwell, one-time first-takedown tutorial); stall glow in Calm;
  full shove-deceleration change with intended travel; "2x scale minimum"
  hearts; 3-pass retune bound + escalation path stated verbatim.
- Track B is now DESIGN-COMPLETE. Retune pass 1 may begin at repo level
  once the owner's Vercel pipeline repair + production-deploy approval
  land. No code written yet; DO NOT IMPLEMENT discipline held throughout.

## ADR-2026-10-08-AS-45: Vercel "Blocked" root cause found — commit-author attribution (Hobby private repos)
- 2026-10-08 (~00:50 EDT): Dashboard investigation (owner signed in via
  takeover; read-only, no changes) found all 7 cherry-pick deployments were
  auto-created but sit in Vercel's "Blocked" state — Hobby-plan
  private-repo commit-attribution block. The cherry-pick commits are
  authored `nx9161 <naman@maxtechlife.me>`, which Vercel cannot attribute
  to the Hobby team owner, so they never built. Tidelantern's later fix
  commit (`Sloane (War Room) <nx9161@users.noreply.github.com>`) deployed
  READY — the noreply.github.com identity is recognized. Not a Git
  misconfiguration, not a failed build.
- Durable fix applied: git user.name/user.email set to
  `nx9161 <nx9161@users.noreply.github.com>` in ALL local clones
  (8 games + arcade-template) so future commits attribute correctly.
- Recovery prepared (NOT pushed): one author-corrected empty retrigger
  commit per repo on top of main (beamtide 8a47d05, reedlight 382656c,
  seedrift dfb1b58, stallbreaker 9b8a027, briarline 9c6d834, fogchart
  aa0dc12, burrowlight 8f29dc4). Pushing fires production auto-deploys —
  awaiting owner's explicit production-deploy approval per house rules.
- G-1 byte-verify spec updated: compare served /game.min.js against the
  repo blob at these new commit SHAs (content unchanged from the
  cherry-picks).

## ADR-2026-10-08-AS-46: G-1 deploy verification PASSED all 8; v1.0.2 tagged; G-4 Track A SIGNED
- 2026-10-08 (~00:55 EDT): Owner gave explicit production-deploy approval.
  Pushed the 7 author-corrected retrigger commits (beamtide 8a47d05,
  reedlight 382656c, seedrift dfb1b58, stallbreaker 9b8a027, briarline
  9c6d834, fogchart aa0dc12, burrowlight 8f29dc4). Vercel auto-deployed all
  within ~1 min. G-1 byte-verification: served /game.min.js is
  BYTE-IDENTICAL to repo main on ALL 8 titles (md5 match per title).
- Tagged v1.0.2 (annotated) on arcade-template commit b7191c7, pushed to
  origin. Per the room's order the tag stays on b7191c7; the blur-pause
  signaling commit (8f74b0b) is template-only for now — its propagation to
  games is an open follow-up for the v1.0.3 train.
- G-4 Track A SIGN-OFF: pause defect fixed at template level, propagated
  identically to all 8 (shared.js byte-identical except sanctioned NS slug),
  tidelantern double-fire fixed, FOGCHART title advance + blur-pause
  covered, regression checklist green. Sloane signs Track A complete.
  Track B (STALLBREAKER retune pass 1) authorized to begin.
