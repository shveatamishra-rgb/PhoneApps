#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="${SCHEME:-Ferry}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${FERRY_BUILD_DIR:-/private/tmp/FerryBuild}"
DERIVED_DATA_PATH="${FERRY_DERIVED_DATA:-/private/tmp/FerryDerivedData}"
MODULE_CACHE_PATH="${FERRY_MODULE_CACHE:-/private/tmp/FerryModuleCache}"

xcodebuild \
  -project "$ROOT_DIR/Ferry.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_PATH" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
