# PRD v2 — PlayStation Portal → Xbox Handheld (Software-Only Mission)

**Product:** PlayStation Portal Remote Player, repurposed as an Xbox handheld (Xbox Cloud Gaming / Xbox console streaming) via open-source software, driven from the owner's MacBook.
**Owner:** Product Owner, Virtual IT Office
**War room phase:** Phase 1 — Intake & PRD (research spike; NO production code in this war room)
**Status:** DRAFT — pending Phase 2 research spike
**Date:** 2026-10-06
**Supersedes:** `prd-v1-superseded.md` (hardware-spike framing: shell access, EDL, firmware dumping). That PRD is archived in this room for background; this PRD replaces it. Its core findings still stand: the Portal is Android-based, USB-C appears charging-oriented, and the only public exploit chain (Feb 2024) is patched in firmware 2.06.

---

## 1. Problem Statement

The owner has a **PlayStation Portal** — Sony's PS5 Remote Play streaming handheld — and wants it to **play Xbox games** (via Xbox Cloud Gaming through a browser, or Xbox console streaming) instead of / alongside PS5 streaming. All setup must be done from the owner's **MacBook Pro over USB-C**, using **public open-source software from GitHub**.

The gap: the Portal is a closed, locked-down streaming client. Out of the box it runs PS5 Remote Play and (since Nov 2025) PlayStation cloud streaming — nothing else. The owner has zero path today to get an Xbox-capable client (browser page, app, or third-party streaming client) onto the device, and Sony provides no developer tooling. The distance between "it streams PS5" and "it plays Xbox games" is the unknown Phase 2 (research spike) must close: **what install path actually works from a MacBook to the Portal** (ADB? a browser-based channel? sideloading at all?), **what Xbox client can run on the Portal**, and whether **controls and latency are playable**.

### Constraints on how we solve it (owner-mandated, non-negotiable)

1. **No hardware modifications of any kind** — no teardown, no UART/JTAG/soldering, no test points, no case opening.
2. **No hardware programmer/flasher dongle** — the owner will not buy special hardware.
3. **No paid tools** — Portal + MacBook + USB-C cable + public open-source code only.
4. **Hugging Face is irrelevant to this plan** — it hosts ML models, not device firmware or game clients. It appears in this PRD only to record that it is *not* part of the solution, unless Phase 2 finds a genuinely applicable use (e.g., an input-mapping model — not expected).

---

## 2. User Stories

All stories assume: Portal in hand + MacBook Pro + a USB-C cable, no purchases, no hardware mods. Each story has **measurable** acceptance criteria. Where current-firmware reality is unknown, the criterion is "Phase 2 must establish X before claiming the story is achievable."

### US-1 — Discover the MacBook→Portal install path

> I follow documented open-source steps from my MacBook to get *something* (a page, an app, a shell session) running on my Portal that Sony didn't ship.

**Why first:** everything else depends on this channel. This is the highest-risk story.

**Acceptance criteria (measurable):**
- [ ] Phase 2 identifies and documents **one** concrete install/launch path from a MacBook to the Portal, with exact commands, repo commit pins, and expected outputs — OR documents with evidence that **no such path exists on current firmware** (negative result counts; the mission pivots to honest "not currently possible").
- [ ] The candidate path is classified against current firmware (2026): works on ≤2.05 only (the Feb 2024 PPSSPP exploit era) vs. works on current firmware. If only the former, the story is **blocked**.
- [ ] No step requires a purchase, a hardware mod, or Sony-signed tooling; each step's tool is open-source and Mac-compatible.
- [ ] The path does not depend on an unreleased exploit, undisclosed vulnerability, or "exploit development from scratch" (explicitly out of scope — see §5).

