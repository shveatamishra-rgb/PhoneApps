# GalleryTransferiOS - Code Review & Fix Handoff

> Handoff doc for a fresh chat. Review done 2026-06-15. **All 5 findings fixed 2026-06-15** - see checked items below. Re-verified with `./build-gallery-transfer.sh` → **BUILD SUCCEEDED**. On-device pass still recommended (local-network + Photos are limited in the simulator).

## What this app is
SwiftUI iOS app (iOS 17+, bundle `com.shveatamishra.gallerytransfer.iphone`) that moves photo/video **originals** between Android and iPhone over local Wi-Fi. It runs a local HTTP server on port **8899**; Android uploads via a browser page (saved into Photos with PhotoKit) and downloads iPhone-exported originals. No Android companion app exists yet (`Android/` is empty).

Key files:
- `PhotoTransferServer.swift` - actor-based HTTP server (routing, upload/download, chunked + fixed-length body parsing, the served HTML page).
- `PhotoLibraryBridge.swift` - PhotoKit save/export, EXIF/QuickTime metadata (GPS, creation date) preservation.
- `TransferViewModel.swift` - `@MainActor` view model, server lifecycle, PhotosPicker export.
- `ContentView.swift` - UI + QR code.
- `NetworkInterface.swift` - en0 IPv4 lookup.

## Build / verify
```zsh
cd iPhone/GalleryTransfer && ./build-gallery-transfer.sh   # builds for iphonesimulator, CODE_SIGNING_ALLOWED=NO
```
Last result: **BUILD SUCCEEDED** (Xcode 26.5 SDK, iOS 17 sim). A real device is recommended for actual transfer testing (local-network + Photos saving are limited in the simulator).

## Findings (open)

### Hardening / security
- [x] **#1 Server is unauthenticated + plaintext.** ~~While the receiver runs, anyone on the LAN reaching `:8899` can `POST /upload` straight into Photos and pull exported originals.~~ **Fixed:** added a per-session 6-digit PIN (`PhotoTransferServer.accessPIN`, regenerated each `start()`). `/upload`, `/download/*`, and `/manifest.json` now require the PIN (query `pin=` or `X-Access-PIN` header) and return 401 otherwise; only `GET /` is public so the served page can show a PIN prompt. The QR payload bakes in `?pin=` so scanning stays hands-free; manual visitors enter the PIN on the page. PIN is shown in-app with an explicit "anyone on this Wi-Fi who has the PIN can connect" note. Compared in constant time. *(Still plaintext HTTP - fine for a same-LAN transient transfer; TLS would need a self-signed cert + trust UX, out of scope.)*
- [x] **#5 Unbounded header buffer.** ~~`receiveHTTPRequestEnvelope` appends 1 MB chunks until it finds `\r\n\r\n`.~~ **Fixed:** added a 64 KB header cap; exceeding it throws `TransferServerError.headerTooLarge` (→ 400) instead of growing unbounded. - `PhotoTransferServer.swift`.

### Robustness
- [x] **#2 `PhotosPicker(maxSelectionCount: 0)` is undocumented.** **Fixed:** now `maxSelectionCount: nil` (documented "unlimited"). - `ContentView.swift`. *(On-device selection still worth a sanity check.)*
- [x] **#3 Relies on `PhotosPickerItem.itemIdentifier`, which can be nil.** **Fixed:** export no longer touches `itemIdentifier`/`PHAsset`. `TransferViewModel.prepareOutgoingPhotos` now loads each item via `loadTransferable(type: PickedMediaFile.self)` - a `Transferable` backed by `FileRepresentation(importedContentType: .item)` that streams the original to app temp storage (no full-file RAM load, works under limited access). `PhotoLibraryBridge.exportOutgoing(from:)` consumes those files; the dead `PHAsset` export helpers were removed. A failing item is skipped, not fatal to the batch. - `TransferViewModel.swift`, `PhotoLibraryBridge.swift`.
- [x] **#4 Temp upload files never cleaned up.** **Fixed:** `receiveUpload` now deletes the per-upload `tmp/GalleryTransferUploads/<uuid>/` dir in a `defer` right after creating it (runs whether the save succeeds or throws). The picker-side staging dir (`GalleryTransferPicked/`) is likewise cleaned in `exportOutgoing`'s `defer`. - `PhotoTransferServer.swift`.

### Notes (no action needed)
- Server runs foreground-only (no background mode) - correctly acknowledged in UI/README.
- GPS/EXIF preservation in `PhotoLibraryBridge.swift` is solid, incl. the 0,0-coordinate guard. For *sending*, metadata is now preserved simply because `loadTransferable` serves the original file bytes unchanged (no transcode).
- Privacy manifest (`PrivacyInfo.xcprivacy`) empty arrays are still **fine** - the export path now also reads `.contentTypeKey`, which (like `.fileSizeKey`) is not a required-reason API.

