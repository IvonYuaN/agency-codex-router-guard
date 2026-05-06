#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
FORCE="false"
PROFILE_LANG="zh"
MODE="auto"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/init-project.sh --project /path/to/repo [--lang zh|en] [--mode auto|scan|dialog|template] [--force]

Options:
  --project PATH    Initialize PATH/.codex/project-profile.md
  --lang LANG       Profile template language: zh (default) or en
  --mode MODE       auto (default), scan existing repo, dialog for new project, or template
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
    --mode)
      MODE="${2:-}"
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

if [[ "${MODE}" != "auto" && "${MODE}" != "scan" && "${MODE}" != "dialog" && "${MODE}" != "template" ]]; then
  echo "Unsupported mode: ${MODE}. Use auto, scan, dialog, or template." >&2
  exit 1
fi

if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "Project directory does not exist: ${PROJECT_DIR}" >&2
  exit 1
fi

PROFILE_DIR="${PROJECT_DIR}/.codex"
PROFILE_FILE="${PROFILE_DIR}/project-profile.md"
INTAKE_FILE="${PROFILE_DIR}/project-intake.md"

if [[ "${PROFILE_LANG}" == "zh" ]]; then
  TEMPLATE_FILE="${SOURCE_DIR}/examples/project-profile.example.zh-CN.md"
  DIALOG_TEMPLATE_FILE="${SOURCE_DIR}/examples/new-project-dialogues.zh-CN.md"
else
  TEMPLATE_FILE="${SOURCE_DIR}/examples/project-profile.example.md"
  DIALOG_TEMPLATE_FILE="${SOURCE_DIR}/examples/new-project-dialogues.md"
fi

mkdir -p "${PROFILE_DIR}"

if [[ -f "${PROFILE_FILE}" && "${FORCE}" != "true" ]]; then
  echo "Project profile already exists at ${PROFILE_FILE}"
  echo "Use --force to overwrite it."
  exit 0
fi

detect_mode() {
  if [[ "${MODE}" != "auto" ]]; then
    printf '%s\n' "${MODE}"
    return
  fi

  if find "${PROJECT_DIR}" -maxdepth 2 -type f \
    ! -path "${PROJECT_DIR}/.git/*" \
    ! -path "${PROJECT_DIR}/.codex/*" \
    ! -name ".DS_Store" | grep -q .; then
    printf '%s\n' "scan"
  else
    printf '%s\n' "dialog"
  fi
}

read_first_line_match() {
  local file="$1"
  local pattern="$2"
  if [[ -f "${file}" ]]; then
    rg -m 1 "${pattern}" "${file}" 2>/dev/null | head -n 1
  fi
}

read_package_field() {
  local field="$1"
  local pkg="${PROJECT_DIR}/package.json"
  if [[ -f "${pkg}" ]]; then
    sed -n "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "${pkg}" | head -n 1
  fi
}

detect_frontend_framework() {
  local deps
  if [[ ! -f "${PROJECT_DIR}/package.json" ]]; then
    return 0
  fi
  deps="$(tr '\n' ' ' < "${PROJECT_DIR}/package.json" 2>/dev/null || true)"
  if [[ "${deps}" == *"next"* ]]; then
    printf '%s\n' "Next.js"
  elif [[ "${deps}" == *"react"* ]]; then
    printf '%s\n' "React"
  elif [[ "${deps}" == *"vue"* ]]; then
    printf '%s\n' "Vue"
  elif [[ "${deps}" == *"svelte"* ]]; then
    printf '%s\n' "Svelte"
  elif [[ "${deps}" == *"nuxt"* ]]; then
    printf '%s\n' "Nuxt"
  fi
}

