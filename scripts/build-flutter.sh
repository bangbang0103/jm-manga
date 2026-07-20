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
Usage: scripts/build-flutter.sh <apk|ios|macos|windows|desktop|all>

Targets:
  apk|ios   Mobile artifacts (all = apk + ios).
  macos     macOS .app zip. Requires macOS with Xcode.
  windows   Windows runner zip. Requires Windows (MSYS2/Git Bash) with VS Build Tools.
  desktop   Desktop artifact for the current host (macos on Darwin, windows on MSYS).

Environment:
  APP_NAME=jm-manga                  Artifact name prefix. Default: jm-manga
  BUILD_MODE=release|debug|profile   Flutter build mode. Default: release
  IOS_EXPORT=unsigned-ipa|unsigned-app
                                      iOS output kind. Default: unsigned-ipa
  CODESIGN_IDENTITY=<identity>        Optional macOS re-sign identity applied after the
                                      build, preserving entitlements. Use "-" for ad-hoc.
                                      Default: keep the build's ad-hoc signature.
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
build_config_for_mode() {
  case "${MODE}" in
    release) printf "%s" "Release" ;;
    debug) printf "%s" "Debug" ;;
    profile) printf "%s" "Profile" ;;
    *)
      echo "Unsupported BUILD_MODE: ${MODE}" >&2
      exit 2
      ;;
  esac
}

# 用指定身份重签 macOS app，保留 entitlements。
#
# 裸 `codesign --force --deep --sign` 会丢弃全部 entitlements（sandbox、
# network 等），因此这里：
# 1. 从签名证书提取 Team ID，展开 entitlements 里的 $(AppIdentifierPrefix)；
# 2. 由内向外逐个签名嵌套组件（Framework/dylib/appex），不用 --deep；
# 3. 最后带展开后的 entitlements 签主 bundle，并校验签名。
resign_macos_app() {
  local app_dir="$1"
  local identity="$2"
  local config="$3"

  local entitlements_src
  if [[ "${config}" == "Release" ]]; then
    entitlements_src="${ROOT_DIR}/app/macos/Runner/Release.entitlements"
  else
    entitlements_src="${ROOT_DIR}/app/macos/Runner/DebugProfile.entitlements"
  fi

  # ad-hoc（"-"）没有 Team ID，AppIdentifierPrefix 展开为空。
  local prefix=""
  if [[ "${identity}" != "-" ]]; then
    local cert_pem
    if [[ "${identity}" =~ ^[0-9A-Fa-f]{40}$ ]]; then
      cert_pem="$(security find-certificate -Z "${identity}" -p 2>/dev/null)"
    else
      cert_pem="$(security find-certificate -c "${identity}" -p 2>/dev/null)"
    fi
    local team_id
    team_id="$(printf "%s" "${cert_pem}" | openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null \
      | sed -n 's/.*OU=\([A-Za-z0-9]*\).*/\1/p' | head -n 1)"
    if [[ -z "${team_id}" ]]; then
      echo "Cannot determine Team ID from signing identity: ${identity}" >&2
      exit 1
    fi
    prefix="${team_id}."
  fi

  local expanded
  expanded="$(mktemp -t macos-entitlements)"
  sed 's/$(AppIdentifierPrefix)/'"${prefix}"'/g' "${entitlements_src}" > "${expanded}"

  echo "==> Re-signing with identity: ${identity}"
  # 先签嵌套组件，再签主 bundle。
  local nested=()
  while IFS= read -r -d '' item; do
    nested+=("${item}")
  done < <(find "${app_dir}/Contents" -depth \( -name "*.framework" -o -name "*.dylib" -o -name "*.appex" \) -print0)
  local item
  for item in ${nested[@]+"${nested[@]}"}; do
    codesign --force --sign "${identity}" "${item}"
  done
  codesign --force --sign "${identity}" --entitlements "${expanded}" "${app_dir}"
  rm -f "${expanded}"

  codesign --verify --deep --strict "${app_dir}" >/dev/null
  echo "==> Re-signed ${app_dir##*/} (entitlements preserved from ${entitlements_src##*/})"
}

build_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "macOS builds require macOS with Xcode installed." >&2
    exit 2
  fi

  local mode_arg version host_platform out_dir config app_dir out_path
  mode_arg="$(flutter_args_for_mode)"
  version="$(app_version)"
  host_platform="$(detect_host_platform)"
  config="$(build_config_for_mode)"
  out_dir="${OUT_ROOT}"
  app_dir="${ROOT_DIR}/app/build/macos/Build/Products/${config}/JM Manga.app"
  out_path="${out_dir}/${APP_NAME}-desktop-v${version}-${host_platform}-${MODE}.zip"

  echo "==> Building Flutter macOS app (${MODE})"
  (cd "${ROOT_DIR}/app" && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build macos "${mode_arg}")

  if [[ ! -d "${app_dir}" ]]; then
    echo "Expected macOS app not found: ${app_dir}" >&2
    exit 1
  fi

  # 默认保留构建产物的 ad-hoc 签名；设置 CODESIGN_IDENTITY 时重签。
  if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    resign_macos_app "${app_dir}" "${CODESIGN_IDENTITY}" "${config}"
  fi

  mkdir -p "${out_dir}"
  rm -f "${out_path}"
  (cd "$(dirname "${app_dir}")" && zip -qry "${out_path}" "$(basename "${app_dir}")")
  echo "Built ${out_path}"
  write_checksum "${out_path}"
}

build_windows() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
      echo "Windows builds require Windows (MSYS2/Git Bash) with Visual Studio Build Tools." >&2
      exit 2
      ;;
  esac

  local mode_arg version host_platform out_dir config arch source_dir out_path
  mode_arg="$(flutter_args_for_mode)"
  version="$(app_version)"
  host_platform="$(detect_host_platform)"
  config="$(build_config_for_mode)"
  arch="x64"
  if [[ "${host_platform}" == *-arm64 ]]; then
    arch="arm64"
  fi
  out_dir="${OUT_ROOT}"
  source_dir="${ROOT_DIR}/app/build/windows/${arch}/runner/${config}"
  out_path="${out_dir}/${APP_NAME}-desktop-v${version}-${host_platform}-${MODE}.zip"

  echo "==> Building Flutter Windows runner (${MODE}, ${arch})"
  (cd "${ROOT_DIR}/app" && "${FLUTTER_BIN}" pub get && "${FLUTTER_BIN}" build windows "${mode_arg}")

  if [[ ! -f "${source_dir}/jm_manga.exe" ]]; then
    echo "Expected Windows runner not found: ${source_dir}/jm_manga.exe" >&2
    exit 1
  fi

  mkdir -p "${out_dir}"
  rm -f "${out_path}"
  (cd "${source_dir}" && zip -qry "${out_path}" .)
  echo "Built ${out_path}"
  write_checksum "${out_path}"
}

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
  macos)
    require_flutter
    build_macos
    ;;
  windows)
    require_flutter
    build_windows
    ;;
  desktop)
    require_flutter
    case "$(uname -s)" in
      Darwin) build_macos ;;
      MINGW*|MSYS*|CYGWIN*) build_windows ;;
      *)
        echo "Unsupported host for desktop builds: $(uname -s)" >&2
        exit 2
        ;;
    esac
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
