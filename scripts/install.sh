#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}/.codex/skills/agency-codex-router"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR=""
FORCE_PROFILE="false"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh [--project /path/to/repo] [--force-profile]

Options:
  --project PATH    Install the skill and initialize PATH/.codex/project-profile.md
  --force-profile   Overwrite an existing project profile
  -h, --help        Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --force-profile)
      FORCE_PROFILE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

mkdir -p "${HOME}/.codex/skills"
rm -rf "${TARGET_DIR}"
cp -R "${SOURCE_DIR}" "${TARGET_DIR}"

echo "Installed to ${TARGET_DIR}"

if [[ -n "${PROJECT_DIR}" ]]; then
  if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo "Project directory does not exist: ${PROJECT_DIR}" >&2
    exit 1
  fi

  PROFILE_DIR="${PROJECT_DIR}/.codex"
  PROFILE_FILE="${PROFILE_DIR}/project-profile.md"
  TEMPLATE_FILE="${SOURCE_DIR}/examples/project-profile.example.md"

  mkdir -p "${PROFILE_DIR}"

  if [[ -f "${PROFILE_FILE}" && "${FORCE_PROFILE}" != "true" ]]; then
    echo "Project profile already exists at ${PROFILE_FILE}"
    echo "Use --force-profile to overwrite it."
  else
    cp "${TEMPLATE_FILE}" "${PROFILE_FILE}"
    echo "Initialized project profile at ${PROFILE_FILE}"
  fi
fi