**Notes from Phase 1 research:** The Feb 2024 exploit chain (TheFloW / Andy Nguyen + xyz + Calle Svensson) ran PPSSPP on the Portal but was responsibly disclosed and **patched in firmware 2.06** (Apr 2024); there is no public sideload/jailbreak method known to work on current firmware. [wololo.net](https://wololo.net/2024/04/03/playstation-portal-theflow-confirms-exploit-patched-in-firmware-2-06/). Community reports describe the Portal's USB-C port as charging-oriented with no data connectivity — so **ADB over USB-C is a hypothesis, not a fact**, and must be verified (not assumed) in Phase 2.

### US-2 — Get an Xbox-capable client running on the Portal

> I get an Xbox Cloud Gaming client (web app at xbox.com/play, or an open-source streaming client) onto/running on my Portal using open-source software.

**Acceptance criteria (measurable):**
- [ ] An Xbox-capable client is launched on the Portal via the path from US-1: either (a) a working web browser that can open **xbox.com/play**, (b) an installable open-source Xbox streaming client APK/app, or (c) another verified path.
- [ ] The client passes Xbox Cloud Gaming's **browser/client requirements**: Microsoft officially supports Edge, Chrome, and Safari for web play ([xbox.com/play requirements](https://www.fortnite.com/news/fortnite-now-available-through-xbox-cloud-gaming-play-via-browser-on-mobile-and-pc-with-xbox-cloud-gaming-for-free); [cloudloadout](https://cloudloadout.com/xbox-cloud-gaming-not-working/)). Whatever browser the Portal runs must be verified against this list in Phase 2.
- [ ] The owner can sign in with their Microsoft account inside the client on the Portal (sign-in completes; no auth loop).
- [ ] **Game Pass Ultimate subscription** is documented as an assumption to verify (see §4): cloud gaming for the full catalog requires Game Pass Ultimate; only select titles (e.g., Fortnite) are free without it.

### US-3 — Controls and input mapping work

> I can control Xbox games on my Portal — the built-in controller (DualSense-style halves) maps correctly, or an external controller works.

**Acceptance criteria (measurable):**
- [ ] Every standard Xbox input (left/right stick + clicks, D-pad, A/B/X/Y, bumpers, triggers, menu/start, view/select) produces the **correct** in-game action in at least one test title — measured by pressing each input and recording the resulting action in the spike log.
- [ ] No input is dead, duplicated, or inverted after mapping is complete; the acceptance log lists each input and its verified mapping.
- [ ] Stick sensitivity and trigger range are usable for gameplay (qualitative owner sign-off in a recorded play session, not a lab metric).
- [ ] Fallback documented: if the built-in Portal controls cannot be remapped, Phase 2 evaluates pairing an external controller (e.g., Bluetooth Xbox controller) and records whether the Portal accepts it.

**Notes:** Xbox Cloud Gaming web supports DualShock 4 and other pads via Bluetooth/USB, but DualSense-on-non-PlayStation-host mapping has historically been inconsistent ([techsith](https://techsith.com/how-good-is-xbox-cloud-gaming/)); the Portal's split-DualSense layout adds mapping risk. Mark expectations conservatively.

### US-4 — Playable end-to-end Xbox session on the Portal

> I sit down with my Portal, launch an Xbox game from my MacBook-set-up device, and actually play it.

**Acceptance criteria (measurable):**
- [ ] From a powered-off Portal: reach a launched, playable Xbox Cloud Gaming session in **≤ 5 minutes** following only the documented steps.
- [ ] Play one full round/level (≥ 10 minutes continuous) of a first-party-recognized game (e.g., Fortnite via free cloud tier, or a Game Pass title) with no session-killing failures.
- [ ] Measured latency/input delay is **playable for the genre tested** (record ms; genre-dependent — fine for RPGs/adventure, borderline for competitive shooters — honestly reported, not hand-waved).
- [ ] Reproducibility: the full setup (US-1 → US-4) is repeated from scratch by following the docs alone, in one evening session, with no step requiring undocumented improvisation.
- [ ] End-to-end path uses **zero paid tools, zero purchases beyond the owner's existing hardware and existing Game Pass status, and zero hardware modifications**.

---

## 3. War-Room Acceptance Criteria (the three hard gates + reproducibility)

These gate the *whole mission*. If any gate fails, the PRD's honest outcome is "not currently achievable" — not a fudged pass.

| Gate | Criterion |
|---|---|
| **No hardware mods** | No teardown, UART/JTAG/soldering, test points, case opening, or component changes appear anywhere in the documented procedure. Verified by procedure review. |
| **No paid tools** | Every tool in the procedure is free and open-source (GitHub public repos, free SDKs/platform-tools). No purchases required — verified against owner's existing kit (Portal + MacBook + USB-C cable). |
| **Reproducible tonight from a MacBook** | A competent owner following the written steps completes US-1 → US-4 in one evening session, with no improvisation beyond the docs and no step that silently depends on an unreleasable exploit or paid asset. |
| **Evidence over assumption** | Every install path, browser capability, and firmware claim is tested on the owner's actual Portal at its actual firmware version, or explicitly marked SPECULATION. |

---

## 4. Edge Cases

1. **Sony firmware updates patch sideload/jailbreak methods.** The Feb-2024 PPSSPP exploit chain was fixed in **firmware 2.06** (Apr 2024) — the *only* public Portal exploit, and it is dead on current firmware ([wololo.net](https://wololo.net/2024/04/03/playstation-portal-theflow-confirms-exploit-patched-in-firmware-2-06/)). Any method Phase 2 proposes **must be checked against current 2026 firmware**, not against 2024-era writeups. The PRD carries a standing risk: Sony can patch any discovered software path at any time; the procedure must pin the exact firmware version it was verified on.
2. **USB-C port data capability limits.** Community reporting describes the Portal's USB-C port as charging-oriented with no data connectivity (no ADB, no USB audio/Ethernet) — [ResetEra owner thread](https://www.resetera.com/threads/the-playstation-portal-remote-player-launches-starting-november-15-in-select-markets-pre-orders-now-live.759663/page-25). This is **not fully settled** (an earlier spike note cites an EDL-over-USB report), but the PRD treats "ADB from the MacBook just works" as unproven. Phase 2 must verify the actual data channel (USB-C data? browser/captive-portal trick? Wi-Fi-based install?) before US-1 can pass.
3. **Xbox Cloud Gaming browser requirements.** Microsoft officially supports web play on **Edge, Chrome, and Safari** via xbox.com/play; minimum ~10 Mbps, 20+ Mbps recommended for larger screens. If the Portal's available browser is not on the supported list (or is a locked-down settings-webview), cloud gaming may not launch — Phase 2 must test the actual client against xbox.com/play. Minimum network bar: sustained ≥ 20 Mbps on the Portal's Wi-Fi (the Portal is Wi-Fi 5-era; record actual link speed).
4. **Game Pass Ultimate assumption.** Full-catalog Xbox Cloud Gaming requires **Game Pass Ultimate** (a paid subscription). Free-to-play titles (e.g., Fortnite) stream without it. The owner's Game Pass status is an **assumption to verify, not a war-room deliverable** — the war room does not buy or provision subscriptions. Phase 2 acceptance testing uses either the free tier or the owner's existing subscription; if neither exists, US-4 degrades to "verified up to sign-in" and the gap is honestly recorded.
5. **Input/latency realities.** Expect: (a) DualSense-layout-on-Xbox mapping quirks (button-label mismatches, historically inconsistent DualSense support on non-PlayStation hosts), (b) cloud-streaming latency stacked on top of the Portal's own decode latency — fine for slower genres, marginal for twitch shooters/fighters, (c) touchpad-dependent Xbox titles may be unplayable on the Portal's control layout. None of these block the mission, but all must be measured and honestly reported in US-3/US-4.
6. **No public method exists on current firmware (mission-kill risk).** As of Phase 1 research: no public sideload path, jailbreak, or ADB access is known to work on current-firmware Portals. If Phase 2 confirms this, the correct PRD outcome is **"mission not currently achievable — blocked pending a new public method,"** with the research documented for future re-evaluation. Do not ship a procedure built on hope.

---

## 5. Out of Scope

- **Exploit development from scratch.** Finding or developing a new vulnerability chain is not this war room's job; we use public, open-source methods or honestly report none exist.
- **Piracy / DRM circumvention.** No bypassing of game licensing, no pirated titles, no circumvention of Xbox or PlayStation DRM. Xbox games are streamed through legitimate Xbox Cloud Gaming with a legitimate account.
- **PS5-side modifications.** The PS5 is untouched; nothing is jailbroken, modded, or reconfigured on the console side.
- **Hardware modifications.** Covered by hard constraint §1, restated here for scope clarity: no teardown, soldering, UART/JTAG, test points, or internal changes.
- **Purchases beyond existing kit.** No hardware programmer/flasher dongle, no new controllers (unless the owner already owns them — then pairing is in scope), no paid software. The Game Pass Ultimate question is an assumption to verify (§4.4), not a war-room deliverable.
- **Hugging Face.** Not a firmware or game-client source; excluded from the plan except as a noted irrelevance.

---

## 6. Sources & Speculation Log

| Claim | Source | Status |
|---|---|---|
| Portal runs Android (Snapdragon-class SoC), OS blocks sideloading | 9to5google, Feb 2024 (via prd-v1-superseded.md) | Evidence |
| Feb-2024 PPSSPP exploit chain patched in firmware 2.06 (Apr 2024); disclosed by TheFloW et al. | [wololo.net](https://wololo.net/2024/04/03/playstation-portal-theflow-confirms-exploit-patched-in-firmware-2-06/) | Evidence |
| Portal USB-C widely reported as charging-only / no data, no USB audio/Ethernet | [ResetEra launch thread](https://www.resetera.com/threads/the-playstation-portal-remote-player-launches-starting-november-15-in-select-markets-pre-orders-now-live.759663/page-25) | Evidence (community reports; Phase 2 to verify on owner's unit) |
| Portal gained PS Plus Premium cloud streaming (Nov 2025) and 1080p High Quality mode (Mar 2026) | [dexerto](https://www.dexerto.com/gaming/playstation-brings-cloud-streaming-to-ps-portal-for-ps5-games-you-already-own-3279767/), [tech-insider](https://tech-insider.org/playstation-portal-cloud-streaming-2026/) | Context (Sony-side capability; not the Xbox path) |
| Xbox Cloud Gaming web: xbox.com/play; supported browsers Edge/Chrome/Safari; ≥10 Mbps min, 20+ recommended | [fortnite.com](https://www.fortnite.com/news/fortnite-now-available-through-xbox-cloud-gaming-play-via-browser-on-mobile-and-pc-with-xbox-cloud-gaming-for-free), [cloudloadout](https://cloudloadout.com/xbox-cloud-gaming-not-working/), [techsith](https://techsith.com/how-good-is-xbox-cloud-gaming/) | Evidence |
| Game Pass Ultimate required for full cloud catalog; Fortnite free tier needs only a Microsoft account | [fortnite.com](https://www.fortnite.com/news/fortnite-now-available-through-xbox-cloud-gaming-play-via-browser-on-mobile-and-pc-with-xbox-cloud-gaming-for-free) | Evidence |
| DualShock 4 + others supported by Xbox Cloud Gaming over BT/USB; DualSense mapping historically inconsistent on non-PS hosts | [techsith](https://techsith.com/how-good-is-xbox-cloud-gaming/) | Evidence (mapping risk noted) |
| An open-source, working, current-firmware install path from MacBook to Portal | — | **SPECULATION / UNKNOWN — Phase 2 must establish or disprove** |
| Whether the Portal's browser (if any) passes xbox.com/play requirements | — | **UNKNOWN — Phase 2 to test** |

---

*End of PRD v2. Next: Phase 2 research spike — verify/establish the US-1 install path on the owner's actual firmware before any further planning.*
