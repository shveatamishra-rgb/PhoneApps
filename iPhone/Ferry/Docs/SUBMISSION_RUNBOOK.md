# Ferry — App Store Connect Submission Runbook (A → Z)

A step-by-step guide to get **Ferry** onto the App Store, with the exact value for
every field. Work top to bottom; each section is one screen/area in App Store Connect
(ASC) or Xcode.

> I can't paste live ASC screen captures (they're behind your login), so each step
> describes what you'll see and exactly what to type. For your *product-page*
> screenshots (the marketing images), **Section H** gives the pixel sizes and how to
> capture them.

---

## 0. Cheat sheet — every value in one place

| Field | Value |
|---|---|
| Platform | iOS |
| App name (store) | **Ferry - Media Transfer** *(plain "Ferry" is taken; see Section C)* |
| Subtitle (≤30 chars) | `Move photos between phones` |
| Bundle ID | `com.shveatamishra.ferry` |
| SKU | `ferry-ios-001` |
| Primary language | English (U.S.) |
| Primary category | Utilities |
| Secondary category | Photo & Video *(optional)* |
| Version | `1.0` |
| Build | `1` |
| Min iOS | 17.0 |
| Price | **Free** (with one In-App Purchase) |
| In-App Purchase | `ferry_pro` — Non-Consumable — **$2.99** |
| Age rating | 4+ |
| Uses IDFA | No |
| Encryption | Exempt (already declared in Info.plist) |
| Data collection | **Data Not Collected** |

