#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${OUT_ROOT:-${ROOT_DIR}/build}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
APP_NAME="${APP_NAME:-jm-manga}"
MODE="${BUILD_MODE:-release}"
IOS_EXPORT="${IOS_EXPORT:-unsigned-ipa}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

usage() {
  cat <<'EOF'
Usage: scripts/build-flutter.sh <apk|ios|all>

Environment:
  APP_NAME=jm-manga                  Artifact name prefix. Default: jm-manga
  BUILD_MODE=release|debug|profile   Flutter build mode. Default: release
  IOS_EXPORT=unsigned-ipa|unsigned-app
                                      iOS output kind. Default: unsigned-ipa
  FLUTTER_BIN=/path/to/flutter       Flutter executable. Default: flutter
  OUT_ROOT=/path/to/output           Output root. Default: build
EOF
}

project_version() {
  tr -d '[:space:]' < "${ROOT_DIR}/VERSION"
}

app_version() {
  local version pubspec_version build_number
  version="$(project_version)"
  pubspec_version="$(awk '/^version:/ {print $2; exit}' "${ROOT_DIR}/app/pubspec.yaml")"
  if [[ "${pubspec_version}" == *+* ]]; then
    build_number="${pubspec_version#*+}"
    printf "%s+%s" "${version}" "${build_number}"
    return
  fi
  printf "%s" "${version}"
}

detect_host_platform() {
  local os arch
  case "$(uname -s)" in
    Darwin) os="macos" ;;
    Linux) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) os="$(uname -s | tr '[:upper:]' '[:lower:]')" ;;
  esac

  case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64) arch="x64" ;;
    *) arch="$(uname -m)" ;;
  esac

  printf "%s-%s" "${os}" "${arch}"
}

require_flutter() {
  if ! command -v "${FLUTTER_BIN}" >/dev/null 2>&1; then
    echo "Flutter executable not found: ${FLUTTER_BIN}" >&2
    exit 127
  fi
}

flutter_args_for_mode() {
  case "${MODE}" in
    release) printf "%s" "--release" ;;
    debug) printf "%s" "--debug" ;;
    profile) printf "%s" "--profile" ;;
    *)
      echo "Unsupported BUILD_MODE: ${MODE}" >&2
      exit 2
      ;;
  esac
}

write_checksum() {
  local file="$1"
  local checksum_file="${file}.sha256"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$(dirname "${file}")" && sha256sum "$(basename "${file}")") > "${checksum_file}"
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$(dirname "${file}")" && shasum -a 256 "$(basename "${file}")") > "${checksum_file}"
  else
    echo "Warning: neither sha256sum nor shasum found, skipping checksum for ${file}" >&2
    return 0
  fi
  echo "Checksum ${checksum_file}"
}

build_apk() {
  local mode_arg source out_dir out_path version
  mode_arg="$(flutter_args_for_mode)"
  version="$(app_version)"
  out_dir="${OUT_ROOT}"
  out_path="${out_dir}/${APP_NAME}-apk-v${version}-android-${MODE}.apk"

  echo "==> Building Flutter APK (${MODE})"
  (cd "${ROOT_DIR}/app" && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build apk "${mode_arg}")

  source="${ROOT_DIR}/app/build/app/outputs/flutter-apk/app-${MODE}.apk"
  if [[ ! -f "${source}" ]]; then
    echo "Expected APK not found: ${source}" >&2
    exit 1
  fi

  mkdir -p "${out_dir}"
  cp -f "${source}" "${out_path}"
  echo "Built ${out_path}"
  write_checksum "${out_path}"
}

build_ios() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "iOS builds require macOS with Xcode installed." >&2
    exit 2
  fi

  local mode_arg out_dir version host_platform
  mode_arg="$(flutter_args_for_mode)"
  version="$(app_version)"
  host_platform="$(detect_host_platform)"
  out_dir="${OUT_ROOT}"

  mkdir -p "${out_dir}"

  if [[ "${IOS_EXPORT}" == "unsigned-ipa" ]]; then
    local unsigned_root unsigned_ipa
    unsigned_root="${ROOT_DIR}/app/build/ios/unsigned-ipa"
    unsigned_ipa="${out_dir}/${APP_NAME}-unsigned-ipa-v${version}-ios-${MODE}.ipa"

    echo "==> Building unsigned Flutter iOS IPA (${MODE})"
    (cd "${ROOT_DIR}/app" && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build ios "${mode_arg}" --no-codesign)

    if [[ ! -d "${ROOT_DIR}/app/build/ios/iphoneos/Runner.app" ]]; then
      echo "Expected iOS app not found: ${ROOT_DIR}/app/build/ios/iphoneos/Runner.app" >&2
      exit 1
    fi

    rm -rf "${unsigned_root}"
    mkdir -p "${unsigned_root}/Payload"
    cp -R "${ROOT_DIR}/app/build/ios/iphoneos/Runner.app" "${unsigned_root}/Payload/Runner.app"

    rm -f "${unsigned_ipa}"
    (cd "${unsigned_root}" && zip -qry "${unsigned_ipa}" Payload)
    echo "Built ${unsigned_ipa}"
    write_checksum "${unsigned_ipa}"
    return
  fi

  if [[ "${IOS_EXPORT}" != "unsigned-app" ]]; then
    echo "Unsupported IOS_EXPORT: ${IOS_EXPORT}" >&2
    exit 2
  fi

  echo "==> Building unsigned Flutter iOS app (${MODE})"
  (cd "${ROOT_DIR}/app" && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build ios "${mode_arg}" --no-codesign)

  if [[ ! -d "${ROOT_DIR}/app/build/ios/iphoneos/Runner.app" ]]; then
    echo "Expected iOS app not found: ${ROOT_DIR}/app/build/ios/iphoneos/Runner.app" >&2
    exit 1
  fi

  local app_zip
  app_zip="${out_dir}/${APP_NAME}-unsigned-app-v${version}-ios-${MODE}-${host_platform}.zip"
  rm -f "${app_zip}"
  (cd "${ROOT_DIR}/app/build/ios/iphoneos" && zip -qry "${app_zip}" Runner.app)
  echo "Built ${app_zip}"
  write_checksum "${app_zip}"
}

target="${1:-all}"
case "${target}" in
  -h|--help)
    usage
    ;;
  apk)
    require_flutter
    build_apk
    ;;
  ios)
    require_flutter
    build_ios
    ;;
  all)
    require_flutter
    build_apk
    build_ios
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
