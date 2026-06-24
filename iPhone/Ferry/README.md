# Ferry - Media Transfer (iPhone)

**Ferry** (subtitle: *Media Transfer*) is a SwiftUI iOS app for moving photo and video originals between Android and iPhone over local Wi-Fi. The home-screen name is "Ferry"; "Media Transfer" is the App Store subtitle / tagline.

## What it does

- Runs a local transfer page from the iPhone.
- Lets Android upload photo and video files through a browser.
- Saves received media directly into the iPhone Photos app with PhotoKit.
- Exports selected iPhone Photo Library originals for Android to download.
- Avoids decoding and recompressing media during transfer.
- Shows a QR code for the Android phone to scan.

## Important platform note

Android to iPhone can land directly in iPhone Photos because this iOS app writes received files with PhotoKit.

iPhone to Android is served as original file downloads from the iPhone. The companion **Ferry Android app** (`Android/Ferry`) saves them straight into the Android MediaStore/Gallery with location and capture metadata preserved. A plain browser can still download the files, but only the native app guarantees gallery placement and metadata every time.

## Build

Open `Ferry.xcodeproj` in Xcode and run the `Ferry` target on a physical iPhone. A real device is recommended because local-network receiving and Photos saving are limited in the simulator.

From the command line:

```zsh
./build.sh
```

## Use

1. Open Ferry on the iPhone.
2. Allow Photos access.
3. Tap **Start Receiver**.
4. Open the shown `http://...:8899` address on Android while both phones are on the same Wi-Fi.
5. Upload Android photos or videos to save them directly to iPhone Photos.
6. To send iPhone media to Android, choose photos or videos in the app, then refresh the Android page and download them.
