# CHALLENGER NOTE — AppSec Lead security review (Phase 3 war room)

**Role:** AppSec Lead · **Date:** 2026-10-06 · **Authority:** assume breach; no feature ships with a known unmitigated high/critical finding; can BLOCK on security grounds.
**Target:** `investigation.md` (Enterprise Architect), `challenge-backend.md` (Backend challenger), `challenge-devops.md` (DevOps challenger, incl. experiment checklist E1–E5), `prd.md` v2.
**Scope:** war-room research spike only — NO production code, NO exploit development, nothing executed against the device in this war room.

---

## Verdict up front

- **Experiments E1–E5: NO-BLOCK (cleared)** — with conditions in §1. The DevOps "zero brick risk" claim is **CONFIRMED as negligible-and-evidence-backed, CORRECTED as not an absolute guarantee** (see §1.2). A hard DO-NOT-RUN list stands in §1.3.
- **Mission paths P1–P3: no independent AppSec block needed** — the mission is already technically BLOCKED (Phase 2 + both challengers), and no AppSec finding changes that. Hypothetical risk profiles are in §2 for the record.
- **Standing conditional block (new):** if any new public method ever appears (exploit, unlock tool, sideload path, "Portal jailbreak" download), it is **BLOCKED by default until AppSec reviews** source provenance, credential handling, flash/write risk, and PSN-account impact. The DO-NOT-RUN list (§1.3) is a permanent standing rule. Rationale and triggers in §5.

---

## 1. Audit of the DevOps experiment checklist (E1–E5)

### 1.1 Per-experiment verdict table

| ID | Experiment | Host command(s) | Read-only? | Brick risk | Data-loss risk | Account risk | AppSec verdict |
|---|---|---|---|---|---|---|---|
| E1 | Record firmware via Settings | none (device UI read) | Yes | **None** | None | None | CLEAR |
| E2 | USB enumeration, booted | `system_profiler SPUSBDataType` | Yes — host-side USB tree read; device only answers standard enumeration | **None** | None | None | CLEAR |
| E3 | ADB probe, booted | `adb devices` | Yes — host sends USB probe; per evidence no ADB daemon exists to answer it | **None** | None | None | CLEAR |
| E4 | Fastboot probe | `fastboot devices`; `fastboot getvar all`; `fastboot oem unlock` (expected: rejected); `fastboot reboot` | Reads + one refused command + one normal reboot | **Negligible** (see §1.2) | None | None | CLEAR with conditions |
| E5 | Powered-off enumeration | `system_profiler SPUSBDataType` | Yes | **None** | None | None | CLEAR |

**No experiment touches the PSN account, sends credentials, or writes device state.** There is no exfiltration surface: the outputs are a firmware string, a USB device list, and fastboot refusal messages.

### 1.2 CONFIRM / CORRECT on the "zero brick risk" claim

**CONFIRMED in substance, CORRECTED in framing.**

The DevOps note says E1–E5 carry "zero brick risk" and that "the device rejects every state-changing command." The evidence supports this *as far as it goes*:

- The only direct test of the Portal's fastboot command surface is the Feb 2024 XDA community test: `oem unlock` → `FAILED (remote: 'unknown command')`; `flash` → unknown command; `boot` → unknown command; `reboot recovery` → `not allowed in user software`; `getvar:cid` → `oem auth failed`. The tester ran the full battery with no effect on the device.
- `fastboot reboot` is a routine reboot the device performs daily; it cannot trip verified boot.

**The correction (AppSec posture — never trust the device to be your safety control):**

