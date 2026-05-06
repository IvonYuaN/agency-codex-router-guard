#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "${SOURCE_DIR}/scripts/init-project.sh" "$@" --mode scan
