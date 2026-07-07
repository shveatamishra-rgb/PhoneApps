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

v1.1 (current):

```
New: Daily Darshan and Choghadiya widgets, katha with meaning, and a living gallery of 60+ divine artworks that grows with every festival.
```

v1.0 (previous, for history):

```
Begin each day with a peaceful darshan, a simple mantra, and one quiet minute of devotion. Fresh deity images and festival collections are added over time.
```

## Description (max 4000) — v1.1

Notes on this revision: adds WIDGETS / LIVING GALLERY / KATHA sections; the Pro
block now matches the redesigned paywall exactly (the old "unlimited wallpaper
saves" claim is GONE, wallpaper saves were never gated); all em dashes removed
per the copy rule.

```
Bhakti Angan, your courtyard of devotion. A calm daily moment with the divine
on your iPhone: a beautiful darshan, a simple mantra, and one quiet minute of
stillness.

Open the app each morning to a new sacred darshan with its mantra, meaning, and
a short blessing. Sit with it for a minute, chant on the japa counter, and carry
a little peace into your day.

• DAILY DARSHAN
A rotating sacred image each day with mantra, meaning, and blessing. A gentle
ritual you can keep in under a minute.

• HOME & LOCK SCREEN WIDGETS (NEW)
The Daily Darshan widget brings each morning's deity straight to your home and
lock screen. The Choghadiya widget shows the current muhurat and when the next
one begins, changing on its own through the day.

• A LIVING GALLERY (NEW)
A growing collection of 60+ original devotional artworks: Krishna's leelas,
Shiva's cosmic forms, Ganesha, Shri Ram, Hanuman, Vishnu's avatars, and the
Devi in her many forms. New art arrives by itself with the festivals, no app
update needed.

• KATHA (NEW)
Timeless sacred stories in English and Hindi, each with a moral for daily life.

• JAPA COUNTER
A calm, distraction-free mala counter with goals from 27 up to 10,000, soft
haptics, and a daily streak that grows as you return.

• AAJ KA PANCHANG (CHOGHADIYA)
Today's auspicious and inauspicious windows: Shubh, Amrit, Labh, Char, Udveg,
Rog, and Kaal, with sunrise and sunset for your city. Calculated on your device.

• ENGLISH & हिंदी
Every screen and every mantra (in Devanagari) switches between English and
Hindi with one tap.

• SAVE & SHARE
Keep any darshan as a wallpaper, mark favorites, and share blessings with family.

• QUIET REMINDERS
One gentle daily reminder at the time you choose. No noise, no feed.

• YOURS, PRIVATELY
No account, no ads, no tracking. Your favorites, streak, and japa count stay on
your device.

BHAKTI ANGAN PRO
The complete collection of the gods, growing with every festival:
• The full darshan library (60+ artworks) and every deity mantra for japa
• Every katha, with meaning
• Widgets that draw on the complete collection
• New festival art that arrives by itself
• All future Pro features, included at no extra cost
Free for 7 days on the annual plan, then it renews at the listed price. Monthly
and a one-time Lifetime option are also available. Payment is charged to your
Apple account. Subscriptions renew automatically unless cancelled at least 24
hours before the period ends; manage or cancel any time in your Apple account
settings.

Terms of Use: https://bhaktiangan.com/terms-of-use/
Privacy Policy: https://bhaktiangan.com/privacy-policy/

Made with devotion. Jai Shri Mahadev 🙏
```

> Host the privacy/terms pages on `bhaktiangan.com` (canonical) — `.in` 301s to
> `.com`. Use the Privacy URL in App Store Connect's App Privacy section and the
> app's Privacy Policy field. See `Docs/DOMAIN_MIGRATION.md`.

## What's New (version 1.1) — paste this one

```
A new home for daily darshan.
• Daily Darshan widget: a fresh darshan on your home and lock screen every morning
• Choghadiya widget: the current muhurat, live through the day
• Katha: sacred stories with a moral, in English and Hindi
• A living gallery of 60+ devotional artworks that grows with every festival, no update needed
• A refreshed Pro: every future Pro feature included, at no extra cost
```

## What's New (version 1.0)

```
Namaste and welcome to Bhakti Angan 🙏
• A new daily darshan with mantra, meaning, and blessing
• Aaj Ka Panchang — today's Choghadiya windows for your city
• A calm japa counter with a daily streak
• Full English & Hindi (हिंदी), with light and dark themes
• Save darshans as wallpapers, mark favorites, and set a gentle daily reminder
```

## Hindi localization (App Store Connect → Hindi)

You are already uploading Hindi screenshots, so fill the Hindi text fields too;
they index for the India storefront alongside English.

- **Subtitle** (max 30): `देवी-देवता, मंत्र और पंचांग`
- **Keywords** (max 100, no spaces after commas):

```
चौघड़िया,मुहूर्त,जप,भजन,आरती,पूजा,शिव,कृष्ण,गणेश,राम,हनुमान,देवी,वॉलपेपर,मंदिर
```

- **Promotional text** (max 170):

```
नया: दैनिक दर्शन और चौघड़िया विजेट, अर्थ सहित कथाएँ, और 60+ दिव्य कलाकृतियों की जीवंत दीर्घा, जो हर पर्व पर और भी बढ़ती है।
```

- **What's New (1.1):** the HI block in `MARKETING_CALENDAR_2026.md` (line "दैनिक दर्शन का नया घर…").
- **Description**:

```
भक्ति आँगन, आपकी भक्ति का आँगन। आपके iPhone पर प्रभु के साथ एक शांत दैनिक क्षण:
सुंदर दर्शन, सरल मंत्र, और एक मिनट की स्थिरता।

हर सुबह ऐप खोलते ही एक नया पावन दर्शन मिलता है, मंत्र, अर्थ और आशीर्वाद के साथ।
एक मिनट उसके साथ बैठिए, जप कीजिए, और दिन भर के लिए थोड़ी शांति साथ ले जाइए।

• दैनिक दर्शन
हर दिन एक नया पावन चित्र, मंत्र, अर्थ और आशीर्वाद के साथ। एक कोमल नित्य नियम,
एक मिनट से भी कम में।

• होम और लॉक स्क्रीन विजेट (नया)
दैनिक दर्शन विजेट हर सुबह के देव के दर्शन सीधे आपकी होम और लॉक स्क्रीन पर लाता है।
चौघड़िया विजेट अभी का मुहूर्त और अगले मुहूर्त का समय दिखाता है, और दिन भर अपने
आप बदलता रहता है।

• जीवंत दीर्घा (नया)
60+ मूल भक्ति कलाकृतियों का बढ़ता संग्रह: कृष्ण की लीलाएँ, शिव के रूप, गणेश,
श्री राम, हनुमान, विष्णु के अवतार, और देवी के अनेक रूप। नई कला पर्व के साथ अपने
आप आती है, बिना किसी ऐप अपडेट के।

• कथा (नया)
कालजयी पावन कथाएँ, हिंदी और अंग्रेज़ी में, हर कथा में जीवन के लिए एक सीख।

• जप गणक
27 से 10,000 तक के लक्ष्य, कोमल हैप्टिक्स और दैनिक स्ट्रीक के साथ एक शांत,
ध्यान भटकाए बिना चलने वाला माला गणक।

• आज का पंचांग (चौघड़िया)
आज के शुभ और अशुभ मुहूर्त: शुभ, अमृत, लाभ, चर, उद्वेग, रोग और काल, आपके शहर के
सूर्योदय और सूर्यास्त के साथ। गणना आपके डिवाइस पर ही होती है।

• अंग्रेज़ी और हिंदी
हर स्क्रीन और हर मंत्र (देवनागरी में) एक टैप में अंग्रेज़ी और हिंदी के बीच बदल
जाता है।

• सहेजें और साझा करें
कोई भी दर्शन वॉलपेपर के रूप में रखें, पसंदीदा चुनें, और परिवार के साथ आशीर्वाद
साझा करें।

• कोमल स्मरण
आपके चुने समय पर दिन में एक कोमल रिमाइंडर। न शोर, न फ़ीड।

• पूरी तरह निजी
न खाता, न विज्ञापन, न ट्रैकिंग। आपकी पसंद, स्ट्रीक और जप गिनती आपके डिवाइस पर
ही रहती है।

भक्ति आँगन प्रो
देवताओं का संपूर्ण संग्रह, हर पर्व के साथ बढ़ता हुआ:
• पूरी दर्शन लाइब्रेरी (60+ कलाकृतियाँ) और जप के लिए हर मंत्र
• हर कथा, अर्थ सहित
• संपूर्ण संग्रह के साथ विजेट
• पर्व की नई कला, जो अपने आप आती है
• भविष्य की सभी प्रो सुविधाएँ, बिना किसी अतिरिक्त शुल्क के
वार्षिक योजना पर 7 दिन नि:शुल्क, फिर सूचीबद्ध मूल्य पर नवीनीकरण। मासिक और एक
बार का लाइफ़टाइम विकल्प भी उपलब्ध हैं। भुगतान आपके Apple खाते से लिया जाता है।
अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न करने पर सदस्यता अपने आप
नवीनीकृत हो जाती है; प्रबंधन या रद्द करना Apple खाता सेटिंग्स में किसी भी समय
संभव है।

उपयोग की शर्तें: https://bhaktiangan.com/terms-of-use/
गोपनीयता नीति: https://bhaktiangan.com/privacy-policy/

भक्ति से बनाया गया। जय श्री महादेव 🙏
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

New in 1.1: two widgets (Daily Darshan and Choghadiya) fed by the app through
an App Group; they work without the app running and use no network. The app
also fetches optional new artwork from our own website (bhaktiangan.com) via a
plain GET with no identifiers, so App Privacy remains "Data Not Collected."
The Katha tab content is bundled in the binary.
```

## Screenshots to upload (v1.1 sets)

The current panels are **1290 × 2796**, which is a valid **6.9" iPhone** size
(Apple accepts 1290 × 2796 or 1320 × 2868 there). IMPORTANT: upload them via
**"View All Sizes in Media Manager" → iPhone 6.9" Display**. Do NOT drop them
into the 6.5" slot on the version page (that slot wants 1242 × 2688 / 1284 × 2778
and rejects these files). Leave 6.5" empty; it inherits the 6.9" set.

- English (U.S.) localization: `AppStore/v1.1/en/` files 01 → 05, in order.
- Hindi localization: `AppStore/v1.1/hi/` files 01 → 05, in order.

Upload order = display order on the store page. Delete the old v1.0 shots from
each localization first. No prices are baked into any panel. (The old v1.0 raw
captures remain in `Docs/Screenshots/v1/` for history.)
```