1. "Zero" is an absolute the evidence cannot carry. The refusal behavior rests on **one 2024 community test**, not a Sony specification, and the bootloader has received ~2.5 years of firmware updates since. The honest rating is **negligible, evidence-backed** — not mathematically zero.
2. **E4 contains one command whose hypothetical success would be destructive: `fastboot oem unlock`.** On many Android devices, an unlock-capable bootloader responds to an unlock command with a factory reset (userdata wipe). The Portal answers "unknown command" per the XDA test — but that is the *device's* refusal, and AppSec does not rely on it as the control. The control is the owner **running the commands one at a time, comparing each output to the expected refusal string, and stopping at the first deviation** before issuing the next.
3. **Deviation rule (make this part of the checklist):** if any command returns anything other than `FAILED (remote: 'unknown command')` / `FAILED (remote: 'not allowed in user software')` / `FAILED (remote: 'oem auth failed')` / `OKAY` for `reboot` — **stop immediately, photograph/log the output, and report to the war room before proceeding.** A changed bootloader surface is itself a finding.

With that deviation rule in place, E4's residual risk is accepted and the checklist is cleared.

### 1.3 DO-NOT-RUN list — commands the owner must never run, and what would happen

The DevOps note flags `flashing unlock`, `erase`, `flash` as excluded. AppSec makes this list explicit and complete. **None of these appear in E1–E5; running any of them is out of scope and prohibited:**

| Forbidden command | Expected per evidence (rejected) | What would happen if it ever succeeded |
|---|---|---|
| `fastboot flashing unlock` / `flashing unlock_critical` | `unknown command` (by analogy with `oem unlock`; not directly tested) | **Bootloader unlock → immediate factory reset (total data wipe)** on most Android bootloaders; verified-boot state changes; warranty voided; no way back — Sony publishes no relock/restore image |
| `fastboot erase <partition>` (any) | `unknown command` (XDA battery covered `flash`/`boot`; `erase` untested but same surface) | **Destruction of the named partition** — erasing `boot`, `system`, or `avb` = soft/hard brick |
| `fastboot flash <partition> <image>` | `unknown command` | **The highest brick risk in this space:** flashing a wrong, corrupt, or malicious image (wrong SoC programmer, mismatched partition layout) = hard brick. **There is no recovery path:** Sony publishes no Portal recovery PUP, no EDL procedure, no firehose loader, no test-point guides (per Backend challenger N4). A bad flash is a dead device. |
| `fastboot boot <image>` | `unknown command` | Booting an unsigned image = exploit-development territory (explicitly out of scope per PRD §5) + verified-boot trip |
| `fastboot --set-active=<slot>` | untested | Could switch to an unbootable/incomplete slot → bootloop |
| Any `fastboot oem <anything>` beyond the listed probe | untested | Unknown vendor commands are the classic brick vector on locked Qualcomm bootloaders — **do not fuzz** |
| Forcing EDL/9008 mode (key combos, cable tricks) | no known procedure exists | Pointless without a loader; and per PRD constraints, any hardware-adjacent entry (test points, disassembly) is forbidden |
| Factory reset of the Portal (Settings) | — | Per TheFloW's documented advice: **factory reset forces a firmware update.** On a ≤2.05 unit this destroys the firmware position permanently; on any unit it wipes all device data (Wi-Fi credentials, settings). Never reset as an "experiment." |

**Bottom line for §1:** the checklist as written stays inside the refusal surface of a locked bootloader and is safe to run tonight. The danger is not in E1–E5 — it is in the owner improvising beyond them.

---

## 2. Hypothetical risk profiles for P1–P3 (recorded for a future re-evaluation)

All three paths are technically BLOCKED; this section exists so a future spike inherits the risk analysis instead of re-deriving it.

### P1 — Sideload vector, hypothetically working

| Risk | Rating | Notes |
|---|---|---|
| Brick | **Low** | User-space APK installs don't touch partitions; worst realistic case is a bootlooping app, fixable by uninstall/factory reset. (Caveat: factory reset forces firmware update — §1.3.) |
| Data loss | **Low** | App-scoped; device data intact. |
| Account risk | **Medium** | Installing unsigned/modified software on a PSN-linked device is a **PSN Terms-of-Service violation**; Sony has banned accounts/consoles for less on other platforms. **The owner's PSN account — with its purchased games — is the highest-value asset in this threat model.** Any future method must be weighed against it. |
| Malware | **Medium** | The install vector itself becomes the supply chain: whatever APK/tool the owner downloads to exploit it must be treated as untrusted until verified (§3). |

