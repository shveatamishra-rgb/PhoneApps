#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="${SCHEME:-DivineStillness}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${DIVINE_STILLNESS_BUILD_DIR:-/private/tmp/DivineStillnessBuild}"
DERIVED_DATA_PATH="${DIVINE_STILLNESS_DERIVED_DATA:-/private/tmp/DivineStillnessDerivedData}"
MODULE_CACHE_PATH="${DIVINE_STILLNESS_MODULE_CACHE:-/private/tmp/DivineStillnessModuleCache}"

xcodebuild \
  -project "$ROOT_DIR/DivineStillness.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_PATH" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
