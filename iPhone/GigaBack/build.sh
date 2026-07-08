#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${TARGET:-GigaBack}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SDK="${SDK:-iphonesimulator}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
BUILD_ROOT="${GIGABACK_BUILD_DIR:-/private/tmp/GigaBackBuild}"

xcodebuild \
  -project "$ROOT_DIR/GigaBack.xcodeproj" \
  -target "$TARGET" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
  SYMROOT="$BUILD_ROOT/Products" \
  OBJROOT="$BUILD_ROOT/Intermediates" \
  build
