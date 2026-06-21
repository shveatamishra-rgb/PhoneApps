# Roadmap & your role after launch

You asked: once the app is live, what's my job, and do the images need
maintenance? Here's the honest map.

## Do the live images need maintenance?

**Technically, no.** The images are bundled into the app — they don't run, break,
or expire. They just sit there and display. There's no server, no upkeep.

**Editorially, yes — lightly and on your terms:**
- **Corrections:** if a devotee reports an iconography concern, fix/replace that
  image in the next update (the catalog now supports pulling an image in one line
  — see `removedImageNames` and `Docs/IMAGE_REVIEW.md`).
- **Quality upgrades:** swap weaker images for better ones over time.
- **Growth:** add new images (festival packs, more deities). This is the main
  ongoing content work — and it doubles as social content.

So "maintenance" is really **curation + growth**, not firefighting.

## Your actual role once live (3 hats, mostly the ones you already wear)

1. **Content creator (your strength, ongoing).** You already make daily darshan
   content for Instagram/YouTube. Keep doing that — each post funnels installs,
   and your best new images become app updates. The app and the channel feed each
   other. This is 80% of your ongoing role and you're already doing it.
2. **Community & growth (light, weekly).** Reply to App Store reviews (especially
   iconography feedback — fix + thank), keep the App Store link in every bio and
   video, tune ASO (title/subtitle/screenshots — changeable without a build), and
   adjust per-country pricing once you have data.
3. **Product owner (occasional).** Decide what ships next (below) and when. You
   set direction; the build/test/release work is a developer task (me), not a
   daily burden for you.

## Technical maintenance cadence (low)

- **Per release (every few weeks):** new images / a festival pack / a fix →
  build, test, submit. A few hours of dev work, not yours to do manually.
- **Yearly (each new iOS, ~Sept):** rebuild on the new Xcode/iOS, test on new
  devices, ship a compatibility update. Predictable, once a year.
- **As needed:** act on a crash/bug report, a pricing change, or a policy update
  if you add features. The app has no backend, so there's nothing to keep running.

## Product roadmap (suggested order)

1. **v1.1 — Voice Japa** (the flagship USP; plan in `Docs/VOICE_JAPA.md`).
   Hands-free, on-device, lead Pro feature. Tune on a real device.
2. **Festival collections** — Janmashtami, Navratri, Diwali, Maha Shivratri,
   Ganesh Chaturthi. Timed Pro drops = recurring revenue spikes and natural
   social moments. This is your best monetization rhythm.
3. **Daily Darshan widget** (home-screen + lock-screen) — shows the day's image.
   Huge for retention/daily opens; strong reason to keep the app installed.
4. **Background music** — add the licensed track (`Docs/BACKGROUND_MUSIC.md`).
5. **Localization** — Hindi first, then Tamil/Telugu, for your India-first
   audience. Meaningfully lifts conversion in non-English storefronts.
6. **Audio aarti / bhajan** playback per deity (Pro) — deepens the practice.
7. **More deity coverage + the iconography re-review** before each content drop.

## The growth loop (how revenue actually compounds)

Daily darshan content (you already make it) → installs → free users → streaks +
daily darshan habit → festival Pro drop or Voice Japa → subscriptions → reviews →
ranking → more installs. Your job is to keep the **content** and the **festival
cadence** going; the app turns that audience into recurring revenue.

## Where a website fits

A simple one-page site (your `.in` domain) is worth it as: the App Store Support
+ Marketing URL, a "link in bio" hub (app + IG + YouTube + FB), and — if you want
— the privacy/terms home instead of the github.io page. It's a credibility and
funnel piece, not a content site. Keep it to one page; don't let it become work.
