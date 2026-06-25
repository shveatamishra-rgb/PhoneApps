#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="${SCHEME:-BhaktiAngan}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${DIVINE_STILLNESS_BUILD_DIR:-/private/tmp/BhaktiAnganBuild}"
DERIVED_DATA_PATH="${DIVINE_STILLNESS_DERIVED_DATA:-/private/tmp/BhaktiAnganDerivedData}"
MODULE_CACHE_PATH="${DIVINE_STILLNESS_MODULE_CACHE:-/private/tmp/BhaktiAnganModuleCache}"

xcodebuild \
  -project "$ROOT_DIR/BhaktiAngan.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_PATH" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
