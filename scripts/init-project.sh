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
  local type stack artifacts preset primary implementer verifier support_a support_b support_c cue_a cue_b cue_c top_files
  local upstream_primary upstream_support_a upstream_support_b upstream_support_c
  local framework package_name python_name go_module rust_package summary_hint
  local heur_1 heur_2 anti_1 anti_2 evo_1 evo_2
  local heur_en_1 heur_en_2 anti_en_1 anti_en_2 evo_en_1 evo_en_2
  local handoff_1 handoff_2 verify_1 verify_2 verify_3
  local section_lang

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
      verifier="Reality Checker"
      support_a="UI Designer"
      support_b="UX Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_a="upstream-agents/design/design-ui-designer.md"
      upstream_support_b="upstream-agents/design/design-ux-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      heur_1="优先解决用户可见的交互影响"
      heur_2="先保证流程清晰，再追求抽象优雅"
      anti_1="不要为简单 UI 行为过度架构"
      anti_2="不要在流程不清时提前追求精致抛光"
      evo_1="保留容易验证的交互改进"
      evo_2="回滚不能提升理解的 UI 复杂度"
      heur_en_1="Prioritize user-visible interaction impact first"
      heur_en_2="Make the flow clear before chasing abstraction elegance"
      anti_en_1="Do not over-architect simple UI behavior"
      anti_en_2="Do not polish too early when the flow is still unclear"
      evo_en_1="Keep interaction improvements that are easy to verify"
      evo_en_2="Revert UI complexity that does not improve understanding"
    elif [[ -d "${PROJECT_DIR}/server" || -d "${PROJECT_DIR}/api" || -d "${PROJECT_DIR}/backend" ]]; then
      type="full-stack web application"
      preset="backend-service"
      stack="Node.js full-stack workspace${framework:+, ${framework}}${package_name:+, package ${package_name}}"
      artifacts="frontend code, backend endpoints, shared assets"
      primary="Software Architect"
      implementer="Frontend Developer"
      verifier="Reality Checker"
      support_a="Frontend Developer"
      support_b="Backend Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-software-architect.md"
      upstream_support_a="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_b="upstream-agents/engineering/engineering-backend-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      heur_1="先保护接口边界和系统结构"
      heur_2="优先保证跨层改动的可解释性"
      anti_1="不要在边界未理清时扩大全栈改动"
      anti_2="不要在没有验证时宣称整体稳定"
      evo_1="保留能减少结构混乱的调整"
      evo_2="回滚扩大风险但没有更清晰边界的改动"
      heur_en_1="Protect interface boundaries and system structure first"
      heur_en_2="Prefer cross-layer changes that remain explainable"
      anti_en_1="Do not widen full-stack changes before the boundaries are clear"
      anti_en_2="Do not claim the whole system is stable without verification"
      evo_en_1="Keep changes that reduce structural confusion"
      evo_en_2="Revert changes that expand risk without clarifying boundaries"
    else
      type="JavaScript application"
      preset="zero-to-one-startup"
      stack="Node.js package-based project${framework:+, ${framework}}${package_name:+, package ${package_name}}"
      artifacts="application code, scripts, static assets"
      primary="Rapid Prototyper"
      implementer="Rapid Prototyper"
      verifier="Reality Checker"
      support_a="Frontend Developer"
      support_b="Backend Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-rapid-prototyper.md"
      upstream_support_a="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_b="upstream-agents/engineering/engineering-backend-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      heur_1="优先产出能验证方向的最小原型"
      heur_2="先证明有效，再补系统化"
      anti_1="不要把原型直接做成正式架构"
      anti_2="不要把大量产出误当成有效验证"
      evo_1="保留能减少不确定性的原型结论"
      evo_2="回滚让范围变大但没有更强证据的实现"
      heur_en_1="Produce the smallest prototype that can validate the direction"
      heur_en_2="Prove usefulness before systematizing"
      anti_en_1="Do not turn the prototype directly into formal architecture"
      anti_en_2="Do not mistake volume of output for evidence"
      evo_en_1="Keep prototype conclusions that reduce uncertainty"
      evo_en_2="Revert implementations that expand scope without stronger proof"
    fi
  elif [[ -f "${PROJECT_DIR}/pyproject.toml" || -f "${PROJECT_DIR}/requirements.txt" ]]; then
    type="Python service or application"
    preset="backend-service"
    stack="Python project${python_name:+, ${python_name}}"
    artifacts="service modules, scripts, docs, app files"
    primary="Backend Architect"
    implementer="Backend Architect"
    verifier="API Tester"
    support_a="API Tester"
    support_b="Software Architect"
    support_c="Technical Writer"
    upstream_primary="upstream-agents/engineering/engineering-backend-architect.md"
    upstream_support_a="upstream-agents/testing/testing-api-tester.md"
    upstream_support_b="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_c="upstream-agents/engineering/engineering-technical-writer.md"
    heur_1="先保护接口和数据流正确性"
    heur_2="优先选择可观测、可验证的后端改动"
    anti_1="不要在依赖未追清时扩大后端改动"
    anti_2="不要没有接口证据就宣称稳定"
    evo_1="保留提升正确性和可追踪性的改动"
    evo_2="回滚放大风险却没有更强保障的后端调整"
    heur_en_1="Protect interface correctness and data flow first"
    heur_en_2="Prefer backend changes that are observable and verifiable"
    anti_en_1="Do not expand backend changes before dependency paths are clear"
    anti_en_2="Do not claim stability without interface-level evidence"
    evo_en_1="Keep changes that improve correctness and traceability"
    evo_en_2="Revert backend adjustments that amplify risk without stronger safeguards"
  elif [[ -f "${PROJECT_DIR}/go.mod" ]]; then
    type="Go service"
    preset="backend-service"
    stack="Go module${go_module:+, ${go_module}}"
    artifacts="packages, handlers, service code"
    primary="Backend Architect"
    implementer="Backend Architect"
    verifier="API Tester"
    support_a="API Tester"
    support_b="SRE"
    support_c="Software Architect"
    upstream_primary="upstream-agents/engineering/engineering-backend-architect.md"
    upstream_support_a="upstream-agents/testing/testing-api-tester.md"
    upstream_support_b="upstream-agents/engineering/engineering-sre.md"
    upstream_support_c="upstream-agents/engineering/engineering-software-architect.md"
    heur_1="先守住接口稳定和运行可靠性"
    heur_2="优先有证据的修复和观测"
    anti_1="不要未排查调用链就扩大服务改动"
    anti_2="不要忽略运行证据只看代码直觉"
    evo_1="保留提升稳定性和可观测性的改动"
    evo_2="回滚制造更多运行不确定性的改动"
    heur_en_1="Protect interface stability and runtime reliability first"
    heur_en_2="Prefer fixes and observations backed by evidence"
    anti_en_1="Do not widen service changes before tracing the call chain"
    anti_en_2="Do not ignore runtime evidence in favor of code intuition"
    evo_en_1="Keep changes that improve stability and observability"
    evo_en_2="Revert changes that create more runtime uncertainty"
  elif [[ -f "${PROJECT_DIR}/Cargo.toml" ]]; then
    type="Rust application or service"
    preset="backend-service"
    stack="Rust cargo project${rust_package:+, ${rust_package}}"
    artifacts="Rust crates, binaries, modules"
    primary="Senior Developer"
    implementer="Senior Developer"
    verifier="Reality Checker"
    support_a="Software Architect"
    support_b="Code Reviewer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/engineering/engineering-senior-developer.md"
    upstream_support_a="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_b="upstream-agents/engineering/engineering-code-reviewer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    heur_1="优先保证实现正确和约束清晰"
    heur_2="先把行为说清楚，再优化技巧"
    anti_1="不要为技巧性实现牺牲可读性"
    anti_2="不要没有验证就扩大语言层级重构"
    evo_1="保留提升正确性和可维护性的实现"
    evo_2="回滚炫技但不增稳的复杂重构"
    heur_en_1="Prioritize implementation correctness and explicit constraints"
    heur_en_2="Clarify behavior before optimizing technique"
    anti_en_1="Do not sacrifice readability for clever implementation"
    anti_en_2="Do not expand language-level refactors without verification"
    evo_en_1="Keep implementations that improve correctness and maintainability"
    evo_en_2="Revert flashy refactors that do not increase stability"
  elif [[ -f "${PROJECT_DIR}/index.html" && ( -d "${PROJECT_DIR}/assets" || -d "${PROJECT_DIR}/images" ) ]]; then
    type="presentation-style static web artifact"
    preset="marketing-site"
    stack="single-page HTML with local assets"
    artifacts="index.html, image assets, presentation visuals"
    primary="Visual Storyteller"
    implementer="Frontend Developer"
    verifier="Reality Checker"
    support_a="UI Designer"
    support_b="Frontend Developer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_a="upstream-agents/design/design-ui-designer.md"
    upstream_support_b="upstream-agents/engineering/engineering-frontend-developer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    heur_1="先让信息层级和故事线成立"
    heur_2="尽快把叙事判断转成浏览器里可见的结构"
    anti_1="不要在核心信息未立住时先堆装饰"
    anti_2="不要让实现细节淹没叙事"
    evo_1="保留能强化叙事和扫读性的改动"
    evo_2="回滚削弱清晰度和节奏的视觉复杂度"
    heur_en_1="Establish information hierarchy and storyline first"
    heur_en_2="Turn narrative judgment into visible browser structure quickly"
    anti_en_1="Do not pile on decoration before the core message stands"
    anti_en_2="Do not let implementation detail drown the narrative"
    evo_en_1="Keep changes that strengthen storytelling and scanability"
    evo_en_2="Revert visual complexity that weakens clarity and pacing"
  elif find "${PROJECT_DIR}" -maxdepth 2 -type f \( -name "*.pptx" -o -name "*.ppt" -o -name "*.key" -o -name "*.pdf" \) | grep -q .; then
    type="presentation or document artifact"
    preset="ppt-storytelling"
    stack="document-driven deliverable"
    artifacts="decks, slides, exported documents, supporting visuals"
    primary="Visual Storyteller"
    implementer="Visual Storyteller"
    verifier="Brand Guardian"
    support_a="Brand Guardian"
    support_b="UI Designer"
    support_c="Project Shepherd"
    upstream_primary="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_a="upstream-agents/design/design-brand-guardian.md"
    upstream_support_b="upstream-agents/design/design-ui-designer.md"
    upstream_support_c="upstream-agents/project-management/project-management-project-shepherd.md"
    heur_1="先保证叙事顺序，再打磨局部页"
    heur_2="优先服务观众理解，而不是信息堆量"
    anti_1="不要在顺序弱时继续塞更多内容"
    anti_2="不要添加削弱论证的花哨形式"
    evo_1="保留能改善故事流的结构调整"
    evo_2="回滚增加噪音却不增强说服力的内容"
    heur_en_1="Get the narrative sequence right before polishing individual pages"
    heur_en_2="Optimize for audience understanding, not information volume"
    anti_en_1="Do not keep adding content when the sequence is still weak"
    anti_en_2="Do not add flashy forms that weaken the argument"
    evo_en_1="Keep structural adjustments that improve story flow"
    evo_en_2="Revert content that adds noise without adding persuasion"
  elif [[ -d "${PROJECT_DIR}/content" || -d "${PROJECT_DIR}/posts" || -d "${PROJECT_DIR}/marketing" ]]; then
    type="content or marketing workspace"
    preset="marketing-site"
    stack="content-oriented project"
    artifacts="copy, campaign assets, visuals, planning docs"
    primary="Content Creator"
    implementer="Content Creator"
    verifier="SEO Specialist"
    support_a="Brand Guardian"
    support_b="Visual Storyteller"
    support_c="SEO Specialist"
    upstream_primary="upstream-agents/marketing/marketing-content-creator.md"
    upstream_support_a="upstream-agents/design/design-brand-guardian.md"
    upstream_support_b="upstream-agents/design/design-visual-storyteller.md"
    upstream_support_c="upstream-agents/marketing/marketing-seo-specialist.md"
    heur_1="先确保信息主张清楚，再扩展内容层次"
    heur_2="优先让叙事和转化目标对齐"
    anti_1="不要内容很多但核心主张模糊"
    anti_2="不要为了堆词牺牲品牌一致性"
    evo_1="保留能提升清晰度和转化意图的内容调整"
    evo_2="回滚拉长内容却降低力度的改动"
    heur_en_1="Make the core message clear before expanding content layers"
    heur_en_2="Align the narrative with the conversion goal first"
    anti_en_1="Do not let the message become vague just because there is more content"
    anti_en_2="Do not sacrifice brand consistency for keyword stuffing"
    evo_en_1="Keep content changes that improve clarity and conversion intent"
    evo_en_2="Revert edits that lengthen content while weakening force"
  else
    type="general software or project workspace"
    preset="zero-to-one-startup"
    stack="mixed or not yet classified"
    artifacts="repository files, docs, implementation assets"
    primary="Codebase Onboarding Engineer"
    implementer="Software Architect"
    verifier="Reality Checker"
    support_a="Software Architect"
    support_b="Technical Writer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/engineering/engineering-codebase-onboarding-engineer.md"
    upstream_support_a="upstream-agents/engineering/engineering-software-architect.md"
    upstream_support_b="upstream-agents/engineering/engineering-technical-writer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    heur_1="先降低不确定性，再扩大执行面"
    heur_2="优先产出能证明下一步方向的最小结果"
    anti_1="不要在问题还没定义稳之前过度建设"
    anti_2="不要把忙碌误当成已验证进展"
    evo_1="保留能减少不确定性的推进"
    evo_2="回滚增加表面积却没有更强把握的工作"
    heur_en_1="Reduce uncertainty before expanding the execution surface"
    heur_en_2="Prefer the smallest result that proves the next direction"
    anti_en_1="Do not overbuild before the problem is clearly defined"
    anti_en_2="Do not mistake busyness for validated progress"
    evo_en_1="Keep progress that reduces uncertainty"
    evo_en_2="Revert work that increases surface area without stronger confidence"
  fi

  section_lang="${PROFILE_LANG}"
  case "${preset}:${section_lang}" in
    frontend-product:zh)
      handoff_1="当任务从实现细节转向整体结构时，切换到 UX Architect"
      handoff_2="当任务从交互实现转向发布验收时，切换到 Reality Checker"
      verify_1="在浏览器中验证关键交互流程"
      verify_2="检查响应式布局和主要视口"
      verify_3="确认改动对用户可见行为确实产生了预期效果"
      ;;
    frontend-product:en)
      handoff_1="Switch to UX Architect when the task moves from implementation details to interaction structure"
      handoff_2="Switch to Reality Checker when the task moves from interaction work to release validation"
      verify_1="Validate the key interaction flow in a browser"
      verify_2="Check responsive behavior across the main viewports"
      verify_3="Confirm the change produced the intended user-visible behavior"
      ;;
    backend-service:zh)
      if [[ "${type}" == "full-stack web application" ]]; then
        handoff_1="当任务分裂成前后端独立问题时，分别切向 Frontend Developer 和 Backend Architect"
        handoff_2="当任务进入整体验收时，切换到 Reality Checker"
        verify_1="验证主要端到端路径没有断裂"
        verify_2="检查跨层变更是否仍与原边界一致"
        verify_3="确认关键功能在集成场景中仍可工作"
      elif [[ "${type}" == "Go service" ]]; then
        handoff_1="当问题转向运行稳定性时，切换到 SRE"
        handoff_2="当问题转向接口确认时，切换到 API Tester"
        verify_1="检查服务级运行证据和错误信号"
        verify_2="验证关键调用链是否恢复正常"
        verify_3="确认修复没有引入新的运行不确定性"
      else
        handoff_1="当任务从设计转向验证时，切换到 API Tester"
        handoff_2="当任务从实现转向边界梳理时，切换到 Software Architect"
        verify_1="验证关键接口输入输出"
        verify_2="检查错误路径和边界条件"
        verify_3="确认改动后数据流仍然一致"
      fi
      ;;
    backend-service:en)
      if [[ "${type}" == "full-stack web application" ]]; then
        handoff_1="Split to Frontend Developer and Backend Architect when the work separates into frontend and backend problems"
        handoff_2="Switch to Reality Checker when the work moves into integrated acceptance"
        verify_1="Verify the main end-to-end path is still intact"
        verify_2="Check that cross-layer changes still respect the original boundaries"
        verify_3="Confirm critical functionality still works in the integrated flow"
      elif [[ "${type}" == "Go service" ]]; then
        handoff_1="Switch to SRE when the problem becomes runtime stability"
        handoff_2="Switch to API Tester when the work becomes interface confirmation"
        verify_1="Inspect service-level runtime evidence and error signals"
        verify_2="Verify the critical call chain has recovered"
        verify_3="Confirm the fix did not introduce new runtime uncertainty"
      else
        handoff_1="Switch to API Tester when the task moves from implementation into verification"
        handoff_2="Switch to Software Architect when the task moves from implementation into boundary design"
        verify_1="Validate the inputs and outputs of critical interfaces"
        verify_2="Check error paths and edge conditions"
        verify_3="Confirm the data flow still behaves consistently after the change"
      fi
      ;;
    zero-to-one-startup:zh)
      handoff_1="当方向被验证后，切换到更稳定的实现角色"
      handoff_2="当原型需要交付判断时，切换到 Reality Checker"
      verify_1="确认原型是否真的回答了关键问题"
      verify_2="检查最小实现是否足以支撑下一步判断"
      verify_3="区分演示有效和生产可用"
      ;;
    zero-to-one-startup:en)
      handoff_1="Switch to a steadier implementation role once the direction has been validated"
      handoff_2="Switch to Reality Checker when the prototype needs delivery judgment"
      verify_1="Confirm the prototype actually answers the key question"
      verify_2="Check whether the minimal implementation is enough to support the next decision"
      verify_3="Distinguish between a convincing demo and a production-ready system"
      ;;
    marketing-site:zh)
      if [[ "${type}" == "presentation-style static web artifact" ]]; then
        handoff_1="当叙事已明确并进入页面落地时，切换到 Frontend Developer"
        handoff_2="当页面进入可交付验收时，切换到 Reality Checker"
        verify_1="检查首屏和关键区块是否传达核心信息"
        verify_2="验证页面层级和扫读路径是否清晰"
        verify_3="确认实现没有破坏叙事节奏"
      else
        handoff_1="当内容框架稳定后，切换到 Visual Storyteller 或 Frontend Developer 落地"
        handoff_2="当目标转向搜索表现时，切换到 SEO Specialist"
        verify_1="检查核心主张是否一眼可见"
        verify_2="验证内容与转化动作是否对齐"
        verify_3="确认文案扩展没有削弱力度"
      fi
      ;;
    marketing-site:en)
      if [[ "${type}" == "presentation-style static web artifact" ]]; then
        handoff_1="Switch to Frontend Developer once the narrative direction is clear and the page needs implementation"
        handoff_2="Switch to Reality Checker when the page moves into delivery validation"
        verify_1="Check whether the hero and key sections communicate the core message"
        verify_2="Validate visual hierarchy and scan path clarity"
        verify_3="Confirm the implementation did not break the narrative rhythm"
      else
        handoff_1="Switch to Visual Storyteller or Frontend Developer once the content frame is stable and needs execution"
        handoff_2="Switch to SEO Specialist when the goal shifts toward search performance"
        verify_1="Check whether the core claim is obvious at a glance"
        verify_2="Validate that the content aligns with the conversion action"
        verify_3="Confirm the copy expansion did not weaken the message"
      fi
      ;;
    ppt-storytelling:zh)
      handoff_1="当问题从故事结构转向品牌一致性时，切换到 Brand Guardian"
      handoff_2="当问题从内容组织转向执行推进时，切换到 Project Shepherd"
      verify_1="检查叙事顺序是否顺畅"
      verify_2="验证每页是否服务整体论证"
      verify_3="确认新增内容没有削弱主线"
      ;;
    ppt-storytelling:en)
      handoff_1="Switch to Brand Guardian when the work moves from story structure to brand consistency"
      handoff_2="Switch to Project Shepherd when the work moves from content shaping to execution coordination"
      verify_1="Check whether the narrative sequence flows smoothly"
      verify_2="Verify that each page supports the overall argument"
      verify_3="Confirm new content did not weaken the main storyline"
      ;;
  esac

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
- Switch to: \`${verifier}\`

## Current Goals
- 基于现有仓库和已部署形态继续推进，而不是假设项目从零开始
- 先沿用当前结构与产物边界，再根据任务决定是否扩大改动范围

## Constraints
- 本 profile 由仓库扫描自动生成，后续需要随着真实需求持续更新
- README 摘要: ${summary_hint:-未读取到标题}
- 扫描样本:
$(printf '%s
' "${top_files}" | sed 's/^/- /')

## Working Style
- 先理解，再做最小有效改动
- 优先使用最小可用 squad，避免无谓扩张

## Decision Heuristics
- ${heur_1}
- ${heur_2}

## Anti-Patterns
- ${anti_1}
- ${anti_2}

## Handoff Triggers
- ${handoff_1}
- ${handoff_2}

## Escalation Policy
- 当同一路径连续失败 2 次以上时，切换到高能动排查模式
- 声称完成前必须有可验证证据

## Verification Protocol
- ${verify_1}
- ${verify_2}
- ${verify_3}

## Evolution Loop
- ${evo_1}
- ${evo_2}
- 每次迭代都要比上一个稳定版本更可信
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
- Switch to: \`${verifier}\`

## Current Goals
- Continue from the existing repository and deployed shape instead of assuming a greenfield project
- Preserve the current structure and artifacts first, then expand the scope only when the task requires it

## Constraints
- This profile was auto-generated from a repository scan and should be refined as real requirements become clearer
- README hint: ${summary_hint:-no README heading detected}
- Scan sample:
$(printf '%s
' "${top_files}" | sed 's/^/- /')

## Working Style
- Understand first, then make the smallest effective change
- Prefer the smallest useful squad before expanding

## Decision Heuristics
- ${heur_en_1}
- ${heur_en_2}

## Anti-Patterns
- ${anti_en_1}
- ${anti_en_2}

## Handoff Triggers
- ${handoff_1}
- ${handoff_2}

## Escalation Policy
- Switch to high-agency mode after 2 repeated failures on the same path
- Require verifiable evidence before claiming completion

## Verification Protocol
- ${verify_1}
- ${verify_2}
- ${verify_3}

## Evolution Loop
- ${evo_en_1}
- ${evo_en_2}
- Make each iteration more trustworthy than the last stable state
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
