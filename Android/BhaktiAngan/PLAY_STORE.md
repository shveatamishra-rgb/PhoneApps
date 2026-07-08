# Bhakti Angan — Google Play submission runbook

App: **Bhakti Angan**  ·  applicationId **in.bhaktiangan.app**  ·  versionCode 1 / versionName 1.0
Package (Kotlin): `app.bhaktiangan`  ·  minSdk 24, targetSdk 36

Generated assets live in `store-assets/`:
- `play-icon-512.png` — 512×512 app icon for the listing
- `feature-graphic-1024x500.png` — feature graphic

---

## 0. Prerequisites (you do these)
- A **Google Play Developer account** ($25 one-time). Console: https://play.google.com/console
- ⚠️ **New personal developer accounts** (created after Nov 2023) must run **closed testing with ≥12 testers for 14 days** before they can request production access. Plan for this: start a Closed Testing track first. (Organisation accounts are exempt.)
- Privacy policy URL (live): https://bhaktiangan.com/privacy-policy/
- Support email: support@bhaktiangan.com

## 1. Create the upload key + signed AAB
We use **Play App Signing** (Google holds the app signing key; you hold the *upload* key).

```
cd Android/BhaktiAngan
keytool -genkeypair -v -keystore bhaktiangan-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# choose + record the passwords; keep the .jks safe (it is gitignored)

cp keystore.properties.template keystore.properties
# edit keystore.properties: set storePassword / keyPassword (storeFile=bhaktiangan-upload.jks, keyAlias=upload)

export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :app:bundleRelease
# signed AAB -> app/build/outputs/bundle/release/app-release.aab
```
(Without `keystore.properties` the build still produces an *unsigned* AAB — fine for testing, not for upload.)

## 2. Create the app in Play Console
- App name: **Bhakti Angan**  ·  Default language: English (US)  ·  App, Free
- Declarations: contains ads = **No**; this is not a game.

## 3. Main store listing
- **App name:** Bhakti Angan
- **Short description (≤80):**
  `Daily darshan, mantras, japa counter and accurate Panchang for your city.`
- **Full description:** see `STORE_DESCRIPTION_EN` below (add Hindi listing too — `STORE_DESCRIPTION_HI`).
- **App icon:** `store-assets/play-icon-512.png`
- **Feature graphic:** `store-assets/feature-graphic-1024x500.png`
- **Phone screenshots:** 2–8 required (1080×1920 or similar 9:16). Capture from the app: Home/Today, Darshan gallery, a Darshan detail, Japa, Panchang, Settings. (I can grab these via adb if a device is connected.)
- **Category:** Lifestyle  ·  **Tags:** devotional, Hindu, Panchang
- Contact details: support@bhaktiangan.com  ·  Privacy policy: https://bhaktiangan.com/privacy-policy/

## 4. In-app products (must match the app's product IDs exactly)
From `core/billing/BillingManager.kt`:
| Product ID | Type | Notes |
|---|---|---|
| `pro_monthly` | Subscription | base plan, auto-renew monthly |
| `pro_yearly` | Subscription | base plan + a **7-day free-trial** offer |
| `pro_lifetime` | One-time in-app product | non-consumable, lifetime unlock |

Suggested base prices (Play auto-converts per country; set INR for India): Monthly ~$4.99, Yearly ~$29.99, Lifetime ~$39.99. Activate all three. Until they exist + are active, the paywall shows fallback prices and shows a "store release" notice instead of launching purchase.

## 5. Data safety
- **No data collected, no data shared.** Favorites, japa, reminders and the chosen city are stored **on-device** (DataStore). Location (coarse) is used **only on-device** for Panchang and is never uploaded. Purchases are handled by Google Play.
- Security: data encrypted in transit = N/A (no data leaves the device); users can request deletion = data is local and cleared on uninstall.

## 6. Content rating, audience, etc.
- Content rating (IARC questionnaire): devotional content → **Everyone / 3+**.
- Target audience: adults + teens (not directed at children → **not** "Made for families").
- Ads: No. News: No. COVID-19 contact tracing: No. Government app: No.

## 7. Countries & release
- Pricing: **Free** app. Distribution: India + worldwide (your choice).
- Start with **Closed testing** (see prerequisite gate), then promote to **Production**.
- Upload `app-release.aab`, add release notes, review, roll out.

---

## STORE_DESCRIPTION_EN
Bhakti Angan is your daily courtyard of devotion: a calm, beautiful space for a few quiet minutes with the divine, every day.

