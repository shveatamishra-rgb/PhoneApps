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
- **Subtitle** (max 30): `Hindu Gods, Mantra & Japa` — 25 chars ✅

## Keywords (max 100 chars, comma-separated, NO spaces)

Do not repeat words already in the name/subtitle (Apple indexes those
separately). This field focuses on deity names and adjacent intents:

```
shiva,krishna,ganesha,ram,hanuman,devi,lakshmi,saraswati,puja,aarti,wallpaper,prayer,om,temple,chalisa
```
(~100 chars — trim if App Store Connect flags it; "bhakti/darshan/mantra/japa" are already in the name/subtitle so they're omitted here)

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

Terms of Use: https://bhaktiangan.in/terms-of-use/
Privacy Policy: https://bhaktiangan.in/privacy-policy/

Made with devotion. Jai Shri Mahadev 🙏
```

> Host the privacy/terms pages on `bhaktiangan.in` (see `Docs/WEBSITE.md`). Use
> the Privacy URL in App Store Connect's App Privacy section and the app's
> Privacy Policy field.

## What's New (version 1.0)

```
Namaste and welcome to Bhakti Angan 🙏
• A new daily darshan with mantra, meaning, and blessing
• A calm japa counter with a daily streak
• Light and dark themes
• Save darshans as wallpapers, mark favorites, and set a gentle daily reminder
```

## App information

- **Primary category:** Lifestyle
- **Secondary category:** Health & Fitness (or Reference)
- **Age rating:** 4+ (complete the questionnaire; no objectionable content)
- **Bundle ID:** `in.bhaktiangan.app`
- **Privacy "Data Not Collected":** declare no data collection (matches the
  privacy manifest and `Docs/PRIVACY_POLICY.md`)
- **Support URL:** `https://bhaktiangan.in/` (lists the brand email)
- **Support email:** set up `hello@bhaktiangan.in` on Hostinger (preferred), or
  keep the existing working gmail until then — the app/legal pages must point to
  a mailbox you actually monitor
- **Marketing URL (optional):** `https://bhaktiangan.in/` or your Instagram

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
darshan, the first set of darshan images, and three japa mantras. Pro unlocks
the full darshan library and all mantras via auto-renewable subscriptions
(monthly, annual with a 7-day free trial) and a non-consumable Lifetime.
Terms of Use and Privacy Policy links appear on the paywall and in Settings.
No account or login is required. A local StoreKit configuration is included for
development; production uses the product IDs in App Store Connect.
All artwork is original devotional art created for this app.
```

## Screenshots to upload

Apple now requires only the **6.9" iPhone** set (1290 × 2796). A 6.5" set is
optional. Capture 5–6, in this order, with a short caption baked into each:

1. Today / daily darshan — caption "A new darshan every day"
2. Japa counter — "Chant with a calm mala counter"
3. Darshan library — "A growing sacred collection"
4. Pro paywall — "Start 7 days free" (do NOT bake a price in; it varies by region)
5. Dark mode home — "Beautiful in light or dark"
6. Reminder/Settings — "One gentle daily reminder"

Capture commands and the promo-video plan are in
`Docs/POST_LAUNCH_PLAYBOOK.md`.
```
