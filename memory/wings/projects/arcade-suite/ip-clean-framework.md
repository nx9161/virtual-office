# IP-Clean Framework — Arcade Spinoff Suite
**Phase 3 War Room · Chief Sloane presiding · 2026-10-07**
**Status: SIGNED (conditional) — all three seats. No blocks raised. Build gate: OPEN under the conditions below. Monetized-launch gate: separate, later, non-waivable (see §8).**

Seats: AppSec Lead · Global Tech Law Lead · General Counsel (sign-off authority).
*This framework is a design/build risk instrument produced by a War Room. It is not legal advice, not legal clearance, and not a guarantee of non-infringement. It does not substitute for licensed counsel.*

---

## §1 — Clean-design rules (numbered, imperative)

### What you MAY borrow (filtered out under Data East / merger / scènes à faire)
1. **Borrow loops and genres as functional ideas.** Maze-chase, fixed shooter, lane-crosser, arena physics, brawler, fighter, shmup — ideas are not expression.
2. **Borrow rules and mechanics.** Pellet-eating, pursuer AI, power-ups, lane-crossing timing, momentum physics. No one may monopolize a sport or a rule set (*Data East v. Epyx*; *Fighter's History* shielded from *Street Fighter II* claims on the same logic).
3. **Borrow scènes à faire.** Elements *necessary* to depict the genre: a grid for tile-matching (*Spry Fox*), a playfield for falling blocks, dots in a maze for maze-chase. If you could not express the loop without it, it is likely unprotectable.
4. **Borrow functional UI conventions.** Score counters, lives, level numbers, pause menus. Functional, not expressive.

**The Data East limiting principle (a constraint, not a blank check):** Data East shields similarities *inherent to depicting the genre* — it does **not** shield expressive choices you could have made differently. Fifteen similarities all rooted in "this is what karate looks like" were fine; a copied expressive arrangement would not be. When a similarity survives Data East filtering, it still faces the Tetris test (Rule 10). **Borrow loops, not lineups: if the element exists because the genre demands it, record the reason in the clearance record; if it exists because the original did it that way, cut it.**

### What you MUST originate (protectable expression under *Tetris Holding* / *Spry Fox* / *Atari v. Philips*)
5. **Originate every title, character name, story text, and UI copy.** Every word invented in-room.
6. **Originate all art, sprites, tiles, backgrounds, and character designs.** Drawn from the functional spec only. The gobbler/ghost problem in *Atari v. Philips* proves character design alone can sink a total-concept-and-feel defense.
7. **Originate all music and SFX.** Every composition, every sound. No sampling, no "in the style of" recreations of iconic jingles.
8. **Originate level layouts and level logic that expresses choice.** Maze layouts, enemy spawn patterns, wave structures, progression logic.
9. **Originate the total concept and feel.** The holistic impression. "Focus on what is similar, not what is different" (*Spry Fox*); "no plagiarist can excuse the wrong by showing how much of his work he did not pirate" (*Atari v. Philips*). You do not get to port the whole vibe and claim credit for a new skin.

### Working standards
10. **Apply the Tetris "could you have expressed it differently?" test to every close call.** *Tetris Holding* protected playfield dimensions, tetromino shapes, ghost piece, and next-piece preview precisely because Dr. Mario proved the same rules could be expressed differently. If your design could not have been expressed differently, document *why* (functional necessity, merger, scènes à faire). If it could have been, express it differently — now.
11. **"If it needs a lawyer to argue, redesign."** Close-call arguments are for defendants with litigation budgets. This suite has 35 titles and no insurance. When a rule admits reasonable doubt, the redesign is cheaper than the analysis.
12. **Clean-room discipline is mandatory, not aspirational.** A study team writes a *functional* loop spec (inputs/outputs/mechanics — never art, text, or layout); implementers build from the spec with zero access to the originals. Deliberate copying was the aggravating fact that buried Xio in *Tetris Holding*; the clean-room record is what proves it did not happen here.

### Marketing
13. **Never market any title as a clone of a named work.** No "a Pac-Man clone," no "like Space Invaders," no rivals' marks in titles, descriptions, keywords, or ad copy. Nominative fair use is narrow (only what is necessary to identify, never to trade on goodwill) and is no shield against a §2(d) likelihood-of-confusion claim. Describe the *loop* ("maze-chase," "fixed shooter"), never the *antecedent*.

---

## §2 — Per-title clearance checklist (the gate form)

**A title does not enter build until BOTH Tech Law and General Counsel sign. A single sign-off is a BLOCK, not a shortcut.**

**A. Trademark screen** (completed before any public use; process in §3):
- [ ] USPTO TESS full-text search, all live marks — exact title, plurals, common misspellings, phonetic equivalents
- [ ] App Store + Google Play + itch.io + Steam — exact and near-match titles
- [ ] Web search (general + image) — title + "game"
- [ ] Phonetic/visual/meaning variant pass under §2(d)
- [ ] Game-adjacent classes reviewed (Classes 9, 28, 41, 25 — read broadly)
- [ ] Domain/social-handle collision noted (collision ≠ confusion, but recorded)

**B. Original-expression inventory** (attested by the design lead; Tech Law spot-checks):
- [ ] All art/sprite/tile/background assets — original authorship; no third-party assets
- [ ] All music/SFX — original composition; no samples, no interpolations
- [ ] All names (title, characters, enemies, items), story text, UI copy — original
- [ ] Level layouts, wave structures, progression logic — original expressive arrangement
- [ ] Total concept and feel — reviewed against the specific inspiration loop; differentiators documented

**C. Trade-dress / UI-identity review** *(GC-required line item)*:
- [ ] HUD layout, character silhouettes, overall UI "look" compared against the inspiration loop for source-confusion risk (Lanham Act §43(a) vector — distinct from copyright); comparison documented

**D. Never-do verification:**
- [ ] No original-studio assets in repo (art, audio, code, fonts, palettes)
- [ ] No homage easter eggs referencing other studios' works — zero tolerance (the "deliberate copying" accelerant from *Tetris Holding*)
- [ ] No inspiration-naming in repo copy, comments, commits, or docs (describing the loop generically is fine; naming the antecedent is not)
- [ ] Clean-room provenance documented — spec authors and implementers separated

**E. Sign-off:**
```
Tech Law Lead: __________________  Date: _______  [SIGN-OFF / CONDITIONAL / BLOCKED]
General Counsel: _________________  Date: _______  [SIGN-OFF / CONDITIONAL / BLOCKED]
```
Both signatures required. Each title gets its own dated clearance record — no batch rubber-stamping across titles. A checklist filled out honestly is evidence; a rubber-stamped one is theater, and theater is worse than nothing.

**Standing block triggers (Tech Law):** (A) any of the ~31 non-flagship titles without a completed per-title clearance is BLOCKED by default — the four flagships' sign-off does not extend to them; (B) any build-stage drift from the MOONDRIFT guardrails (§4) or the never-do verification triggers immediate Phase 3 re-review and halts that title's ship until re-signed. The forbidden list is audited at merge, not assumed.

---

## §3 — Trademark-screening process

- **Who runs it:** the trademark screener role named per title in the Phase 0 perfected prompt (typically Prompt Writer or a designated research seat). Tech Law reviews the screen; General Counsel signs the risk call. **The owner does not self-clear.**
- **Sources:** USPTO TESS (all live marks; advanced Boolean operators, not just basic word search), App Store, Google Play, itch.io, Steam, general web search, phonetic/visual/meaning variant pass.
- **What kills a name (likelihood of confusion, plain language):** an existing live mark or prominent game title that (a) sounds like it, looks like it, or means the same thing, **and** (b) lives in games or adjacent goods/services. The store-search test: *if a shopper typing our title could land on their product — or vice versa — the name dies.* Game-adjacent classes are read broadly; "different class" is not a defense against confusion in app stores.
- **The rename-in-room rule:** a killed name is renamed *in the War Room session*, re-screened the same day, and the clearance record notes the kill and the replacement. Dead names are never "reconsidered later." One title, one cleared name, before build starts.

---

## §4 — High-heat loop guidance: MOONDRIFT (maze-chase)

Maze-chase is the highest legal heat in the suite: *Atari v. Philips* enjoined K.C. Munchkin! with **zero** copied code or art, on total concept and feel alone, with gobbler-plus-ghost character designs decisive. The locked flood-maze / no-fixed-layout / no-dot-grid architecture is strong — it attacks exactly the features *Tetris Holding* treats as protectable expression (fixed layout, fixed playfield, pellet-grid arrangement). **It is sufficient to proceed ONLY with these five extra guardrails locked as build requirements, not preferences:**

1. **Pursuer count and AI distinctness.** Do not default to 4 pursuers with personality-archetype AI (the chaser/ambusher/patroller/shy quartet is the single most recognizable expressive signature of the antecedent). Use a different count (3 or 5+) with AI behaviors derived from the *lanternfish* biology fiction — deep-sea luring, bioluminescent ambush, current-riding — and document each behavior's fictional origin. Distinct by design, not by accident.
2. **Player-goal expression.** No "eat all dots to clear the maze." The moon-jellyfish goal must be expressed through the redemption/biome fiction (e.g., *restore bioluminescence nodes to heal the reef*) with different win/lose mechanics and scoring — not a pellet-percentage clone wearing a jellyfish skin. (*Spry Fox*: a full art swap does not cure a copied structure.)
3. **Character design distance.** Player and hunters must read as jellyfish and lanternfish *on their biology*, with no visual rhyme to the antecedent's designs — mouths, eyes, ghostly body shapes all off-limits. Run designs past a design seat that has never seen the spec's inspiration line.
4. **Maze-generation constraints.** Procedural flood-maze generation must produce no stable "signature" layout across runs, and flood reconfiguration must be mechanically load-bearing (gating routing decisions), not cosmetic. If the maze feels like the antecedent with water in it, the design failed.
5. **Sound and pacing distance.** No waka-waka-style rhythmic eating audio; no siren-rising-on-clearance audio arc. Original soundscape from the reef fiction.

**GC-required addition:** before MOONDRIFT's build completes, a documented *Atari-v-Philips-factor* differentiation analysis (the factors the Seventh Circuit weighed: character design, total concept and feel, idea-vs-expression framing) must be filed in its clearance record. Any one of the five guardrails slipping in build triggers a Phase 3 re-review before ship.

---

## §5 — Loop-specific cautions: other three flagships

- **BEACONFALL (fixed shooter) — moderate heat.** Risk is *Tetris Holding*-style protectable expression in playfield geometry and threat-wave choreography: wave patterns, descent behavior, shield/defense arrangements. The tidal-lighthouse fiction helps, but do not mirror classic invader-row descent cadences or barrier arrangements; vary grid shape, descent logic, and projectile behavior and document the differences.
- **MARSHLIGHT (lane-crosser) — low-moderate heat.** Lane-crossing sits near *Data East* territory: timing, lane density, obstacle cadence are largely scènes à faire. Risk concentrates in expressive extras — the light-as-fuel mechanic is the right kind of origination. Caution: do not reproduce a signature obstacle taxonomy (a recognizable ladder of obstacle types with the same speeds and spacing) — the "total concept and feel" of a specific original's level progression is where *Atari v. Philips* could bite.
- **SEEDSTORM (arena physics) — low-moderate heat.** Momentum/no-brakes/collision mechanics are functional and heavily filtered; dandelion-seed fiction is strongly originating. Caution: if the arena includes pickups, power-ups, or hazards, do not copy a recognizable power-up taxonomy or expressive scoring structure from a specific original — invent storm systems from the seed fiction, and keep arena geometry procedurally varied rather than a fixed signature layout.

---

## §6 — AppSec serving annex

The Phase 2 posture is sound for static game hosting (no backends, no PII, no accounts, no third-party scripts — the attack surface is genuinely small). The following are **required changes**, not preferences:

1. **Headers — strengthen the CSP.** Keep the six locked headers; expand CSP beyond `frame-ancestors` to a strict policy: `default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'`. This runtime-enforces the no-third-party-assets rule: any smuggled CDN script will not execute. **Consequence for the template: zero inline scripts, inline styles, or inline event handlers** — or the policy breaks the game or fails to protect it. *(Chief's note: this diverges from the GLOAM precedent, which ships inline scripts; the template build phase must resolve it — externalize all scripts/styles in the arcade-suite template.)* Pin HSTS at `max-age=31536000` minimum; `includeSubDomains` only after confirming no sibling-subdomain HTTP need; do **not** preload without an explicit recorded decision (effectively irreversible at 35-project scale).
2. **Minification — honest limits.** Minification deters casual copy-paste and nothing else; a prettifier restores readable logic in seconds. Acceptable as a deterrent because nothing confidential ships (no secrets, no PII, no license checks of value in client code, by locked policy). Required: (a) reproducible builds — CI verifies served bytes are byte-identical to a fresh build from private source, closing the "reviewed source, served something else" gap; (b) obscurity is never a control — if a future title needs real secrecy, that is a backend, which triggers fresh review.
3. **404 posture.** Per title: `outputDirectory` pinned explicitly to the dist dir; repo root (`src/`, `tools/`, `.github/`, `package.json`, `README.md`, `.env`) never inside it. Automated post-deploy probe asserting **404** on: `/.git/`, `/.git/HEAD`, `/src/`, `/tools/`, `/package.json`, `/package-lock.json`, `/.env`, `/README.md`, `/.github/`, `/node_modules/`, `/api/` — with **no `api/` directory shipping at all** (no serverless functions, no unintended endpoints). Directory listing disabled (Vercel default — verify once per template, not per title).
4. **Preview gating.** Login-gated previews (Vercel Deployment Protection) keep pre-release bytes off the public internet. Verify ON for previews on **every** one of the ~35 projects before the launch wave (team default if available, else per-project checklist); production stays public. Note: gating stops third parties, not Vercel itself — see point 6.
5. **Caching.** HTML entry points `no-cache` (or short TTL); JS/CSS/assets content-hash fingerprinted and immutable. A header fix or shared.js patch behind a stale CDN cache is a fix that did not ship. One-time template setting in `vercel.json`.
6. **Model-training ingestion — HARD PRE-DEPLOY CONDITION.** Vercel Hobby ToS §3 grants training rights over deployed content plus third-party sharing; the opt-out is currently **off**, so every deploy is an **irreversible** disclosure of original game code, art, and music — you cannot un-train a model, and it amplifies any future secrets slip from "rotate and purge" to "ingested by third parties, unfixable." This directly contradicts the owner's locked posture (private repos, minified deterrent, zero tracking). **Required (owner-side, ~5 minutes, team-level — one flip covers all 35 projects): flip Team Settings → Data Preferences opt-out and confirm; the Chief verifies BEFORE the first production deploy of any title.** Alternatives that also close it: upgrade to Pro (training off by default), or the planned Cloudflare Pages migration at first dollar — but verify Pages' training terms first, do not assume. Not a BLOCK on builds because the harm attaches to *deploys*, not builds — halting build work gains nothing. **No production deploy until flipped.**
7. **Topology: per-project-per-title** (affirms locked posture). Blast-radius containment — a leaked deploy hook/token or bad push affects one title; independent per-title rollback and collaborator access. Config drift across 35 projects is mitigated by the template plus automated header-conformance probes. Operational flag (not a gate): sanity-check Hobby project-count and bandwidth limits for 35 projects.
8. **Frozen shared.js duplication — keep it, add process.** Duplication wins: hermetic per title, zero runtime supply-chain surface. Its weakness is patch propagation. Required before the 6th title ships: (a) single canonical `shared.js` in the template repo; (b) version stamp in every copy (`SHARED_JS_VERSION`); (c) CI drift-diff job across the fleet flagging stale copies; (d) security patches ship with a tracked fleet-rollout checklist; (e) reproducible-build verification per point 2. A shared runtime dependency would trade a manageable process problem for an unmanageable supply-chain attack surface — the wrong trade.
9. **Secrets hygiene at 35-repo scale.** Required: (a) secret scanner (gitleaks or equivalent) in template CI, blocking on hits, inherited by every title repo; (b) `.env` in the template `.gitignore`; (c) documented rule — secrets live only in Vercel project environment variables, per-project scope, never in git, never in served files; (d) periodic fleet sweep; (e) the no-analytics/trackers-without-review gate doubles as the secrets gate for future third-party additions.
10. **Off-site link hygiene (Ko-fi).** (a) The Ko-fi URL lives as a **single constant** in the template (`shared.js` config) — 35 hand-typed URLs *will* produce a typo that becomes a typosquat donation leak; (b) `rel="noopener"` on every external link (tabnabbing); `no-referrer` already covers referrer leakage; (c) no on-site payment code ever without fresh review.
11. **Client-side hygiene (cheap CI bans).** Ban `eval(`, `new Function(`, `document.write(`; manual review of any `innerHTML`; no reflection of URL parameters into the DOM without encoding (shared game links like `?name=` are the realistic reflected-XSS vector). The strict CSP is the backstop. Note: localStorage high scores are trivially forgeable — fine, as long as no value (prizes, paid unlocks) is ever attached.
12. **Fleet runbook.** Before the fleet scales: one-page runbook covering emergency shared.js patch rollout, per-project deploy-token/credential rotation, and how to pull a title (remove deployment / pause project). Rehearse once on a sacrificial title.

---

## §7 — Residual risk statement (General Counsel, plain language)

What this framework does NOT cover:

**(a) Jurisdiction variance.** The doctrine briefed is US law. The major arcade IP owners are Japanese — Namco (Bandai Namco), Capcom, SNK, Taito, Konami — and Japanese/EU enforcement postures were **not researched**. A design clean under US idea/expression analysis may still draw a demand letter from a Japanese rightsholder under different enforcement norms, and EU unfair-competition regimes have their own "look and feel" doctrines. Licensed counsel must brief JP/EU posture before launch targets those markets, or launch stays geofenced to the US until briefed.

**(b) "Total concept and feel" is deliberately fuzzy.** *Atari v. Philips* applied it broadly (maze-chase clone enjoined); *Data East v. Epyx* applied it narrowly (karate-game clone cleared). Similar fact patterns, opposite outcomes — the difference turned on how much expressive detail was taken and how the judge framed idea versus expression. No checklist converts this into a formula. The framework's honest function is to push every title as far toward the *Data East* end of the spectrum as possible and to flag MOONDRIFT for high-heat treatment.

**(c) Trade-dress and UI-copy risk beyond copyright.** Copyright covers code, art, music. Trademark law (Lanham Act §43(a)) separately protects source-identifying visual identity — distinctive HUD layouts, character silhouettes, overall UI "look" that could confuse consumers about origin. A title can be 100% copyright-clean and still draw a trade-dress claim. §2(C) of the clearance checklist covers this vector explicitly.

**(d) Minification and private repos are deterrents, not shields.** In litigation, discovery reaches everything regardless of repo visibility, and served bytes are always fetchable. They must never be invoked as legal defenses or relied upon to excuse a weak clearance record.

**The honest promise:** Conscientiously followed and documented, this framework makes infringement claims against these titles **meritless** — independent creation, contemporaneously documented, is a complete defense, and there will be no copying to point to. What it **cannot** promise is that no one ever files: anyone can send a demand letter, file a meritless suit, or issue a DMCA takedown to a host (Vercel/Cloudflare), each of which costs time and money to defeat even when you win. **Meritless ≠ costless.** That residual nuisance risk is inherent to publishing anything in a genre with aggressive incumbents.

---

## §8 — Gates

**Build gate (THIS phase — now OPEN, conditional).** Title builds may proceed under all conditions recorded in this document: per-title §2 clearance with both Tech Law and GC signatures, MOONDRIFT's §4 guardrails, the AppSec annex's required changes (with the model-training opt-out verified before the first production deploy), and the standing block triggers in §2.

**Monetized-launch gate (NON-WAIVABLE, separate, later).** Before ANY monetized step — and "monetized" explicitly includes **Ko-fi tip links going live**, not just a commercial launch — **licensed counsel must review that title (or launch batch) for clearance.** No seat in this office, no checklist, and no framework sign-off substitutes for that review. Think building permit versus occupancy certificate: you do not need the occupancy inspection to approve the blueprints, but you may not open the doors without it. Signing this framework does not waive, satisfy, or substitute for the counsel gate. The gate may not be waived, narrowed, or removed by any seat.

---

## §9 — Blocks raised and resolved

**No blocks were raised by any seat.** The phase's blocking power was exercised as standing conditions and required changes instead:

- Tech Law: two standing block triggers (§2) — non-flagship titles blocked by default until cleared; build drift triggers re-review.
- General Counsel: six sign-off conditions (§7/§8 + §2(C) trade-dress line item + written counsel gate + JP/EU briefing rule).
- AppSec: seven required changes (§6), with the model-training opt-out as a hard pre-deploy condition.
- Chief's recorded divergence: strict-CSP's zero-inline-scripts requirement vs. the GLOAM inline-script precedent — flagged for the template build phase to resolve (§6.1).

No regression rounds were needed (max 3 permitted; 0 used).

---

## §10 — Sign-offs

**AppSec Lead: CONDITIONAL SIGN-OFF** — Serving posture is sound for static game hosting; no production deploy of any title until the Vercel AI-training opt-out is flipped and verified, with strict-CSP, 404/header conformance probes, per-project preview-gating verification, shared.js version-stamp + fleet drift control, and CI secret scanning in place.

**Global Tech Law Lead: CONDITIONAL SIGN-OFF** — Four flagship frameworks are IP-clean as specified; build may proceed only upon per-title completion of the §2 clearance gate with BOTH Tech Law and GC signatures, MOONDRIFT's five extra guardrails (§4) documented as build requirements, and the two standing block triggers enforced.

**General Counsel: CONDITIONAL SIGN-OFF** — Framework is sufficient as a design/build risk instrument; builds may proceed only under these conditions: (1) the non-waivable licensed-counsel review gate before any monetized step (Ko-fi tips going live counts) is written into the framework document; (2) per-title clearance includes an explicit trade-dress/UI-identity line item with documented comparison; (3) MOONDRIFT's high-heat guardrails are applied with a documented Atari-v-Philips-factor differentiation analysis before build completes; (4) each title gets its own dated clearance record — no batch rubber-stamping; (5) the framework is never represented as legal clearance or a guarantee; (6) JP/EU enforcement posture is briefed by licensed counsel before launch targets those markets, or launch is geofenced to the US until briefed.

*Phase 3 gate: SIGNED. Title builds are unblocked under the conditions above. — Chief Sloane*
