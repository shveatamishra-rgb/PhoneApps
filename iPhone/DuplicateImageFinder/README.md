# Duplicate Image Finder for iPhone

A native iOS SwiftUI app for scanning the iPhone Photo Library for duplicate images.

## What It Detects

- **Byte-identical**: photo resources that match byte for byte.
- **Pixel-identical**: images that decode to the same oriented sRGB pixels, matching the macOS app's pixel criteria.
- **Look-alike**: visually matching images after recompression, resizing, or forwarding through apps such as WhatsApp.

The scanner uses PhotoKit, runs on-device, and requests Photo Library permission before scanning. Limited Photos access is supported; the app scans only the images the user has granted.

## WhatsApp Images

iOS does not allow one app to scan another app's private storage. If WhatsApp is set not to save media into Photos, those images will not appear in a Photo Library scan.

To include those images, share or save them from WhatsApp into the Files app, then use **Import Images** in Duplicate Image Finder. Imported images are copied into the app's private storage and scanned together with Photos, so a WhatsApp export can still match the original camera photo by visual look.

## Reviewing Results

Tap any image in a duplicate set, or use **Compare**, to open the group full screen. Swipe between the images to compare them closely, then use **Select for Delete** on the copies you want removed.

The look-alike matcher is stricter for screenshots so text-heavy screenshots with different content are less likely to be grouped together just because their layouts are similar.

## Build

Open `DuplicateImageFinderiOS.xcodeproj` in Xcode and run the `DuplicateImageFinderiOS` scheme on an iPhone or iOS Simulator.

From the command line:

```zsh
./build.sh
```

## Test

```zsh
./test.sh
```

The smoke test generates temporary images and verifies exact pixel matching, visual matching for recompressed images with different bytes, and screenshot false-positive protection.
