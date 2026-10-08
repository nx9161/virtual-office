# STALLBREAKER Track B — Design One-Pager

- **Date:** 2026-10-07
- **Status:** **PENDING PRODUCER SIGN-OFF — REVISION 2**
- **Owner:** Gameplay Designer seat
- **Design lock only.** No game code or template code was touched by this document.

## Ember difficulty targets

| Parameter | Before | After |
|-----------|--------|-------|
| Windup telegraph | 0.65s | **0.75s**, plus a **90ms pre-hit commit flash** |
| Knockback | 260 px/s | **140 px/s** |
| Invulnerability | — | **1.2s with blink** |
| Spawn interval (`spawnEvery`) | 3.2s | **4.5s** |
| First spawn | — | **+2.5s delay** on first spawn |

## Shove / takedown geometry fix

- Shove flight time: 0.5s → **0.9s**
- Shove speed: 470 → **420 px/s**, deceleration `pow(0.001, dt)` → `pow(0.02, dt)`
  (**~180–220px intended travel**)
- **25° aim-assist cone** on shove targeting
- Stall trigger at **r+24**
- Shove cooldown: 7s → **4s**
- **NO silent mid-run reshuffles of tuning constants.** Once the run starts, constants are
  frozen; retune values apply between runs only.

## Takedown feedback stack (AS-42-converged, design-level)

1. **Telegraphed windup** — readable anticipation signal before the hit lands.
2. **Commit flash** — 90ms pre-hit flash marking the point of no return.
3. **Hit-stop** — 120ms game-sim freeze on takedown landing (accept: sim
   halts exactly 120ms while particles continue; must be perceptible, not
   janky).
4. **Shake** — screen shake at **6px amplitude**, ~200ms exponential decay
   (accept: displacement never exceeds 6px; settles to zero within 250ms).
5. **2x lingering "TAKEDOWN" pop** — text pop at **2x UI scale**, dwelling
   **900ms** before fade-out (accept: pop reads clearly at 2x, fully faded
   by 1.2s).
6. **One-time first-takedown tutorial banner** — exact trigger: fires once
   per session on the **first landed takedown**; dismisses on any key press
   or after 3s, never shows again that session (accept: exactly one showing
   per session, only after a real takedown event).

## Hearts legibility spec

- Hearts displayed **top-right**
- **2x scale minimum**
- White-stroke, high-contrast fill
- **200ms damage pulse** on hit
- **"GRIT −1" edge-flash** on damage
- **Screenshot proof required at native resolution before sign-off.**

## Calm mode spec

- Banner: **"CALM — practice, no damage"**
- Ambient pedestrians (non-threatening; **no parked combat-looking thugs**)
- **Stall glow** — ambient stalls render with a soft glow so they read as
  practice props/scenery, not threats
- **SAFE-tagged hearts**
- **CALM chip indicator** visible during play

## Intended Ember median survival target

> **Locked: 45s median survival on Ember** (quantitative acceptance measure
> for "Ember reads as gentle").
> Gameplay reasoning: a gentle mode must sustain roughly a minute of play
> before median death — 45s beats the observed 6–17s floor ~3× while still
> keeping death a live possibility, so Ember reads forgiving without
> reading trivial. Producer may accept or reject the number, not set it.

## Sign-off gate

**Retune pass 1 requires Producer sign-off before any implementation.** This document is
the design record; the first code change may only land after the Game Producer has signed
off on the numbers above. Retune bound: retune bounded at 3 passes; escalation to Sloane beyond that.