Additional: warranty void on any modification; Sony's ~monthly update cadence would likely re-break the vector quickly, stranding the owner on an old firmware with degraded online features.

### P2 — Firmware-dependent path (≤2.05 unit / downgrade), hypothetically working

| Risk | Rating | Notes |
|---|---|---|
| Brick | **High** | Downgrade attempts against verified boot / anti-rollback are the classic soft-brick (bootloop) vector; a wrong image flashed in this space = hard brick with **no recovery image** (§1.3). |
| Data loss | **High** | Downgrade/unlock procedures wipe userdata by design; TheFloW's documented warning — *do not factory reset or it force-updates* — means one wrong tap destroys the ≤2.05 position irreversibly. |
| Account risk | **Low–Medium** | Downgrade alone rarely triggers bans, but a unit pinned to old firmware degrades to offline-only for Remote Play/cloud — the practical enforcement mechanism (per DevOps §6.3). |

Note: per both challengers, even a preserved ≤2.05 unit has **no public working implementation** — the risk profile above applies to any hypothetical future tool, and that tool's provenance would itself need AppSec review (§5).

### P3 — Any other credible software-only path (none found)

No path, no profile. If the one known missed surface — the **hidden legal-docs WebView** (Backend challenger N1/D1) — were ever publicly weaponized, the AppSec pre-assessment would be: **credential-phishing risk first** (a WebView that renders remote content is a login-form spoofing surface), RCE second. Weaponizing it = exploit development = out of scope per PRD §5, so this stays a watching brief, not an action item.

---

## 3. Supply-chain hygiene (conditional — applies if the owner ever runs device tools)

The mission's toolset is open-source code from GitHub (platform-tools, EDL clients, future utilities). The mission is blocked, so this is **standing guidance for any future re-evaluation**, not tonight's work:

