# Gallery Transfer — Android companion

Native Android companion to the iPhone **Gallery Transfer** app. It exists for one
reason the browser-based flow can't solve: **a web upload loses GPS location and the
real filename** because Android scoped storage redacts location from files handed to
apps without `ACCESS_MEDIA_LOCATION`, and browsers expose a numeric MediaStore name
for videos. This app reads the **true original** (`MediaStore.setRequireOriginal`,
with `ACCESS_MEDIA_LOCATION`) and the real `DISPLAY_NAME`, then uploads to the iPhone's
existing PIN-protected `/upload` endpoint.

## Status — first cut (send only)

- ✅ Connect to the iPhone server (address + 6-digit PIN, remembered).
- ✅ Browse recent photos/videos from MediaStore, multi-select, see total size.
- ✅ Upload originals with GPS + real filename preserved, streamed (no full-file RAM load).
- ✅ Dark/Light/System theme (forest-green + gold, matching the iPhone app + web page).
- ⬜ TODO: receive (download the iPhone's selected media into the gallery) — for now use the browser page.
- ⬜ TODO: QR scan to fill address + PIN automatically.

## Build

There's no Android toolchain in this dev environment, so this was written but not yet
compiled — expect to iterate on first build.

1. Install **Android Studio** (it bundles the SDK, a JDK 17, and Gradle).
2. **Open** `Android/GalleryTransfer` in Android Studio and let it sync.
   - The Gradle **wrapper jar** isn't committed. If AS doesn't generate it automatically,
     run `gradle wrapper --gradle-version 8.7` once (with a system Gradle), or use
     *File ▸ Sync Project with Gradle Files*.
3. Run on a device/emulator (min SDK 29 / Android 10).

```
applicationId  com.shveatamishra.gallerytransfer
minSdk 29   targetSdk 34   compileSdk 34
Kotlin 1.9.24 · AGP 8.5.2 · Compose BOM 2024.09.00 · OkHttp 4.12
```

## How it talks to the iPhone

`http://<iphone-ip>:8899` with the PIN as `?pin=` (same scheme the served web page uses).
The iPhone server allows cleartext on the LAN; this app sets `usesCleartextTraffic="true"`.
