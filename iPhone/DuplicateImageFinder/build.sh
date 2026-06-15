#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${TARGET:-DuplicateImageFinderiOS}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${DUPLICATE_IMAGE_FINDER_IOS_BUILD_DIR:-/private/tmp/DuplicateImageFinderiOSBuild}"

xcodebuild \
  -project "$ROOT_DIR/DuplicateImageFinderiOS.xcodeproj" \
  -target "$TARGET" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
