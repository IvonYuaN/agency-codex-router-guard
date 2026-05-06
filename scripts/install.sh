#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}/.codex/skills/agency-codex-router"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "${HOME}/.codex/skills"
rm -rf "${TARGET_DIR}"
cp -R "${SOURCE_DIR}" "${TARGET_DIR}"

echo "Installed to ${TARGET_DIR}"
