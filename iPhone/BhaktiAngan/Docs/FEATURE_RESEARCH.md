# Feature research: what makes devotional apps win, and what Bhakti Angan should build

Date: 2026-07-07. Method: multi-agent web research (103 agents) over Sri Mandir /
AppsForBharat, Diya, Hallow, YouVersion, Gita apps, AstroTalk, plus Apple's
privacy-label rules; adversarial verification ran partially (session limits), so
each claim below is tagged VERIFIED (2-3 independent confirmations) or SOURCED
(credible source, not adversarially verified). Full raw output:
`/private/tmp/.../tasks/w5bru3qqf.output` (session scratch).

## The two winning models (and which one is ours)

**Model A: ritual commerce.** Sri Mandir's core is transactional devotion:
remote pujas and chadhava offerings in your name at 100+ partner temples
[VERIFIED, App Store listing]. It layers subscriptions ($4.99/mo, $29.99/yr) on
top [VERIFIED]. Reported scale: 1.2M users, 5.2M paid rituals in a year, ~55%
six-month retention that their CEO attributes to recurring religious
transactions across the festival year; AstroTalk (+85% revenue FY25) is the
same transactional pattern with astrologers [all SOURCED: TechCrunch, YourStory].
This model requires temples, logistics, payments, accounts and a backend. Sri
Mandir's privacy label: tracks Usage Data, collects name/phone linked to
identity [VERIFIED]. **Not our model, and not replicable solo.**

**Model B: content + habit loop + seasonal moments.** Hallow (Catholic) and
YouVersion (Bible) grow on daily content, streaks, reading plans, and
religious-calendar campaigns (Hallow's Lent push famously took it to #1 on the
App Store; YouVersion's verse-of-the-day + plans + shareable verse images)
[SOURCED]. **This is exactly Bhakti Angan's model, and the key enabler is
VERIFIED from Apple's own docs: data processed only on-device is not
"collection", so streaks, plans, progress and habit mechanics all keep the
"Data Not Collected" label.** The festival calendar insight transfers directly:
the retention engine in faith apps is the religious calendar itself, and our
remote festival-drop pipeline is already built for it.

**The diaspora insight.** Sri Mandir reports ~20% of demand from the US, UK,
UAE, Canada, Australia, NZ, with diaspora ARPU roughly 10x domestic (~$81 vs
$7-9) [SOURCED]. We are unusually well positioned: iOS-first IS the diaspora
platform, the app is bilingual, our Panchang/Choghadiya computes on-device for
any city in the world (a diaspora devotee in New Jersey gets correct local
muhurat, which India-server apps get wrong or ignore), and our pricing already
separates US/India tiers. Diaspora storefronts should be the first Apple
Search Ads spend.

## New feature candidates (research-driven, not yet in the backlog)

Ranked. Every one is accounts-free, server-free, label-safe.

1. **Share-as-card (viral loop).** YouVersion's verse-image sharing is its
   organic growth engine [SOURCED]. Build: render today's shlok / darshan
   blessing as a beautiful branded card (art + Devanagari + meaning + tiny app
   mark) via on-device UIGraphicsImageRenderer, share sheet to WhatsApp/IG
   stories. WhatsApp forwarding is India's distribution network. Small build,
   rides the verse library. Target: v1.2.
2. **Reading plans with completion.** YouVersion's plans + New Year momentum
   [SOURCED]; Hallow's routines [SOURCED]. Build: "Gita in 30 days" (one verse
   chunk/day, on-device progress ring, completion badge). Later: "Hanuman
   Chalisa in 7 days", "Navratri 9-day path". Bundled content + local
   notifications only. Target: v1.2 (chapter 1 plan) / v1.3 (full).
3. **Festival mode (seasonal campaign engine).** Hallow's Lent and YouVersion's
   seasonal spikes are the single biggest growth moments in faith apps
   [SOURCED]. We already have manifest date windows; add an in-app festival
   card (countdown, special darshan run, themed widget accent) driven entirely
   by the manifest. Zero new infrastructure, turns every festival into a
   mini-launch. Target: v1.3, content-first pilot during Navratri via existing
   pipeline.
