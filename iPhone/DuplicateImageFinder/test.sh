#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${DUPLICATE_IMAGE_FINDER_IOS_TEST_BUILD_DIR:-/private/tmp/DuplicateImageFinderiOSTests}"
TEST_BIN="$BUILD_DIR/image-fingerprint-smoke-test"

mkdir -p "$BUILD_DIR"

xcrun swiftc \
  -swift-version 5 \
  -O \
  -target arm64-apple-macosx14.0 \
  "$ROOT_DIR/DuplicateImageFinderiOS/ImageFingerprint.swift" \
  "$ROOT_DIR/Tests/ImageFingerprintSmokeTest.swift" \
  -o "$TEST_BIN" \
  -framework AppKit \
  -framework CoreImage \
  -framework CryptoKit \
  -framework ImageIO

"$TEST_BIN"

