# Weather App — Interaction & Design Specification
**Division:** Product & UX · **Author:** UI/UX Designer · **Reports to:** Sloane
**Version:** 1.0 · **Date:** 2026-10-06
**Scope:** Production-grade Flutter app, Android + iOS, Open-Meteo API (no key), live telemetry + GDPR-compliant geolocation.

---

## 1. Design Principles

1. **Glanceable first** — current conditions readable in <2 seconds; details one level down.
2. **Honest data** — every number carries provenance (source + "updated Xm ago"); never show stale data as live.
3. **Consent before convenience** — location is opt-in with coarse precision, always reversible.
4. **Every screen, every state** — loading, empty, error, and offline are designed screens, not afterthoughts.
5. **System over style** — one token set drives both platforms; no hardcoded values outside tokens.

---

## 2. Design Tokens

### 2.1 Color palette (light + dark)

| Token | Light mode | Dark mode | Use |
|---|---|---|---|
| `surface-primary` | #FFFFFF | #0D1420 | App background |
| `surface-secondary` | #F2F5F9 | #16202F | Cards, sheets |
| `surface-tertiary` | #E8EDF4 | #1F2B3D | Chips, dividers |
| `text-primary` | #101828 | #F5F8FC | Headlines, body |
| `text-secondary` | #475467 | #A8B4C6 | Subtitles, metadata |
| `text-tertiary` | #667085 | #7B8BA1 | Hints, timestamps |
| `accent-primary` | #0E6FF2 | #5EA3FF | CTAs, links, selected state |
| `accent-primary-pressed` | #0B5BCC | #4C8BE0 | Pressed CTAs |
| `accent-on-accent` | #FFFFFF | #06203F | Text on accent buttons |
| `success` | #12805C | #3FBF8F | Live data freshness, consent on |
| `warning` | #B54708 | #F5A524 | Stale data, degraded precision |
| `error` | #B42318 | #F97066 | API errors, blocking issues |
| `error-surface` | #FDECEC | #2A1518 | Error banners/cards |
| `focus-ring` | #0E6FF2 @ 3px offset | #5EA3FF @ 3px offset | Keyboard/talkback focus |
| `scrim` | rgba(16,24,40,.5) | rgba(0,0,0,.65) | Sheet/dialog background |

**Sky-tint gradients (decorative only, never carry meaning):** clear-day `#2E90FA→#0E6FF2`, night `#1D2939→#0D1420`, rain `#475467→#1D2939`, snow `#D0D5DD→#98A2B3`, storm `#6941C6→#1D2939`. Contrast of overlaid text is verified against the darkest stop (min 4.5:1).

