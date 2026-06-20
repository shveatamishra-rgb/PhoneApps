# Divine Stillness Om for iPhone

Divine Stillness Om is a native SwiftUI devotional app built from the 60-image
Divine Stillness content collection.

## Product

Free includes:

- A rotating daily darshan with mantra, meaning, and blessing
- The first 12 darshan images
- Shiva, Ganesha, and Krishna japa mantras
- A japa counter with a daily darshan streak
- Favorites, sharing, and the daily wallpaper save
- One daily local reminder

Pro includes:

- The complete 60-image darshan library
- All 19 deity themes and mantras
- Unlimited wallpaper saves
- A 7-day free trial on the annual plan, plus monthly and lifetime options
- The product foundation for future festival collections

The app uses one App Store binary with StoreKit entitlements. This is preferable
to separate Free and Pro apps because reviews, ranking, updates, and conversion
remain in one listing.

## Requirements

- Xcode 26.5 or later
- iOS 17 or later
- Apple Developer team `45QWJVLL5D`

Open `DivineStillness.xcodeproj`, select the `DivineStillness` scheme, and run on
an iPhone simulator or device.

```sh
./build.sh
```

Run unit tests:

```sh
xcodebuild \
  -project DivineStillness.xcodeproj \
  -scheme DivineStillness \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

## StoreKit products

- `com.shveatamishra.divinestillness.pro.monthly`
- `com.shveatamishra.divinestillness.pro.yearly`
- `com.shveatamishra.divinestillness.pro.lifetime`

`DivineStillness/Resources/Subscriptions.storekit` provides local StoreKit
testing in Xcode. The same identifiers must be created in App Store Connect.

## Source layout

- `App/`: lifecycle and shared state
- `Data/`: 60-day catalog and devotional copy
- `Features/`: onboarding, Today, library, japa, settings, and paywall
- `Services/`: StoreKit, local notifications, and photo saving
- `Resources/Assets.xcassets`: optimized app icon and all 60 images
- `DivineStillnessTests/`: catalog and Free/Pro rule tests
- `Docs/`: launch, content-review, and App Store checklists

## Release prerequisites

The code and local product are complete, but App Store publication still
requires account-side work:

1. Create the app record and three products in App Store Connect.
2. Host the privacy policy on a public HTTPS URL.
3. Complete a human iconography review of every generated deity image.
4. Test purchases with StoreKit Sandbox and TestFlight.
5. Supply App Store screenshots, support URL, banking, tax, and agreements.

See `Docs/APP_STORE_CONNECT.md` and `Docs/RELEASE_CHECKLIST.md`.
