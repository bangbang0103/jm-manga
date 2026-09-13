#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
OUT_ROOT="${OUT_ROOT:-${ROOT_DIR}/build}"
APP_NAME="${APP_NAME:-jm-manga}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

usage() {
  cat <<'EOF'
Usage: scripts/release.sh [all|mobile|apk|ios|desktop|macos|windows]

Build release artifacts for the current VERSION.

Targets:
  all      Build mobile (APK + iOS). Default.
  mobile   Build mobile only (APK + iOS).
  apk      Build Android APK only.
  ios      Build unsigned iOS IPA only.
  desktop  Build the desktop artifact for the current host (macOS or Windows).
  macos    Build macOS .app zip only. Requires macOS.
  windows  Build Windows runner zip only. Requires Windows.

Environment:
  APP_NAME=jm-manga                  Mobile artifact prefix. Default: jm-manga
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
  all|mobile|apk|ios|desktop|macos|windows)
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: ${ROOT_DIR}" >&2
  exit 1
fi

dirty_files="$(git -C "${ROOT_DIR}" status --porcelain --untracked-files=no)"
if [[ -n "${dirty_files}" ]]; then
  echo "Working tree has uncommitted changes to tracked files:" >&2
  echo "${dirty_files}" >&2
  echo "Commit or stash them, then re-run this script." >&2
  exit 1
fi

pubspec_version="$(awk '/^version:/ {print $2; exit}' "${ROOT_DIR}/app/pubspec.yaml")"
pubspec_version="${pubspec_version%%+*}"
if [[ "${pubspec_version}" != "${version}" ]]; then
  echo "Version mismatch: VERSION=${version}, app/pubspec.yaml=${pubspec_version}" >&2
  echo "Run scripts/sync-version.sh first, then re-run this script." >&2
  exit 1
fi

run_flutter() {
  local flutter_target="$1"
  "${ROOT_DIR}/scripts/build-flutter.sh" "${flutter_target}"
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
    desktop|macos|windows)
      patterns+=(
        "${OUT_ROOT}/${APP_NAME}-desktop-v${version}-*.zip"
        "${OUT_ROOT}/${APP_NAME}-desktop-v${version}-*.zip.sha256"
      )
      ;;
  esac

  local any=0
  # Empty IFS disables word splitting so paths with spaces expand as one
  # word, while pathname expansion (glob) still applies to the pattern.
  local IFS=
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
    run_flutter all
    ;;
  mobile)
    run_flutter all
    ;;
  apk)
    run_flutter apk
    ;;
  ios)
    run_flutter ios
    ;;
  desktop|macos|windows)
    run_flutter "${target}"
    ;;
esac

echo ""
echo "==> Release artifacts for v${version}:"
ls -1 "${OUT_ROOT}" | grep -E "${APP_NAME}-(apk|unsigned-ipa|unsigned-app|desktop)-v${version}[-.]" || true
