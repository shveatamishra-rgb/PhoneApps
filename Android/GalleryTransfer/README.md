# Ferry — Android companion

Native Android companion to the iPhone **Ferry** app. It exists for one reason the
browser-based flow can't solve: **a web upload loses GPS location and the real
filename** because Android scoped storage redacts location from files handed to apps
without `ACCESS_MEDIA_LOCATION`, and browsers expose a numeric MediaStore name for
videos. This app reads the **true original** (`MediaStore.setRequireOriginal`, with
`ACCESS_MEDIA_LOCATION`) and the real `DISPLAY_NAME`, then uploads to the iPhone's
existing PIN-protected `/upload` endpoint.

> The display name is **Ferry**; the project folder and package id still read
> `gallerytransfer` (internal only — safe to rename later).

## Status — first cut (send only)

- ✅ Connect to the iPhone server (address + 6-digit PIN, remembered).
- ✅ **Album/folder gallery** (MediaStore buckets) with cover + count, drilling into a
  thumbnail grid (Coil; video frames too), multi-select across folders, running total size.
- ✅ Upload originals with GPS + real filename preserved, streamed (no full-file RAM load).
- ✅ Adaptive **Ferry** launcher icon; Dark/Light/System theme (forest-green + gold,
  matching the iPhone app + web page).
- ⬜ TODO: receive (download the iPhone's selected media into the gallery) — for now use the browser page.
- ⬜ TODO: QR scan to fill address + PIN automatically.

## Build

Compiles to a debug APK (verified 2026-06-15 with the Gradle wrapper, Android Studio's
JDK 21, and SDK platform 36).

1. **Open** `Android/GalleryTransfer` in Android Studio and let it sync, **or** from a
   terminal: `./gradlew :app:assembleDebug` (the wrapper is committed).
   - Needs a `local.properties` with `sdk.dir=/path/to/Android/sdk` (Android Studio
     writes this automatically; it's gitignored).
3. Run on a device/emulator (min SDK 29 / Android 10).

```
applicationId  com.shveatamishra.gallerytransfer
minSdk 29   targetSdk 34   compileSdk 36 (only platform installed here; AGP warning suppressed)
Kotlin 1.9.24 · AGP 8.5.2 · Gradle 8.7 · Compose BOM 2024.09.00 · OkHttp 4.12
```

## How it talks to the iPhone

`http://<iphone-ip>:8899` with the PIN as `?pin=` (same scheme the served web page uses).
The iPhone server allows cleartext on the LAN; this app sets `usesCleartextTraffic="true"`.