write_scan_profile() {
  local type stack artifacts preset primary implementer support_a support_b support_c cue_a cue_b cue_c top_files
  local upstream_primary upstream_support_a upstream_support_b upstream_support_c
  local framework package_name python_name go_module rust_package summary_hint

  top_files="$(find "${PROJECT_DIR}" -maxdepth 2 -type f \
    ! -path "${PROJECT_DIR}/.git/*" \
    ! -path "${PROJECT_DIR}/.codex/*" \
    ! -name ".DS_Store" | sed "s#${PROJECT_DIR}/##" | sort | head -n 40)"

  package_name="$(read_package_field "name")"
  framework="$(detect_frontend_framework)"
  python_name="$(read_first_line_match "${PROJECT_DIR}/pyproject.toml" '^name[[:space:]]*=')"
  go_module="$(read_first_line_match "${PROJECT_DIR}/go.mod" '^module ')"
  rust_package="$(read_first_line_match "${PROJECT_DIR}/Cargo.toml" '^name[[:space:]]*=')"
  summary_hint="$(read_first_line_match "${PROJECT_DIR}/README.md" '^# ')"

  if [[ -f "${PROJECT_DIR}/package.json" ]]; then
    if [[ -f "${PROJECT_DIR}/next.config.js" || -f "${PROJECT_DIR}/next.config.mjs" || -d "${PROJECT_DIR}/app" || -d "${PROJECT_DIR}/pages" || -d "${PROJECT_DIR}/components" ]]; then
      type="frontend web application"
      preset="frontend-product"
      stack="Node.js frontend stack based on package.json${framework:+, ${framework}}${package_name:+, package ${package_name}}"
      artifacts="app pages, components, styles, frontend assets"
      primary="Frontend Developer"
      implementer="Frontend Developer"
      support_a="UI Designer"
      support_b="UX Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_a="upstream-agents/design/design-ui-designer.md"
      upstream_support_b="upstream-agents/design/design-ux-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    elif [[ -d "${PROJECT_DIR}/server" || -d "${PROJECT_DIR}/api" || -d "${PROJECT_DIR}/backend" ]]; then
      type="full-stack web application"
      preset="backend-service"
      stack="Node.js full-stack workspace${framework:+, ${framework}}${package_name:+, package ${package_name}}"
      artifacts="frontend code, backend endpoints, shared assets"
      primary="Software Architect"
      implementer="Frontend Developer"
      support_a="Frontend Developer"
      support_b="Backend Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-software-architect.md"
      upstream_support_a="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_b="upstream-agents/engineering/engineering-backend-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    else
      type="JavaScript application"
      preset="zero-to-one-startup"
      stack="Node.js package-based project${framework:+, ${framework}}${package_name:+, package ${package_name}}"
      artifacts="application code, scripts, static assets"
      primary="Rapid Prototyper"
      implementer="Rapid Prototyper"
      support_a="Frontend Developer"
      support_b="Backend Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-rapid-prototyper.md"
      upstream_support_a="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_b="upstream-agents/engineering/engineering-backend-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    fi
  elif [[ -f "${PROJECT_DIR}/pyproject.toml" || -f "${PROJECT_DIR}/requirements.txt" ]]; then
    type="Python service or application"
    preset="backend-service"
    stack="Python project${python_name:+, ${python_name}}"
    artifacts="service modules, scripts, docs, app files"
    primary="Backend Architect"
    implementer="Backend Architect"
    support_a="API Tester"
    support_b="Software Architect"
    support_c="Technical Writer"
    upstream_primary="upstream-agents/engineering/engineering-backend-architect.md"
    upstream_support_a="upstream-agents/testing/testing-api-tester.md"
    upstream_support_b="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_c="upstream-agents/engineering/engineering-technical-writer.md"
  elif [[ -f "${PROJECT_DIR}/go.mod" ]]; then
    type="Go service"
    preset="backend-service"
    stack="Go module${go_module:+, ${go_module}}"
    artifacts="packages, handlers, service code"
    primary="Backend Architect"
    implementer="Backend Architect"
    support_a="API Tester"
    support_b="SRE"
    support_c="Software Architect"
    upstream_primary="upstream-agents/engineering/engineering-backend-architect.md"
    upstream_support_a="upstream-agents/testing/testing-api-tester.md"
    upstream_support_b="upstream-agents/engineering/engineering-sre.md"
    upstream_support_c="upstream-agents/engineering/engineering-software-architect.md"
  elif [[ -f "${PROJECT_DIR}/Cargo.toml" ]]; then
    type="Rust application or service"
    preset="backend-service"
    stack="Rust cargo project${rust_package:+, ${rust_package}}"
    artifacts="Rust crates, binaries, modules"
    primary="Senior Developer"
    implementer="Senior Developer"
    support_a="Software Architect"
    support_b="Code Reviewer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/engineering/engineering-senior-developer.md"
    upstream_support_a="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_b="upstream-agents/engineering/engineering-code-reviewer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
  elif [[ -f "${PROJECT_DIR}/index.html" && ( -d "${PROJECT_DIR}/assets" || -d "${PROJECT_DIR}/images" ) ]]; then
    type="presentation-style static web artifact"
    preset="marketing-site"
    stack="single-page HTML with local assets"
    artifacts="index.html, image assets, presentation visuals"
    primary="Visual Storyteller"
    implementer="Frontend Developer"
    support_a="UI Designer"
    support_b="Frontend Developer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_a="upstream-agents/design/design-ui-designer.md"
    upstream_support_b="upstream-agents/engineering/engineering-frontend-developer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
  elif find "${PROJECT_DIR}" -maxdepth 2 -type f \( -name "*.pptx" -o -name "*.ppt" -o -name "*.key" -o -name "*.pdf" \) | grep -q .; then
    type="presentation or document artifact"
    preset="ppt-storytelling"
    stack="document-driven deliverable"
    artifacts="decks, slides, exported documents, supporting visuals"
    primary="Visual Storyteller"
    implementer="Visual Storyteller"
    support_a="Brand Guardian"
    support_b="UI Designer"
    support_c="Project Shepherd"
    upstream_primary="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_a="upstream-agents/design/design-brand-guardian.md"
    upstream_support_b="upstream-agents/design/design-ui-designer.md"
    upstream_support_c="upstream-agents/project-management/project-management-project-shepherd.md"
  elif [[ -d "${PROJECT_DIR}/content" || -d "${PROJECT_DIR}/posts" || -d "${PROJECT_DIR}/marketing" ]]; then
    type="content or marketing workspace"
    preset="marketing-site"
    stack="content-oriented project"
    artifacts="copy, campaign assets, visuals, planning docs"
    primary="Content Creator"
    implementer="Content Creator"
    support_a="Brand Guardian"
    support_b="Visual Storyteller"
    support_c="SEO Specialist"
    upstream_primary="upstream-agents/marketing/marketing-content-creator.md"
    upstream_support_a="upstream-agents/design/design-brand-guardian.md"
    upstream_support_b="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_c="upstream-agents/marketing/marketing-seo-specialist.md"
  else
    type="general software or project workspace"
    preset="zero-to-one-startup"
    stack="mixed or not yet classified"
    artifacts="repository files, docs, implementation assets"
    primary="Codebase Onboarding Engineer"
    implementer="Software Architect"
    support_a="Software Architect"
    support_b="Technical Writer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/engineering/engineering-codebase-onboarding-engineer.md"
    upstream_support_a="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_b="upstream-agents/engineering/engineering-technical-writer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
  fi

  if [[ "${PROFILE_LANG}" == "zh" ]]; then
    cue_a="先理解仓库结构、入口、数据流和主要模块"
    cue_b="开始具体实现、修 bug、改页面、补功能"
    cue_c="验证交付质量、响应式、测试结论或上线准备度"
    cat > "${PROFILE_FILE}" <<EOF
# Project Profile

## Summary
- Type: ${type}
- Stack: ${stack}
- Primary artifacts: ${artifacts}

## Default Squad
- Preset: \`${preset}\`
- Primary: \`${primary}\`
- Supporting: \`${support_a}\`、\`${support_b}\`、\`${support_c}\`
- Upstream agents:
  - \`${upstream_primary}\`
  - \`${upstream_support_a}\`
  - \`${upstream_support_b}\`
  - \`${upstream_support_c}\`

## Routing Cues
- If user asks for: ${cue_a}
- Switch to: \`Codebase Onboarding Engineer\`
- If user asks for: ${cue_b}
- Switch to: \`${implementer}\`
- If user asks for: ${cue_c}
- Switch to: \`${support_c}\`

## Current Goals
- 基于现有仓库和已部署形态继续推进，而不是假设项目从零开始
- 先沿用当前结构与产物边界，再根据任务决定是否扩大改动范围

## Constraints
- 本 profile 由仓库扫描自动生成，后续需要随着真实需求持续更新
- README 摘要: ${summary_hint:-未读取到标题}
- 扫描样本:
$(printf '%s\n' "${top_files}" | sed 's/^/- /')

## Working Style
- 先理解，再做最小有效改动
- 优先使用最小可用 squad，避免无谓扩张

## Handoff Triggers
- 当任务从理解仓库切到实现时，切换到 \`${implementer}\`
- 当任务从实现切到验证时，切换到 \`${support_c}\`

## Escalation Policy
- 当同一路径连续失败 2 次以上时，切换到高能动排查模式
- 声称完成前必须有可验证证据
EOF
  else
    cue_a="understand repository structure, entry points, data flow, and main modules first"
    cue_b="implement, debug, redesign, or extend functionality"
    cue_c="verify quality, responsiveness, testing results, or release readiness"
    cat > "${PROFILE_FILE}" <<EOF
# Project Profile

## Summary
- Type: ${type}
- Stack: ${stack}
- Primary artifacts: ${artifacts}

## Default Squad
- Preset: \`${preset}\`
- Primary: \`${primary}\`
- Supporting: \`${support_a}\`, \`${support_b}\`, \`${support_c}\`
- Upstream agents:
  - \`${upstream_primary}\`
  - \`${upstream_support_a}\`
  - \`${upstream_support_b}\`
  - \`${upstream_support_c}\`

## Routing Cues
- If user asks for: ${cue_a}
- Switch to: \`Codebase Onboarding Engineer\`
- If user asks for: ${cue_b}
- Switch to: \`${implementer}\`
- If user asks for: ${cue_c}
- Switch to: \`${support_c}\`

## Current Goals
- Continue from the existing repository and deployed shape instead of assuming a greenfield project
- Preserve the current structure and artifacts first, then expand the scope only when the task requires it

## Constraints
- This profile was auto-generated from a repository scan and should be refined as real requirements become clearer
- README hint: ${summary_hint:-no README heading detected}
- Scan sample:
$(printf '%s\n' "${top_files}" | sed 's/^/- /')

## Working Style
- Understand first, then make the smallest effective change
- Prefer the smallest useful squad before expanding

## Handoff Triggers
- Switch to \`${implementer}\` when the task moves from understanding to implementation
- Switch to \`${support_c}\` when the task moves from implementation to verification

## Escalation Policy
- Switch to high-agency mode after 2 repeated failures on the same path
- Require verifiable evidence before claiming completion
EOF
  fi
}

write_dialog_files() {
  cp "${TEMPLATE_FILE}" "${PROFILE_FILE}"
  cp "${DIALOG_TEMPLATE_FILE}" "${INTAKE_FILE}"
}

SELECTED_MODE="$(detect_mode)"

case "${SELECTED_MODE}" in
  scan)
    write_scan_profile
    echo "Scanned repository and initialized ${PROFILE_LANG} project profile at ${PROFILE_FILE}"
    ;;
  dialog)
    write_dialog_files
    echo "Initialized ${PROFILE_LANG} project profile at ${PROFILE_FILE}"
    echo "Initialized ${PROFILE_LANG} project intake prompts at ${INTAKE_FILE}"
    ;;
  template)
    cp "${TEMPLATE_FILE}" "${PROFILE_FILE}"
    echo "Initialized ${PROFILE_LANG} project profile at ${PROFILE_FILE}"
    ;;
esac
