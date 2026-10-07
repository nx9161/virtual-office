# PRD — PS Portal ↔ MacBook USB-C Link (Programmable Portal Spike)

**Product:** PlayStation Portal Remote Player ↔ MacBook Pro direct USB-C link for programming/tinkering
**Owner:** Product Owner, Virtual IT Office
**War room phase:** Phase 1 — Intake & PRD (research spike; NO production code, NO build work in this war room)
**Status:** DRAFT — pending spike experiments
**Date:** 2026-10-06

---

## 1. Problem Statement

The owner holds a **PlayStation Portal** handheld and a **MacBook Pro**. The Portal is an
Android-based device (Snapdragon-class Qualcomm SoC; 8" 1080p LCD; USB-C port) whose
official software only does PS5 Remote Play / cloud streaming — a black box the owner
cannot program.

The owner wants to **treat the Portal as a general-purpose programmable Android device**:
get a shell, sideload their own software, inspect the firmware, and run custom code —
over a **direct Portal↔MacBook USB-C link** (not via the PS5, not over Remote Play).

**The gap:** plugging the Portal into the MacBook with USB-C *today* only charges it.
Sony documents the USB-C port for charging, and ships no developer tooling, no
documented USB data mode, and an OS that blocks APK installation ([9to5google, Feb 2024](https://9to5google.com/2024/02/20/sony-playstation-portal-android-psp-mod/)).
The distance between "cable physically fits" and "programmable device" is the entire
unknown the spike must close:

1. **Physical/electrical:** does the USB-C port carry USB data at all, or is it power-only?
2. **Enumeration:** when plugged into a MacBook, what (if anything) shows up in the USB stack (`system_profiler SPUSBDataType`, `ioreg`)?
3. **Trust/channel:** is there any path to ADB/fastboot, or to Qualcomm EDL/recovery, that survives Sony's lockdown?
4. **Software policy:** even with a data link, Sony blocks sideloading — the spike must identify which layer to attack (exploit, EDL, OTA package analysis) without *developing* a new exploit in this war room.
5. **Patch level:** the only public exploit chain (Feb 2024, Google engineers) was patched in firmware **2.06** (Apr 2024); the current firmware is **7.x** (see Edge cases §4).

### Why this is a war room, not a weekend project

- The port's data capability is genuinely disputed (charging-only per Sony vs. bootloader USB modes per hardware reality).
- One real-world data point strongly suggests **data does flow**: a researcher got a Portal into **Qualcomm EDL (Emergency Download) mode over USB on Windows 11** (detected by the `edl` tool with Sahara protocol, HWID `0x002360e1`, recovery codename `bengal`) — EDL is impossible over a power-only port ([bkerler/edl#674](https://github.com/bkerler/edl/issues/674)). **Mark as evidence, not proof** — needs replication on the owner's unit and on macOS.
- The exploit landscape moved on: the Feb 2024 exploit chain was responsibly disclosed and is dead on current firmware; there is no public "tinkerer's jailbreak" to copy.

---

## 2. User Stories

All stories assume the owner's **Portal in hand** + **MacBook Pro**, a **USB-C↔USB-C cable
known to carry data** (test the cable against a phone first), and no PS5 involvement.
"Portal" = PlayStation Portal (not Meta/Facebook Portal — a different device entirely;
do not mix up documentation).

### US-1 — Establish a data link Portal↔MacBook (USB-C)

> As the owner, I want to plug the Portal into my MacBook over USB-C and see it
> enumerate as a USB device, so I have a confirmed data channel to build on.

**Acceptance criteria (measurable):**
- [ ] Portal plugged into MacBook via USB-C appears in `system_profiler SPUSBDataType`
      output (any VID/PID recorded in the spike log), OR is shown to enumerate in
      **no** mode across power-on / recovery / powered-off states (negative result is
      also a result — record VID/PID or "not enumerated" per state).
- [ ] A data-capable control check: the same cable + MacBook port enumerates a known
      Android phone, isolating cable/port as variables.
- [ ] Spike log records Portal USB behavior in each state: normal boot, powered off,
      recovery mode (button combo), EDL mode — with timestamps and firmware version.

**Speculation flagged:** Sony's docs describe the port for charging ([Push Square hardware review](https://www.pushsquare.com/features/hardware-review-ps-portal-is-the-perfect-ps5-companion-for-some)).
Whether any data pins are live is unverified on the owner's unit.

### US-2 — Shell / ADB access

> As the owner, I want an `adb shell` prompt on the Portal from my MacBook, so I can
> inspect the live system (processes, partitions, properties).

**Acceptance criteria (measurable):**
- [ ] `adb devices` lists the Portal with state `device` (after authorizing the host
      key on the Portal screen, if reachable).
- [ ] `adb shell getprop ro.build.version.release` returns the Portal's Android
      version; `adb shell getprop ro.product.model` identifies the unit. Values logged.
- [ ] `adb shell` interactive session works (prompt, `ls`, `id`).
- [ ] If ADB is unreachable in normal boot, the spike documents *which* fallback was
      tried and the outcome: ADB-over-Wi-Fi (needs IP + an initial ADB channel —
      chicken-and-egg, document), recovery-mode ADB sideload interface, fastboot
      (`fastboot devices`), Qualcomm EDL (Sahara/Firehose detect via `edl` tool).

**Known constraints:**
- Portal Settings expose no documented Developer Options / USB-debugging toggle;
  stock UI is a locked launcher (speculation: toggle absent by design — verify in spike).
- Android security model: USB debugging requires on-device RSA authorization; without
  screen access to the dialog, `adb` stays `unauthorized` (established Android behavior,
  not Portal-specific).

### US-3 — Sideloading apps

> As the owner, I want to install my own APK on the Portal (`adb install`), so I can
> run my own software alongside (or instead of) Sony's launcher.

**Acceptance criteria (measurable):**
- [ ] A trivial hello-world APK (debug-signed, `targetSdk` matching Portal's Android
      version) installs via `adb install` with `Success` — or the exact failure
      (`INSTALL_FAILED_*`, signature/permission error) is recorded.
- [ ] If installed, the app **launches** (`adb shell am start …`) and renders on the
      8" display; a screenshot/logcat capture proves it.
- [ ] Package-manager state recorded: `adb shell pm list packages` output archived in
      the spike log (shows what Sony ships, what's a system app, available storage —
      public reporting noted ~6 GB user storage).

**Known constraints:**
- Public reporting (Feb 2024) states Sony blocks APK installation and the Google team
  found a bypass that was **never released and was patched in 2.06** — do NOT assume
  `adb install` works on current firmware ([9to5google](https://9to5google.com/2024/02/20/sony-playstation-portal-android-psp-mod/),
  [VGC](https://www.videogameschronicle.com/news/hackers-who-got-ps-portal-to-run-psp-games-offline-helped-sony-to-patch-out-the-exploit/)).

### US-4 — Firmware inspection / dump

> As the owner, I want to obtain and inspect the Portal's firmware/software image, so I
> can study its Android build, partition layout, and update mechanism without
> modifying the device.

**Acceptance criteria (measurable):**
- [ ] The Portal's current **system software version** is recorded from the device UI.
- [ ] Sony's GPL/open-source publication for the Portal OS is located (Sony has
      published Portal OS source for versions 1.00/1.01/2.0.0 under OSS licenses —
      [wccftech](https://wccftech.com/playstation-portal-os-source-code-cpu/)); the
      spike archives which version's source is available and what it reveals
      (kernel config, `SM6225`/Snapdragon 680 references, partition info).
- [ ] The **OTA update mechanism** is documented from observation: how updates are
      delivered (over Wi-Fi via PSN), package format if obtainable, and whether the
      update file is capturable for offline analysis (proxy capture) — read-only.
- [ ] A partition map is produced from the least-invasive available channel
      (`adb shell ls /dev/block`, recovery, or EDL `printgpt` if EDL is reachable —
      note the public EDL attempt stalled at loader upload, so treat as experimental).
- [ ] No write operations to flash in this spike; inspection is **read-only**.

### US-5 — Run custom homebrew code

> As the owner, I want to run my own native/Android code on the Portal (the
> "PPSSPP moment" for this device), proving the Portal is genuinely programmable.

**Acceptance criteria (measurable):**
- [ ] A "hello-world" native or Android app **executes on Portal hardware** and produces
      observable output (on-screen render, logcat line, or file written to app storage).
- [ ] The execution path is classified: (a) via ADB/sideload on stock firmware,
      (b) via a known exploit chain on a pinned old firmware, or (c) via EDL/fastboot
      flashing — with the exact firmware version the path works on.
- [ ] The spike states plainly whether this is achievable on the owner's **current**
      firmware or requires downgrading / an unpatched unit — no hand-waving.

**Known constraints:**
- The only demonstrated native-code execution (PPSSPP, Feb 2024) was a Google-internal
  exploit chain, never released, patched in 2.06. Reproducing it is **out of scope**
  for this war room (see §5).

---

## 3. Acceptance Criteria for the War Room Itself

This is a **research spike**, not a build. The war room succeeds when it delivers a
**verdict + evidence + recommended next path**, even if the verdict is negative.
"Connected and programmable" for the spike's recommendation means:

| # | Criterion | Evidence artifact |
|---|-----------|-------------------|
| 1 | **Port truth established** | Spike log: USB enumeration results per device state (boot / off / recovery / EDL), with VID/PID or documented absence. |
| 2 | **Channel inventory complete** | For each of ADB / fastboot / recovery-ADB / EDL: reachable or not, from macOS, with exact commands run and outputs. |
| 3 | **Firmware baseline recorded** | Owner's Portal system-software version + Android version/API level (from device or ADB), checked against the public firmware history (2.0.6 … 7.x). |
| 4 | **Policy layer mapped** | Documented: sideload block behavior (`adb install` result), launcher lockdown, OTA mechanism, available OSS source drops. |
| 5 | **Path recommendation** | One of: (a) "programmable today via path X on firmware Y" with repro steps; (b) "blocked at layer Z — here is the cheapest experiment to unblock"; (c) "not feasible without new exploit development — do not proceed." |
| 6 | **Risk register** | Bricking, warranty, PSN-account, and data-loss risks enumerated with mitigations (see §4). |
| 7 | **No new exploit developed** | The war room produces research and read-only inspection only — no exploit code, no flash writes (§5). |

The spike **fails** if it ends with "we didn't try the cable" — i.e., missing the
cheap physical-layer experiments — or with an unverified claim presented as fact.

---

## 4. Edge Cases

### Firmware version differences
- Public firmware history runs **1.x → 2.0.6 (exploit patched, Apr 2024) → 3.0/3.0.1 →
  4.0/4.0.1 (cloud streaming beta, Nov 2024) → 5.x → 6.x → 7.0.x → 7.1 (2026)**
  ([xtremeps3 firmware history](https://www.xtremeps3.com/playstation-portal-firmware-history/)).
  The owner's unit is almost certainly on 7.x; **every finding must be tagged with the
  tested firmware version** — behavior on 2.05-era units (pre-patch) does not transfer.
- Sony pushes updates aggressively at setup; assume the Portal will want to update
  the moment it sees Wi-Fi. Spike protocol: record version **before** connecting to
  Wi-Fi, and decide deliberately whether to allow updates.
- Downgrade path: unknown/undocumented; do not assume one exists.

### Sony patches & the moving target
- The Feb 2024 exploit chain (Nguyen/Svensson, Google) was **responsibly disclosed and
  patched in 2.06**; the team stated they would not release it, arguing public release
  would only have bought "a few weeks" ([GameSpot](https://www.gamespot.com/articles/playstation-portal-exploit-that-let-it-run-psp-games-fixed-due-to-hacker-help/1100-6522377/)).
  Treat any "Portal jailbreak" tutorial referencing pre-2.06 firmware as historical.
- Expect server-side gating too: PSN sign-in and update delivery are Sony-controlled;
  client-side findings can be invalidated by a forced update.

### USB-C port limitations
- Officially charging (and the 3.5mm jack covers wired audio); no Sony documentation
  of USB data, MTP, or accessory modes.
- Counter-evidence: Qualcomm EDL over USB was achieved by a third party on Windows 11
  ([bkerler/edl#674](https://github.com/bkerler/edl/issues/674)) — bootloader-level USB
  exists at least in EDL mode. Whether the **application processor's USB stack**
  exposes anything in normal boot is the spike's first experiment.
- Practical gotchas: charge-only cables (use a known data cable), USB-C power
  negotiation quirks, and hubs — test direct MacBook port first.

### Bricking & recovery
- Any flash write (fastboot flash, EDL programmer, OTA interruption) can brick the
  device; Sony offers no public unbrick/flash tool for the Portal.
- EDL experiment risk is real: the public attempt failed at loader upload with USB
  pipe errors — a half-written loader state is a brick vector. **This war room does
  read-only work**; any future write-path work needs a documented recovery plan first.
- Mitigation: full photo/notes baseline of a working unit before any experiment;
  never interrupt an OTA; keep the Portal charged.

### macOS vs Windows/Linux tooling
- **macOS:** no drivers needed for ADB/fastboot (Google platform-tools work over
  standard USB); EDL tooling (`edl` by B. Kerler) is Python + libusb and runs on macOS
  but Qualcomm Sahara/Firehose workflows are far better documented on Windows/Linux.
  Use `system_profiler SPUSBDataType` / `ioreg -p IOUSB` for enumeration checks.
- **Windows:** needs the Google USB driver for ADB and Qualcomm HS-USB drivers for
  EDL (QDLoader 9008); the only public Portal-EDL data point is Windows 11.
- **Linux:** best `udev`/libusb ergonomics for EDL and USB sniffing (`usbmon`,
  Wireshark); recommended if macOS hits a wall on the EDL path.
- Recommendation: start on macOS (owner's machine); escalate specific experiments to
  Linux/Windows only if the macOS USB stack shows nothing.

### Hardware identity confusion (do not get wrong)
- "Portal" also names **Meta Portal** smart displays (Android 9–10, a frequent source
  of "Portal ADB over USB-C" documentation — e.g. community AGENTS.md files). **None
  of that applies to the PlayStation Portal.** The spike must sanity-check every
  source for which "Portal" it means.
- SoC reporting conflicts: teardown reads **Qualcomm SG4150P** ([icon-era](https://icon-era.com/threads/sony-playstation-portal-handheld-teardown-reveals-a-qualcomm-sg4150p-chip-and-16-6-wh-battery.7531/));
  OSS source references **SM6225 = Snapdragon 680** ([wccftech](https://wccftech.com/playstation-portal-os-source-code-cpu/));
  EDL recovery reports codename **"bengal"** (Snapdragon 662 family). Record all three;
  treat the exact SoC as **unresolved** until `adb shell getprop` / EDL HWID says otherwise.

---

## 5. Out of Scope

This spike explicitly will **NOT** cover:

1. **Developing a new exploit from scratch** — no vulnerability research, no exploit
   code, no jailbreak development. Mapping *where* an exploit would be needed is in
   scope; *writing* one is not.
2. **PSN account circumvention** — no bypassing sign-in, entitlement checks, or
   account bans; no credential stuffing, token theft, or account sharing schemes.
3. **Piracy-enabling work** — no game dumping, ISO sourcing, DRM circumvention, or
   instructions facilitating copyright infringement. (Running the owner's own
   homebrew/hello-world code is the legitimate target; emulators are discussed only
   as historical context for what native execution looked like.)
4. **Flash writes / permanent modification** — no `fastboot flash`, no EDL flashing,
   no bootloader unlock attempts, no OTA package forging in this war room. Read-only
   inspection only.
5. **Hardware modification** — no disassembly beyond what's publicly documented, no
   soldering, UART/JTAG probing, or chip-off work.
6. **PS5-side work** — the link under test is Portal↔MacBook directly; Remote Play
   internals and PS5 modification are out of scope.
7. **Releasing or publishing circumvention details** — findings stay in the palace
   (this repo); nothing is published externally from this war room.

### Security / legal blocks the Product Owner will not override

- If an experiment requires violating Sony's ToS in a way that risks the owner's PSN
  account or crosses into CFAA/DMCA anti-circumvention territory (e.g., distributing
  a bypass), it stops at research and is flagged to the owner for an explicit,
  informed decision — the war room does not proceed on implied consent.
- Any step that could brick the owner's only unit without a recovery path requires
  explicit owner approval naming the risk.

---

## Appendix A — Spike experiment backlog (Phase 2 input, not committed)

1. Cable/port control: enumerate a known Android phone on the MacBook; then the Portal.
2. `system_profiler SPUSBDataType` across Portal states (off / booted / recovery / EDL).
3. `adb devices` with platform-tools; document `unauthorized` vs absent.
4. Research recovery-mode entry combo for the Portal; check for ADB sideload menu.
5. Attempt EDL entry (documented button combo per edl issue) — **detection only**,
   no loader upload without owner sign-off.
6. `adb install` hello-world APK; record exact result code.
7. Locate Sony OSS source drop for the closest firmware; extract kernel/board config.
8. Proxy-capture an OTA update (read-only) to document package format.
9. Record firmware + Android/API version; file the version-tagged findings log.

## Appendix B — Sources

- VGC: Google researchers' exploit patched in 2.06 —
  <https://www.videogameschronicle.com/news/hackers-who-got-ps-portal-to-run-psp-games-offline-helped-sony-to-patch-out-the-exploit/>
- 9to5Google: Feb 2024 PPSSPP mod, APK-install block, ~6 GB storage —
  <https://9to5google.com/2024/02/20/sony-playstation-portal-android-psp-mod/>
- GameSpot: exploit disclosure/backlash summary —
  <https://www.gamespot.com/articles/playstation-portal-exploit-that-let-it-run-psp-games-fixed-due-to-hacker-help/1100-6522377/>
- TechSpot: exploit was all-software, Android-based Portal —
  <https://www.techspot.com/news/102503-sony-fixed-security-exploit-turned-ps-portal-psp.html>
- bkerler/edl issue #674: Portal EDL over USB on Windows 11 (bengal codename, Sahara) —
  <https://github.com/bkerler/edl/issues/674>
- IconEra: teardown — Qualcomm SG4150P, Samsung LPDDR4x, 16.6 Wh —
  <https://icon-era.com/threads/sony-playstation-portal-handheld-teardown-reveals-a-qualcomm-sg4150p-chip-and-16-6-wh-battery.7531/>
- WCCFTech: OSS source drop, SM6225/Snapdragon 680 —
  <https://wccftech.com/playstation-portal-os-source-code-cpu/>
- XtremePS3: Portal firmware history (through 7.x) —
  <https://www.xtremeps3.com/playstation-portal-firmware-history/>
- Push Square: hardware review (USB-C described for charging) —
  <https://www.pushsquare.com/features/hardware-review-ps-portal-is-the-perfect-ps5-companion-for-some>
