#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/build.sh <all|apk|ios>

Outputs are copied into the repository-level build/ directory:
  build/jm-manga-apk-v<version>-android-<mode>.apk
  build/jm-manga-apk-v<version>-android-<mode>.apk.sha256
  build/jm-manga-unsigned-ipa-v<version>-ios-<mode>.ipa
  build/jm-manga-unsigned-ipa-v<version>-ios-<mode>.ipa.sha256

Notes:
  - This project only supports mobile builds (Android / iOS).
  - iOS builds require macOS with Xcode installed.
  - APK builds require Flutter plus Android SDK setup.

Environment:
  APP_NAME=jm-manga
  BUILD_MODE=release|debug|profile
  IOS_EXPORT=unsigned-ipa|unsigned-app
EOF
}

target="${1:-all}"
case "${target}" in
  -h|--help)
    usage
    ;;
  all)
    "${ROOT_DIR}/scripts/build-flutter.sh" all
    ;;
  apk)
    "${ROOT_DIR}/scripts/build-flutter.sh" apk
    ;;
  ios)
    "${ROOT_DIR}/scripts/build-flutter.sh" ios
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
