#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "VERSION file not found: ${VERSION_FILE}" >&2
  exit 1
fi

version="$(tr -d '[:space:]' < "${VERSION_FILE}")"
if [[ ! "${version}" =~ ^[0-9]+[.][0-9]+[.][0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Unsupported VERSION value: ${version}" >&2
  exit 2
fi

pubspec="${ROOT_DIR}/app/pubspec.yaml"
current_pubspec_version="$(awk '/^version:/ {print $2; exit}' "${pubspec}")"
build_number="1"
if [[ "${current_pubspec_version}" == *+* ]]; then
  build_number="${current_pubspec_version#*+}"
fi

export JM_MANGA_VERSION="${version}"
export JM_MANGA_FLUTTER_VERSION="${version}+${build_number}"

LC_ALL=C LC_CTYPE=C LANG=C perl -0pi -e \
  's/^version: .+$/version: $ENV{JM_MANGA_FLUTTER_VERSION}/m' \
  "${pubspec}"

echo "Synced version ${JM_MANGA_VERSION}"
echo "Flutter version ${JM_MANGA_FLUTTER_VERSION}"
