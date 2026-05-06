#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}/.codex/skills/agency-codex-router-guard"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR=""
FORCE_PROFILE="false"
PROFILE_LANG="zh"
PROFILE_MODE="auto"
PROJECT_GOAL=""
SUCCESS_METRIC=""
STACK_CHOICE=""
ARTIFACT_SHAPE=""
FIRST_MOVE=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh [--project /path/to/repo] [--lang zh|en] [--mode auto|scan|dialog|template] [--goal VALUE] [--success VALUE] [--stack VALUE] [--artifact VALUE] [--first-move VALUE] [--force-profile]

Options:
  --project PATH    Install the skill and initialize PATH/.codex/project-profile.md
  --lang LANG       Profile template language: zh (default) or en
  --mode MODE       auto (default), scan existing repo, dialog for new project, or template
  --goal VALUE      New-project goal, e.g. website, web app, api, presentation, content
  --success VALUE   Success metric, e.g. ready-to-ship, looks-better, more-reliable
  --stack VALUE     Stack hint, e.g. react, nextjs, python, nodejs, undecided
  --artifact VALUE  Deliverable, e.g. repo, page, api, slides, document
  --first-move VALUE First priority, e.g. clarify-plan, scaffold, build-ui, build-backend, write-copy, validate
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
    --lang)
      PROFILE_LANG="${2:-}"
      shift 2
      ;;
    --mode)
      PROFILE_MODE="${2:-}"
      shift 2
      ;;
    --goal)
      PROJECT_GOAL="${2:-}"
      shift 2
      ;;
    --success)
      SUCCESS_METRIC="${2:-}"
      shift 2
      ;;
    --stack)
      STACK_CHOICE="${2:-}"
      shift 2
      ;;
    --artifact)
      ARTIFACT_SHAPE="${2:-}"
      shift 2
      ;;
    --first-move)
      FIRST_MOVE="${2:-}"
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

if [[ "${PROFILE_LANG}" != "zh" && "${PROFILE_LANG}" != "en" ]]; then
  echo "Unsupported language: ${PROFILE_LANG}. Use zh or en." >&2
  exit 1
fi

if [[ "${PROFILE_MODE}" != "auto" && "${PROFILE_MODE}" != "scan" && "${PROFILE_MODE}" != "dialog" && "${PROFILE_MODE}" != "template" ]]; then
  echo "Unsupported mode: ${PROFILE_MODE}. Use auto, scan, dialog, or template." >&2
  exit 1
fi

mkdir -p "${HOME}/.codex/skills"
rm -rf "${TARGET_DIR}"
cp -R "${SOURCE_DIR}" "${TARGET_DIR}"

echo "Installed to ${TARGET_DIR}"
chmod +x "${TARGET_DIR}/scripts/"*.sh

if [[ -n "${PROJECT_DIR}" ]]; then
  if [[ ! -d "${PROJECT_DIR}" ]]; then
    echo "Project directory does not exist: ${PROJECT_DIR}" >&2
    exit 1
  fi

  INIT_ARGS=(--project "${PROJECT_DIR}" --lang "${PROFILE_LANG}" --mode "${PROFILE_MODE}")

  if [[ -n "${PROJECT_GOAL}" ]]; then
    INIT_ARGS+=(--goal "${PROJECT_GOAL}")
  fi
  if [[ -n "${SUCCESS_METRIC}" ]]; then
    INIT_ARGS+=(--success "${SUCCESS_METRIC}")
  fi
  if [[ -n "${STACK_CHOICE}" ]]; then
    INIT_ARGS+=(--stack "${STACK_CHOICE}")
  fi
  if [[ -n "${ARTIFACT_SHAPE}" ]]; then
    INIT_ARGS+=(--artifact "${ARTIFACT_SHAPE}")
  fi
  if [[ -n "${FIRST_MOVE}" ]]; then
    INIT_ARGS+=(--first-move "${FIRST_MOVE}")
  fi

  if [[ "${FORCE_PROFILE}" == "true" ]]; then
    INIT_ARGS+=(--force)
  fi

  bash "${SOURCE_DIR}/scripts/init-project.sh" "${INIT_ARGS[@]}"
fi