## Status
All 5 findings fixed on 2026-06-15; `./build-gallery-transfer.sh` → **BUILD SUCCEEDED**.

### Post-review storage/memory hardening (2026-06-15)
- **Receive peak ~1x:** save now uses `shouldMoveFile = true` so Photos consumes the staged temp file instead of copying it (defer cleanup still covers leftovers/failures). - `PhotoLibraryBridge.saveReceivedMediaToPhotos`.
- **Outgoing staging cleared on stop:** `stopServer()` calls `PhotoLibraryBridge.clearExportedOriginals()` and empties `outgoingFiles`, so the staged send copies in `tmp/GalleryTransferOutgoing` don't linger in the app container. - `TransferViewModel`, `PhotoLibraryBridge`.
- **Downloads stream from disk:** `sendDownload` no longer does `Data(contentsOf:)` (whole file into RAM); `streamFile` sends headers then 256 KB chunks with `contentProcessed` backpressure, so a multi-GB video stays bounded in memory. - `PhotoTransferServer`.

### Send-path metadata guarantee (hybrid export, 2026-06-15)
- `prepareOutgoingPhotos` now prefers the **true Photos original** (`PhotoLibraryBridge.exportAssetOriginal` via `PHAssetResourceManager`, guaranteed GPS/EXIF) when the picker gives a usable `itemIdentifier`, and falls back to `loadTransferable`/`adoptPickedFile` only when the identifier is nil or the asset isn't fetchable under limited access. Best of both: guaranteed metadata + limited-access robustness. - `TransferViewModel`, `PhotoLibraryBridge`.

### UI / theming (2026-06-15)
- **Theme toggle on both surfaces.** iPhone: `AppTheme` (System/Light/Dark) via `@AppStorage`, applied with `.preferredColorScheme` + `.tint`, toolbar menu in `ContentView`; brand palette (black/forest-green/gold dark, ivory/forest/gold light) as dynamic `Color`s. Served web page: CSS-variable themes with a no-flash head script + `localStorage` persistence and a header toggle.
- **Total size before transfer.** Web page shows "N items · X total" on selection (`showSelection`/`formatBytes`); the iPhone download list also shows per-file size + a total chip. Web page got a general visual polish (app bar, card surfaces, row styling).

### ⚠️ Android→iPhone location loss is NOT an iPhone bug (open, needs Android app)
Symptom: a photo that shows a location in the Android gallery imports to iPhone Photos with "Add a location."
Cause: **Android scoped storage (Android 10+) redacts GPS EXIF from files handed to apps without `ACCESS_MEDIA_LOCATION`** - including browser file uploads. The gallery shows location (it reads MediaStore / holds the permission); the browser-uploaded copy already has GPS stripped before it ever reaches the iPhone. The iPhone side is correct: it sets `creationDate`/`location` from whatever metadata arrives and saves bytes unchanged. Confirm via the "Recent saves" row ("No GPS location metadata arrived…") and by checking whether the capture **date** survived (it usually does - Android strips GPS specifically).
Fix requires a **native Android companion app** that holds `ACCESS_MEDIA_LOCATION` and reads originals from MediaStore. Not fixable on iPhone. (`Android/` is still empty.)

**Same root cause - video filenames.** Browsers expose videos to `<input type=file>` with a numeric MediaStore-ID display name (e.g. `1000000234.mp4`) rather than the gallery's `VID_…` name (images usually keep `IMG_…`). The app previously rewrote all-numeric names to a timestamp (`looksLikeAndroidProviderID`); that's now removed - `preferredSavedFilename`/`isGenericUploadName` preserves whatever Android sends and only synthesizes a timestamp when no name arrives. So the saved name now equals exactly what the browser handed over (which makes the Android-layer naming visible). Recovering true `VID_…`/`IMG_…` names - like location - needs the native Android app reading `DISPLAY_NAME` from MediaStore.

### Possible follow-ups (not blockers)
- No rate-limiting on PIN attempts. A 6-digit PIN against a transient same-LAN server is acceptable, but a few-tries lockout would harden the manual-entry path.
- Still plaintext HTTP. TLS would need a self-signed cert + a trust step on the Android browser - deferred.

### Left for an on-device pass
- Confirm multi-select works with `maxSelectionCount: nil` (#2); hybrid send path returns originals **with GPS/EXIF** under both full and limited access (#3).
- End-to-end PIN flow (#1): QR scan auto-connects; manual address entry prompts for the PIN; wrong PIN → 401 + re-prompt; upload→Photos and download both succeed with the PIN.
- Theme toggle persists and looks right in both schemes on device + in the Android browser.