Open the app each morning for a fresh darshan aligned to the day's deity, say a simple mantra, count your japa, and check an accurate Panchang for your own city. Everything works offline and stays private on your device.

DAILY DARSHAN
• A new sacred darshan every day, in HD devotional art
• Save any darshan as your phone wallpaper
• A growing gallery of Shiva, Krishna, Radha Krishna, Shri Ram, Hanuman, Ganesha, Lakshmi, Durga, Saraswati, Vishnu, Balaji and more

MANTRA & JAPA
• Simple mantras with meaning for each deity
• A built-in japa counter with a daily goal and streak
• Gentle, distraction-free design

ACCURATE PANCHANG
• Aaj ka Panchang for your exact city: tithi, nakshatra, yoga, karana
• Sunrise, sunset and the Choghadiya for day and night
• Rahu Kaal, Gulika, Yamaganda and the Abhijit shubh muhurat
• Calculated on your device for any city in India and worldwide

CALM BY DESIGN
• Bilingual: English and हिन्दी
• Light and dark themes
• A daily darshan reminder you can set to any time
• No ads, no clutter, no noise

PRIVATE BY DEFAULT
• Your favorites, japa and reminders stay on your device
• Location is used only on-device for the Panchang and is never uploaded
• No tracking, no data collection

BHAKTI ANGAN PRO
Unlock the complete darshan library, unlimited wallpaper saves, every deity mantra, custom reminders and new festival collections. Available as a monthly or annual subscription (with a free trial) or a one-time lifetime purchase. Subscriptions are billed through Google Play and renew automatically unless cancelled.

Har din bhakti, har mann shanti. 🙏

## STORE_DESCRIPTION_HI
भक्ति आँगन आपकी रोज़ की भक्ति का आँगन है: हर दिन कुछ शांत पलों के लिए एक सुंदर, शांत स्थान, भगवान के साथ।

हर सुबह ऐप खोलिए और दिन के देवता के अनुसार एक नया दर्शन पाइए, एक सरल मंत्र बोलिए, अपनी जप गिनती कीजिए, और अपने शहर का सटीक पंचांग देखिए। सब कुछ ऑफ़लाइन चलता है और आपके फ़ोन पर ही निजी रहता है।

रोज़ का दर्शन
• हर दिन एक नया पावन दर्शन, HD भक्ति कला में
• किसी भी दर्शन को अपना वॉलपेपर बनाइए
• शिव, कृष्ण, राधा कृष्ण, श्री राम, हनुमान, गणेश, लक्ष्मी, दुर्गा, सरस्वती, विष्णु, बालाजी और अनेक देवताओं का संग्रह

मंत्र और जप
• हर देवता के लिए अर्थ सहित सरल मंत्र
• दैनिक लक्ष्य और स्ट्रिक के साथ जप काउंटर
• शांत, ध्यान भटकाव रहित डिज़ाइन

सटीक पंचांग
• आपके शहर का आज का पंचांग: तिथि, नक्षत्र, योग, करण
• सूर्योदय, सूर्यास्त और दिन-रात का चौघड़िया
• राहु काल, गुलिक, यमगंड और अभिजित शुभ मुहूर्त
• आपके डिवाइस पर ही गणना, भारत और दुनिया के किसी भी शहर के लिए

शांति से बना
• द्विभाषी: English और हिन्दी
• लाइट और डार्क थीम
• किसी भी समय का दैनिक दर्शन स्मरण
• कोई विज्ञापन नहीं, कोई शोर नहीं

निजता सर्वोपरि
• आपकी पसंद, जप और स्मरण आपके डिवाइस पर ही रहते हैं
• स्थान केवल पंचांग के लिए डिवाइस पर ही उपयोग होता है, कभी अपलोड नहीं होता
• कोई ट्रैकिंग नहीं, कोई डेटा संग्रह नहीं

भक्ति आँगन प्रो
संपूर्ण दर्शन संग्रह, असीमित वॉलपेपर, हर देवता के मंत्र, अनुकूलित स्मरण और नए पर्व संग्रह अनलॉक कीजिए। मासिक या वार्षिक सदस्यता (निःशुल्क परीक्षण के साथ) या एकमुश्त लाइफटाइम खरीद के रूप में उपलब्ध। बिलिंग Google Play द्वारा होती है और सदस्यता स्वतः नवीनीकृत होती है।

हर दिन भक्ति, हर मन शांति। 🙏

## SHORT_DESCRIPTION_HI (≤80)
रोज़ का दर्शन, मंत्र, जप काउंटर और अपने शहर का सटीक पंचांग।
