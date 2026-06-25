# App Store Metadata — ready to paste

Everything below is final copy for App Store Connect. Nothing here is wired into
the binary, so you can tune it any time without a new build. Character limits are
Apple's; counts are noted so you stay inside them.

## Name & subtitle (App Store search weighs these most)

The brand is **Bhakti Angan** (भक्ति आँगन — "the courtyard of devotion"): a warm,
broad umbrella name that reads as instantly Hindu to rural + urban audiences and
can house future products (e.g. a Gita app). It's distinctive (no existing app
and not a common ashram name) and fully ownable (`bhaktiangan.in`, handles
secured). Win discovery by adding the high-intent keyword **Darshan** to the
title and packing the subtitle.

- **App Name** (max 30): `Bhakti Angan: Daily Darshan` — 27 chars ✅
  - Home-screen display name is `Bhakti Angan` (set in the app)
- **Subtitle** (max 30): `Hindu Gods, Mantra & Panchang` — 29 chars ✅
  (adds the high-intent keyword "Panchang"; "Japa/Choghadiya" live in the keyword field)

## Keywords (max 100 chars, comma-separated, NO spaces)

Do not repeat words already in the name/subtitle (Apple indexes those
separately). This field focuses on deity names and adjacent intents:

```
choghadiya,muhurat,japa,shiva,krishna,ganesha,ram,hanuman,devi,lakshmi,aarti,puja,wallpaper,temple
```
(~98 chars — leads with the high-intent Choghadiya/Muhurat/Japa, then deities. "bhakti/darshan/mantra/panchang" are already in the name/subtitle, so they're omitted here. Trim if App Store Connect flags it.)

## Promotional text (max 170 — editable any time without review)

```
Begin each day with a peaceful darshan, a simple mantra, and one quiet minute of devotion. Fresh deity images and festival collections are added over time.
```

## Description (max 4000)

```
Bhakti Angan — your courtyard of devotion. A calm, daily moment with the divine
on your iPhone: a beautiful darshan, a simple mantra, and one quiet minute of
stillness.

Open the app each morning to a new sacred darshan with its mantra, meaning, and
a short blessing. Sit with it for a minute, chant on the japa counter, and carry
a little peace into your day.

• DAILY DARSHAN
A rotating sacred image each day with mantra, meaning, and blessing — a gentle
ritual you can keep in under a minute.

• JAPA COUNTER
A calm, distraction-free mala counter with goals from 27 up to 10,000, soft
haptics, and a daily darshan streak that grows as you return.

• MANY DEITIES
Shiva, Ganesha, Krishna, Radha-Krishna, Ram, Hanuman, Vishnu, Lakshmi,
Saraswati, Vaishno Devi, Balaji, Narasimha, Brahma, and more — with their
mantras for japa.

• AAJ KA PANCHANG (CHOGHADIYA)
See today's auspicious and inauspicious windows — Shubh, Amrit, Labh, Char, Udveg,
Rog, and Kaal — with sunrise and sunset for your city. Calculated on your device.

• ENGLISH & हिंदी
The whole app — every screen and every mantra (in Devanagari) — switches between
English and Hindi with one tap.

• SAVE & SHARE
Keep any darshan as a wallpaper, mark favorites, and share blessings with family.

• QUIET REMINDERS
Choose a morning or evening time for one gentle daily reminder. No noise, no feed.

• YOURS, PRIVATELY
No account, no ads, no tracking. Your favorites, streak, and japa count stay on
your device.

BHAKTI ANGAN PRO
Unlock the complete darshan library, every deity mantra, unlimited wallpaper
saves, and future festival collections.
• Free for 7 days on the annual plan, then it renews at the listed price.
• Monthly and a one-time Lifetime option are also available.
Payment is charged to your Apple account. Subscriptions renew automatically
unless cancelled at least 24 hours before the period ends; manage or cancel any
time in your Apple account settings.

Terms of Use: https://bhaktiangan.com/terms-of-use/
Privacy Policy: https://bhaktiangan.com/privacy-policy/

Made with devotion. Jai Shri Mahadev 🙏
```

> Host the privacy/terms pages on `bhaktiangan.com` (canonical) — `.in` 301s to
> `.com`. Use the Privacy URL in App Store Connect's App Privacy section and the
> app's Privacy Policy field. See `Docs/DOMAIN_MIGRATION.md`.

## What's New (version 1.0)

```
Namaste and welcome to Bhakti Angan 🙏
• A new daily darshan with mantra, meaning, and blessing
• Aaj Ka Panchang — today's Choghadiya windows for your city
• A calm japa counter with a daily streak
• Full English & Hindi (हिंदी), with light and dark themes
• Save darshans as wallpapers, mark favorites, and set a gentle daily reminder
```

## App information

- **Primary category:** Lifestyle
- **Secondary category:** Health & Fitness (or Reference)
- **Age rating:** 4+ (complete the questionnaire; no objectionable content)
- **Bundle ID:** `in.bhaktiangan.app`
- **App Privacy → "Data Not Collected":** the *app* collects nothing — favorites,
  japa, streak, reminders, and the Panchang location are all on-device; purchases
  go through Apple. (The Google Analytics in the privacy policy is the *website*,
  not the app, so it does not change the app's label.) Matches `PrivacyInfo.xcprivacy`.
- **Languages:** English (primary). The binary also ships Hindi (`CFBundleLocalizations`
  en, hi). Adding a Hindi localization with translated name/subtitle/description in
  App Store Connect is an optional post-launch ASO boost for India.
- **Support URL:** `https://bhaktiangan.com/contact/` (the contact form)
- **Support email:** `support@bhaktiangan.com`
- **Marketing URL (optional):** `https://bhaktiangan.com/` or your Instagram

> **Domain:** the brand is moving to **bhaktiangan.com** as the canonical site,
> with **bhaktiangan.in** 301-redirecting to it. Use `.com` URLs everywhere in
> App Store Connect (privacy, terms, support, marketing) and the
> `support@bhaktiangan.com` mailbox. Do not submit until that mailbox is live and
> `bhaktiangan.com` resolves. See "Domain migration" below.

## Pricing — country-specific (not currency conversion)

Set "India" deliberately low for volume; keep Tier-1 markets at standard psych
pricing. App Store Connect lets you set a base price and then override per
territory. Suggested launch prices:

| Plan | USD (US/UK/EU/CA/AU) | India (INR) | Notes |
| --- | --- | --- | --- |
| Pro Monthly | $4.99 | ₹149 | Impulse tier |
| Pro Annual | $29.99 (7-day free trial) | ₹999 (7-day free trial) | Headline plan |
| Pro Lifetime | $39.99 | ₹1,499 | One-time, anchors the annual |

Also lower for other price-sensitive, high-Hindu-population storefronts:
Nepal, Indonesia, Philippines, Sri Lanka, Bangladesh, UAE (mixed) — start near
the India tier and adjust after you see conversion.

Rationale: the annual trial is the headline; lifetime at ~1.3× the annual makes
the annual feel like the easy choice while still capturing one-time buyers.

## App Review notes (paste into "Notes")

```
The app has a Free tier and a StoreKit 2 Pro tier. Free includes the daily
darshan, the first 12 darshan images, three japa mantras, and the Panchang
(Choghadiya) page. Pro unlocks the full darshan library and all mantras via
auto-renewable subscriptions (monthly, annual with a 7-day free trial) and a
non-consumable Lifetime. Terms of Use and Privacy Policy links appear on the
paywall and in Settings. No account or login is required.

The app is fully bilingual (English / Hindi) — toggle in Settings or the top of
the Home screen. The Panchang feature can use location for accurate sunrise; it
is optional (a city picker is offered) and used only on-device — nothing is
transmitted, so App Privacy is "Data Not Collected." A local StoreKit
configuration is included for development; production uses the product IDs in
App Store Connect. All artwork is original devotional art created for this app.
```

## Screenshots to upload

Apple requires the **6.9" iPhone** set — **1320 × 2868**. (A 6.5" set is optional;
App Store Connect auto-scales the 6.9" set down for smaller devices.)

**Fresh captures are ready in `Docs/Screenshots/v1/`** — 6 shots, exactly
1320 × 2868, from the current build (teal theme, Panchang, bilingual):

| File | Screen | Suggested caption |
| --- | --- | --- |
| 01-today.png | Today — live date, Panchang card, darshan | A calm start to every day |
| 03-japa.png | Japa counter | Chant with a calm mala counter |
| 02-darshan.png | Darshan library | A growing sacred collection |
| 05-paywall.png | Pro paywall | Start 7 days free (also the IAP review screenshot) |
| 06-today-dark.png | Today in dark mode | Beautiful in light or dark |
| 04-settings.png | Settings — language + theme | English & हिंदी, light or dark |

Upload them in that order (darshan first, settings last). Captions are optional —
the raw shots are acceptable; add captions later for polish. Do NOT bake prices
into caption artwork (they vary by region). The promo-video plan is in
`Docs/POST_LAUNCH_PLAYBOOK.md`.
```
