#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="${SCHEME:-CreatorFunnelOS}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${CREATOR_FUNNEL_OS_BUILD_DIR:-/private/tmp/CreatorFunnelOSBuild}"
DERIVED_DATA_PATH="${CREATOR_FUNNEL_OS_DERIVED_DATA:-/private/tmp/CreatorFunnelOSDerivedData}"
MODULE_CACHE_PATH="${CREATOR_FUNNEL_OS_MODULE_CACHE:-/private/tmp/CreatorFunnelOSModuleCache}"

xcodebuild \
  -project "$ROOT_DIR/CreatorFunnelOS.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_PATH" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
