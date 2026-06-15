#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="${SCHEME:-GalleryTransferiOS}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${GALLERY_TRANSFER_IOS_BUILD_DIR:-/private/tmp/GalleryTransferiOSBuild}"
DERIVED_DATA_PATH="${GALLERY_TRANSFER_IOS_DERIVED_DATA:-/private/tmp/GalleryTransferiOSDerivedData}"
MODULE_CACHE_PATH="${GALLERY_TRANSFER_IOS_MODULE_CACHE:-/private/tmp/GalleryTransferiOSModuleCache}"

xcodebuild \
  -project "$ROOT_DIR/GalleryTransferiOS.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_PATH" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
