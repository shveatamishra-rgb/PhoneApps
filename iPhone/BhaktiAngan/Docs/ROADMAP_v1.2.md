# Bhakti Angan v1.2 scope (app + website)

Drafted 2026-07-07, the day v1.1 went to review. Sources: the deferred items in
RELEASE_v1.1_PLAN.md (#4, #5, #8, audio), the owner's standing asks (more widgets:
daily verses, shlokas, Bhagavad Gita), and the Diya competitor teardown
(iPhone/BhaktiAngan/diyapp screenshots/, reviewed 2026-07-07).

Guiding rule, unchanged: everything ships without accounts, without third-party
embeds, and without breaking App Privacy "Data Not Collected".

## App

### 1. Daily Verse widget + Shloka library (the headline)
- Third widget in the existing DarshanWidgetExtension: verse of the day
  (Devanagari + EN/HI meaning), small/medium + lock screen. Rides the proven
  App Group bridge; no new Xcode target needed.
- In-app Verse library: Bhagavad Gita first. Public-domain Sanskrit, our own
  EN/HI translations (native-speaker review before ship). Per verse: Devanagari,
  transliteration, meaning EN/HI, one-line "how to live it today".
- Surfaces: a "Today's Shlok" card on the Today tab; library section with
  search by theme (dharma, peace, courage); save to favorites.
- Free/Pro: daily verse + chapter 1 free, full library Pro. Content bundled as
  a dataset (like stories.json); later verses can arrive via the remote pipeline.
- Validated by Diya: their Verse Library + "Add Verse Widget" interest tile are
  core onboarding hooks. Ours ships without their server or chatbot.

### 2. Bhagavad Gita "Sacred Library" (deep content, #8)
- Chaptered Gita reading: chapter intro (what it teaches, when to read it),
  verses in the verse-library format, chapter summary.
- Per-deity journey structure ties it together: intro, stories (Katha),
  shlokas, mantras, darshan gallery. Krishna first.
- Author once, publish twice: the same content feeds the website Gita section.

### 3. Intent onboarding (light, 2 screens)
- "What brings you here" multi-select (daily darshan, panchang and muhurat,
  japa, learn the scriptures, katha) ahead of the existing ishta grid.
- Uses: default landing tab, notification opt-in framing, which taster content
  is surfaced first. Stored locally only (@AppStorage), no analytics.
- NOT the Diya funnel: no pledge screen, no benefit statistics, no paywall
  before content.

### 4. "Your practice" card
- Days practiced (existing streak), japa completed (existing counts), darshans
  seen, katha read, verses saved. All already on device; render on Today or in
  Settings. Zero new data collection.

### 5. Voice Japa (#4, flagship Pro USP)
- Plan in Docs/VOICE_JAPA.md: on-device mic onset counting + calibration,
  no audio leaves the device. Needs real-device tuning (sim has no mic).

### 6. Festival collections (#5, rides the pipeline)
- Janmashtami, Ganesh Chaturthi, Navratri, Diwali packs prepared early with
  availableFrom/Until windows in the manifest; never races App Review.
  Prep dates are in Docs/MARKETING_CALENDAR_2026.md.

### 7. Audio, done truthfully (asset-blocked)
- Commission 2-3 tracks from Indian artists, owned outright ("recorded for
  Bhakti Angan", true). Chant sessions with target counts (27/54/108) on the
  japa screen; ambient track wakes the dormant AudioManager.
- Explicitly rejected: YouTube embeds of third-party channels (Diya wraps
  T-Series behind its paywall; YouTube ToS forbids paywalled embeds, and one
  embed would end our privacy label), and any AI chatbot for now (server cost,
  moderation risk on religious guidance, privacy label).

### 8. Small touches
- Settings support entry reworded personal: "Write to us, we read everything"
  (mirrors Diya's Text-the-Founder trust signal with our existing mail composer).
- Katha follow-ons from v1.1: darshan <-> katha cross-links, "read the full
  story" into long-form once #2 content exists.

## Website

### 1. Bhagavad Gita section
- /bhagavad-gita/ pillar + per-chapter pages (EN + HI real pages via Polylang),
  same verse format as the app; "Aaj ka Shlok" block on the homepage.
- SEO target: "bhagavad gita in hindi", "gita shlok with meaning" family.
  Single content source with the app dataset.

### 2. Long-form story track (already in flight)
- Krishna long-form (page 1080, /krishna/, noindex): owner verdict, then flip
  to index + link from the stories hub and Explore.
- Author the Hindi version (written, not machine-translated).
- Next deity long-form after Krishna (Shiva for Shravan timing), then Devi
  before Navratri.

### 3. Gallery follow-ons
- Katha tab on the gallery (per the gallery prompt-library plan).
- Auto-fit wallpaper downloads (phone-sized crops).
- Keep the collectible cadence: new scenes land as festival drops, gallery
  first, app manifest same day.

### 4. Newsletter growth loop
- Opt-in exists on the gallery; add the same block to story pages and
  /panchang/ (highest-traffic page).
- First real newsletter when the list reaches ~100 subscribers (target: before
  Shravan, Jul 30). Until then, announcement energy goes to IG/YT/WhatsApp.

### 5. Revenue activation stubs (waiting on owner inputs)
- Amazon Associates tag -> puja-essentials placements on panchang + gallery.
- UPI / Buy-Me-a-Coffee -> "support the seva" button.
- Display ads remain rejected (clashes with the elite feel).

### 6. Later
- Gujarati as the third Polylang language (after Hindi content is complete).

## Sequencing

1. Now (writing work, no build): Gita translations EN/HI, long-form Hindi
   Krishna, Shiva long-form draft. Website Gita section can go live before the
   app build.
2. First v1.2 build (small, low review risk): Verse widget + Shloka library +
   intent onboarding + practice card + support copy.
3. Second wave: Voice Japa (device tuning) + festival packs (content, no build).
4. When assets arrive: commissioned audio + chant sessions.

## Do-not-copy list (from the Diya teardown, keep for reference)
- No third-party YouTube/Spotify embeds, ever, while we carry the
  "Data Not Collected" label.
- No unsubstantiated health statistics in-app or in ASC metadata (2.3.1 risk).
- No "money-back guarantee" claims (Apple IAP refunds are not ours to promise).
- No hard paywall before the user has seen real content.
- No fabricated social proof counters.
