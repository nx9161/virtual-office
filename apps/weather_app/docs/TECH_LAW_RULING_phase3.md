# Weather App — Global Tech Law Lead Ruling (War Room Phase 3)

**Role:** Global Tech Law Lead, Security & Compliance division · **Date:** 2026-10-06
**Inputs:** PRD v1.0, design-spec v1.0, ARCHITECTURE.md v1.0 incl. §14 (Sloane's Phase 2 rulings — binding)
**Authority:** Privacy review is a War Room gate; Tech Law may BLOCK on compliance grounds.

> ⚖️ This office is not a law firm. Items flagged "REAL COUNSEL" at the end require a licensed attorney; everything else is the office's compliance determination.

---

## VERDICT: **CLEAR WITH CONDITIONS**

Seven binding conditions (C1–C7) below. None is a BLOCK provided all are accepted and scheduled before build sign-off; C1, C2, C3, and C5 must be closed before QA sign-off. Failure to close any condition converts this ruling to BLOCK.

---

## Item-by-item rulings

### 1. GDPR geolocation — consent flow, lawful basis, minimization, storage

**Lawful basis: consent (GDPR Art. 6(1)(a)) — VALID, provided the flow is implemented as specified.**

- **Freely given (Art. 7, Recitals 42–43):** ✓. The app is fully functional without location (US-11 AC3 — all P0 stories pass with permission denied). Declining carries no detriment and no degraded service. Consent is not bundled with terms or made a condition of the app.
- **Specific:** ✓. One stated purpose — "fetch weather for your area" (§5.1 consent sheet). Single-purpose consent; no scope creep.
- **Informed (Art. 4(11), Art. 13):** ✓ *conditionally* — depends on C1 (precision copy) and C2 (BigDataCloud disclosure). The sheet must state: what is accessed (approximate location), why (local weather), precision (~1 km, rounded), memory-only handling, revocability, and the privacy-notice link. All are in the design except the precision figure, which is wrong (see item 2).
- **Unambiguous:** ✓. Affirmative "Allow" tap; no pre-ticked boxes; refusal ("Not now") is equally available and equally easy.
- **Withdrawal as easy as giving (Art. 7(3)):** ✓. Giving = one tap on the welcome/consent sheet; withdrawal = Settings toggle OFF (one tap) plus OS-level revoke. FM-16/§4.3 revocation wipes in-memory coords, deletes stored city, clears device-keyed cache entries (R-13). Withdrawal takes effect immediately (PRD US-3 AC3 test).
- **Two-step structure is correct:** the in-app sheet is the GDPR consent record (persisted `ConsentState` in SharedPreferences); the subsequent OS dialog is a platform permission, not the GDPR legal act. Getting app-level consent *before* the OS prompt is best practice and must be kept (DoD #5).
- **Data minimization (Art. 5(1)(c)):** ✓. 2 decimals (~1.1 km) is adequate, relevant, and limited: rounding happens once at the datasource boundary (ADR-07), the OS precise fix never persists, and Open-Meteo's ~0.1° model grid cannot use finer precision anyway. Full precision would violate minimization; 1 decimal would risk wrong-city/wrong-grid-cell with no privacy gain (city name is persisted regardless). 2 dp is the correct point on the curve.
- **Storage limitation (Art. 5(1)(e)):** ✓ with one addition. Memory-only coordinates with discard after the forecast call, on revocation, and on process death is exemplary — nothing further to minimize. The **city name (+country/admin1)** persisted in SharedPreferences is personal data (see item 4) and needs a defined retention rule: *retained until the user changes the location, clears it, or uses "Delete local data."* State this in the privacy notice (C2) — indefinite silent retention would fail Art. 5(1)(e).

**Ruling: COMPLIANT** (subject to C1, C2, C6).

### 2. Consent copy: "~10 km" vs "~1 km" (R-4)

**Confirmed: the precision statement is legally material and MUST be corrected before build sign-off (C1).**

- A misstated material fact (precision of the location data being processed) means consent is not *informed* — Art. 4(11) fails, and the entire Art. 6(1)(a) basis collapses. This is not a cosmetic copy nit; it is the load-bearing fact of the consent.
- The design spec states "~10 km" in **four** places that must all change: consent sheet body (§5.1 step 2a), consent bullet list (§5.1), Settings "Location precision" row (§3.5: currently "Coarse — ~10 km"), and privacy notice §5.4 (twice). Correct text per R-4: **"~1 km (rounded coordinates)"**.
- Additionally the consent bullet "we never store your precise coordinates — only the nearest city name" is accurate and must be kept verbatim in substance.
- Copy must be final (no `[COPY TBD]`) before QA sign-off per design spec §7.

**Ruling: R-4 CONFIRMED AND ELEVATED — copy correction is a gating condition, not a suggestion.**

### 3. Re-prompt policy: 30-day suppression (in-app decline) vs never-reprompt (OS denial)

**The distinction is COMPLIANT and must be preserved as specified.**

- **In-app decline → 30-day suppression:** Lawful. GDPR does not impose a never-ask-again rule after a declined consent; the EDPB consent guidelines permit re-requesting after a reasonable interval provided each request presents a genuine, unpressured choice. 30 days is a defensible cooling-off period. Conditions: the re-prompt must be the *same* neutral sheet (no dark patterns — no confirm-shaming, no pre-selection, no nagging), and the suppression logic must be implemented and documented (C4). Decline must remain one tap.
- **OS denial → never re-prompt from the app (FM-7):** Correct and required. After OS denial the platform itself governs re-prompting (iOS/Android throttle or block repeat system dialogs); the in-app sheet is moot. The app must offer only "Search for a city" and, for permanently-denied (FM-8/FM-14), the OS settings deep-link. Re-triggering the OS dialog would be both futile and a consent-harassment dark pattern.
- The two paths are legally distinct events (app-level consent decision vs. platform permission state) and correctly receive different treatment.

**Ruling: COMPLIANT** (subject to C4).

### 4. Data mapping — what exists, where it lives, retention

| Data | Location | Retention | Personal data? |
|---|---|---|---|
| Device coordinates (rounded 2 dp) | RAM only (`DevicePosition`, non-serializable type, no `toJson`) | Discarded after forecast call; cleared on revocation, mode-off, process death | **Yes** — location data of an identifiable user (Recital 30; treat as personal data) |
| City name + country/admin1 (device-derived) | SharedPreferences | Until user changes location, clears it, or deletes local data (C6) | **Yes** — conservative classification: location interest linked to a single-user device |
| Search query strings | Transmitted to `geocoding-api.open-meteo.com`; 60 s in-memory per-query cache | In-memory 60 s TTL only; not persisted | Query text — disclose transmission in notice; cap 100 chars (already specified) |
| Recent searches ≤10 (name, admin1, country, coords rounded 2 dp) | Hive `recent_places` | Until "Clear recents" / LRU eviction / "Delete local data" | **Yes** (same reasoning as city name); these are *public place* coords, never device-derived (US-13 AC3 test) |
| Unit system, theme, consent state | SharedPreferences | Durable until changed | Consent state is compliance metadata — keep; units/theme are not personal data |
| Cached forecasts (keyed `lat_2dp,lon_2dp`, `source` flag per R-13) | Hive `forecast_cache`, ≤20 entries | TTLs 10 min / 60 min SWR / 24 h max; device-source entries deleted on revocation | Forecast content is not personal data; keys encode coarse coords of the *requested* place |
| Crash reports (Sentry) | Sentry backend | 90-day default — confirm in project settings (C3) | **Yes** — IP at ingest + device model (see item 5) |

**Is the persisted city name personal data?** The conservative and correct answer is **yes**. A city name alone is public information, but stored on a personal device alongside consent state and app-instance telemetry, it relates to an identifiable natural person (CJEU *Breyer* C-582/14 on relatability). The design already treats it with appropriate safeguards (minimization to name+region+country, user-deletable, revocation-wiped). No design change needed — just the retention statement (C6) and erasure path ("Delete local data" already specified in design §3.5).

**Ruling: MAP APPROVED.** No undisclosed personal-data stores. Add the retention schedule to the privacy notice (C2/C6).

### 5. Sentry — default-on opt-out, DSN region, DPA, IP/device model

- **Default-on with opt-out — DEFENSIBLE but conditional.** Crash reporting is non-essential processing, so the strictest reading of GDPR (and German supervisory practice in particular) prefers opt-in. The office's posture — crash-only config, `tracesSampleRate: 0`, replay/performance off, PII scrubbing on, zero coordinates in payloads (R-2), disclosure in the first-run privacy notice *before the first report* (R-17), and a prominent Settings opt-out that disables the initialized client — satisfies Art. 6(1)(f) legitimate interests (app stability/security, Art. 32) with a documented balancing test, *provided* IP storage is disabled (below). This is the standard posture of EU-shipped crash tooling and I clear it on that basis — but it is the single highest-risk call in this review; see REAL COUNSEL F1.
- **DSN: EU REQUIRED (C3).** Post-*Schrems II*, routing EEA users' crash data (containing IP + device model) to a US Sentry DSN requires SCCs plus a transfer impact assessment. Sentry offers EU data residency — use the **EU DSN** and eliminate the transfer question entirely. ADR-10's "EU DSN option noted" is now a requirement, not an option.
- **Sentry DPA: must be confirmed (C3).** Sentry incorporates a DPA in its terms; the owner must confirm the current DPA is accepted and on file, and record evidence. This is an owner action, not a code action.
- **IP-at-ingest + device model: personal data — YES.** IP addresses are personal data (CJEU *Breyer*); device model combined with IP/app instance is identifying. Mitigations required: enable Sentry's *"Prevent Storing of IP Addresses"* (server-side scrubbing) in project settings, keep `sendDefaultPii` off, and rely on R-2's full coordinate scrubbing (which overrules ARCH §3.2's 40-char query truncation — query strings must be fully redacted via `sanitizeUri()`).
- Release Health (R-17) is crash telemetry, not behavioral analytics — permitted within the crash-only posture.

**Ruling: COMPLIANT WITH C3** (EU DSN + DPA confirmation + IP scrubbing + existing opt-out/disclosure/scrubbing posture). See F1/F2 for counsel flags.

### 6. BigDataCloud fallback — disclosure and consent coverage

- The fallback transmits coarse (2 dp) coordinates to `api.bigdatacloud.net` on a path the user did not explicitly invoke (only when on-device reverse-geocoding fails, FM-17). This is **purpose-compatible** with the original consent (same feature: resolve device location → city name; GDPR purpose limitation, Art. 5(1)(b), satisfied — no new purpose).
- **BUT transparency (Art. 13(1)(e)) requires naming the recipient.** The architecture discloses it ("disclosed in privacy notice," ADR-08, §2 topology), but the design spec's privacy notice §5.4 currently names **only Open-Meteo** ("weather requests go to Open-Meteo"). **C2: the notice must name BigDataCloud as the fallback reverse-geocode recipient, state it receives only coarse rounded coordinates, only when on-device lookup fails, and link its privacy policy.**
- BigDataCloud is US-based: the transfer is of coarse, minimized data with a named-recipient disclosure — acceptable, but it must be transparent (no adequacy decision relied upon; document the transfer in the notice).
- The consent sheet's "Used only to fetch weather" bullet remains accurate; the fallback is an implementation detail of that purpose, properly disclosed one level down in the notice. No separate consent needed. Recommendation (non-blocking): make the fallback observable in code review (single call site, coarse coords only, failure → "Current location" label).

**Ruling: COMPLIANT SUBJECT TO C2.**

### 7. "No backend = not a data controller" — backend reviewer's argument

**CORRECTED. The argument is wrong; the conclusion (no BFF) is right for the wrong reason.**

- **Controller determination (Art. 4(7)) turns on who determines purposes and means — not on where servers sit.** The app's code, written at the owner's direction, decides to obtain the user's coordinates and transmit them to Open-Meteo for weather. **The app owner is therefore the controller of the transmitted coordinates, backend or no backend.**
- Having no backend changes *exposure*, not *status*: no server-side at-rest storage, no server logs of coordinates, no sub-processor chain on our side. That is a genuine privacy win and the correct reason to keep ADR-01 — but it does not make the owner "not a controller."
- **Open-Meteo's role:** with a keyless API and no contract/DPA, Open-Meteo is an **independent controller** of the data it receives, processing under its own privacy policy — not our processor. Consequences: (a) we cannot impose processor terms; (b) transparency is our compliance instrument — the privacy notice must link Open-Meteo's privacy policy (design §5.4 already requires this); (c) our Art. 6 basis (consent) covers *our* transmission; Open-Meteo relies on its own basis for its processing.
- **A BFF proxy** would not make us "a controller" (we already are one) — it would add server-side *processing* of coordinates by us, expanding liability, log-scrubbing duties, and breach-notification surface for zero functional benefit. ADR-01's rejection of the BFF stands, on corrected reasoning.
- **C5:** correct the controller analysis in the architecture's privacy paragraph (§12) or a short ADR addendum, and reflect it in the privacy notice ("controller: [owner entity], contact [email]").

**Ruling: ARGUMENT CORRECTED; ADR-01 UPHELD ON CORRECTED GROUNDS.**

### 8. Privacy notice — mandatory content

The in-app notice (S-4, §5.4) MUST contain these sections/statements (plain language, ≤ grade-8 reading level per design §6; final copy before build sign-off; "Last updated" date stamp):

1. **Who we are:** controller identity ([owner entity]) + contact ([support email] — currently a placeholder; must be filled).
2. **What we collect:** (a) approximate location (coarse, ~1 km, rounded) *only* when you opt in; (b) city/region/country name you choose or we derive; (c) cities you search; (d) preferences (units, theme); (e) crash reports (what they contain, what they don't).
3. **What we NEVER collect/store:** precise GPS coordinates, location history, background location (foreground-only), accounts, advertising identifiers.
4. **Why (purpose) + lawful basis per item:** weather for your area (consent); crash diagnostics (legitimate interests — app stability); preferences (contract/performance of the app's function).
5. **What is transmitted and to whom:** rounded coordinates or city name → **Open-Meteo** (forecast + search; link their privacy policy); coarse coords → **BigDataCloud** (fallback reverse-geocode only, when on-device lookup fails; link policy); crash data → **Sentry (EU region)**.
6. **What stays on your device:** everything else; no account, no sync, no server of ours.
7. **Retention:** coords — memory only, never stored; city/recents/preferences — until you change, clear, or delete them; crash reports — 90 days at Sentry.
8. **Your rights:** access, correction, deletion, withdrawal of consent, objection to crash reporting — all exercisable in-app (Settings → toggles, "Clear recents," "Delete local data") or by contacting us; plus the right to complain to your supervisory authority.
9. **How to revoke location:** in-app toggle (immediate) + OS settings; what happens on revocation (city cleared, coords dropped, cache purged).
10. **No ads, no tracking, no analytics SDKs, no sale of data** — stated explicitly (Priya's persona demands it; CCPA demands it).
11. **Crash reporting disclosure:** that it is on by default, crash-only, how to opt out (Settings) — shown at first run *before* any report (R-17).
12. **Changes to this notice** + version date.

**Ruling: CONTENT SPEC APPROVED — C2 requires the notice be written to this outline.**

### 9. CCPA/CPRA — sale/sharing

**Confirmed negative: no sale, no sharing.**

- **Sale (Cal. Civ. Code §1798.140(ad)):** no personal information is exchanged for monetary or "other valuable consideration." No ads, no analytics SDKs, no data brokers.
- **Sharing (§1798.140(ah)):** no cross-context behavioral advertising; no ad-tech recipients whatsoever.
- **Service providers:** Open-Meteo, BigDataCloud, and Sentry receive limited personal information solely to provide the requested service (weather data, fallback geocoding, crash diagnostics) — classic service-provider processing, not sale/sharing. Document them as such.
- **Sensitive personal information:** CPRA "precise geolocation" means within 1,850 feet; the app transmits only 2-dp rounded coordinates (~1.1 km) — outside the precise-geolocation definition. (The OS supplies a precise fix that is rounded immediately at the datasource boundary and never transmitted or stored — note this in the record.)
- Threshold note: the app as specified is unlikely to trip CCPA applicability thresholds (100k CA consumers/households), but the notice and rights posture above satisfy the requirements regardless. **If the app later adds analytics, ads, or crosses thresholds → full re-review.**

**Ruling: CLEAR. Negative confirmed; re-review trigger recorded.**

### 10. EU AI Act — applicability

**Out of scope — confirmed.**

- The app deploys no AI system: no machine-learning models on-device or server-side, no GPAI model integration, no biometric or emotion-recognition, no automated decision-making, no high-risk use case (Annex III).
- Consuming numerical weather-model *output* via an API is not "deploying an AI system" under the Act (the Act regulates AI systems, not data products that happen to be model-derived).
- **Re-review trigger:** if a future version adds on-device ML (e.g., nowcasting, smart alerts) or LLM features, the AI Act analysis reopens — including GPAI transparency duties if applicable.

**Ruling: NOT APPLICABLE (v1).**

---

## Required remediations (binding conditions)

| # | Condition | Owner | Gate |
|---|---|---|---|
| C1 | Correct "~10 km" → **"~1 km (rounded coordinates)"** in all four design-spec locations: consent sheet body + bullets (§5.1), Settings precision row (§3.5), privacy notice §5.4 (×2). Final copy, no placeholders. | UI/UX Designer | **Pre-build-sign-off** |
| C2 | Privacy notice rewritten to the §8 outline above: add **BigDataCloud** as named fallback recipient (+policy link), retention schedule, rights, revocation effects, crash-reporting disclosure, controller identity + contact, last-updated date. | Product Owner + UI/UX Designer | Pre-QA-sign-off |
| C3 | Sentry: **EU DSN** (not US); confirm **Sentry DPA** accepted and filed (owner action); enable **"Prevent Storing of IP Addresses"**; retain crash-only config, opt-out toggle, first-run disclosure, R-2 zero-coordinate scrubbing. | Lead Mobile/Frontend + owner | Pre-QA-sign-off |
| C4 | 30-day re-prompt: identical neutral sheet, genuine one-tap decline, no dark patterns; suppression logic implemented and code-reviewed; never re-prompt after OS denial (FM-7 stands). | Lead Mobile/Frontend | Build |
| C5 | Correct the controller analysis: owner = **controller** of transmitted coordinates; Open-Meteo = **independent controller**; record in architecture §12/ADR addendum; reflect in privacy notice. | Enterprise Architect | Pre-QA-sign-off |
| C6 | Retention schedule documented (city/recents/prefs until user clears; coords memory-only; Sentry 90 d); "Delete local data" verified as the erasure path. | Lead Mobile/Frontend | Build |
| C7 | DoD privacy gates kept and enforced: automated test — no device coords in persistent storage after a session; automated test — no coords in release logs/Sentry payloads (R-2); manual test — consent sheet precedes OS prompt. | QA Manager | Release |

---

## Flags for REAL COUNSEL (owner action — this office is not a law firm)

- **F1 — Default-on crash reporting in strict jurisdictions.** The legitimate-interests basis for default-on crash reporting is defensible and standard, but German supervisory authorities have taken stricter views of non-essential telemetry. If launch targets Germany/EEA broadly, obtain local counsel's opinion on whether an **EEA opt-in variant** is advisable. Fallback position: ship opt-in for EEA SKUs without re-architecting (the opt-out toggle + R-17 disclosure already exist).
- **F2 — Sentry DPA evidence.** Owner to confirm the current Sentry DPA/data-residency terms are accepted and keep the record (screenshot + date). Required before production traffic.
- **F3 — BigDataCloud terms.** Confirm BigDataCloud's terms permit this use pattern at our volume, and note their US-based processing in the transfer record.
- **F4 — Re-review triggers.** Any of: analytics/ads SDKs, user accounts or sync, a backend/BFF, AI/ML features, crossing CCPA thresholds, or processing children's data → return to Tech Law before build.

---

*End of ruling — Global Tech Law Lead, War Room Phase 3. Verdict: **CLEAR WITH CONDITIONS** (C1–C7).*
