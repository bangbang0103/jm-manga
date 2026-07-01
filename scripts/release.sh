#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
OUT_ROOT="${OUT_ROOT:-${ROOT_DIR}/build}"
APP_NAME="${APP_NAME:-jm-manga}"
SERVER_APP_NAME="${SERVER_APP_NAME:-jm-manga-server}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

usage() {
  cat <<'EOF'
Usage: scripts/release.sh [all|mobile|server|apk|ios]

Build release artifacts for the current VERSION.

Targets:
  all      Build mobile (APK + iOS) and server package. Default.
  mobile   Build mobile only (APK + iOS).
  server   Package server/ into a tar.gz archive.
  apk      Build Android APK only.
  ios      Build unsigned iOS IPA only.

Environment:
  APP_NAME=jm-manga                  Mobile artifact prefix. Default: jm-manga
  SERVER_APP_NAME=jm-manga-server    Server artifact prefix. Default: jm-manga-server
  BUILD_MODE=release|debug|profile   Flutter build mode. Default: release
  IOS_EXPORT=unsigned-ipa|unsigned-app  iOS output kind. Default: unsigned-ipa
  OUT_ROOT=/path/to/output           Output root. Default: build
  FLUTTER_BIN=/path/to/flutter       Flutter executable. Default: flutter

Outputs are written to the repository-level build/ directory.
EOF
}

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "VERSION file not found: ${VERSION_FILE}" >&2
  exit 1
fi

version="$(tr -d '[:space:]' < "${VERSION_FILE}")"

target="${1:-all}"
case "${target}" in
  -h|--help)
    usage
    exit 0
    ;;
  all|mobile|server|apk|ios)
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

run_mobile() {
  local mobile_target="$1"
  "${ROOT_DIR}/scripts/build-flutter.sh" "${mobile_target}"
}

run_server() {
  "${ROOT_DIR}/scripts/package-server.sh" tar.gz
}

# Clean current-version artifacts so stale files are not left behind.
clean_current_artifacts() {
  local patterns=()
  case "${target}" in
    all|mobile)
      patterns+=(
        "${OUT_ROOT}/${APP_NAME}-apk-v${version}-android-*.apk"
        "${OUT_ROOT}/${APP_NAME}-apk-v${version}-android-*.apk.sha256"
        "${OUT_ROOT}/${APP_NAME}-unsigned-ipa-v${version}-ios-*.ipa"
        "${OUT_ROOT}/${APP_NAME}-unsigned-ipa-v${version}-ios-*.ipa.sha256"
        "${OUT_ROOT}/${APP_NAME}-unsigned-app-v${version}-ios-*.zip"
        "${OUT_ROOT}/${APP_NAME}-unsigned-app-v${version}-ios-*.zip.sha256"
      )
      ;;
    apk)
      patterns+=(
        "${OUT_ROOT}/${APP_NAME}-apk-v${version}-android-*.apk"
        "${OUT_ROOT}/${APP_NAME}-apk-v${version}-android-*.apk.sha256"
      )
      ;;
    ios)
      patterns+=(
        "${OUT_ROOT}/${APP_NAME}-unsigned-ipa-v${version}-ios-*.ipa"
        "${OUT_ROOT}/${APP_NAME}-unsigned-ipa-v${version}-ios-*.ipa.sha256"
        "${OUT_ROOT}/${APP_NAME}-unsigned-app-v${version}-ios-*.zip"
        "${OUT_ROOT}/${APP_NAME}-unsigned-app-v${version}-ios-*.zip.sha256"
      )
      ;;
  esac
  if [[ "${target}" == "all" || "${target}" == "server" ]]; then
    patterns+=(
      "${OUT_ROOT}/${SERVER_APP_NAME}-v${version}.tar.gz"
      "${OUT_ROOT}/${SERVER_APP_NAME}-v${version}.tar.gz.sha256"
    )
  fi

  local any=0
  for pattern in "${patterns[@]}"; do
    for f in ${pattern}; do
      if [[ -e "${f}" ]]; then
        rm -f "${f}"
        any=1
      fi
    done
  done
}

clean_current_artifacts

case "${target}" in
  all)
    run_mobile all
    run_server
    ;;
  mobile)
    run_mobile all
    ;;
  server)
    run_server
    ;;
  apk)
    run_mobile apk
    ;;
  ios)
    run_mobile ios
    ;;
esac

echo ""
echo "==> Release artifacts for v${version}:"
ls -1 "${OUT_ROOT}" | grep -E "(${APP_NAME}-(apk|unsigned-ipa|unsigned-app)-v${version}|${SERVER_APP_NAME}-v${version})[-.]" || true
