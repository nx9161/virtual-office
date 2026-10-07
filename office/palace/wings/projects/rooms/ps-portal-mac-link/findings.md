# findings.md — Phase 4: Findings & Recommendation

**War room:** ps-portal-mac-link · **Date:** 2026-10-06
**Mission:** Software-only repurposing of the PlayStation Portal into an Xbox handheld (Xbox Cloud Gaming), programmed from the MacBook via USB-C, using open-source software. Constraints: no hw mods, no paid tools, no special hardware.

---

## Verdict

**BLOCKED — not currently achievable.** No software-only path exists on current firmware (7.1.7, Sept 2026). This is a well-evidenced negative, not a lack of effort: one real exploit chain ever (patched, unreleased), a locked bootloader, an OS with no ADB/browser/dev surface, and 2.5 years of scene silence.

## Ranked options

| Rank | Option | Verdict | One-line rationale |
|------|--------|---------|-------------------|
| 1 | **Verify-then-redirect (RECOMMENDED)** | ✅ Viable tonight | Run read-only experiments E1–E5 to confirm the verdict on your own unit (30–45 min, negligible risk), then play Xbox via xbox.com/play on your MacBook/phone tonight |
| 2 | P1 — Sideload Xbox client via any install vector | ❌ BLOCKED (technical) + Tech Law conditional block | No install vector exists: no ADB, no browser, no dev options, locked bootloader, USB-C dead in OS |
| 3 | P2 — Downgrade to ≤2.05, reuse 2024 chain | ❌ BLOCKED (technical) + Tech Law conditional block | No public working implementation even on ≤2.05 (partial PoC only); no public downgrade; reconstructing = exploit dev (out of scope) |
| 4 | P3 — Other software-only paths (WebView, QR flow, etc.) | ❌ NONE FOUND | Hidden WebView exists but is restricted and weaponizing it = exploit dev; all other surfaces exhausted |
| 5 | P4a — PS Plus Premium cloud streaming on the Portal | ✅ Viable tonight (PlayStation games, not Xbox) | Official Sony path since Nov 2025: 2,800+ games, 1080p, no PS5 needed — the Portal's legitimate "handheld cloud" mode |
| 6 | P4b — Buy a cloud handheld (ROG Xbox Ally, G Cloud) | ⚠️ Real but a purchase | Outside mission constraints; noted for completeness |

## Recommended path: verify-then-redirect

**Why it wins:** it's the only option that is (a) fully inside the owner's constraints, (b) AppSec-cleared, (c) executable tonight, and (d) converts a "trust us, it's blocked" into first-hand verified knowledge plus an actually-playable Xbox session.

### First 3 concrete steps for the owner (tonight, MacBook only)

**Step 1 — Confirm your firmware (2 min, zero risk).**
On the Portal: Settings → System → System Software. Record the version (expect 7.1.7 or newer). If it's somehow ≤2.05, stop and tell the office before doing anything — the re-evaluation path changes.

**Step 2 — Prove the USB-C reality to yourself (30–40 min, read-only, negligible risk).**
On the MacBook:
```bash
brew install android-platform-tools
# Portal booted, plugged in:
system_profiler SPUSBDataType   # expect: charging only, no data node
adb devices                      # expect: empty list (no ADB daemon)
# Portal powered OFF, plugged in, hold Power+VolDown → fastboot:
fastboot devices                 # expect: device listed (data lines ARE live here)
fastboot getvar all              # expect: failures / 'oem auth failed'
fastboot oem unlock              # expect: FAILED (remote: 'unknown command')
fastboot reboot                  # expect: OKAY — safe reboot back to normal
system_profiler SPUSBDataType   # powered off: expect nothing
```
Rules: run one command at a time; compare each output to the expected refusal strings; **stop and report** on any deviation. **NEVER run:** `flashing unlock`, `erase`, `flash`, `fastboot boot`, EDL forcing, or factory reset (forces a firmware update). Use a data-capable USB-C cable, not a charge-only one.

**Step 3 — Play Xbox tonight (15 min, zero cost).**
Open **xbox.com/play** in Edge/Chrome/Safari on your MacBook or phone, sign in with your Microsoft account (Game Pass Ultimate required for cloud gaming), pair your controller, play. Optionally: on the Portal itself, try **PS Plus Premium cloud streaming** — the legitimate handheld-cloud experience Sony actually ships.

### What NOT to do
- Do not download any 2026 "PS Portal unlock/jailbreak tool" — the exploit void is a scam magnet; no public 7.x jailbreak exists, so such downloads are fraudulent until proven otherwise (treat as hostile, report don't run).
- Do not attempt bootloader unlocks, flashing, or EDL procedures found online — no public recovery path exists for this device; a bad flash is a dead Portal.

## Re-evaluation triggers
Re-run this spike if: a new public Portal exploit is published · Sony opens a sideload/browser path · the hidden WebView attack surface changes · any "Portal jailbreak" appears in your path (hostile until verified). This room is the baseline.

## Record locations
- PRD v2: `prd.md` · Investigation: `investigation.md` · Challenges: `challenge-backend.md`, `challenge-devops.md`, `challenge-appsec.md`, `challenge-techlaw.md`
- Halls: `halls/facts.md`, `halls/decisions.md`, `halls/events.md`
