# Bhakti Angan — Low-Level Design (LLD) & Android Port Specification

> **Purpose.** The iOS app (`iPhone/BhaktiAngan`, SwiftUI, ~4,300 LOC across 26
> files) is the **reference implementation**. This document captures every screen,
> model, algorithm, persistence key, and business rule so the Android app can be
> rebuilt **feature-for-feature without missing a beat**. Where behaviour is
> subtle (the Panchang astronomy, the sunrise-to-sunrise "Hindu day", the free/Pro
> split, the bilingual toggle) the exact rule is written out, not summarised.
>
> **Status:** iOS v1.0 is in App Store review. Android target: a 1:1 port.
> **Reference paths** below are relative to `iPhone/BhaktiAngan/BhaktiAngan/`.

---

## 1. Product in one paragraph

A bilingual (English / Hindi) Hindu devotional app. Each day it shows a **darshan**
(a sacred image of a deity) with a mantra, meaning, and blessing, aligned to the
**weekday's deity**. It has a **japa** (mala/chant) counter with a daily streak, a
browsable **darshan library** (free + Pro), an on-device **Panchang** (tithi,
nakshatra, yoga, karana, sunrise/sunset, Choghadiya, Rahu Kaal and other muhurtas,
with date navigation), gentle daily **reminders**, **wallpaper save/share**, and a
**Pro** subscription (monthly / annual-with-trial / lifetime). Everything is
**on-device** — no account, no backend, no analytics, no tracking → App Store
privacy label is **"Data Not Collected"**, and the Android build must preserve this.

---

## 2. Architecture

**Pattern:** lightweight MVVM with observable app-wide stores injected via the
SwiftUI environment. There is **no networking layer and no database** — all state
is small key/value (UserDefaults) plus two static, in-memory datasets (the content
catalog and the bundled cities list). Pure-function "service" enums do the
computation (Panchang, astronomy).

**Five app-wide observable objects** (created in `BhaktiAnganApp`, injected as
`@EnvironmentObject`):

| Object | Role | Android equivalent |
|---|---|---|
| `AppState` | favorites, onboarding flag, selected tab, selected mantra, japa count, streaks | `AppStateViewModel` (app-scoped) backed by DataStore |
| `StoreManager` | products, entitlements, purchase/restore (StoreKit 2) | `BillingViewModel` (Play Billing v6/7) |
| `LocalizationManager` | EN/HI preference + `s(en,hi)` resolver | `LocaleViewModel` backed by DataStore |
| `AudioManager` (singleton) | optional looping ambience (ships dormant) | `AudioController` (ExoPlayer/MediaPlayer) |
| `LocationManager` (singleton) | GPS or manual city for Panchang | `LocationController` (FusedLocationProvider) |

**Layering for Android (recommended packages under `in.bhaktiangan.app`):**

```
app/            — Application, MainActivity, NavHost, theme wiring
core/model/     — DevotionalItem, MantraChoice, DeityCategory, City, Panchang*
core/data/      — ContentCatalog, PanchangNames, Cities loader, DataStore repos
core/panchang/  — Astronomy, PanchangCalculator  (pure Kotlin, unit-tested)
core/billing/   — BillingViewModel + Play Billing wrapper
core/location/  — LocationController
core/notify/    — ReminderScheduler (AlarmManager)
core/media/     — WallpaperSaver, AudioController
feature/onboarding, feature/home, feature/library, feature/japa,
feature/panchang, feature/settings, feature/paywall, feature/support
designsystem/   — Theme (colors/typography), shared composables
```

---

## 3. Tech-stack mapping (iOS → Android)

| iOS | Android |
|---|---|
| SwiftUI | Jetpack Compose + Material 3 |
| `@StateObject`/`@EnvironmentObject`/`ObservableObject`/`@Published` | `ViewModel` + `StateFlow`, hoisted to a `NavHost`/`CompositionLocal` |
| `@AppStorage` / `UserDefaults` | **Preferences DataStore** (one repo per concern) |
| `NavigationStack` / `TabView` | `NavHost` + `NavigationBar` (bottom bar) |
| `.sheet` | `ModalBottomSheet` / dialog destinations |
| StoreKit 2 (`Product`, `Transaction`, entitlements) | **Play Billing Library** (`ProductDetails`, `Purchase`, `queryPurchasesAsync`) |
| CoreLocation `CLLocationManager` | `FusedLocationProviderClient` (Play Services Location) |
| `UNUserNotificationCenter` repeating calendar trigger | `AlarmManager.setRepeating`/exact alarm + `NotificationCompat` (or daily `WorkManager`) |
| `PHPhotoLibrary` add wallpaper | `MediaStore.Images` insert (scoped storage; no permission needed on API 29+) |
| `AVAudioPlayer` loop | `ExoPlayer`/`MediaPlayer` looping |
| `UIActivityViewController` share | `Intent.ACTION_SEND` (image + text) chooser |
| Asset catalog imagesets | `res/drawable-nodpi` (or `assets/`) WebP images |
| `NSDataAsset("cities")` JSON | `assets/cities.json` parsed with kotlinx-serialization off the main thread |
| Dynamic light/dark `UIColor` | Material 3 light/dark `ColorScheme` |
| `Bundle.main` version | `BuildConfig.VERSION_NAME` / `VERSION_CODE` |
| `MFMailComposeViewController` / `mailto:` | `Intent.ACTION_SENDTO` `mailto:` |
| `requestReview` (SKStoreReviewController) | Play In-App Review API |

**Recommended Android baseline:** Kotlin, Jetpack Compose (BOM), Material 3,
minSdk **24**, targetSdk current, single-activity, `ViewModel` + `StateFlow`,
Preferences DataStore, Play Billing 7, Play Services Location, kotlinx-serialization.
applicationId **`in.bhaktiangan.app`** (mirror the iOS bundle id).