**Already handled in the project (don't redo):** bundle id, `CFBundleDisplayName = Ferry`
(home-screen label), `ITSAppUsesNonExemptEncryption = false`, Local Network + Photos
usage strings, privacy manifest, version 1.0 / build 1.

**You still need to provide:** a unique store name, a **Privacy Policy URL**, a **Support
URL**, screenshots, and the IAP + build inside ASC. These are called out below.

---

## The pipeline at a glance

```
0. Prereqs: Developer Program + Agreements/Tax/Banking (required for IAP)
A. Xcode pre-flight (capabilities, privacy-manifest fix, version)
B. Register the Bundle ID (if not already)
C. Create the app record  ← the "New App" screen you're on now
D. App Information (category, age rating, privacy policy URL)
E. Pricing (Free)
F. Create In-App Purchase  ferry_pro
G. Version page copy (description, keywords, URLs)
H. Screenshots
I. App Privacy (Data Not Collected)
J. Archive in Xcode + upload the build
K. Attach the build + the IAP to the version
L. App Review Information (the 2-device test notes — important!)
M. Export compliance + IDFA
N. Submit for Review
O. Pre-empt the likely rejections
```

---

## 0. Prerequisites (do these first or submission will block)

1. **Apple Developer Program** membership active ($99/yr) under your team.
2. **Agreements, Tax, and Banking** (ASC → *Business* / *Agreements*): the **Paid
   Applications** agreement must be **Active**, with banking + tax forms complete.
   *Even though Ferry is free, it has an In-App Purchase, so this agreement is
   mandatory — IAPs won't go live without it.* This is the #1 silent blocker.
3. The **Apple ID** you sign in to ASC with has the **App Manager** or **Admin** role.

---

## A. Xcode pre-flight

Open `iPhone/Ferry/Ferry.xcodeproj`, select the **Ferry** target → **Signing &
Capabilities**.

1. **Team:** select your Apple Developer team. Leave **Automatically manage signing** on.
2. **Bundle Identifier:** confirm `com.shveatamishra.ferry`.
3. **iCloud → Key-Value storage** (recommended): click **+ Capability → iCloud**, tick
   **Key-Value storage**. This makes the "50 free transfers" count sync per-Apple-ID and
   survive reinstalls. *Without it the app still works — the count just falls back to
   on-device only.*
4. **Version / Build:** General tab → Version `1.0`, Build `1` (already set).

**Required privacy-manifest fix (do before archiving).** Ferry uses `UserDefaults`
(the theme setting + the free-transfer counter mirror), which is an Apple
"required-reason" API. Add this inside the `NSPrivacyAccessedAPITypes` array in
`Ferry/PrivacyInfo.xcprivacy` so the automated check (ITMS-91053) doesn't email you a
warning:

```xml
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>CA92.1</string>
    </array>
</dict>
```

*(`CA92.1` = "access info only accessible to the app itself.")*

---

## B. Register the Bundle ID

If `com.shveatamishra.ferry` isn't registered yet:
*developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → + →
App IDs → App* →
- **Description:** `Ferry`
- **Bundle ID:** Explicit → `com.shveatamishra.ferry`
- **Capabilities:** tick **iCloud** (Include CloudKit support not needed — KVS only) if
  you enabled it in Step A.
- Register.

*(If you turned on automatic signing in Xcode, Xcode may have created this for you
already — then it'll just appear in the dropdown in Section C.)*

---

## C. Create the app record — the "New App" screen

This is the dialog you're on. Enter:

| Field | Value |
|---|---|
| Platforms | ✅ **iOS** only |
| **Name** | `Ferry - Media Transfer` |
| Primary Language | English (U.S.) |
| Bundle ID | **Ferry — com.shveatamishra.ferry** (pick from dropdown) |
| SKU | `ferry-ios-001` |
| User Access | Full Access |

**About the "name is already used" error:** App Store names are unique across the
*entire* store and plain **"Ferry" is taken**. Your **home-screen icon will still say
"Ferry"** regardless (that's `CFBundleDisplayName`, already set) — only the store title
needs to differ. Use `Ferry - Media Transfer`. If that's also taken, try, in order:
`Ferry: Photo Transfer` → `Ferry - Phone to Phone` → `Ferry Media Transfer`.
Do **not** click "submit a claim" — that's only for registered trademark owners.

Click **Create**. You now have an app record with empty sections to fill.

---

## D. App Information (left sidebar → *General → App Information*)

| Field | Value |
|---|---|
| Subtitle | `Move photos between phones` |
| Category — Primary | **Utilities** |
| Category — Secondary | Photo & Video *(optional)* |
| Content Rights | "No, it does not contain, show, or access third-party content." |
| **Privacy Policy URL** | `https://shveatamishra-rgb.github.io/ferry/privacy.html` |
| Age Rating | Click **Edit** → answer **None / No** to every question → **4+** |

**Privacy Policy URL** — done. The page is live at
`https://shveatamishra-rgb.github.io/ferry/privacy.html` (source in your
`shveatamishra-rgb.github.io` repo under `ferry/`). It states Ferry collects nothing.
There's also a **Terms** page (`https://shveatamishra-rgb.github.io/ferry/terms.html`) you
can add as a custom **License Agreement** under App Information if you want; otherwise
Apple's standard EULA is used.

---

## E. Pricing and Availability (sidebar → *Pricing and Availability*)

| Field | Value |
|---|---|
| Price | **Free** (USD 0 / Tier 0) |
| Availability | All countries/regions (or trim as you like) |
| Pre-Orders | Off |

Ferry is free to download; money comes only from the **Ferry Pro** IAP (Section F).

---

## F. Create the In-App Purchase `ferry_pro`

Sidebar → *Monetization → In-App Purchases* → **＋**.

| Field | Value |
|---|---|
| Type | **Non-Consumable** |
| Reference Name | `Ferry Pro` *(internal only)* |
| Product ID | `ferry_pro` *(must match the app's code exactly)* |
| Price | **$2.99** (USD Tier 3) |
| Display Name (en-US) | `Ferry Pro` |
| Description (en-US) | `Unlimited sending and receiving, straight into Photos with metadata.` |
| Availability | All countries |

Then scroll to **App Store Promotion / Review Information**:
- **Review screenshot (required):** a screenshot of the **Ferry Pro upgrade sheet** in
  the app (the screen with the price + "Unlock"/"Restore" buttons). Any size; just show
  the purchase UI.
- **Review notes:** `Ferry Pro is a one-time unlock that removes the free 50-transfer
  lifetime limit. Tap "Go Pro" in the top bar of the app to reach this screen.`

Save. **The first IAP must be submitted together with the app version** (Section K) — a
brand-new IAP can't go live on its own.

---

## G. Version page copy (sidebar → *iOS App → 1.0 Prepare for Submission*)

**Promotional text** (≤170 chars, editable anytime without re-review):
```
Send full-quality photos and videos between iPhone and Android over Wi-Fi - no cables,
no cloud, no compression. Location and capture date stay intact.
```

**Description** (≤4000 chars):
```
Ferry moves your photos and videos between iPhone and Android the way they should move:
full quality, over your own Wi-Fi, with nothing uploaded to a server.

Pick the photos and videos you want, scan a QR code, and they transfer directly between
the two phones on the same network. Received media lands straight in your Photos library,
and the original location and capture date come along for the ride.

HOW IT WORKS
- Put both phones on the same Wi-Fi.
- Open Ferry, tap Start, and scan the QR code (or type the address + PIN).
- Choose photos and videos, and send. That's it.

WHY FERRY
- Full quality. Originals are sent without recompression.
- Keeps metadata. GPS location and capture date are preserved.
- Private. Transfers happen device-to-device on your local network. Nothing goes to the
  cloud, and Ferry has no account.
- Fast. Limited only by your Wi-Fi, not your data plan.
- Secure. Every session is protected by a one-time PIN.

FREE AND PRO
Ferry is free for your first 50 transfers. Ferry Pro is a one-time purchase that unlocks
unlimited sending and receiving, forever.

Works with the free Ferry app for Android.
```

**Keywords** (≤100 chars, comma-separated, no spaces after commas):
```
photo transfer,video,android,wifi,move,share,send,migrate,backup,export,gallery,qr
```

**Support URL** (required): `https://shveatamishra-rgb.github.io/ferry/support.html` — a
Ferry support page with a contact form (messages reach you by email) and a short FAQ.
Already live.

**Marketing URL** (optional): your product page if you make one.

**Copyright** (App Information): `2026 Shveata Mishra`.

---

## H. Screenshots

**Required size — iPhone 6.9":** `1320 × 2868` px, **portrait**. Upload this set and
Apple scales it down for smaller iPhones. (6.7" `1290 × 2796` is an accepted alternative;
6.5" `1242 × 2688` is now optional.) **1–10 images**; supply at least **3**. No iPad
screenshots needed unless you add iPad support.

**How to capture (free, from the simulator):**
1. In Xcode, set the run destination to **iPhone 16 Pro Max** (a 6.9" device) and run
   Ferry.
2. Navigate to the screen you want.
3. In Simulator: **File → Save Screen** (`⌘S`). It writes a PNG at exactly `1320 × 2868`
   to your Desktop — the correct size, no editing needed.
4. (Optional) drop them into a frame/caption tool, but raw screenshots are accepted.

**Suggested 5 frames** (first 2–3 are what most users actually see):
1. **Start Receiver + QR code** — caption idea: "Scan to connect."
2. **Picking photos/videos with the running total** — "Send full quality."
3. **Transfer in progress (progress bar)** — "Over Wi-Fi, no cloud."
4. **A received item with the View button (in Photos)** — "Lands in Photos, metadata intact."
5. **Ferry Pro upgrade sheet** — "Go unlimited with Ferry Pro."

---

## I. App Privacy (sidebar → *App Privacy*)

Click **Get Started**. Because Ferry has no server, account, analytics, or tracking:

- **Do you collect data from this app?** → **No, we do not collect data from this app.**
- That yields a **"Data Not Collected"** privacy label. Done.

*(This matches `PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, no collected data
types. Transfers are peer-to-peer on the local network; nothing reaches a backend.)*

---

## J. Archive in Xcode and upload the build

1. In Xcode, set the run destination to **Any iOS Device (arm64)** (not a simulator).
2. **Product → Archive.** Wait for the Organizer to open.
3. Select the archive → **Distribute App → App Store Connect → Upload.**
4. Keep defaults (automatic signing, symbols on) → **Upload.**
5. Wait ~5–30 min for processing. The build appears under *TestFlight* / the version's
   **Build** picker. You may get an email when it's ready.

*If you enabled iCloud KVS (Step A), the distribution profile needs the iCloud
entitlement — automatic signing handles this.*

---

## K. Attach the build + IAP to the version

Back on the **1.0** version page:
1. **Build** section → **＋ / Select a build** → choose build **1**.
2. **In-App Purchases** section on the version page → **add `Ferry Pro`** so it's reviewed
   *with* this version (required for the first IAP).

---

## L. App Review Information (on the version page) — read this one carefully

Ferry needs **two devices** for a full transfer, so give the reviewer a single-device path
or they may reject it as "unable to review."

- **Sign-in required:** **No.**
- **Contact:** your name, phone, email.
- **Notes:**
```
Ferry transfers photos/videos between an iPhone and a second device (Android phone or
another iPhone) on the same Wi-Fi. A full end-to-end transfer needs two devices, but you
can verify it on one:

1. Launch Ferry and tap "Start Receiver." The app shows a local address
   (http://<ip>:8899) and a 6-digit PIN, and starts a small local web server.
2. On a Mac or second device on the SAME Wi-Fi, open that address in a browser, enter the
   PIN, and upload a photo. It saves into the iPhone's Photos library (the receive path).
3. To see the send path, select photos in the app; they are offered for download at the
   same address.

Notes for review:
- Local Network permission is required so the two devices can discover each other
  (Bonjour + a local HTTP server on port 8899). No data leaves the local network; there
  is NO backend server, NO account, NO tracking.
- "Ferry Pro" (product id: ferry_pro) is a one-time non-consumable that removes the free
  50-transfer limit. The free count is stored per Apple ID via iCloud key-value storage.
- Companion free Android app:
  https://github.com/shveatamishra-rgb/PhoneApps/releases/latest/download/ferry.apk

No login is required to use the app.
```
- **Attachment (optional but helpful):** a short screen recording of the browser-upload
  test above.

---

## M. Export compliance & IDFA

- **Export compliance:** because `ITSAppUsesNonExemptEncryption = false` is in Info.plist,
  ASC won't prompt you. If it ever asks: Ferry uses only exempt encryption → **Yes,
  exempt**.
- **Advertising Identifier (IDFA):** **No** — Ferry doesn't use it.

---

## N. Version Release & Submit

1. **Version Release:** choose **Manually release this version** (so you control go-live)
   or automatic.
2. Top right → **Add for Review** → **Submit for Review.**
3. Status goes **Waiting for Review → In Review → (Pending Developer Release or Ready for
   Sale).** Typical wait: 24–48 h.

---

## O. Pre-empt the likely rejections (Ferry-specific)

| Risk | Why | Fix (already addressed or do this) |
|---|---|---|
| "Couldn't review — needs 2nd device" | Transfers need two devices | The Section L notes give a one-device test path. **Don't skip them.** |
| Local Network / HTTP server scrutiny | Apps running a local server + Local Network prompt get extra eyes | Notes explain it's LAN-only, no backend, PIN-protected. The usage string is already user-friendly. |
| Guideline 4.2 "minimum functionality" | Utility apps must clearly do something | Description + screenshots show the full send/receive flow. |
| IAP not reviewable | First IAP must ship with a build | Section K attaches `Ferry Pro` to the version. |
| Missing privacy-manifest reason (ITMS-91053) | `UserDefaults` is a required-reason API | Add the `CA92.1` block from Section A before archiving. |
| Privacy Policy URL missing | Required field | Provide one (Section D) — offer stands to draft it. |
| Android link in metadata | Apple dislikes pointing users off-platform in the *description* | Keep the Android mention factual ("Works with the free Ferry app for Android"); put the actual APK link only in **Review Notes**, not the public description. |

---

## Still-open items (your action)

- [ ] Confirm a unique store **Name** (try `Ferry - Media Transfer`).
- [x] ~~Create / host a **Privacy Policy URL** and a **Support URL**.~~ Live at
  `https://shveatamishra-rgb.github.io/ferry/` (privacy/terms/support).
- [x] ~~Add the **`CA92.1` UserDefaults** block to `PrivacyInfo.xcprivacy`.~~ Done; manifest
  lints OK and the app still builds.
- [ ] (Recommended) enable **iCloud Key-Value storage** capability.
- [ ] Capture **screenshots** (1320 × 2868).
- [ ] Create the **`ferry_pro`** IAP in ASC + its review screenshot.
- [ ] **Archive & upload** the build, then attach build + IAP and submit.
- [ ] Ensure **Agreements/Tax/Banking** is Active (needed for the IAP).
