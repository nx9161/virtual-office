# facts.md — ps-portal-mac-link

Non-negotiable truths for this room: constraints, dependencies, key
technical facts. Edit when the truth changes; never duplicate guesses.

| Fact | Source / Date |
|------|---------------|
| Mission verdict: **BLOCKED — not currently achievable.** No software-only path exists to turn a PlayStation Portal into an Xbox handheld on current firmware. | War room Phase 2+challengers, 2026-10-06 |
| Portal runs heavily modified **Android 13** on **Snapdragon 680** (best current answer; early press cited SD662/SG4150P — 680 evidence from Sony OSS drop + LPDDR4X is stronger) | investigation.md §1.1; challenge-backend (agreed) |
| Stock OS: slim settings only — **no developer options, no secret menu, no usable browser** (a hidden restricted WebView exists via Settings → legal notices → "other documents"; no address bar; not an install vector) | investigation.md §1.2; challenge-backend D1/N1 (correction) |
| **No Bluetooth hardware** — even an installed Xbox client could not pair an external Xbox controller | investigation.md §1.2 (TechSpot/IGN specs) |
| USB-C in booted OS: **charging-only** — no ADB/MTP/accessories (tested) | investigation.md §1.3 (Digital Trends; ResetEra) |
| USB-C data lines exist at bootloader level: Power+VolDown boots **locked fastboot** enumerating over USB; `oem unlock`/`flash`/`boot`/`recovery` all rejected; `getvar` fails auth | investigation.md §1.3 (XDA, Feb 2024) |
| **No ADB daemon** in the booted OS on any firmware (confirmed by 2.5 years of scene absence) | investigation.md §1.3 |
| **Only public exploit chain ever** (TheFloW+xyz+ZetaTwo, Feb 2024: HEVC-decoder RCE + CVE-2023-33106 privesc, ran PPSSPP) was **PATCHED in firmware 2.06 (Apr 2024)** via responsible disclosure and **never released** as a usable tool (partial PoC only) | investigation.md §2.1 (wololo.net) |
| **Nothing replaced it 2024–2026**: wololo Portal archive ends Jun 2024; zero Portal jailbreak/sideload repos on GitHub; r/PlaystationPortal scene ceiling is a PS5-side bitrate tool | investigation.md §2.2; challenge-backend N3 (gh search) |
| **No community project** puts Xbox Cloud Gaming / a browser / any Xbox client on the Portal | investigation.md §3 |
| Current firmware **7.1.7** (2026-09-24); Sony ships ~monthly updates — any pinned procedure rots within weeks | investigation.md §1.4; challenge-devops |
| Downgrade: **no public method** — no Sony recovery image, fastboot flashing blocked; "forces latest firmware on boot" is a single 2024 community report (overstated; factory-reset forces update per TheFloW; router-level update blocking documented 2026) | investigation.md §1.4; challenge-backend D2; challenge-devops D2 |
| TheFloW announced **leaving the PlayStation scene** (Sept 2026) after his PS5 hypervisor vuln leaked to Sony | challenge-backend N2 |
| Owner hard constraints: software-only; no hw mods; no programmer/flasher; no soldering; no paid tools; no special hardware purchases; Portal + MacBook + USB-C + public code | PRD v2 §constraints; owner redirect 2026-10-06 |
| **AppSec: NO-BLOCK on read-only experiments E1–E5** (negligible brick risk, evidence-backed); **standing conditional BLOCK** on any future method until reviewed; DO-NOT-RUN list is permanent (`flashing unlock`, `erase`/`flash`, `fastboot boot`, EDL forcing, factory reset) | challenge-appsec.md |
| **Tech Law: CONDITIONAL BLOCK on P1+P2** as compliance policy — defeating TPMs (locked bootloader, verified boot, APK-install prevention) = act of circumvention under DMCA §1201(a)(1); Copyright Office repeatedly denied console jailbreak exemptions (2012/2015/2018; none 2024); Sony ToS §24.6/24.8 + EULA ban it, reserve console/account suspension; Sony enforcement history: Filipiak, Divineo, Hotz | challenge-techlaw.md |
| Sony warranty post-2018 is causation-based; a modified/bricked unit should be assumed warranty-denied in practice | challenge-techlaw.md |
| Exploit void = scam magnet: any 2026 "Portal unlock tool" download is fraudulent until proven otherwise (info-stealer pattern); treat as hostile | challenge-appsec.md |
| Hugging Face is irrelevant to this mission (hosts ML models, not device firmware) | Owner redirect; PRD v2 §out-of-scope |
| Honest alternatives that work tonight: (1) xbox.com/play on owner's existing MacBook/phone — zero cost; (2) PS Plus Premium cloud streaming on the Portal itself (Sony content, 1080p) | challenge-devops (ranked alternatives) |
| Re-evaluation triggers: new public Portal exploit; Sony opening a sideload/browser path; hidden-WebView weaponization; any "Portal jailbreak" download appearing (treat as hostile) | challenge-appsec.md; challenge-devops |