---

## 4. Data models  (`Models/DevotionalContent.swift`, `Models/…`, `Data/Cities.swift`)

### Lang & localization helper
- `enum Lang { en, hi }`. Every content model exposes `field(_ l: Lang)` accessors
  returning the EN or HI string. **Port:** Kotlin `enum class Lang { EN, HI }` and
  `fun deity(l: Lang)` style accessors, OR a `BiText(en, hi)` value class.

### DevotionalItem
```
day:Int, imageName:String (= id), deityEN/HI, category:DeityCategory,
mantraEN/HI, meaningEN/HI, blessingEN/HI, isPremium:Bool
```
- `shareText(l)` = `deity\n\nmantra\n\nblessing\n\n` + footer
  (EN "Shared from Bhakti Angan" / HI "भक्ति आँगन से साझा किया गया").

### MantraChoice
```
id:String, deityEN/HI, mantraEN/HI, meaningEN/HI, isPremium:Bool
```
Used by the Japa screen + the daily "Begin Japa" handoff.

### DeityCategory (enum, raw EN string + HI map)
`all("All"/सभी), shiva(Shiva/शिव), vishnu(Vishnu/विष्णु), shakti(Devi/देवी),
rama(Rama/राम), krishna(Krishna/कृष्ण), ganesha(Ganesha/गणेश)`. `label(l)`.

### City  (`Data/Cities.swift`)
```
id, nameEN, nameHI, regionEN, latitude, longitude, timeZoneID
```
- Decoded from a **positional JSON array** `[id, name, region, lat, lon, tz]`
  (name is used for both EN and HI — place names stay romanized).
- `tzSeconds(for date)` = UTC offset incl. DST for that date (use
  `TimeZone.getTimeZone(timeZoneID).getOffset(epochMillis)/1000` on Android).
- `Cities.all` = decode `cities.json` once (sorted by population, largest first).
- `Cities.byID(id)`, `Cities.search(query, limit=50)` — **name-prefix matches first**,
  then name/region "contains", capped at `limit`, case-insensitive.

---

## 5. Content catalog  (`Data/ContentCatalog.swift`) — business rules

- **`templates`**: a dictionary keyed by **slug** (19 unique deities) → all the
  bilingual copy (deity, mantra, meaning, blessing, category). Full table is in
  §5.1. Hindi devotional copy is an authored draft (flagged for review).
- **`slugs`**: an array of **60** entries that *repeats* the 19 slugs in a fixed
  rotation (so `day1..day60` each map to a slug). `imageName = "day{index+1}_{slug}"`.
- **`removedImageNames`** (Set): images pulled after iconography review — skipped
  when building items. **Port this set verbatim** (9 entries):
  `day12_venkateshwar_swami, day16_maa_kali, day35_maa_kali, day54_maa_kali,
  day13_balaji, day32_balaji, day51_balaji, day11_vaishno_devi, day30_vaishno_devi`.
- **`items`**: built by walking `slugs`, skipping removed names, assigning
  `day = index+1`. **`isPremium = (position >= freeDarshanCount)`** where
  position is the index *into the surviving list* (NOT the day number) — so pulling
  an image never changes how many are free.
- **`freeDarshanCount = 12`** — first 12 surviving darshans are always free.
- **`mantraChoices`**: one per template (19), sorted by `deityEN`.
  `isPremium = id ∉ {shiv, ganesh, krishna}` (those 3 are the free japa mantras /
  onboarding choices).