1. **Official sources only.** `android-platform-tools` via Homebrew (hash-pinned casks) or direct from Google (`developer.android.com` / `dl.google.com`, verifying Google's published SHA-256). `bkerler/edl` from the upstream repo only — never a fork's "releases" binary.
2. **Pin and verify.** Pin release tags or commit hashes; verify GPG/cosign signatures and checksums where the project publishes them. A release artifact that doesn't match its published hash is hostile until proven otherwise.
3. **Privilege discipline.** EDL-class tools typically need raw USB access (often `sudo`). **Running unverified code as root is the highest-privilege supply-chain exposure in this mission.** Read the code (or at minimum the install script and USB-access scope) before elevating; prefer a Python venv over system-wide `pip install`.
4. **No typosquats, no `curl | sudo bash`.** Check package/repo names character-for-character; never pipe a remote script into a privileged shell.
5. **The void is a scam magnet — the most likely security event for this mission.** No public Portal jailbreak exists for firmware 7.x (verified 2026-10-06). Therefore **any site, video, or download claiming a current-firmware Portal jailbreak/unlock tool in 2026 is fraudulent until proven otherwise.** Fake "unlock tools" are a classic malware-delivery pattern (info-stealers, credential harvesters, survey-gated binaries). The owner should treat unsolicited "Portal unlock" downloads as hostile and report them to the war room rather than running them. This warning outranks all other supply-chain notes in practical importance.

---

## 4. Threat model: the "closest alternatives" (brief)

These are legitimate-use alternatives, not attack paths. Notes are proportional to actual risk:

- **xbox.com/play in a real browser (MacBook/phone/Steam Deck Chromium).** Legitimate Microsoft service. Threat model is standard web hygiene: type the URL or use a bookmark (no search-result roulette — phishing clones of login pages exist for every major gaming service), confirm the TLS domain is `xbox.com` / `microsoft.com` at sign-in, sign in only on the genuine Microsoft login flow. Credential risk: **low** when done this way. No new device or account exposure beyond normal Game Pass use.
- **Third-party Xbox wrappers (e.g., open-source WebView apps like Mac-XCloud).** Functionally they render xbox.com/play in an embedded browser — credentials still go to Microsoft, but **the app binary sits between the keyboard and the login form** and can in principle intercept keystrokes, cookies, or session tokens. Trust decision = repo provenance + building from source + maintainer history. **AppSec recommendation: use an official browser (Edge/Chrome/Safari), not a wrapper, for Microsoft sign-in.**
- **PS Plus Premium cloud streaming — on the Portal itself.** First-party Sony service over the stock OS. No new attack surface, no new credential handling, no ToS exposure. **Lowest-risk alternative; the security posture is identical to normal Portal use.**
- **chiaki-ng (open-source PS Remote Play client) on Steam Deck/PC.** Runs on the owner's *other* devices, not the Portal — correctly scoped as a PS5-streaming redirect, not an Xbox path. Credential handling is the item to watch: Chiaki's PSN linkage has historically required the user's PSN credentials/account token through a third-party helper to obtain the account ID. **Threat: credential exposure to third-party code.** Mitigations: read the helper script before running it; confirm exactly what is sent where; keep PSN 2FA enabled; consider a dedicated PSN sub-account if the tool's trust level is unclear; do not port-forward the PS5 to the internet for remote Chiaki use (that exposes the console's Remote Play surface to the open internet — keep it LAN or VPN-only).
- **Sideloading APKs from random GitHub repos (general guidance, for other devices).** Moot for the Portal (no install path), but standing guidance: an APK from an unknown maintainer is untrusted code running alongside your logged-in accounts. Check: repo history and maintainer identity, whether binaries are built by public CI from the published source (reproducible provenance), requested Android permissions vs. claimed function, and community reputation. A "game streaming client" asking for SMS/contacts/accessibility permissions is a red flag.

---

## 5. Decision: BLOCK / NO-BLOCK, with rationale

**Decision:**

1. **E1–E5 experiments: NO-BLOCK — CLEARED**, subject to the deviation rule in §1.2 (stop-and-report on any output that doesn't match the expected refusal strings) and the permanent DO-NOT-RUN list in §1.3. Rationale: all five are read-only or refused-by-device; no credentials, no PSN interaction, no state change; brick risk is negligible and evidence-backed (Feb 2024 XDA test); data-loss and account risk are nil.
2. **No independent AppSec BLOCK on the mission.** The mission is already technically BLOCKED (Phase 2 verdict, sustained by both challengers). There is no unmitigated high/critical security finding that adds a block on top of the technical one — the dangerous actions (flashing, unlocking, EDL, exploit tooling) are already out of scope via the PRD's hard constraints, and the experiments stay clear of them.
3. **Standing conditional BLOCK (new, persists beyond this war room):** any *future* public method — new exploit, unlock tool, sideload path, or downloadable "Portal jailbreak" — is **BLOCKED by default until AppSec reviews**: (a) source provenance and supply-chain integrity (§3), (b) credential/PSN-account handling, (c) flash/write/brick risk (§2 profiles), and (d) PSN ToS/account-ban exposure for the owner's account. The §1.3 DO-NOT-RUN list is permanent and needs no re-authorization to enforce.

**Rationale (against the role brief):** "No feature ships with a known unmitigated high/critical finding" — nothing ships here at all; the deliverable is a negative result plus a read-only checklist, and the checklist's risks are mitigated to negligible with documented evidence and a deviation stop-rule. AppSec's value-add is therefore preventive: the explicit forbidden-command inventory, the scam-magnet warning (§3.5 — the most probable real-world security incident for this mission profile), and the conditional block that prevents a future "it works now, run it tonight" moment from skipping security review.

**Re-evaluation triggers** (AppSec concurs with the challengers, plus one): a new public Portal exploit; Sony opening a sideload/browser path; public weaponization of the hidden WebView; **or** any download claiming to unlock/jailbreak the Portal appearing in the owner's path (treat as hostile per §3.5, report, do not run).

---

*End of AppSec review. File: `challenge-appsec.md`.*
