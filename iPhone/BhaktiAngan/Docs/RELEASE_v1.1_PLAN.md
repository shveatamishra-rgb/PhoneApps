# Bhakti Angan — v1.1 (next feature release) plan & checklist

**Status:** v1.0 is **APPROVED & LIVE** on the App Store (id6782816559, released
2026-07-02). v1.1 build is now **in progress** (version bumped to 1.1(1)). Do **not**
upload a new build while any v1.0 review is pending; local development is fine.

## Progress log since v1.0 approval

- **2026-07-04 — #6 Remote content pipeline: SHIPPED & VERIFIED.** `Services/RemoteCatalog.swift`
  (manifest fetch/cache/refresh, offline-first `DarshanImageStore` seam, festival windows,
  `removed` kill-switch, `replaces` swap) wired into `ContentCatalog.items`, the launch
  refresh hook, and every image call site. Website endpoint `GET /wp-json/bhaktiangan/v1/app-catalog`
  live + schema-valid; publisher `bhaktiangan-site/95-app-catalog.mjs`. 5 RemoteCatalogTests
  pass; full app compiles on iPhone 17 sim.
- **2026-07-04 — #7 Library/Gallery redesign: BUILT & VERIFIED.** `Features/Library/LibraryView.swift`
  rebuilt from a flat grid + chip filter into curated per-deity shelves (gold COLLECTION
  eyebrow, serif family headers, teal See all → per-deity grid, editorial cover cards with
  scrim + serif name, favorite + Pro lock preserved; search → flat results grid). Verified
  visually in the simulator across all collections. NOTE: the deeper #7 goals (avatar
  collections as categories; darshan ↔ story internal links) depend on #1 (stories in-app).
- Committed to `main` 2026-07-04 (remote pipeline + Library redesign + tests).

_Keep appending dated entries here as v1.1/v1.2 items land._

**Scope agreed with owner:** all five below go into the next release cycle (they can
be split across v1.1 / v1.2 by the sequencing at the bottom — voice + festivals are
the natural v1.2 if we want a faster first drop).

Current app baseline (v1.0): Today, Darshan Library (51 images / 19 deity templates),
Japa (tap counter), Panchang/Choghadiya (on-device location), Settings, Support,
Paywall (Pro monthly2 / yearly+trial / lifetime), Onboarding. Bilingual EN/HI.
Data Not Collected. Models in `BhaktiAngan/Models/DevotionalContent.swift`;
catalog in `Data/ContentCatalog.swift`; tabs in `App/RootView.swift` (`AppTab`).

---

## 1 · Stories & Katha (port the website content) — highest value, unblocked

The website already has this content written; the app has **no story field at all**
(darshan detail shows only deity / mantra / meaning / blessing).