**Contrast budget:** `text-primary` on `surface-primary` ≥ 15:1 both modes. `text-secondary` ≥ 7:1. `text-tertiary` ≥ 4.6:1. `accent-on-accent` on `accent-primary` ≥ 4.5:1 both modes (dark: #06203F on #5EA3FF ≈ 7.2:1).

### 2.2 Typography scale

| Style | Size / Weight / Line-height | Use |
|---|---|---|
| `display-xl` | 64 / 600 / 72 | Hero temperature |
| `display-l` | 48 / 600 / 56 | Hero temperature (small screens) |
| `heading-l` | 24 / 700 / 32 | Screen titles, section headers |
| `heading-m` | 20 / 600 / 28 | Card titles, dialog titles |
| `heading-s` | 16 / 600 / 24 | List item titles |
| `body-l` | 16 / 400 / 24 | Primary reading |
| `body-m` | 14 / 400 / 20 | Secondary reading, list metadata |
| `body-s` | 12 / 400 / 16 | Timestamps, captions, provenance |
| `label-m` | 14 / 600 / 20 | Buttons, chips, tabs |
| `label-s` | 12 / 600 / 16 | Badges, overline labels |

Platform fonts: system default (San Francisco / Roboto). Numeric values in temperature use tabular figures (`font-variant-numeric: tabular-nums`) so digits don't jitter on refresh.

### 2.3 Spacing & shape

- Base unit 4pt; spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64.
- Screen side margin: 16 (phone), 24 (tablet ≥600dp).
- Cards: 16pt radius, 1pt border `surface-tertiary`, elevation 1dp (light) / 0dp + border (dark).
- Buttons: 12pt radius, min height 48pt; chips 32pt height, pill radius.
- Touch targets: **min 48×48pt** everywhere, no exceptions.
- Max content width 720dp centered on tablets/large screens.

### 2.4 Motion

- Sheet: slide-up 250ms ease-out; dialog: scale 0.96→1.0, 180ms.
- Refresh: skeleton shimmer 1200ms cycle (respect `prefers-reduced-motion` → static placeholders).
- Haptics: light impact on pull-to-refresh, medium on consent confirm.

---

## 3. Screen List

### 3.1 Home / Current Conditions (`/home`)

**Purpose:** One-glance answer: "What's it like right now, where I am?"

**Layout (top → bottom):**
1. **App bar** — left: location label (city name or "Device location", `heading-s`) + "Updated 4 min ago" (`body-s`, warning color if >30 min); right: search icon button, settings icon button.
2. **Hero card** (`surface-secondary`) — weather condition icon (48pt, decorative), `display-xl` temperature in °C/°F, condition text ("Light rain"), "feels like" line, high/low row with up/down arrows.
3. **Provenance strip** (`body-s`): "Open-Meteo · updated 12:04 · precise location off".
4. **Key metrics grid** (2×2 cards): Wind (speed + direction arrow), Humidity, Precipitation probability, UV index. Each card: icon + `heading-s` value + `body-s` label.
5. **Hourly preview** — horizontal scroll of next 8 hours (time, icon, temp); "See all →" link.
6. **Daily preview** — 3 rows (Today / Tue / Wed): day, icon, low–high temp bar.
7. **Footer CTA:** "Change location" button when using device location.

**States:**
- **Loading (first launch, no cached data):** full-screen skeleton — hero block + 4 metric card placeholders; shimmer or static per reduced-motion. Announce "Loading weather" to screen readers.
- **Loading (refresh / pull-to-refresh):** content stays, thin progress bar under app bar; metrics dim to 50%.
- **Empty:** only reachable if no location set and none chosen — replaced by **first-run location prompt screen** (see §5), not an empty home.
- **Error — API failure:** keep last cached data, banner below app bar: "Couldn't refresh — showing data from 1h ago. Retry." + Retry button; error color icon.
- **Error — location denied mid-session:** banner: "Location access was revoked — we switched to your saved city." + "Review settings" link.
- **Offline:** on connectivity loss, top banner: "You're offline. Showing last update from 12:04." All values marked stale; refresh disabled with explanation on tap.

### 3.2 Search City (`/search`, modal sheet)

**Purpose:** Find a city and switch to it (does not touch device-location permission).

**Layout:**
1. Drag handle + "Choose a city" (`heading-m`) + close button.
2. Search field — autofocus, placeholder "Search cities…", clear (×) button when text present, magnifier icon.
3. Below field: "Use device location" row (only if permission granted; shows "Coarse precision on").
4. **Recent searches** section (max 5, local-only list): city, region, temp chip; swipe-to-delete.
5. **Results list:** rows with city name (`heading-s`), "Region, Country" (`body-m`), 24pt weather icon + temp (`body-m`). Ambiguous results (e.g. "Springfield") show country + admin region disambiguation on every row — never merge duplicates.

**States:**
- **Loading:** 3 skeleton rows after 300ms debounce (no spinner flash for fast results).
- **Empty (no query):** recents + hint illustration text "Search for any city to see its weather."
- **Empty (no results):** icon + "No cities found for “{query}”" + "Check spelling or try a larger nearby city." + "Search the web" NOT offered (out of scope).
- **Error:** inline card "Search failed. Check your connection and try again." + Retry button; preserves typed query.
- **Offline:** search field disabled with caption "Search needs a connection — your saved cities still work."

Selecting a result: sheet dismisses with 250ms slide-down; home reloads with new city; toast/snackbar "Showing Paris, France".

### 3.3 Hourly Forecast (`/hourly`)

**Purpose:** Next 48 hours, hour by hour.

**Layout:**
1. App bar: back + "Hourly forecast — {City}" + unit toggle (°C/°F) in overflow.
2. **Now card** pinned at top: current hour summary.
3. Scrollable list grouped by day ("Today", "Tomorrow", date): rows with time (`label-m`, tabular), icon, temp, precip % (blue, bold if ≥50%), wind speed. Row min height 56pt.
4. Horizontal temp-sparkline strip optional at top of each day group (decorative, hidden from AT).

**States:**
- **Loading:** 8 skeleton rows.
- **Empty:** unreachable with valid location; if API returns no hourly data → "Hourly data unavailable for this location right now." + Retry.
- **Error:** full-screen card with icon, "Couldn't load the hourly forecast." + Retry + "Back to current conditions".
- **Offline:** cached hours shown with stale banner (same pattern as home).

### 3.4 Daily Forecast (`/daily`)

**Purpose:** 7-day outlook.

**Layout:**
1. App bar: back + "7-day forecast — {City}".
2. List of 7 day-cards: weekday + date (`heading-s`), condition icon, condition text (`body-m`), low–high with gradient temp bar (blue→amber), precip % and wind on expanded tap.
3. Tapping a day expands inline (accordion, one open at a time): sunrise/sunset, UV max, precip sum, wind max.

**States:** mirror §3.3 — skeleton list loading; full-screen error card with Retry; cached + stale banner offline; "Daily data unavailable" empty variant.

### 3.5 Settings & Privacy (`/settings`)

**Purpose:** Units, location control, privacy transparency. This is a first-class screen, not a dumping ground.

**Layout (grouped list):**
1. **Location** group:
   - "Use device location" toggle (reflects OS permission; toggling OFF here opens OS settings deep-link; toggling ON re-triggers consent sheet).
   - "Saved city" row → opens search sheet.
   - "Location precision" row (read-only value "Coarse — ~1 km (rounded coordinates)", info icon → explainer dialog).
2. **Units** group: Temperature (°C/°F), Wind (km/h, mph, m/s), segmented controls.
3. **Privacy** group:
   - "Privacy notice" row → full notice screen (§5.4).
   - "What we store" row → storage explainer: "We store only your chosen city name and unit preferences on this device. Precise coordinates are never stored."
   - "Delete local data" button (destructive, confirm dialog) — clears recents, saved city, preferences.
4. **About** group: "Data source: Open-Meteo", app version, "Rate this app" link.

**States:**
- **Loading:** settings read from local storage is synchronous; no loading state needed. If OS permission query pending → toggle shows indeterminate shimmer max 1s.
- **Empty:** n/a (static screen).
- **Error:** if OS settings deep-link fails → snackbar "Couldn't open system settings — change location permission manually." Data-delete failure → error dialog with retry.

---

## 4. Global Components & States

- **Offline banner:** persistent, `warning` tinted, appears on all screens above content; announces via live region.
- **Snackbar:** 4s, action optional, bottom-above-nav; used for confirmations ("Saved", "Location updated").
- **Pull-to-refresh:** home only; haptic + spinner; disabled offline.
- **Navigation:** bottom nav NOT used (5 screens, hierarchical). Back = system back / app-bar back; search is a modal sheet; settings pushed on stack.

---

## 5. Location-Consent Flow (step-by-step)

GDPR principles applied: **prior consent, purpose limitation, data minimisation (coarse precision), no storage of precise coordinates, revocable at any time.**

### 5.1 First run (no city, no permission)

1. **Welcome screen:** headline "Know the weather, your way", body explains two options. Two buttons: "Use my location" (primary), "Choose a city instead" (secondary). Footer link: "How we handle location data" → privacy notice.
2. **User taps "Use my location":**
   a. **In-app consent sheet** (BEFORE the OS dialog — this is the GDPR first-class moment):
      - Title: "Allow location access?"
      - Body: "We'll use your device location once to find nearby weather. We request **coarse precision only** (~1 km — coordinates are rounded before use), and we **never store your precise coordinates** — only the nearest city name."
      - Bullet list with icons: "Used only to fetch weather", "Coarse precision (~1 km, rounded)", "You can switch to a manual city anytime".
      - Buttons: "Allow" (primary), "Not now" (text).
   b. **User taps "Allow"** → OS permission dialog (system UI, `ACCESS_COARSE_LOCATION` on Android / `kCLLocationAccuracyReduced` on iOS — never request fine).
   c. **Granted:** fetch city via reverse-geocode, **immediately discard lat/lon**, persist `{city, region, country}` only. Show home with toast "Using your approximate location". Privacy strip on home reads "precise location off".
   d. **Denied:** fall through to manual city search; remember "declined" so we don't re-prompt for 30 days; settings still offers re-enable.
3. **User taps "Choose a city instead":** → search sheet (§3.2); permission never requested.

### 5.2 Returning user toggles location on in Settings

Settings → "Use device location" ON → shows the same in-app consent sheet (step 2a) → OS dialog → granted: replace saved city with device-derived city (confirm via snackbar with Undo 5s); denied: toggle reverts with explanation.

### 5.3 Revocation

- OS-level revoke → app detects on next foreground → banner (§3.1 error state) → falls back to last saved manual city or search sheet.
- In-app: Settings toggle OFF → stops location use immediately, clears derived city, prompts to pick a manual city. No "dark pattern" confirm-shaming.

### 5.4 Privacy notice (in-app screen, linked from welcome + settings)

Plain-language sections, `body-l`, max 720dp width:
1. What we collect: city name you choose OR approximate area (coarse, ~1 km — coordinates rounded before use) when you opt in.
2. What we never collect/store: precise GPS coordinates, location history, background location (we request foreground-only).
3. Why: only to fetch weather for where you are.
4. Where data lives: on your device only; weather requests go to Open-Meteo (link to their privacy policy).
5. Your rights: change or delete anytime in Settings; contact line placeholder `[support email]`.
6. "Last updated" date stamp. No lorem ipsum — final copy required before build sign-off.

---

## 6. Accessibility Notes (WCAG 2.1 AA)

- **Contrast:** all text ≥ 4.5:1, large text ≥ 3:1 (verified against both themes, §2.1). Temp-bar gradients are decorative; values always paired with text.
- **Focus order:** logical top-to-bottom, left-to-right; modal sheet traps focus until dismissed; consent sheet focus starts on title, then body, then actions.
- **Visible focus:** 3px `focus-ring` outline on all interactive elements (keyboard, switch control, TalkBack linear nav).
- **Labels:** every icon-only button has an accessible label ("Search", "Settings", "Close", "Retry", "Back"). Weather icons marked decorative; condition conveyed in text. Toggle states announced ("Use device location, switch, on").
- **Keyboard nav:** full app operable without touch — Tab/Shift+Tab, Enter/Space, Esc dismisses sheets/dialogs. No keyboard traps.
- **Screen reader:** headings use semantic heading levels; lists announced as lists with counts; loading states announce once ("Loading weather", not per-skeleton); errors announced via assertive live region; temperature reads "21 degrees Celsius".
- **Motion:** `prefers-reduced-motion` (and OS reduce-motion) disables shimmer, parallax, and sheet slide → instant transitions.
- **Touch targets:** ≥48×48pt (§2.3); adjacent targets ≥8pt apart.
- **Text scaling:** layouts survive 200% text scaling — no clipped text, no overlapping; hero temp wraps gracefully; test at largest accessibility sizes on both platforms.
- **Color independence:** precip ≥50% uses bold + "%" text, not blue alone; stale data uses text label "stale", not warning color alone; error states pair icon + text.
- **Timing:** no time-limited interactions; snackbars with actions persist until dismissed when action is destructive-adjacent (Undo).
- **Language:** `body-l` copy at ≤ grade-8 reading level for consent/privacy text.

---

## 7. Content Rules (no lorem ipsum)

- Every string in this spec's screens ships with **final copy** or an explicit `[COPY TBD — owner: …]` tag; nothing marked "ready for build" contains placeholder text.
- Empty/error states always: (1) say what happened in plain language, (2) say what the user can do, (3) offer the action inline. No bare error codes.
- Numbers always carry units; times show timezone context ("14:00 local").

---

## 8. Open Questions for Sloane / Engineering

1. Reverse-geocoding provider for coarse coords → city name (Open-Meteo geocoding API supports this; confirm).
2. Offline cache TTL policy (propose: 6h current, 12h forecast) — needs product sign-off.
3. Support email + Open-Meteo attribution wording for privacy notice §5.4.
4. °F default for US locale vs. always °C default — needs decision before build.

---

*End of spec v1.0 — ready for engineering review and copywriting pass.*
