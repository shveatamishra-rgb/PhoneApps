# GigaBack — App Store Connect Metadata

> Everything needed to create the app record. Create the record early to lock the name.
> No em dashes anywhere in store copy (house rule). No third-party platform names in metadata
> (2.3.10 gotcha). No "Allow" wording on pre-permission buttons (5.1.1(iv) gotcha).

## App record (New App dialog)

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `GigaBack: Photo Video Cleaner` (29/30 chars) |
| Primary language | English (U.S.) |
| Bundle ID | `com.shveatamishra.gigaback` (already set in the Xcode project) |
| SKU | `gigaback-ios-001` |
| User access | Full Access |

Name fallbacks if sniped at creation time (recheck iTunes Search first):
1. `PhotoVac: Storage Cleaner`
2. `GigaBack: Duplicate Cleaner`

## Version information

| Field | Value |
|---|---|
| Subtitle | `Delete Duplicates, Free Space` (29/30) |
| Primary category | Utilities |
| Secondary category | Photo & Video |
| Age rating | 4+ (all "No" answers) |
| Version | 1.0 |
| Copyright | © 2026 Shveata Mishra |

## Keywords (100-char field)

Do not repeat title/subtitle words (photo, video, cleaner, delete, duplicates, free, space already index):

```
storage,similar,screenshot,blurry,swipe,compress,gallery,large,burst,clean up,phone,organizer
```
(97 chars — verify at submit time.)

## Promotional text (170-char field; editable any time WITHOUT a new review, use it for seasonal pushes later)

```
See how many gigabytes your photos are hiding. Scan free, review every duplicate, and clear space in minutes. Private: nothing ever leaves your iPhone.
```
(151 chars.)

## What's New (version 1.0)

```
Welcome to GigaBack 1.0.

- Find exact and look-alike duplicate photos
- Group similar and burst shots
- Swipe through old screenshots: left to delete, right to keep
- Spot blurry photos automatically
- See your largest videos sorted by size
- 100% on-device: your photos never leave your iPhone
```

## Description (draft)

```
Get your gigabytes back.

GigaBack finds everything wasting space in your photo library and clears it in minutes:

DUPLICATES
Exact copies and look-alike shots, found with precise on-device matching. Review every group and keep the best one.

SIMILAR PHOTOS
Burst shots and near-identical photos grouped together so you keep one, not seven.

SCREENSHOTS
Swipe through old screenshots: left to delete, right to keep. Oddly satisfying.

BLURRY PHOTOS
Out-of-focus shots detected automatically.

LARGE VIDEOS
Your biggest space hogs, sorted by size.

SAFE BY DESIGN
Nothing is removed without your confirmation, and everything you delete stays recoverable in Recently Deleted for 30 days.

PRIVATE BY DESIGN
GigaBack works 100% on your iPhone. Your photos never leave your device. No ads, no tracking, no account.

GIGABACK PRO
Scan free and see exactly how much space you can reclaim. Upgrade to Pro for one-tap Smart Clean across all categories, similar and blurry cleanup, and large video tools.

Terms of Use: https://shveatamishra-rgb.github.io/gigaback/terms.html
Privacy Policy: https://shveatamishra-rgb.github.io/gigaback/privacy.html
```

## URLs (legal-pages site, one kebab folder per app)

| Field | Value |
|---|---|
| Support URL | `https://shveatamishra-rgb.github.io/gigaback/` |
| Marketing URL | `https://shveatamishra-rgb.github.io/gigaback/` |
| Privacy Policy URL | `https://shveatamishra-rgb.github.io/gigaback/privacy.html` |
| Terms (EULA) | `https://shveatamishra-rgb.github.io/gigaback/terms.html` (also linked inside the paywall — 3.1.2 requirement) |

DONE 2026-07-06: `/gigaback/` pages (index, privacy, terms, support with contact form) are live in shveatamishra-rgb.github.io.

## Remaining ASC form fields (New App / version page)

| Field | Value |
|---|---|
| Promotional text | see above (170-char field) |
| What's New | see above |
| EULA | Leave as Apple's standard EULA (custom EULA not needed; Terms link in description + paywall satisfies 3.1.2) |
| Copyright | © 2026 Shveata Mishra |
| Content rights | Does not contain third-party content |
| Age rating questionnaire | All "None/No"; result 4+ |
| Pricing | App itself: Free; availability: all territories |
| App Review contact | Your name + phone + kharasportsdaily@gmail.com |
| Sign-in required | No (no demo account needed) |
| Version release | Manually release this version (recommended: lets you verify IAPs are live before users arrive) |

## App Privacy (nutrition label)

- Data collection: **Data Not Collected** (all "No" answers). App is fully on-device, no analytics, no network calls except StoreKit.
- Privacy manifest in repo already declares FileTimestamp/C617.1; no tracking domains.

## In-App Purchases

Subscription group: `GigaBack Pro` (create the group first).

| Product | Product ID | Type | Price (US) | Notes |
|---|---|---|---|---|
| Pro Weekly | `com.shveatamishra.gigaback.pro.weekly` | Auto-renew, 1 week | $4.99 | 3-day free trial (intro offer) |
| Pro Annual | `com.shveatamishra.gigaback.pro.annual` | Auto-renew, 1 year | $29.99 | The tier we visually push |
| Pro Lifetime | `com.shveatamishra.gigaback.pro.lifetime` | Non-consumable | $49.99 | High anchor; outside the sub group |

Display names (visible on Apple's sheets): "GigaBack Pro Weekly", "GigaBack Pro Annual", "GigaBack Pro Lifetime".

3.1.2 checklist for the paywall (enforced in code, verify at review):
- [ ] Price AND length prominent (largest text after the title, high contrast)
- [ ] Trial terms explicit: "3 days free, then $4.99/week"
- [ ] Functional Terms of Use + Privacy Policy links on the paywall itself
- [ ] Restore Purchases button
- [ ] Same Terms/Privacy links in the App Store description (done above)
- [ ] Never overstate reclaimable GB anywhere (screenshots included)

## Review notes (fill the box, multi-feature apps get fewer questions)

```
GigaBack is a fully on-device photo library cleaner. No account or login is needed.
To test: grant photo library access with any library containing photos; tap Scan.
Duplicates/Similar/Screenshots/Blurry/Large Videos populate after the scan.
Free tier: full scan, per-group deletion, screenshot swipe.
Pro (weekly/annual subscription or lifetime unlock) enables bulk Smart Clean and
similar/blurry/large-video bulk actions. Deletion always goes through the system
Photos confirmation and items remain in Recently Deleted for 30 days.
```

## Screenshot assets (captured 2026-07-06, native 1320x2868)

All in `iPhone/GigaBack/Screenshots/`:
- `01-home-dashboard.png` … `06-compare-preview.png`: the store set, upload in numeric order.
- `07-iap-review-paywall.png`: the **IAP review screenshot**. Upload it in the
  Review Information > Screenshot field of EACH of the three IAPs (weekly, annual,
  lifetime; the same image is fine for all three). Reviewers see it; users never do.

## Screenshots plan (6.9" + 6.5", no priced-feature claims in captions)

1. Hero: storage meter + "12.4 GB reclaimable" scan result (use a real, reproducible number)
2. Duplicate groups grid with Keep/Delete selections
3. Swipe triage mid-gesture on a screenshot
4. Similar/burst group with best-shot highlighted
5. Large videos list sorted by size
6. Before/after storage bar + "recoverable for 30 days" callout
