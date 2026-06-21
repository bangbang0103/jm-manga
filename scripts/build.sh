#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/build.sh <all|server|server-web|flutter|apk|ios|web>

Outputs are copied into the repository-level build/ directory:
  build/jm-manga-server-source-v<version>-<platform>.tar.gz
  build/jm-manga-server-source-web-v<version>-<platform>.tar.gz
  build/jm-manga-flutter-web-v<version>-web-<mode>.tar.gz
  build/jm-manga-flutter-apk-v<version>-android-<mode>.apk
  build/jm-manga-flutter-unsigned-*.zip|*.ipa

Notes:
  - Server builds package Python source files. They do not build a binary.
  - Use the server-web target, or SERVER_INCLUDE_WEB=true, to include Flutter Web.
  - iOS builds require macOS with Xcode installed.
  - APK builds require Flutter plus Android SDK setup.
  - Web builds are also copied to server/web/ by default so FastAPI can serve them.

Environment:
  APP_NAME=jm-manga
  BUILD_MODE=release|debug|profile
  IOS_EXPORT=unsigned-ipa|unsigned-app
  SERVER_PLATFORM=python
  SERVER_INCLUDE_WEB=true|false
  SERVER_BUILD_WEB=true|false
  SERVER_WEB_SOURCE=/path/to/web
  WEB_BASE_HREF=/
  WEB_SERVER_DIR=/path/to/server/web
EOF
}

target="${1:-all}"
case "${target}" in
  -h|--help)
    usage
    ;;
  all)
    "${ROOT_DIR}/scripts/build-server-package.sh"
    "${ROOT_DIR}/scripts/build-flutter.sh" all
    ;;
  server)
    "${ROOT_DIR}/scripts/build-server-package.sh"
    ;;
  server-web)
    SERVER_INCLUDE_WEB=true SERVER_BUILD_WEB=true "${ROOT_DIR}/scripts/build-server-package.sh"
    ;;
  flutter)
    "${ROOT_DIR}/scripts/build-flutter.sh" all
    ;;
  apk)
    "${ROOT_DIR}/scripts/build-flutter.sh" apk
    ;;
  ios)
    "${ROOT_DIR}/scripts/build-flutter.sh" ios
    ;;
  web)
    "${ROOT_DIR}/scripts/build-flutter.sh" web
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
