#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ROOT="${OUT_ROOT:-${ROOT_DIR}/build}"
APP_NAME="${APP_NAME:-jm-manga}"
SERVER_PLATFORM="${SERVER_PLATFORM:-python}"
SERVER_INCLUDE_WEB="${SERVER_INCLUDE_WEB:-false}"
SERVER_BUILD_WEB="${SERVER_BUILD_WEB:-false}"
SERVER_WEB_SOURCE="${SERVER_WEB_SOURCE:-${ROOT_DIR}/server/web}"

usage() {
  cat <<'EOF'
Usage: scripts/build-server-package.sh

Packages the Python server source. It does not build a server binary.

Environment:
  APP_NAME=jm-manga                  Artifact name prefix. Default: jm-manga
  OUT_ROOT=/path/to/output           Output root. Default: build
  SERVER_PLATFORM=python             Artifact platform label. Default: python
  SERVER_INCLUDE_WEB=true|false      Include Flutter Web files. Default: false
  SERVER_BUILD_WEB=true|false        Build Flutter Web before packaging. Default: false
  SERVER_WEB_SOURCE=/path/to/web     Web files to include. Default: server/web
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

server_version() {
  tr -d '[:space:]' < "${ROOT_DIR}/VERSION"
}

sanitize_label() {
  printf "%s" "$1" | tr ' /:' '---'
}

copy_server_source() {
  local stage_dir="$1"
  mkdir -p "${stage_dir}/server"

  rsync -a \
    --exclude='.DS_Store' \
    --exclude='.env' \
    --exclude='.venv' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='.ruff_cache' \
    --exclude='*.spec' \
    --exclude='build' \
    --exclude='dist' \
    --exclude='data' \
    --exclude='web' \
    "${ROOT_DIR}/server/" "${stage_dir}/server/"

  if [[ -f "${ROOT_DIR}/README.md" ]]; then
    cp -f "${ROOT_DIR}/README.md" "${stage_dir}/README.md"
  fi
  cp -f "${ROOT_DIR}/VERSION" "${stage_dir}/VERSION"
  if [[ -f "${ROOT_DIR}/scripts/jm-manga-server.service" ]]; then
    mkdir -p "${stage_dir}/scripts"
    cp -f "${ROOT_DIR}/scripts/jm-manga-server.service" "${stage_dir}/scripts/"
  fi
}

include_web_assets() {
  local stage_dir="$1"

  if [[ "${SERVER_BUILD_WEB}" == "true" ]]; then
    WEB_SERVER_DIR="${ROOT_DIR}/server/web" "${ROOT_DIR}/scripts/build-flutter.sh" web
    SERVER_WEB_SOURCE="${ROOT_DIR}/server/web"
  fi

  if [[ ! -f "${SERVER_WEB_SOURCE}/index.html" ]]; then
    echo "Web assets not found at ${SERVER_WEB_SOURCE}. Build web first or set SERVER_BUILD_WEB=true." >&2
    exit 1
  fi

  mkdir -p "${stage_dir}/server/web"
  cp -R "${SERVER_WEB_SOURCE}/." "${stage_dir}/server/web/"
}

version="$(server_version)"
if [[ -z "${version}" ]]; then
  echo "Could not determine server version." >&2
  exit 1
fi

function_label="server-source"
if [[ "${SERVER_INCLUDE_WEB}" == "true" ]]; then
  function_label="server-source-web"
fi

platform_label="$(sanitize_label "${SERVER_PLATFORM}")"
artifact_name="${APP_NAME}-${function_label}-v${version}-${platform_label}.tar.gz"
out_dir="${OUT_ROOT}"
out_path="${out_dir}/${artifact_name}"
stage_root="$(mktemp -d "${TMPDIR:-/tmp}/jm-manga-server-package-${function_label}.XXXXXX")"
stage_dir="${stage_root}/${APP_NAME}-${function_label}-v${version}"

mkdir -p "${stage_dir}" "${out_dir}"
trap 'rm -rf "${stage_root}"' EXIT

copy_server_source "${stage_dir}"

if [[ "${SERVER_INCLUDE_WEB}" == "true" ]]; then
  include_web_assets "${stage_dir}"
fi

rm -f "${out_path}"
LC_ALL=C tar -C "${stage_root}" -czf "${out_path}" "$(basename "${stage_dir}")"

echo "Built ${out_path}"
