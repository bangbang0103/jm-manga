#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"
OUT_ROOT="${OUT_ROOT:-${ROOT_DIR}/build}"
APP_NAME="${APP_NAME:-jm-manga-server}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

usage() {
  cat <<'EOF'
Usage: scripts/package-server.sh [tar.gz|zip]

Package the tracked files under server/ into a deployable archive.

Outputs are written to the repository-level build/ directory:
  build/jm-manga-server-v<version>.tar.gz
  build/jm-manga-server-v<version>.tar.gz.sha256

Notes:
  - Only tracked files are included (git archive), so local runtime data
    such as .venv, cache/, logs/, __pycache__/ and .env are excluded.
  - Run this script from a git clone with the server/ tree committed.

Environment:
  APP_NAME=jm-manga-server    Artifact name prefix. Default: jm-manga-server
  OUT_ROOT=/path/to/output    Output root. Default: build
EOF
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

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "VERSION file not found: ${VERSION_FILE}" >&2
  exit 1
fi

version="$(tr -d '[:space:]' < "${VERSION_FILE}")"

format="${1:-tar.gz}"
case "${format}" in
  -h|--help)
    usage
    exit 0
    ;;
  tar.gz|zip)
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

out_dir="${OUT_ROOT}"
mkdir -p "${out_dir}"
out_path="${out_dir}/${APP_NAME}-v${version}.${format}"
rm -f "${out_path}"

echo "==> Packaging tracked server/ files into ${out_path}"

case "${format}" in
  tar.gz)
    git -C "${ROOT_DIR}" archive --format=tar.gz HEAD server/ > "${out_path}"
    ;;
  zip)
    git -C "${ROOT_DIR}" archive --format=zip HEAD server/ > "${out_path}"
    ;;
esac

echo "Packaged ${out_path}"
write_checksum "${out_path}"
