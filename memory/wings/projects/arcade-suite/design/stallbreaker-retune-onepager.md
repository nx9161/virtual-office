# STALLBREAKER Track B — Design One-Pager

- **Date:** 2026-10-07
- **Status:** **PENDING PRODUCER SIGN-OFF — DO NOT IMPLEMENT THE RETUNE YET**
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
- Shove speed: 470 → **420 px/s**, deceleration `pow(0.02, dt)`
- **25° aim-assist cone** on shove targeting
- Stall trigger at **r+24**
- Shove cooldown: 7s → **4s**
- **NO silent mid-run reshuffles of tuning constants.** Once the run starts, constants are
  frozen; retune values apply between runs only.

## Takedown feedback stack (design-level)

1. **Telegraphed windup** — readable anticipation signal before the hit lands.
2. **Commit flash** — 90ms pre-hit flash marking the point of no return.
3. **Impact feedback** — distinct confirm on landing (visual/audio kick, no code specified
   here; exact feel to be prototyped at implementation).

## Hearts legibility spec

- Hearts displayed **top-right**
- **2x scale**
- White-stroke, high-contrast fill
- **200ms damage pulse** on hit
- **"GRIT −1" edge-flash** on damage
- **Screenshot proof required at native resolution before sign-off.**

## Calm mode spec

- Banner: **"CALM — practice, no damage"**
- Ambient pedestrians (non-threatening; **no parked combat-looking thugs**)
- **SAFE-tagged hearts**
- **CALM chip indicator** visible during play

## Intended Ember median survival target

> **TBD — to be set by Game Producer at sign-off; prior floor was 6–17s on 'gentle' Ember.**
> No target number is locked in this document.

## Sign-off gate

**Retune pass 1 requires Producer sign-off before any implementation.** This document is
the design record; the first code change may only land after the Game Producer has signed
off on the numbers above (and set the TBD survival target).