**Content sources (reuse, don't rewrite):**
- 44 **avatar** narratives — `bhaktiangan-site/75-avatar-stories.mjs` (EN) +
  `78-hi-avatar-stories.mjs` (HI). Fields per item: `name/hi`, `eyebrow`, `story[]`
  (paragraphs), `meaning`, mantra. Dashavatar + Shiva forms + Devi/Tridevi/Navadurga
  + 10 Mahavidya + Ganesha/Hanuman.
- 10 **katha** — `76-hindu-stories.mjs` (EN) + `79-hi-stories.mjs` (HI). Fields:
  `title/hi`, `eyebrow`, `deity`, `story[]`, `moral`.

**Build tasks:**
- [ ] Add a `story` model: `struct Story { id, titleEN/HI, eyebrowEN/HI, deity,
      bodyEN/HI: [String], moralEN/HI, imageName, isPremium }`. Consider an optional
      `story`/`iconography`/`significance` on `DevotionalItem` too, so a darshan can
      link to its narrative.
- [ ] Extraction script: pull EN+HI prose from the four builders into a bundled
      `stories.json` (single source; no network). Keep Devanagari intact.
- [ ] New **Katha** tab in `AppTab` + `RootView` (icon `book.closed.fill`,
      "Katha"/"कथा"), list → detail reader. Match `DarshanDetailView` styling.
- [ ] Bundle the story hero art (portrait for cards, landscape for reader header) —
      sources in `bhaktiangan-site/Bhakti_Angan_Story_Images/`.
- [ ] Pro-gating decision: first N stories free, rest Pro (mirrors darshan model).
- [ ] Cross-link: darshan detail → "Read the story" when a matching katha exists.

---

## 2 · Daily Darshan widget — best retention feature

- [ ] New **WidgetKit** extension target (app group for shared state:
      `group.in.bhaktiangan.app`).
- [ ] Small/medium/large + lock-screen (accessoryRectangular) showing the day's
      darshan image + deity + short mantra. `TimelineProvider` rolling at midnight.
- [ ] Tap → deep-link into the app's Today screen.
- [ ] Free (drives daily opens); do not gate.

---

## 3 · Panchang / Choghadiya widget (owner-requested)

Widget that keeps showing the **current muhurat/choghadiya**, location-selectable.

> **PLATFORM LIMITATION — flag before building (per standing rule):** an iOS widget
> **cannot** contain a free-form, in-tile location *search/picker*. Widgets are
> timeline-driven; interactivity is limited to Buttons/Toggles (App Intents, iOS 17+).
> Two viable patterns:
> - **(A) Widget configuration (recommended):** user long-presses the widget →
>   **Edit Widget** → picks a city from an **AppIntent configuration** list (fed by
>   our `Data/Cities.swift`). This is the native "per-widget location" and supports
>   multiple widgets on different cities.
> - **(B) Follow the app's location:** widget mirrors the location set inside the app
>   (simplest; one shared city via the app group).
> Recommend **A** (matches the "select location in the widget" intent as closely as
> iOS allows), with **B** as the default before configuration.

- [ ] Reuse `Services/Panchang.swift` + `Astronomy.swift` in the extension (share the
      sources with the widget target — no duplicate engine).
- [ ] `TimelineProvider` with entries at each choghadiya boundary so the tile always
      shows the *current* period + time remaining + next period.
- [ ] `AppIntentConfiguration` city picker from `Cities.swift`.
- [ ] Small = current choghadiya + ends-at; medium = current + next 2–3.

---

## 4 · Voice Japa — flagship USP (plan: `Docs/VOICE_JAPA.md`)

- [ ] Hands-free on-device chant counting (JapaView is tap-only today).
- [ ] `NSMicrophoneUsageDescription` + on-device detection (keep Data Not Collected —
      **no audio leaves the device**; document for App Review).
- [ ] Lead Pro feature; needs **real-device tuning** (sensitivity/false counts).
- [ ] Higher review scrutiny (mic) → keep the privacy note explicit.

---

## 5 · Festival collections — recurring-revenue cadence

- [ ] Festival pack data model (Janmashtami, Navratri, Diwali, Maha Shivratri,
      Ganesh Chaturthi): themed darshan sets with date windows.
- [ ] Timed Pro drops surfaced on Today + Paywall (copy already promises
      "New festival collections" in `PaywallView`/`SettingsView`).
- [ ] Doubles as social content moments.

---

## 6 · Remote content pipeline — images without builds (owner-approved 2026-07-01)

One-time build work; afterwards adding/replacing/removing darshan images never
requires a release. Apple allows downloading *content* (not code) — standard.

- [ ] Manifest JSON hosted on bhaktiangan.com (e.g. `/app/catalog.json`), fetched
      on launch + daily. Entries: id, image URL, deityEN/HI, mantraEN/HI,
      meaningEN/HI, blessingEN/HI, category, `isPremium`, optional festival window.
- [ ] **`replaces`**: manifest entry with a bundled image's id + remote URL → app
      prefers the remote version (corrected-iconography swaps without a build).
      Versioned filenames (`-v2`) for cache-busting.
- [ ] **`removed`**: remote kill-switch mirroring `ContentCatalog.removedImageNames`
      — pull a reported image same-day, before corrected art exists.
- [ ] Background download + on-device cache (offline-first: bundled 51 remain the
      base; no network = bundled + cached still work).
- [ ] Keep requests bare GETs (no device IDs, no analytics) → **App Privacy stays
      "Data Not Collected"**.
- [ ] Publisher script in `bhaktiangan-site/` (wp.mjs) — one command: upload image(s),
      regenerate + upload catalog.json. Iconography pre-publish check per
      `IMAGE_REVIEW.md` becomes the only quality gate (no App Review speed bump).
- [ ] Festival packs (#5) ride this: a pack = manifest entries with a date window,
      prepared early, appears on time — never race App Review before a festival.

## 7 · Library / Gallery redesign — elite, curated, interlinked (owner, 2026-07-01)

Owner verdict: the current in-app gallery isn't good enough — "more robust and
elite." Direction:

- [ ] **Proper categories**: replace the flat grid + chip filter with a curated,
      sectioned library (per deity with cover art; collections as rows/shelves,
      editorial covers, Cormorant/serif headers — match the website's elite look).
- [ ] **Avatar collections**: introduce the finalized avatar image sets (Dashavatar,
      Shiva forms, Devi/Navadurga, Mahavidya…) as first-class categories — same art
      direction as the website avatar pages (44 heroes already exist for web; app
      versions once finalized).
- [ ] **Internal linking**: darshan detail → its avatar page / story (Stories tab,
      #1) when one exists; avatar/story pages → their darshan images. One connected
      content graph, not three silos.
- [ ] Depends on #1 (stories in-app) + benefits from #6 (categories/collections can
      grow remotely).

## 8 · Deep devotional content — verses, shlokas, beginner stories (owner, 2026-07-01)

Owner: website stories are brief/high-level; someone who knows *nothing* about
Krishna needs more. App (and later web) should carry real depth:

- [ ] **Shlokas & verses** per deity/story: Devanagari + transliteration + EN/HI
      meaning (public-domain sources — Gita, Puranas; aligns with the earlier
      "Sacred Library / Bhagavad Gita" v1.2 idea).
- [ ] **Long-form beginner stories**: assume zero background — who the deity is,
      the full narrative arc (childhood, key episodes, why it matters), glossary
      of terms (avatar, lila, darshan…), written in chapters/sections rather than
      the website's 4-6 paragraph summaries.
- [ ] Author once, publish twice: the long-form content should also feed the
      website story pages later ("Read the full story" expansions) — single
      content source, app + web.
- [ ] Bilingual EN/HI like everything else; native-speaker review before ship.
- [ ] Candidate structure: per-deity "journey" (intro → stories → shlokas →
      mantras → darshan gallery) — ties #1, #7, and this together.

## Audio (music / aarti) — asset-blocked, not code-blocked

`Services/AudioManager.swift` is scaffolded; it only shows the music UI once a
bundled track exists (`ambient_darshan.m4a`, see `Docs/BACKGROUND_MUSIC.md`).
Per-deity aarti/bhajan (`ROADMAP.md` item 6) also needs **licensed audio**. Land
these whenever the tracks are sourced — no engine work required first.

---

## Suggested sequencing

- **v1.1 (content + retention, low review risk):** #6 Remote content pipeline
  (foundation — do first so everything after grows without builds), #1 Stories &
  Katha, #7 Library/Gallery redesign, #2 Daily Darshan widget, #3 Panchang widget.
- **v1.2 (native + monetization + depth):** #4 Voice Japa, #5 Festival collections
  (data rides #6), #8 deep content (shlokas + long-form beginner stories — content
  authoring can start anytime, it's writing work not build work).
- **Anytime the assets arrive:** background music + aarti audio.

## Open decisions to confirm at build time
- Panchang widget location model: **A (widget configuration)** vs B (follow app).
- Stories Pro-gating threshold (how many free).
- Whether avatar narratives attach to darshan detail, live only in the Katha tab, or both.
- Gallery redesign: shelf/collection layout vs per-deity hub pages (mock both).
- Deep content (#8): start with which deity (Krishna suggested — owner's example)
  and which shloka sources first.
