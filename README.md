# PhoneApps

A small monorepo of companion phone apps, organised by platform.

```
PhoneApps/
├── iPhone/
│   ├── GalleryTransfer/       # Wi-Fi photo/video transfer between Android and iPhone (SwiftUI)
│   └── DuplicateImageFinder/  # On-device duplicate-photo scanner (SwiftUI)
└── Android/
    └── GalleryTransfer/       # Companion app for GalleryTransfer (Kotlin) - in progress
```

## iPhone apps

Each app folder holds its own `.xcodeproj`. Open it in Xcode, or use the per-app
build script:

```zsh
cd iPhone/GalleryTransfer && ./build-gallery-transfer.sh
cd iPhone/DuplicateImageFinder && ./build.sh
```

## Android apps

Open `Android/GalleryTransfer` in Android Studio (it brings its own SDK, JDK and
Gradle). The GalleryTransfer Android app is the companion that talks to the iPhone
app's local server; it exists so photos keep their **GPS location and original
filenames**, which a plain browser upload loses to Android scoped-storage redaction.

See each app's `README.md` and `CODE_REVIEW.md` for details.