4. **Live Activity / Dynamic Island for Choghadiya.** No devotional app does
   this. The current muhurat with a countdown in the Dynamic Island during the
   day; pure ActivityKit, on-device, label-safe. A genuinely iOS-native
   differentiator that markets itself in screenshots. Target: v1.3.
5. **Vrat reminders (Ekadashi, Somwar, Purnima).** The panchang engine already
   computes the calendar; add opt-in local notifications ("Kal Ekadashi hai").
   High-retention, zero-cost, deeply useful to the core audience. Target: v1.3.
6. **App Intents / Siri shortcuts.** "Aaj ka darshan" / "Aaj ka choghadiya"
   from Siri and the Shortcuts gallery; free OS-level discoverability, trivial
   surface. Target: v1.3.
7. **Apple Watch japa counter.** Wrist-tap japa with haptics; the physical mala
   gesture on the device devotees already wear. Niche but loved, and a
   review-friendly showcase. Target: v1.4.

## Explicitly NOT building (research-confirmed dead ends for us)

- Puja booking / chadhava marketplace (Model A: needs temples, ops, accounts).
- Astrologer chat/calls (AstroTalk model: marketplace + payments + liability).
- Accounts, community feeds, prayer walls (server + moderation + label death).
- AI chatbot (server cost, religious-guidance moderation risk, label).
- Third-party media embeds (YouTube/Spotify: ToS + label; see Diya teardown in
  ROADMAP_v1.2.md).
- Meta SDK for install ads (tracking + ATT prompt + label death; use Apple
  Search Ads instead, diaspora storefronts first).

## The consolidated future outline (everything discussed, one list)

**v1.2 (build after v1.1 approval; checklist in RELEASE_v1.2_CHECKLIST.md)**
- Bhagavad Gita verse library (Devanagari + transliteration + EN/HI meaning;
  daily verse + ch.1 free, full library Pro)
- Daily Verse widget (widget #3)
- "Today's Shlok" card on Today tab
- Share-as-card for shlok + darshan blessings  [research add]
- "Gita in 30 days" plan, chapter 1 pilot  [research add]
- Intent onboarding (2 screens, local only)
- "Your practice" stats card
- Settings support copy ("Write to us, we read everything")
- Website: /bhagavad-gita/ pillar EN+HI, Aaj ka Shlok homepage block, opt-in
  blocks on story + panchang pages, gallery Katha tab + auto-fit wallpapers

**v1.3 (native depth + seasonal engine)**
- Voice Japa (on-device mic counting, flagship Pro USP; Docs/VOICE_JAPA.md)
- Festival mode card + themed windows (manifest-driven)  [research add]
- Choghadiya Live Activity / Dynamic Island  [research add]
- Vrat reminders (Ekadashi/Somwar/Purnima, local notifications)  [research add]
- App Intents / Siri shortcuts  [research add]
- Festival packs content cadence (Janmashtami, Navratri, Diwali windows)
- Full Gita reading plans + more plans (Chalisa 7-day, Navratri 9-day)

**v1.4+ (assets + platforms)**
- Commissioned audio: japa chant sessions (27/54/108), ambient aarti
  (AudioManager is scaffolded, asset-blocked)
- Apple Watch japa companion  [research add]
- Long-form beginner journeys in-app (per-deity: intro, stories, shlokas,
  mantras, darshan), fed by the website long-form content
- Sacred Library beyond Gita (Hanuman Chalisa, Ramcharitmanas excerpts,
  Puranas selections, all public domain)
- Gujarati as third language (site first, then app)

**Growth mechanics (no build required)**
- Apple Search Ads: India + diaspora storefronts (US/UK/CA/AU/AE), keyword set
  from APP_STORE_METADATA.md keywords
- Execution per MARKETING_EXECUTION_PACK.md (reels, newsletters, IST schedule)
- Bio links: App Store link first + website, IG and FB (native install sheet)
- Newsletter list growth via gallery/story/panchang opt-ins, first send at ~100