- **`dailyItem(for date, hasPro)`** — the Home hero selector:
  1. pool = `hasPro ? items : items.prefix(12)` (free users never see Pro art as the daily hero).
  2. weekday = `Calendar.weekday - 1` (0=Sunday).
  3. `keywords = weekdayDeity[weekday]`; `matches = pool.filter { imageName contains any keyword }`.
  4. if matches: `week = ordinality(.weekOfYear, in:.year)`; return `matches[(week-1) % matches.count]`
     → **same weekday stays on its deity but the image advances each week**.
  5. fallback (shouldn't happen): `day = ordinality(.day,in:.year)`; `pool[(day-1)%count]`.
- **`weekdayDeity`** (0=Sun): `0:[shri_ram], 1:[shiv], 2:[hanuman], 3:[ganesh],
  4:[vishnu], 5:[vaishno_devi, saraswati], 6:[hanuman]`
  (Sun Ram · Mon Shiva · Tue Hanuman · Wed Ganesha · Thu Vishnu · Fri Devi · Sat Hanuman).
  > NOTE: keyword match is substring-on-imageName, e.g. `"hanuman"` matches
  > `dayN_shri_hanuman`. Keep the keyword list, not the slug list.

### 5.1 Template table (slug → EN deity · category · EN mantra)
`shiv` Lord Shiva·Shiva·Om Namah Shivaya · `ganesh` Lord Ganesha·Ganesha·Om Gan Ganapataye Namah ·
`shiv_parivar` Shiv Parivar·Shiva·Om Uma Maheshwaraya Namah · `krishna` Lord Krishna·Krishna·Hare Krishna Hare Rama ·
`radha_krishna` Radha Krishna·Krishna·Radhe Radhe · `shri_ram` Shri Ram·Rama·Shri Ram Jai Ram Jai Jai Ram ·
`shri_ram_parivar` Ram Darbar·Rama·Jai Siya Ram · `shri_hanuman` Shri Hanuman·Rama·Om Hanumate Namah ·
`vishnu` Lord Vishnu·Vishnu·Om Namo Narayanaya · `vishnu_lakshmi` Vishnu Lakshmi·Vishnu·Om Lakshmi Narayanaya Namah ·
`vaishno_devi` Mata Vaishno Devi·Devi·Jai Mata Di · `venkateshwar_swami` Venkateshwar Swami·Vishnu·Om Namo Venkatesaya ·
`balaji` Lord Balaji·Vishnu·Govinda Govinda · `shiv_ling` Shiv Ling·Shiva·Om Namah Shivaya ·
`saraswati_mata` Saraswati Mata·Devi·Om Aim Saraswatyai Namah · `maa_kali` Maa Kali·Devi·Om Krim Kalikayai Namah ·
`brahma` Lord Brahma·Vishnu·Om Brahmane Namah · `narsimha` Lord Narasimha·Vishnu·Om Namo Bhagavate Narasimhaya ·
`prahlad_and_narsimha` Prahlad and Narasimha·Vishnu·Om Namo Bhagavate Narasimhaya.
> The full HI deity/mantra/meaning/blessing strings live in `ContentCatalog.swift`
> — copy them verbatim into the Android catalog (a generated Kotlin file or a
> bundled JSON). Do not paraphrase the devotional copy.

---

## 6. The Panchang engine — **port bit-for-bit**

Three pure files: `Services/Astronomy.swift`, `Services/Panchang.swift`,
`Data/PanchangNames.swift`. No platform APIs except calendar/timezone math →
translate directly to pure Kotlin in `core/panchang/`. **Write unit tests that
compare Android output to iOS output for several dates/cities before trusting it.**

### 6.1 Astronomy (Meeus / NOAA)
- `deg = π/180`. `norm360(x)` = positive modulo 360.
- `julianDay(date)` = `epochSeconds/86400 + 2440587.5`.
- `julianDay(y,m,d)` at 0h UT: if `m≤2 {y-=1; m+=12}`; `a=⌊y/100⌋`;
  `b=2-a+⌊a/4⌋`; `JD=⌊365.25(y+4716)⌋+⌊30.6001(m+1)⌋+d+b-1524.5`.
- `julianCentury(jd) = (jd-2451545)/36525`.
- **`sunLongitude(jd)`** (tropical, deg):
  `L0=280.46646+36000.76983 t+0.0003032 t²`;
  `M=(357.52911+35999.05029 t-0.0001537 t²)·deg`;
  `C=(1.914602-0.004817 t-0.000014 t²)sinM+(0.019993-0.000101 t)sin2M+0.000289 sin3M`;
  `Ω=(125.04-1934.136 t)·deg`; return `norm360(L0+C-0.00569-0.00478 sinΩ)`.
- **`moonLongitude(jd)`** (truncated Meeus ch.47, **35 periodic terms**):
  compute `L'`, `D`, `M(sun)`, `M'(moon)`, `F`, `E` (the full polynomials are in
  the source — copy exactly), then sum over the **35-term table**
  `(D, M, M', F, coeff×1e-6)` with the `E` correction (`×E` when |M|=1, `×E²` when
  |M|=2); return `norm360(L' + Σ/1e6)`. **Copy the 35-tuple table verbatim** from
  `Astronomy.swift` lines 62–75.
- **`ayanamsaLahiri(jd)`** = `23.85 + 0.013972 · ((jd-2451545)/365.25)`.
- **`sunriseSunset(y,m,d, lat, lon, tzSeconds) -> (sunrise, sunset)?`** — NOAA:
  computes geometric mean longitude/anomaly, eccentricity, equation of center,
  obliquity (corrected), declination, equation of time, then
  `cosHA = cos(90.833°)/(cos lat·cos δ) - tan lat·tan δ`. If `|cosHA|>1` return
  **null** (polar day/night). `HA=acos(cosHA)`; `solarNoonMin = 720 - 4·lon - eqTime
  + tzHours·60`; sunrise/sunset = `solarNoon ∓ HA·4` minutes. Build absolute instant
  from local midnight (in a `TimeZone(secondsFromGMT: tzSeconds)`) + minutes.
  Use **90.833°** zenith (includes refraction + solar radius). Copy constants exactly.

### 6.2 PanchangCalculator (`Services/Panchang.swift`)
**Result structs** (`PanchangResult`): date, city, sunrise, sunset, varaEN/HI,
`tithi/nakshatra/yoga/karana` (each a `PanchangElement {nameEN,nameHI,endsAt:Date?}`),
`dayChoghadiya[8]`, `nightChoghadiya[8]`, `rahu/gulika/yamaganda/abhijit/varaVela/
kalaVela/kalaRatri` (each a `KaalWindow {nameEN,nameHI,start,end}`), `vrat:PanchangElement?`.
`Choghadiya {nameEN,nameHI,start,end,quality(good/neutral/bad),isDay}` with
`contains(date)` and `currentChoghadiya(at:)` = first window containing the instant.

**`computeForInstant(now, city)`** — picks the **sunrise-to-sunrise Hindu day**:
compute today; if `now < today.sunrise`, recompute for `now - 24h` (so the live
"right now" stays correct before sunrise). This is what the Home card + "Right now"
banner use.

**`compute(for date, city)`** steps:
1. Resolve `tz`, gregorian calendar in that tz; extract `y,m,d,weekday` (0=Sunday).
2. `today = Astronomy.sunriseSunset(...)` for the date; `tomorrow` = same for date+1.
   `nextSunrise = tomorrow.sunrise ?? sunset+12h` (bounds the night Choghadiya).
3. Calendar elements **as of sunrise**: `jd=julianDay(sunrise)`, `sun=sunLongitude`,
   `moon=moonLongitude`, `ayan=ayanamsaLahiri`, `diff=norm360(moon-sun)`.
   - **Tithi**: `idx=min(29, ⌊diff/12⌋)`. Name: idx 14→Purnima, 29→Amavasya, else
     `paksha(<15 Shukla else Krishna) + tithi[idx%15]`. `endsAt` via root-find on
     `⌊norm360(moon-sun)/12⌋` over a 30h window.
   - **Nakshatra**: `idx=min(26, ⌊norm360(moon-ayan)/(360/27)⌋)`; endsAt 30h.
   - **Yoga**: `idx=min(26, ⌊norm360(sun+moon-2·ayan)/(360/27)⌋)`; endsAt 30h.
   - **Karana**: `idx=min(59, ⌊diff/6⌋)`; 0→Kimstughna, 57→Shakuni, 58→Chatushpada,
     59→Naga, else `karanaMovable[(idx-1)%7]`. endsAt over an **18h** window.
4. **`vrat`** = `PanchangNames.vrat[tithiIdx]` if present (tithi-derived parva).
5. **Choghadiya**: `dayChoghadiya = choghadiya(sunrise→sunset, startIdx=dayStartIdx[weekday], isDay=true)`;
   `nightChoghadiya = choghadiya(sunset→nextSunrise, startIdx=nightStartIdx[weekday], isDay=false)`.
6. **Kaal windows** (each = the `seg`-th eighth between sunrise & sunset):
   rahu `rahuSeg[weekday]`, gulika `gulikaSeg`, yamaganda `yamaSeg`.
7. **Segment windows**: `abhijit` = 8th of **15** equal parts sunrise→sunset;
   `varaVela` = 8th of **8** parts (sunrise→sunset); `kalaVela` = `kalaVelaSeg[weekday]`th
   of 8 (sunrise→sunset); `kalaRatri` = `kalaRatriSeg[weekday]`th of 8 (sunset→nextSunrise).

**Transition root-finding** (`transitionEnd(start, hours, index:)`): step forward in
**600 s** increments up to `hours` ahead; when the integer index changes, **bisect 24
times** between the bracketing samples; return the upper bound. Returns null if no
change in the window. Index functions recompute moon/sun/ayan at the probe instant.

**Choghadiya builder** (`choghadiya(start,end,startIdx,isDay)`): `dur=(end-start)/8`;
`step = isDay ? 1 : 5` (night advances −2 ≡ +5 mod 7); for i in 0..<8:
`idx=(startIdx+step·i)%7`; quality = good if idx∈{2,3,5} (Labh/Amrit/Shubh), neutral
if idx∈{1} (Char), else bad; window = `[start+i·dur, start+(i+1)·dur)`; name = `cycle[idx]`.

**Weekday index tables (Sun..Sat, copy verbatim):**
```
cycle (Choghadiya names) = Udveg, Char, Labh, Amrit, Kaal, Shubh, Rog   // idx 0..6
dayStartIdx   = [0, 3, 6, 2, 5, 1, 4]
nightStartIdx = [5, 1, 4, 0, 3, 6, 2]
rahuSeg       = [8, 2, 7, 5, 6, 4, 3]   // 1-based daytime eighth
gulikaSeg     = [7, 6, 5, 4, 3, 2, 1]
yamaSeg       = [5, 4, 3, 2, 1, 7, 6]
kalaVelaSeg   = [5, 2, 6, 3, 7, 4, 1]
kalaRatriSeg  = [7, 5, 8, 6, 6, 4, 7]   // verified vs DrikPanchang
goodIdx={2,3,5}  neutralIdx={1}
```

### 6.3 PanchangNames (`Data/PanchangNames.swift`)
Bilingual tables (copy verbatim): `tithi[15]` (Pratipada..Purnima), `amavasya`,
`shuklaPaksha`/`krishnaPaksha`, `nakshatra[27]`, `yoga[27]`, `karanaMovable[7]` +
`karanaShakuni/Chatushpada/Naga/Kimstughna`, `choghadiya[7]`, `vara[7]`,
`rahuKaal/gulikaKaal/yamaganda`, `abhijit/varaVela/kalaVela/kalaRatri`, and the
**`vrat: [Int:Bi]`** map keyed by tithi index 0–29:
`3 Vinayaka Chaturthi, 7 Durga Ashtami, 10 Ekadashi, 12 Pradosh Vrat, 14 Purnima,
18 Sankashti Chaturthi, 22 Kalashtami, 25 Ekadashi, 27 Pradosh Vrat,
28 Masik Shivaratri, 29 Amavasya`.

> **Accuracy note (carry to Android):** Sun/Moon longitudes ≈ arc-minute,
> sunrise/sunset ≈ 1 min. Transition *minutes* can differ slightly from a
> Swiss-Ephemeris reference; the in-app disclaimer ("confirm important muhurta with
> your local Panchang") must be ported too.

---

## 7. State & persistence  (`App/AppState.swift`, `App/LocalizationManager.swift`)

All persistence is UserDefaults keys → **Preferences DataStore** on Android. **Keep
the same semantics** (key names can change but the behaviour must not):

| Concern | iOS key | Type | Notes |
|---|---|---|---|
| Favorites | `favoriteImageNames` | [String] | set of imageNames; toggle |
| Onboarding done | `hasCompletedOnboarding` | Bool | |
| Selected mantra | `selectedMantraID` | String | default `"shiv"` |
| Current streak | `currentStreak` | Int | |
| Best streak | `bestStreak` | Int | |
| Last visit day | `lastVisitDay` | String `yyyy-MM-dd` | for streak |
| Japa per day | `japaCount.{yyyy-MM-dd}` | Int | per-day key |
| Language | `appLanguage` | `system/english/hindi` | |
| Appearance | `appearancePreference` | `system/light/dark` | |
| Reminder on | `dailyReminderEnabled` | Bool | |
| Reminder time | `dailyReminderHour`/`Minute` | Int | default 7:00 |
| Japa goal | `japaGoal` | Int | default 108 |
| Use GPS | `panchangUseGPS` | Bool | |
| Manual city | `panchangCityID` | String | |
| Music on | `backgroundMusicEnabled` | Bool | |
| Last review prompt version | `lastReviewRequestVersion` | String | rate-limit review |

**Japa logic:** counter is stored under a **per-day key**; `refreshJapaForToday()`
rolls the in-memory count over when the civil day changes (call on app-foreground &
on Japa screen appear). `incrementJapa()` bumps and persists; `resetJapa()` zeroes
today.

**Streak logic (`recordDailyVisit`)**: once per civil day. If `lastVisit ==
yesterday` → `currentStreak += 1`; else `currentStreak = 1`. `bestStreak = max(...)`.
Persist `lastVisitDay=today`. Called from Home `onAppear` and on foreground. Day
strings use a **gregorian, en_US_POSIX, `yyyy-MM-dd`** formatter (use the same on
Android to avoid locale digit surprises).

**LocalizationManager:** `preference ∈ {system, english, hindi}`. Resolved `lang`:
english→EN, hindi→HI, system→HI if device language starts with `hi` else EN.
`s(en,hi)` returns the active string; content models use `field(lang)`. Changing the
preference must **instantly re-render** the whole UI (StateFlow drives recomposition;
no activity restart). This is an **in-app** language toggle independent of the OS
locale — do **not** rely on Android per-resource `values-hi/` for content strings
(use the bilingual model + a `LocalLang` CompositionLocal). UI chrome strings can use
the same `s(en,hi)` helper rather than string resources, to match iOS exactly.

---

## 8. Services & their Android equivalents

### LocationManager (`Services/LocationManager.swift`)
- Holds `authorization`, `location`, `useGPS` (persisted), `revision` (bumped on each
  fix so views recompute cheaply). `desiredAccuracy = kilometer` (city-level).
- `enableGPS()`: set useGPS=true; request when-in-use permission / a single fix.
- `useManualCity()`: useGPS=false, clear location.
- **`activeCity(manualID, lang)`** — the single source of truth for "which City to
  feed Panchang": if `useGPS && location != nil` → an ad-hoc `City(id:"current",
  name:"My Location"/"मेरा स्थान", lat/lon from fix, tz = device tz)`; else
  `Cities.byID(manualID)`; else **nil** (UI then prompts to choose a location).
- **Privacy:** the fix is used **only on-device** — never reverse-geocoded,
  transmitted, or stored. Preserve this on Android (FusedLocationProvider, no
  geocoding, `ACCESS_COARSE_LOCATION` is enough since accuracy is city-level).

### NotificationManager (`Services/NotificationManager.swift`)
- One repeating daily local notification at `hour:minute`, id
  `divine-stillness.daily-darshan` (legacy id string — keep stable or migrate),
  title/body localized. Request permission; on denial throw.
  `disableDailyReminder()` cancels.
- **Android:** create a notification channel; schedule via `AlarmManager` (exact or
  inexact repeating) or a daily periodic `WorkManager`; POST_NOTIFICATIONS runtime
  permission on API 33+; reschedule on `BOOT_COMPLETED`.

### WallpaperLibrary (`Services/WallpaperLibrary.swift`)
- Loads the bundled image by name, requests **add-only** photo permission, writes to
  the photo library. Errors: imageMissing / permissionDenied (localized).
- **Android:** insert into `MediaStore.Images` (Pictures/BhaktiAngan). No runtime
  permission needed on API 29+ for own-app inserts.

### AudioManager (`Services/AudioManager.swift`)
- Optional looping ambience, **ships dormant**: `isAvailable` is true only when a
  bundled track `ambient_darshan.m4a/.mp3` exists. Until then the Settings toggle is
  hidden and no audio session activates. Plays with `.mixWithOthers` (polite layering),
  fade-in to volume 0.55, loops forever; pause on background, resume on foreground.
- **Android:** same dormant pattern — show the toggle only if a bundled track exists;
  ExoPlayer looping, `AudioFocusRequest` with may-duck/`setWillPauseWhenDucked(false)`
  to layer politely; pause/resume on lifecycle.

### StoreManager → Billing  (`Services/StoreManager.swift`) — see §9.

---

## 9. Monetization

**Product IDs (must match the stores; iOS uses these exact StoreKit IDs):**
- Monthly (auto-renew): `in.bhaktiangan.app.pro.monthly2` — *`.pro.monthly` was
  created+deleted and Apple reserves IDs forever, hence `monthly2`.*
- Annual (auto-renew, **7-day free trial** intro offer): `in.bhaktiangan.app.pro.yearly`
- Lifetime (non-consumable): `in.bhaktiangan.app.pro.lifetime`
- Prices (US): $4.99/mo · $29.99/yr · $39.99 lifetime. India: ₹149 / ₹999 / ₹1,499.

**`hasPro`** = owns any of the three product IDs (OR a DEBUG/QA override). Annual has
the only intro free trial; monthly has none by design (steer trials to annual).

**StoreManager surface to mirror:** `products`, `purchasedProductIDs`, `isLoading`,
`errorMessage`, `hasPro`; `start()` (observe transactions + load products + refresh
entitlements), `loadProducts()` (sorted yearly<monthly<lifetime), `purchase(product)`,
`restore()` (AppStore.sync), `refreshEntitlements()` (current entitlements, skip
revoked). Helpers used by the paywall: `freeTrialDays(product)`,
`monthlyEquivalentText` (annual ÷ 12 → "$2.50/mo"), `annualSavingsPercent`
(`(monthly·12 - annual)/(monthly·12)` rounded).

**Android (Play Billing):** subscriptions = base plans within a subscription product;
the free trial = an **offer** on the annual base plan. Map:
- `queryProductDetailsAsync` (SUBS for monthly+annual, INAPP for lifetime).
- entitlement = `queryPurchasesAsync` for SUBS + INAPP, filter `PURCHASED` &
  acknowledged; **acknowledge** new purchases (or they auto-refund in 3 days).
- restore = re-query purchases (no separate "restore" UI is strictly needed, but keep
  the button for parity).
- Play product IDs can differ from Apple's — define them in `core/billing` constants.
  Recommended: `pro_monthly`, `pro_yearly` (+ offer id `yearly-free-trial`), `pro_lifetime`.
- trial/price strings come from `ProductDetails` (`formattedPrice`,
  `pricingPhases`) — compute the per-month and savings text the same way.

**Paywall (`Features/Subscription/PaywallView.swift`)** — port the layout:
BrandMark, title "Bhakti Angan Pro" + subtitle, a 5-row **feature list** (complete
library / unlimited wallpaper saves / all mantras / custom reminders / new festival
collections), **3 selectable product cards** (annual pre-selected, "BEST VALUE" badge
on annual; each shows title/price/detail with trial+per-month+savings), a primary CTA
whose label is **"Start Free Trial"** when the selected product has a trial else
"Unlock Lifetime"/"Continue", **Restore Purchases**, the **auto-renew disclosure**
paragraph (EN+HI, verbatim — this is the #1 subscription-rejection guard), and
**Terms · Privacy** links. If products fail to load, show **fallback hard-coded
options** with the US prices so the paywall is never empty.

**Where the paywall appears:** (1) once right after onboarding completes if not Pro
(`RootView` watches `hasCompletedOnboarding`), (2) Home Pro buttons / Pro invitation
card, (3) Library locked tiles, (4) Japa locked mantra, (5) Settings "Unlock".
**Review prompt:** `ReviewPrompter.requestIfAppropriate` — at most once per app
version, fired after a **completed mala** (Play In-App Review on Android).

---

## 10. Screen-by-screen spec

Navigation root (`App/RootView.swift`): if `--open-panchang` QA arg → Panchang; else
if onboarding done → **MainTabView**; else **Onboarding**. Applies `.tint(vermilion)`
and the appearance color scheme. Shows the welcome paywall once after onboarding.
On `scenePhase==active`: resume audio + `refreshJapaForToday`.

**MainTabView — bottom tabs (4):** Today (`sun.max.fill`), Darshan (`photo…`),
Japa (`circle.grid.3x3.fill`), Settings (`gearshape.fill`). Labels bilingual
(Today/आज, Darshan/दर्शन, Japa/जप, Settings/सेटिंग्स). Selected tab is in `AppState`.

### 10.1 Onboarding (`Features/Onboarding/OnboardingView.swift`)
3-page horizontal pager with dots:
1. **Welcome** — `day1_shiv` image (250×360, rounded) with caption overlay; title
   "Bhakti Angan"; subtitle; "Continue".
2. **Ritual** — sun icon; "Make devotion a gentle habit"; 3 benefit rows (Daily
   Darshan / Japa Counter / Quiet Reminders); "Choose My Deity".
3. **Preference** — "Who would you like to begin with?"; 3 ishta radio rows
   (Shiva / Ganesha / Krishna); "Begin My Daily Darshan" → `completeOnboarding(ishta)`
   (sets selectedMantraID + onboarding flag).
`PrimaryButtonStyle` = filled plum, rounded 12, white headline.

### 10.2 Home / "Today" (`Features/Home/HomeView.swift`)
Scroll of: **header** (greeting by hour + live device date/time via a 30 s ticking
`TimelineView` + a streak chip when streak>1; right side: language menu `EN/हिं`,
theme menu, Pro control (badge or sparkles button)) → **PanchangCard** (§10.6) →
"Today's Darshan" heading → **hero** (500-tall image of `today.imageName`, bottom
gradient, collection/deity/mantra, and Favorite/Share/Save pill buttons) →
**practice** card (meaning + blessing + "Begin Japa" → JapaPracticeView with today's
mantra) → **explore** (horizontal rail of free-or-all items → DarshanDetail) →
**proInvitation** card (if not Pro). Toast overlay for favorite/save feedback. Share
uses the image + `shareText`. `today` recomputes on appear / foreground / hasPro
change via `ContentCatalog.dailyItem`. Records daily visit on appear/foreground.
Greeting: <12 morning, <17 afternoon, else evening.

### 10.3 Library (`Features/Library/LibraryView.swift`)
Searchable 2-col grid of **all** items. A horizontal **category chip** row
(`DeityCategory.allCases`). Filter = category match AND search match
(deity/mantra EN+HI contains). Free items → `DarshanDetail`; **premium items when
not Pro → a locked card** (dark overlay + lock + PRO badge) that opens the paywall.
Favorite hearts overlay on cards.

### 10.4 Darshan detail (`Features/Library/DarshanDetailView.swift`)
Full image (fit, black bg) + collection/deity/mantra/meaning/blessing + Favorite /
Share / Save action buttons + toast. Nav title = deity.

### 10.5 Japa (`Features/Japa/JapaView.swift`)
**Mantra selector** menu (all `mantraChoices`; premium-locked → paywall when not
Pro) + **JapaPracticeView**: mantra + meaning, a big circular **progress ring**
(count/goal) with a central tap-to-chant button showing count "of goal" and
"Tap to chant"/"Mala complete", **goal presets** 27/54/108/1008/10000, and a Reset
button. Haptics: soft on each chant, success on completion; on reaching the goal show
a "Mala complete · N names 🙏" banner and trigger the **review prompt**. Goal persists
(`japaGoal`). `JapaPracticeView` is reused from Home's "Begin Japa".

### 10.6 Panchang (`Features/Panchang/PanchangView.swift` — most complex)
- **PanchangCard** (on Home): title "Today's Panchang", city label (location.fill when
  GPS active else mappin), a 60 s ticking **Now: {Choghadiya}** row with quality dot +
  "until {time}", and a tithi · nakshatra line + a vrat chip. Taps → full screen.
  Recomputes on appear and when `cityID`/`location.revision`/`useGPS` change, using
  `computeForInstant(now)`.
- **Full screen**: if no location → an empty-state prompt with "Choose location"
  (opens CityPicker). Else a scroll of:
  - **dateNav** — ‹ chevron · calendar button (full weekday+date of the *sunrise*) ·
    chevron ›; sub-label "Panchang day · sunrise to sunrise" + a **"Today"** button
    when not live. `shiftDay(±1)` moves `viewDate` by a day in the city's tz.
  - **summary** — optional vrat chip + Sunrise/Sunset stats.
  - **nowBanner** (only when `isLive`) — "Right now" + current Choghadiya name,
    quality label + window, tinted by quality.
  - **elements** — Tithi/Nakshatra/Yoga/Karana rows, each with "until {endsAt}".
  - **Day Choghadiya** & **Night Choghadiya** — 8 rows each; the **current** row is
    bold, tinted stronger, with a "NOW" pill (only when live); ranges print the date
    when crossing midnight.
  - **auspicious** — Abhijit Muhurat window (teal).
  - **inauspicious** — Rahu, Gulika, Yamaganda, Vara Vela, Kala Vela, Kala Ratri
    (vermilion times).
  - device-calculation disclaimer.
  - **`isLive`** = `result.currentChoghadiya(at: now) != nil`. On first compute,
    **anchor** to the running sunrise-to-sunrise day (if before today's sunrise, start
    at yesterday). "Today" button resets the anchor.
- **CityPickerView** (sheet): "Use my location" (GPS, with denied-state hint) +
  searchable city list ("10,000+ cities"); selecting a city sets manual mode + cityID.
  GPS footer reassures it's on-device only.
- **Quality colors:** good→teal, neutral→marigold, bad→vermilion. Current-row tint
  opacity is **scheme-aware** (dark mode uses higher opacity: now 0.42 dark / 0.20
  light; non-now 0.22 dark / 0.08 light).

### 10.7 Settings (`Features/Settings/SettingsView.swift`)
Form sections: **Membership** (Pro active + Manage Subscription / or Unlock + Restore),
**Appearance & Language** (Language picker, Appearance picker, Background music toggle
*if available*), **Daily Practice** (reminder toggle + time picker, Preferred deity
picker limited to shiv/ganesh/krishna), **Connect** (Instagram
`instagram.com/bhaktiangan/`, YouTube `@bhaktiangan-om`, Facebook page link),
**About** (Contact Support, Privacy, Terms, Image & Faith Standards, Acknowledgements,
Apple Standard EULA link, Version). Reminder changes call NotificationManager. Legal
copy lives in `LegalCopy` (§ shared). DEBUG: a "Preview Pro entitlement" toggle.

### 10.8 Support (`Features/Settings/SupportView.swift`)
Topic picker (Question / Report an image / Subscription & billing / Feedback / Other)
+ message editor → opens the **system mail composer** prefilled to
`support@bhaktiangan.com` with subject `[Bhakti Angan] {topic}` + the message +
diagnostics (`App ver (build) · iOS ver · device`). Falls back to `mailto:` then to a
"copy address" alert. **No server** — preserves the no-data posture. Android:
`Intent.ACTION_SENDTO mailto:` with subject/body; diagnostics =
`App {VERSION_NAME} ({VERSION_CODE}) · Android {SDK} · {MODEL}`.

---

## 11. Design system  (`Design/AppTheme.swift`, `Components/SharedComponents.swift`)

**Dynamic colors (light / dark RGB 0–1):**
| Token | Light | Dark |
|---|---|---|
| ivory (bg) | 0.98,0.96,0.91 | 0.07,0.06,0.08 |
| paper (surface) | 1.00,0.99,0.97 | 0.14,0.12,0.15 |
| vermilion (accent/tint) | 0.72,0.18,0.08 | 0.93,0.42,0.28 |
| marigold | 0.94,0.58,0.10 | 0.98,0.69,0.24 |
| plum (primary btn) | 0.24,0.08,0.16 | 0.72,0.34,0.52 |
| teal (good / japa) | 0.08,0.38,0.36 | 0.26,0.68,0.62 |
| ink (text) | 0.15,0.12,0.10 | 0.96,0.94,0.90 |
| muted (2nd text) | 0.43,0.39,0.35 | 0.68,0.64,0.60 |

**Appearance** = system/light/dark (`appearancePreference`). **Tint** = vermilion.
**Shared components:** `ProBadge` (vermilion "PRO" capsule), `SectionHeading`,
`ToastView` (teal capsule, checkmark), `ActivityView` (share sheet),
`LegalTextView` + `LegalCopy` (privacy/terms/faithStandards/acknowledgements — copy
verbatim, incl. the **GeoNames CC BY 4.0** attribution), `ReviewPrompter`,
`PrimaryButtonStyle`. Corner radii 10–18, generous padding; SF Symbols → Material
Icons (closest equivalents). Fonts: system; Hindi needs a Devanagari-capable font
(bundle **Noto Sans/Serif Devanagari** on Android to match the web + render HI cleanly).

---

## 12. Assets

- **Darshan images:** 52 imagesets named `day{N}_{slug}` (+ removed ones excluded by
  catalog). Re-export as **WebP** into `res/drawable-nodpi/` (or `assets/darshan/`)
  with the **same base names** (Android resource names: lowercase, digits ok, e.g.
  `day1_shiv`). Source PNGs/originals live in the iOS asset catalog / the
  `DivineStillnessOm` content project.
- **BrandMark** imageset → `brandmark` drawable (used on the paywall).
- **App icon:** the `Icon Images/` set → Android adaptive icon.
- **cities.json:** 5.3 MB, positional `[[id,name,region,lat,lon,tz], …]`, sorted by
  population. Ship under `assets/cities.json`; parse off the main thread on first use
  (kotlinx-serialization to `List<JsonArray>` → `City`). Same on-device, no network.
- **Ambient track** (optional, dormant): `ambient_darshan.m4a/.mp3` — only if licensed.

---

## 13. Privacy & store compliance (must hold on Android)

- **No account, no backend, no analytics, no ads, no tracking.** All state on-device.
- Location: on-device only, never transmitted/geocoded/stored → Play **Data Safety =
  "No data collected/shared."** (Mirror the iOS "Data Not Collected" label.)
- Permissions: coarse location (optional, Panchang), notifications (API 33+, optional
  reminder). No storage permission needed for MediaStore inserts on API 29+.
- Port the in-app **Privacy / Terms / Faith Standards / Acknowledgements** text and
  the Panchang disclaimer. Subscription disclosure paragraph is mandatory on the paywall.
- `support@bhaktiangan.com` is the support channel; legal pages live at
  `bhaktiangan.com/privacy-policy/`, `/terms-of-use/`, `/contact/`.

---

## 14. QA / launch hooks (iOS) → Android equivalents

iOS reads `ProcessInfo.arguments`: `--skip-onboarding`, `--tab-library/-japa/-settings`,
`--pro-mode`, `--show-paywall`, `--open-panchang`. On Android, gate the same behaviours
behind a **debug-only** Intent extras / BuildConfig flags for screenshot automation.

---

## 15. Port plan (suggested phases)

1. **Scaffold** — Gradle, Compose, Material 3 theme (colors/typography), DataStore,
   nav graph, bottom bar, applicationId `in.bhaktiangan.app`.
2. **core/model + core/data** — models, ContentCatalog (generated Kotlin/JSON), cities
   loader. Unit-test `dailyItem`, free/premium split, `Cities.search`.
3. **core/panchang** — Astronomy + PanchangCalculator + names, **with a golden-file
   unit test** comparing to iOS output for ≥5 city/date pairs (incl. a pre-sunrise
   instant and a midnight-crossing night Choghadiya).
4. **feature/panchang** (card + full screen + city picker + GPS) — highest-value, most
   logic.
5. **feature/home, library, darshan detail, japa, onboarding** — UI + state.
6. **core/billing** (Play Billing) + **feature/paywall** + entitlement gating.
7. **services** — reminders (AlarmManager), wallpaper (MediaStore), share, review,
   audio (dormant), support mail.
8. **settings**, legal text, privacy, Data Safety form, store listing.
9. **Polish** — dark mode, Devanagari font, accessibility, screenshot QA hooks.

> **Constraint:** there is currently **no local Android toolchain** on this machine,
> so Android code is authored here but built/tested in Android Studio / CI. Keep
> `core/panchang` and `core/data` as **pure-Kotlin, JVM-unit-testable** modules so
> the riskiest logic can be verified without a device.

---

## 16. File-by-file source index (iOS → what to port)
```
App/BhaktiAnganApp.swift     → Application + DI wiring + decode cities off-main
App/RootView.swift           → NavHost root + welcome paywall + scenePhase hooks
App/AppState.swift           → AppStateViewModel (DataStore): favorites/japa/streak/tab/mantra
App/LocalizationManager.swift→ LocaleViewModel + s(en,hi) + LocalLang
Design/AppTheme.swift        → Material 3 ColorScheme (light/dark) + AppearanceMode
Components/SharedComponents  → ProBadge/SectionHeading/Toast/Share/Legal/ReviewPrompter
Models/DevotionalContent     → DevotionalItem/MantraChoice/DeityCategory
Data/ContentCatalog.swift    → catalog + slugs + removed set + dailyItem + weekdayDeity
Data/PanchangNames.swift     → bilingual name tables + vrat map
Data/Cities.swift            → City + positional decode + search
Services/Astronomy.swift     → pure Kotlin Astronomy (copy constants/35-term table)
Services/Panchang.swift      → PanchangCalculator (copy weekday index tables + rules)
Services/StoreManager.swift  → BillingViewModel (Play Billing)
Services/LocationManager     → LocationController (Fused, on-device only)
Services/NotificationManager → ReminderScheduler (AlarmManager/WorkManager)
Services/AudioManager        → AudioController (dormant unless track bundled)
Services/WallpaperLibrary    → WallpaperSaver (MediaStore)
Features/Onboarding          → OnboardingScreen (3-page pager)
Features/Home/HomeView       → HomeScreen (header/panchang card/hero/practice/explore/pro)
Features/Library             → LibraryScreen + DarshanDetailScreen
Features/Japa                → JapaScreen + JapaPracticeView (ring + presets + reset)
Features/Panchang            → PanchangCard + PanchangScreen + CityPickerScreen
Features/Settings            → SettingsScreen + SupportScreen
Features/Subscription        → PaywallScreen
```
```
Reference: iPhone/BhaktiAngan/  (Swift sources, Docs/, Resources/Assets.xcassets/)
Bundle id: in.bhaktiangan.app  ·  iOS deployment target 17.0  ·  Swift 5
```
