# PhoneApps

A small monorepo of companion phone apps, organised by platform.

```
PhoneApps/
├── iPhone/
│   ├── Ferry/                 # Wi-Fi photo/video transfer between Android and iPhone (SwiftUI)
│   └── DuplicateImageFinder/  # On-device duplicate-photo scanner (SwiftUI)
└── Android/
    └── Ferry/                 # Companion app for Ferry (Kotlin)
```

## iPhone apps

Each app folder holds its own `.xcodeproj`. Open it in Xcode, or use the per-app
build script:

```zsh
cd iPhone/Ferry && ./build.sh
cd iPhone/DuplicateImageFinder && ./build.sh
```

## Android apps

Open `Android/Ferry` in Android Studio (it brings its own SDK, JDK and
Gradle). The Ferry Android app is the companion that talks to the iPhone
app's local server; it exists so photos keep their **GPS location and original
filenames**, which a plain browser upload loses to Android scoped-storage redaction.

See each app's `README.md` and `CODE_REVIEW.md` for details.
