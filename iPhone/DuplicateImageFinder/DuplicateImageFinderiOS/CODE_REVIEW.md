# DuplicateImageFinderiOS — Code Review & Fix Handoff

> Handoff doc for a fresh chat. Review done 2026-06-15. **No fixes applied yet** — all items below are open.

## What this app is
SwiftUI iOS app (iOS 17+, bundle `com.shveatamishra.duplicateimagefinder.iphone`), the iPhone port of the macOS Duplicate Image Finder. On-device PhotoKit scan for three duplicate kinds: **byte-identical**, **pixel-identical** (oriented sRGB decode), and **look-alike** (perceptual hash after recompression/resize). Supports limited Photos access and importing image files (e.g. WhatsApp exports) from the Files app.

Key files:
- `ImageFingerprint.swift` — byte SHA-256, pixel SHA-256 (full-res RGBA decode), perceptual `visualHash` (9×8 dHash + 32×32 luma signature), screenshot-precision matching.
- `PhotoLibraryDuplicateScanner.swift` — fetch candidates, byte/pixel/visual passes, BK-tree + disjoint-set grouping, `ImportedImageStore`.
- `ContentView.swift` — UI + `ScanViewModel` (`@MainActor`), thumbnail/full-image loaders, delete flow.
- `Tests/ImageFingerprintSmokeTest.swift` — macOS standalone test of the fingerprint logic.

## Build / verify
```zsh
cd iPhone/DuplicateImageFinder && ./build.sh   # builds DuplicateImageFinderiOS for iphonesimulator
cd iPhone/DuplicateImageFinder && ./test.sh    # compiles + runs ImageFingerprint smoke test on macOS
```
Last result: **BUILD SUCCEEDED** (Xcode 26.5 SDK, iOS 17 sim); smoke test **passed** (recompressed-JPEG visual distance 0; screenshot false-positive protection holds).

## Findings (open)

### Ship-blockers (do before App Store submit)
- [ ] **#4 Privacy manifest missing a required-reason declaration.** Scanner reads `.contentModificationDateKey` (`PhotoLibraryDuplicateScanner.swift:315`) = **File Timestamp** required-reason API, but `NSPrivacyAccessedAPITypes` is empty. App Store Connect will flag/reject. Add `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1`. — `PrivacyInfo.xcprivacy:6`.
- [ ] **#1 Full-res RGBA decode can trigger memory-pressure (jetsam) termination.** `pixelSHA256` allocates `width × height × 4` bytes; cap is `maxDecodedBytes = 1_500_000_000` (1.5 GB — a macOS-era value). A 48 MP photo ≈ 190 MB in one allocation; iOS kills the app well before 1.5 GB on low-RAM devices. Lower the cap to ~150–250 MB and skip oversized images, or downsample to a fixed comparison resolution before hashing. — `ImageFingerprint.swift:110` (cap) and `:126` (alloc).

### High-value, low-effort
- [ ] **#2 New `CIContext` created per render call.** `render(...)` builds `CIContext(options:)` every invocation, up to 3× per image (full-res pixel hash + 9×8 + 32×32). `CIContext` creation is expensive → big scan-time cost on large libraries. Make it a cached `static let` and reuse. — `ImageFingerprint.swift:262`.
- [ ] **#3 `requestImage` continuations can hang/leak on failure.** `FullImageLoader.requestPreview` and `ThumbnailLoader.requestThumbnail` do `if degraded { return }` and only resume on a non-degraded result. If only degraded callbacks arrive (e.g. iCloud fetch fails with `.opportunistic`), the continuation never resumes → `await` hangs forever + leak. Handle `info[PHImageErrorKey]`/cancellation and resume on final delivery even when image is nil (mirror `photoImageData` in the scanner). — `ContentView.swift:690` (full), `:760` (thumbnail).

### Hardening / UX
- [ ] **#5 Scan silently downloads the entire iCloud library.** `isNetworkAccessAllowed = true` + `.highQualityFormat` + full-res data pulls every original from iCloud on an "Optimize iPhone Storage" library — potentially GBs, no warning. Add a toggle ("scan iCloud originals") or a UI heads-up. — `PhotoLibraryDuplicateScanner.swift:593`.

### Minor / by-design
- Byte hash uses original `.photo` resource (`:547`) while pixel/visual use `version = .current` (edited) (`:591`) — edited photos can disagree across modes.
- Look-alike candidate buckets are aspect-ratio ±1 (~±2%) (`:464`) — a **cropped** copy (aspect change) can be missed. Fine for the recompress/resize WhatsApp use case.
- Manual selection allows selecting every image in a group (no "keep at least one" guard); "Select Extras" correctly preserves the first.

### Good (keep)
- Screenshot-precision path (stricter hash + luma + dark-mask Jaccard) avoids grouping unrelated text-heavy screenshots.
- BK-tree + disjoint-set grouping scales well.
- Heavy scan work runs off the main thread (nonisolated async on the global executor), UI stays responsive.

## Suggested order
1. #4 (privacy manifest) — required, trivial.
2. #1 (decode cap) — required, small.
3. #2 (shared CIContext) — perf, small.
4. #3 (continuation fix) — correctness, small.
5. #5 (iCloud warning) — UX.

After any change: re-run `./build.sh` (and `./test.sh` if `ImageFingerprint.swift` changed) and update the checkboxes above.
