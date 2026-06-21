# App Store Metadata — ready to paste

Everything below is final copy for App Store Connect. Nothing here is wired into
the binary, so you can tune it any time without a new build. Character limits are
Apple's; counts are noted so you stay inside them.

## Name & subtitle (App Store search weighs these most)

Market research note: "Divine Stillness Om" is **not used by any existing App
Store app or competing brand**, so it is safe and consistent with your
Instagram/YouTube/Facebook handles — keep the brand. The niche (Sri Mandir,
DevDham, Dharmayana, Mandir Darshan) is competitive and the word "Stillness"
alone skews toward Christian meditation apps, so we win discovery by putting the
high-intent Hindu keyword **Darshan** into the title and packing the subtitle.

- **App Name** (max 30): `Divine Stillness Om: Darshan` — 28 chars ✅
  - Pure-brand alternative: `Divine Stillness Om` (19)
- **Subtitle** (max 30): `Hindu Gods, Mantra & Japa` — 25 chars ✅

## Keywords (max 100 chars, comma-separated, NO spaces)

Do not repeat words already in the name/subtitle (Apple indexes those
separately). This field focuses on deity names and adjacent intents:

```
shiva,krishna,ganesha,ram,hanuman,devi,lakshmi,bhakti,puja,aarti,wallpaper,prayer,om,temple,chalisa
```
(99 chars ✅)

## Promotional text (max 170 — editable any time without review)

```
Begin each day with a peaceful darshan, a simple mantra, and one quiet minute of devotion. Fresh deity images and festival collections are added over time.
```

## Description (max 4000)

```
Divine Stillness Om brings a calm, daily moment of devotion to your iPhone —
a beautiful darshan, a simple mantra, and one quiet minute of stillness.

Open the app each morning to a new sacred darshan with its mantra, meaning, and
a short blessing. Sit with it for a minute, chant on the japa counter, and carry
a little peace into your day.

• DAILY DARSHAN
A rotating sacred image each day with mantra, meaning, and blessing — a gentle
ritual you can keep in under a minute.

• JAPA COUNTER
A calm, distraction-free mala counter with 27, 54, and 108 goals, soft haptics,
and a daily darshan streak that grows as you return.

• MANY DEITIES
Shiva, Ganesha, Krishna, Radha-Krishna, Ram, Hanuman, Vishnu, Lakshmi, Durga,
Kali, Saraswati, Balaji, Narasimha, and more — with their mantras for japa.

• SAVE & SHARE
Keep any darshan as a wallpaper, mark favorites, and share blessings with family.

• QUIET REMINDERS
Choose a morning or evening time for one gentle daily reminder. No noise, no feed.

• YOURS, PRIVATELY
No account, no ads, no tracking. Your favorites, streak, and japa count stay on
your device.

DIVINE STILLNESS PRO
Unlock the complete darshan library, every deity mantra, unlimited wallpaper
saves, and future festival collections.
• Free for 7 days on the annual plan, then it renews at the listed price.
• Monthly and a one-time Lifetime option are also available.
Payment is charged to your Apple account. Subscriptions renew automatically
unless cancelled at least 24 hours before the period ends; manage or cancel any
time in your Apple account settings.

Terms of Use: https://shveatamishra-rgb.github.io/PhoneApps/divine-stillness/terms
Privacy Policy: https://shveatamishra-rgb.github.io/PhoneApps/divine-stillness/privacy

Made with devotion. Jai Shri Mahadev 🙏
```

> The Terms/Privacy URLs above assume GitHub Pages hosting from the repo (see
> `Docs/POST_LAUNCH_PLAYBOOK.md`). Swap them if you host elsewhere.

## What's New (version 1.0)

```
Namaste and welcome to Divine Stillness Om 🙏
• A new daily darshan with mantra, meaning, and blessing
• A calm japa counter with a daily streak
• Light and dark themes
• Save darshans as wallpapers, mark favorites, and set a gentle daily reminder
```

## App information

- **Primary category:** Lifestyle
- **Secondary category:** Health & Fitness (or Reference)
- **Age rating:** 4+ (complete the questionnaire; no objectionable content)
- **Bundle ID:** `com.shveatamishra.divinestillness`
- **Privacy "Data Not Collected":** declare no data collection (matches the
  privacy manifest and `Docs/PRIVACY_POLICY.md`)
- **Support URL:** GitHub Pages support page (or a simple page that lists the
  brand email `divine.stillness.om@gmail.com`)
- **Marketing URL (optional):** your Instagram or a link-in-bio page

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
