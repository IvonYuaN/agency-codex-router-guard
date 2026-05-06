#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
FORCE="false"
PROFILE_LANG="zh"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/init-project.sh --project /path/to/repo [--lang zh|en] [--force]

Options:
  --project PATH    Initialize PATH/.codex/project-profile.md
  --lang LANG       Profile template language: zh (default) or en
  --force           Overwrite an existing project profile
  -h, --help        Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="${2:-}"
      shift 2
      ;;
    --lang)
      PROFILE_LANG="${2:-}"
      shift 2
      ;;
    --force)
      FORCE="true"
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

if [[ -z "${PROJECT_DIR}" ]]; then
  echo "--project is required." >&2
  usage >&2
  exit 1
fi

if [[ "${PROFILE_LANG}" != "zh" && "${PROFILE_LANG}" != "en" ]]; then
  echo "Unsupported language: ${PROFILE_LANG}. Use zh or en." >&2
  exit 1
fi

if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "Project directory does not exist: ${PROJECT_DIR}" >&2
  exit 1
fi

PROFILE_DIR="${PROJECT_DIR}/.codex"
PROFILE_FILE="${PROFILE_DIR}/project-profile.md"

if [[ "${PROFILE_LANG}" == "zh" ]]; then
  TEMPLATE_FILE="${SOURCE_DIR}/examples/project-profile.example.zh-CN.md"
else
  TEMPLATE_FILE="${SOURCE_DIR}/examples/project-profile.example.md"
fi

mkdir -p "${PROFILE_DIR}"

if [[ -f "${PROFILE_FILE}" && "${FORCE}" != "true" ]]; then
  echo "Project profile already exists at ${PROFILE_FILE}"
  echo "Use --force to overwrite it."
  exit 0
fi

cp "${TEMPLATE_FILE}" "${PROFILE_FILE}"
echo "Initialized ${PROFILE_LANG} project profile at ${PROFILE_FILE}"
