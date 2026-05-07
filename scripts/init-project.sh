#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
FORCE="false"
PROFILE_LANG="zh"
MODE="auto"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_GOAL=""
SUCCESS_METRIC=""
STACK_CHOICE=""
ARTIFACT_SHAPE=""
FIRST_MOVE=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/init-project.sh --project /path/to/repo [--lang zh|en] [--mode auto|scan|dialog|template] [--goal VALUE] [--success VALUE] [--stack VALUE] [--artifact VALUE] [--first-move VALUE] [--force]

Options:
  --project PATH    Initialize PATH/.codex/project-profile.md
  --lang LANG       Profile template language: zh (default) or en
  --mode MODE       auto (default), scan existing repo, dialog for new project, or template
  --goal VALUE      New-project goal, e.g. website, web app, api, presentation, content
  --success VALUE   Success metric, e.g. ready-to-ship, looks-better, more-reliable
  --stack VALUE     Stack hint, e.g. react, nextjs, python, nodejs, undecided
  --artifact VALUE  Deliverable, e.g. repo, page, api, slides, document
  --first-move VALUE First priority, e.g. clarify-plan, scaffold, build-ui, build-backend, write-copy, validate
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

project_has_path() {
  local target="$1"
  [[ -e "${PROJECT_DIR}/${target}" ]]
}

project_has_glob() {
  local glob="$1"
  compgen -G "${PROJECT_DIR}/${glob}" > /dev/null
}

project_matches_text() {
  local pattern="$1"
  local search_files=()

  for candidate in \
    "${PROJECT_DIR}/package.json" \
    "${PROJECT_DIR}/pyproject.toml" \
    "${PROJECT_DIR}/requirements.txt" \
    "${PROJECT_DIR}/README.md" \
    "${PROJECT_DIR}/Cargo.toml" \
    "${PROJECT_DIR}/go.mod"; do
    if [[ -f "${candidate}" ]]; then
      search_files+=("${candidate}")
    fi
  done

  if (( ${#search_files[@]} == 0 )); then
    return 1
  fi

  rg -n -i -m 1 "${pattern}" "${search_files[@]}" >/dev/null 2>&1
}

read_preset_defaults() {
  local preset_key="$1"
  local lang_key="$2"

  PRESET_DEFAULTS_FILE="${SOURCE_DIR}/references/preset-defaults.json" \
  PRESET_KEY="${preset_key}" \
  PRESET_LANG="${lang_key}" \
  python3 - <<'PY'
from pathlib import Path
import json
import os

defaults = json.loads(Path(os.environ["PRESET_DEFAULTS_FILE"]).read_text()).get("reroute", {})
preset = defaults.get(os.environ["PRESET_KEY"])
if not preset:
    raise SystemExit(f"Unknown preset: {os.environ['PRESET_KEY']}")

lang = os.environ["PRESET_LANG"]
supporting = list(preset.get("supporting", []))
upstream = list(preset.get("upstream", []))
routing = list(preset.get("routing", {}).get(lang, []))
delivery_gate = list(preset.get("delivery_gate", {}).get(lang, []))
task_class = preset.get("task_class", {}).get(lang, "")

values = [
    preset.get("primary", ""),
    *supporting[:3],
    *([""] * max(0, 3 - len(supporting))),
    *upstream[:4],
    *([""] * max(0, 4 - len(upstream))),
    task_class,
    *[entry.get("ask", "") for entry in routing[:3]],
    *([""] * max(0, 3 - len(routing))),
    *[entry.get("switch", "") for entry in routing[:3]],
    *([""] * max(0, 3 - len(routing))),
    *delivery_gate[:3],
    *([""] * max(0, 3 - len(delivery_gate))),
]
print("\n".join(values))
PY
}

write_scan_profile() {
  local type stack artifacts preset primary implementer verifier support_a support_b support_c cue_a cue_b cue_c top_files
  local upstream_primary upstream_support_a upstream_support_b upstream_support_c
  local framework package_name python_name go_module rust_package summary_hint
  local heur_1 heur_2 anti_1 anti_2 evo_1 evo_2
  local heur_en_1 heur_en_2 anti_en_1 anti_en_2 evo_en_1 evo_en_2
  local handoff_1 handoff_2 verify_1 verify_2 verify_3
  local task_class task_class_en gate_1 gate_2 gate_3 gate_en_1 gate_en_2 gate_en_3
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

  if project_has_path "Assets" || project_has_path "ProjectSettings" || project_has_path "Packages/manifest.json" || project_has_path "godot.project" || project_has_glob "*.godot" || project_has_path "Config/DefaultEngine.ini" || project_has_path "Source"; then
    type="game development workspace"
    preset="game-production"
    stack="game engine workspace${package_name:+, package ${package_name}}"
    artifacts="game systems, scenes, assets, engine configuration"
    primary="Game Designer"
    implementer="Game Designer"
    verifier="Reality Checker"
    support_a="Technical Artist"
    support_b="Level Designer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/game-development/game-designer.md"
    upstream_support_a="upstream-agents/game-development/technical-artist.md"
    upstream_support_b="upstream-agents/game-development/level-designer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    if project_has_path "Assets" || project_has_path "ProjectSettings" || project_has_path "Packages/manifest.json"; then
      stack="Unity project workspace"
      primary="Unity Architect"
      implementer="Unity Architect"
      support_a="Technical Artist"
      support_b="Game Designer"
      upstream_primary="upstream-agents/game-development/unity/unity-architect.md"
      upstream_support_a="upstream-agents/game-development/technical-artist.md"
      upstream_support_b="upstream-agents/game-development/game-designer.md"
    elif project_has_path "godot.project" || project_has_glob "*.godot"; then
      stack="Godot project workspace"
      primary="Godot Gameplay Scripter"
      implementer="Godot Gameplay Scripter"
      support_a="Game Designer"
      support_b="Technical Artist"
      upstream_primary="upstream-agents/game-development/godot/godot-gameplay-scripter.md"
      upstream_support_a="upstream-agents/game-development/game-designer.md"
      upstream_support_b="upstream-agents/game-development/technical-artist.md"
    elif project_has_path "Config/DefaultEngine.ini" || project_has_path "Source"; then
      stack="Unreal Engine project workspace"
      primary="Unreal Systems Engineer"
      implementer="Unreal Systems Engineer"
      support_a="Unreal Technical Artist"
      support_b="Game Designer"
      upstream_primary="upstream-agents/game-development/unreal-engine/unreal-systems-engineer.md"
      upstream_support_a="upstream-agents/game-development/unreal-engine/unreal-technical-artist.md"
      upstream_support_b="upstream-agents/game-development/game-designer.md"
    fi
    heur_1="先保证核心玩法循环或关卡体验成立，再扩展系统复杂度"
    heur_2="优先用可试玩或可观察证据判断体验，而不是只看实现完成度"
    anti_1="不要在核心反馈未成立时同时扩张多个系统"
    anti_2="不要把引擎内可编译误当成玩家体验已成立"
    evo_1="保留能提高可玩性、可观察性和迭代速度的改动"
    evo_2="回滚增加内容量却削弱节奏和反馈的改动"
    heur_en_1="Make the core loop or level experience work before expanding system complexity"
    heur_en_2="Prefer playable or observable evidence over implementation completeness"
    anti_en_1="Do not expand multiple systems before the core feedback loop works"
    anti_en_2="Do not confuse engine-level correctness with player experience validity"
    evo_en_1="Keep changes that improve playability, observability, and iteration speed"
    evo_en_2="Revert changes that add content volume while weakening pacing or feedback"
    task_class="large"
    task_class_en="large"
    gate_1="核心玩法循环、关键场景或关键系统已有可试玩验证"
    gate_2="性能、美术实现与体验判断至少有一项有实际证据"
    gate_3="仍未验证的平台或内容边界已说明"
    gate_en_1="The core loop, key scene, or key system has playable verification"
    gate_en_2="Performance, visual implementation, or experience quality has at least one real evidence source"
    gate_en_3="Any platform or content boundary not yet verified is stated explicitly"
  elif project_matches_text '(openai|anthropic|langchain|llamaindex|autogen|crewai|mastra|assistants|agents sdk|model context protocol|mcp)' || project_has_path ".cursor/rules" || project_has_path "agents" || project_has_path "skills"; then
    type="AI agent or LLM workflow workspace"
    preset="ai-agent-stack"
    stack="AI application stack${package_name:+, package ${package_name}}${python_name:+, ${python_name}}"
    artifacts="agent flows, prompts, tools, MCP integrations, evaluation assets"
    primary="AI Engineer"
    implementer="AI Engineer"
    verifier="Reality Checker"
    support_a="MCP Builder"
    support_b="Autonomous Optimization Architect"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/engineering/engineering-ai-engineer.md"
    upstream_support_a="upstream-agents/specialized/specialized-mcp-builder.md"
    upstream_support_b="upstream-agents/engineering/engineering-autonomous-optimization-architect.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    heur_1="先保证 agent 回路、工具调用和上下文边界可解释"
    heur_2="优先建立可重复的评估与回归，而不是只追求演示效果"
    anti_1="不要把一次成功对话误当成系统稳定"
    anti_2="不要在缺少评估数据时持续堆提示词和工具"
    evo_1="保留能提升成功率、可解释性和评估闭环的改动"
    evo_2="回滚让行为更神秘却没有提升证据的 agent 复杂度"
    heur_en_1="Make the agent loop, tool calls, and context boundaries explainable first"
    heur_en_2="Prefer repeatable evaluation and regression checks over demo-only success"
    anti_en_1="Do not treat one successful conversation as system stability"
    anti_en_2="Do not keep adding prompts and tools without evaluation evidence"
    evo_en_1="Keep changes that improve success rate, explainability, and evaluation closure"
    evo_en_2="Revert agent complexity that makes behavior murkier without stronger evidence"
    task_class="large"
    task_class_en="large"
    gate_1="关键 agent 回路或工具链已有真实样例验证"
    gate_2="失败模式、回退路径或评估方式已说明"
    gate_3="没有把 prompt 想法误报成稳定能力"
    gate_en_1="The critical agent loop or tool chain has been verified with real examples"
    gate_en_2="Failure modes, rollback paths, or evaluation methods are documented"
    gate_en_3="Prompt ideas are not being reported as stable capability"
  elif project_matches_text '(xiaohongshu|douyin|kuaishou|wechat|weibo|bilibili|zhihu|private domain|私域|小红书|抖音|快手|公众号|视频号|微博|知乎)' || project_has_path "wechat" || project_has_path "xiaohongshu" || project_has_path "douyin"; then
    type="China-market content or growth workspace"
    preset="china-market-growth"
    stack="China-channel growth workflow"
    artifacts="channel strategy, localized copy, publishing plans, growth assets"
    primary="China Market Localization Strategist"
    implementer="China Market Localization Strategist"
    verifier="Reality Checker"
    support_a="Xiaohongshu Specialist"
    support_b="Douyin Strategist"
    support_c="WeChat Official Account"
    upstream_primary="upstream-agents/marketing/marketing-china-market-localization-strategist.md"
    upstream_support_a="upstream-agents/marketing/marketing-xiaohongshu-specialist.md"
    upstream_support_b="upstream-agents/marketing/marketing-douyin-strategist.md"
    upstream_support_c="upstream-agents/marketing/marketing-wechat-official-account.md"
    heur_1="先统一中文市场主张和渠道分工，再扩展内容数量"
    heur_2="优先让平台语境、转化路径和品牌表达对齐"
    anti_1="不要一套内容生硬平移到所有中文渠道"
    anti_2="不要把平台发布动作误当成增长验证"
    evo_1="保留能提升本地化贴合度和渠道匹配度的改动"
    evo_2="回滚表面热闹却没有更强转化证据的内容扩张"
    heur_en_1="Align the China-market message and channel roles before expanding content volume"
    heur_en_2="Keep platform context, conversion path, and brand expression aligned"
    anti_en_1="Do not force one content shape unchanged across every Chinese channel"
    anti_en_2="Do not treat publishing activity as growth validation"
    evo_en_1="Keep changes that improve localization fit and channel-match quality"
    evo_en_2="Revert expansion that looks busy but lacks stronger conversion evidence"
    task_class="medium"
    task_class_en="medium"
    gate_1="核心渠道分工和本地化主张已清楚"
    gate_2="至少一个渠道的内容样例或验证标准已落地"
    gate_3="未验证的投放或增长假设已标注"
    gate_en_1="The core channel split and localized message are clear"
    gate_en_2="At least one channel has a concrete content sample or validation standard"
    gate_en_3="Any unverified distribution or growth assumption is marked explicitly"
  elif project_matches_text '(visionos|vision pro|xr|arkit|realitykit|spatial computing|spatial)' || project_has_path "Packages/manifest.json" && project_matches_text '(xr interaction toolkit|arkit|visionos)' ; then
    type="spatial computing workspace"
    preset="spatial-computing"
    stack="XR or spatial computing project"
    artifacts="immersive flows, interaction systems, spatial UI, engine integrations"
    primary="XR Interface Architect"
    implementer="XR Interface Architect"
    verifier="Reality Checker"
    support_a="XR Immersive Developer"
    support_b="VisionOS Spatial Engineer"
    support_c="Reality Checker"
    upstream_primary="upstream-agents/spatial-computing/xr-interface-architect.md"
    upstream_support_a="upstream-agents/spatial-computing/xr-immersive-developer.md"
    upstream_support_b="upstream-agents/spatial-computing/visionos-spatial-engineer.md"
    upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
    heur_1="先保证空间交互心智模型成立，再扩展沉浸效果"
    heur_2="优先验证用户在空间中的方向感、可达性和任务流"
    anti_1="不要在交互模型未稳定时堆沉浸特效"
    anti_2="不要把二维界面经验直接套进空间场景"
    evo_1="保留能提升空间可理解性和交互稳定性的改动"
    evo_2="回滚削弱空间定向感却只增加炫技效果的实现"
    heur_en_1="Make the spatial interaction model work before adding immersive flourish"
    heur_en_2="Prioritize orientation, reachability, and task flow in space"
    anti_en_1="Do not pile on immersive effects before the interaction model is stable"
    anti_en_2="Do not paste flat-screen habits directly into spatial scenes"
    evo_en_1="Keep changes that improve spatial legibility and interaction stability"
    evo_en_2="Revert flashy additions that weaken orientation or clarity"
    task_class="large"
    task_class_en="large"
    gate_1="核心空间交互或沉浸流程已有实际验证"
    gate_2="关键可达性、方向感或舒适性风险已检查"
    gate_3="仍停留在静态推断的空间判断已说明"
    gate_en_1="The core spatial interaction or immersive flow has real validation"
    gate_en_2="Key reachability, orientation, or comfort risks have been checked"
    gate_en_3="Any spatial judgment still based only on static inference is stated"
  elif [[ -f "${PROJECT_DIR}/package.json" ]]; then
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
      task_class="medium"
      task_class_en="medium"
      gate_1="关键用户路径或交互已实际验证"
      gate_2="主要视口下的用户可见行为有证据支持"
      gate_3="若仍有未验证项，必须明确列出"
      gate_en_1="The critical user path or interaction has been actually verified"
      gate_en_2="User-visible behavior across the main viewports is backed by evidence"
      gate_en_3="Any unverified area is stated explicitly"
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
      task_class="large"
      task_class_en="large"
      gate_1="跨层主路径已联通验证"
      gate_2="边界和影响面已经说明清楚"
      gate_3="关键风险和未覆盖点已显式列出"
      gate_en_1="The cross-layer primary path has been validated end to end"
      gate_en_2="Boundaries and adjacent impact are described clearly"
      gate_en_3="Key risks and uncovered areas are listed explicitly"
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
      task_class="lightweight"
      task_class_en="lightweight"
      gate_1="当前产物已证明或否定一个明确假设"
      gate_2="演示可用与生产可用已区分"
      gate_3="下一步判断所需证据已说明"
      gate_en_1="The current artifact proves or disproves a clear hypothesis"
      gate_en_2="Demo-ready and production-ready have been distinguished"
      gate_en_3="The next evidence needed for a decision is stated"
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
    task_class="medium"
    task_class_en="medium"
    gate_1="关键接口输入输出已验证"
    gate_2="错误路径和边界条件已有证据"
    gate_3="未执行的验证项已明确说明"
    gate_en_1="Critical interface inputs and outputs have been verified"
    gate_en_2="Error paths and edge conditions have supporting evidence"
    gate_en_3="Any verification not executed is stated clearly"
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
    task_class="large"
    task_class_en="large"
    gate_1="关键调用链和运行证据已检查"
    gate_2="修复效果有日志、测试或观测佐证"
    gate_3="运行风险和回退点已说明"
    gate_en_1="Critical call chains and runtime evidence were inspected"
    gate_en_2="The fix is backed by logs, tests, or observable signals"
    gate_en_3="Runtime risks and rollback points are documented"
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
    task_class="medium"
    task_class_en="medium"
    gate_1="关键行为已被验证或回归检查覆盖"
    gate_2="重构影响范围已说明"
    gate_3="未验证的语言级风险已列出"
    gate_en_1="Critical behavior is covered by verification or regression checks"
    gate_en_2="The refactor impact surface is described"
    gate_en_3="Any unverified language-level risk is listed"
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
    task_class="medium"
    task_class_en="medium"
    gate_1="首屏和关键区块已做可见性验证"
    gate_2="叙事层级和扫读路径已检查"
    gate_3="任何仅停留在静态判断的部分已明确说明"
    gate_en_1="The hero and key sections have been checked visually"
    gate_en_2="Narrative hierarchy and scan path were reviewed"
    gate_en_3="Any area still judged only statically is stated explicitly"
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
    task_class="medium"
    task_class_en="medium"
    gate_1="叙事顺序和每页作用已复核"
    gate_2="主线和品牌表达没有互相冲突"
    gate_3="任何未做最终渲染验证的部分已说明"
    gate_en_1="Narrative order and page purpose have been reviewed"
    gate_en_2="Main storyline and brand expression do not conflict"
    gate_en_3="Any part without final render validation is called out"
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
    task_class="lightweight"
    task_class_en="lightweight"
    gate_1="核心主张和目标动作已清晰可辨"
    gate_2="品牌一致性和转化意图已复核"
    gate_3="未验证渠道表现的部分已说明"
    gate_en_1="The core message and intended action are clearly visible"
    gate_en_2="Brand consistency and conversion intent were reviewed"
    gate_en_3="Any unverified channel-performance claim is stated as such"
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
    task_class="lightweight"
    task_class_en="lightweight"
    gate_1="当前结果确实降低了不确定性"
    gate_2="下一步判断所需证据已说明"
    gate_3="没有把忙碌误报成完成"
    gate_en_1="The current result genuinely reduced uncertainty"
    gate_en_2="The next evidence needed for a decision is stated"
    gate_en_3="Busy activity is not being reported as completion"
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
    ai-agent-stack:zh)
      handoff_1="当重点从 agent 设计转向工具接入时，切换到 MCP Builder"
      handoff_2="当重点从功能实现转向评估和成本稳定性时，切换到 Autonomous Optimization Architect"
      verify_1="验证关键 agent 回路和工具调用是否真实跑通"
      verify_2="检查失败模式、回退路径和上下文边界"
      verify_3="确认当前能力不是只靠单一样例成立"
      ;;
    ai-agent-stack:en)
      handoff_1="Switch to MCP Builder when the work shifts from agent design to tool integration"
      handoff_2="Switch to Autonomous Optimization Architect when the focus becomes evaluation, cost, or stability"
      verify_1="Verify the critical agent loop and tool calls actually run"
      verify_2="Check failure modes, rollback paths, and context boundaries"
      verify_3="Confirm the capability does not only work on one lucky example"
      ;;
    game-production:zh)
      handoff_1="当重点从玩法转向美术实现与性能时，切换到 Technical Artist"
      handoff_2="当重点从系统实现转向关卡与体验节奏时，切换到 Level Designer"
      verify_1="验证核心循环、关键场景或任务流是否可玩"
      verify_2="检查性能、反馈和可读性是否支撑体验"
      verify_3="确认新增内容没有破坏节奏或调试可追踪性"
      ;;
    game-production:en)
      handoff_1="Switch to Technical Artist when the focus shifts from gameplay to visual implementation or performance"
      handoff_2="Switch to Level Designer when the work shifts from systems to pacing and experience flow"
      verify_1="Validate that the core loop, key scene, or task flow is playable"
      verify_2="Check that performance, feedback, and readability support the experience"
      verify_3="Confirm new content did not break pacing or debugging traceability"
      ;;
    china-market-growth:zh)
      handoff_1="当重点从总策略转向平台内容时，切换到 Xiaohongshu Specialist 或 Douyin Strategist"
      handoff_2="当重点从发布计划转向私域或公众号承接时，切换到 WeChat Official Account"
      verify_1="检查渠道分工和内容语境是否匹配"
      verify_2="验证样例内容是否真的符合平台表达习惯"
      verify_3="确认增长判断没有脱离实际渠道证据"
      ;;
    china-market-growth:en)
      handoff_1="Switch to Xiaohongshu Specialist or Douyin Strategist when the work moves from overall strategy into platform content"
      handoff_2="Switch to WeChat Official Account when the focus shifts from publishing to retention or private-domain capture"
      verify_1="Check whether the channel split and content context match"
      verify_2="Validate that sample content actually fits the platform style"
      verify_3="Confirm growth claims are grounded in real channel evidence"
      ;;
    spatial-computing:zh)
      handoff_1="当重点从空间交互框架转向沉浸实现时，切换到 XR Immersive Developer"
      handoff_2="当重点落到 visionOS 设备约束时，切换到 VisionOS Spatial Engineer"
      verify_1="验证核心空间任务流和定向感"
      verify_2="检查关键交互是否可达、可理解、可恢复"
      verify_3="确认沉浸效果没有牺牲任务完成率"
      ;;
    spatial-computing:en)
      handoff_1="Switch to XR Immersive Developer when the work shifts from spatial interaction design into immersive implementation"
      handoff_2="Switch to VisionOS Spatial Engineer when device-specific constraints become the focus"
      verify_1="Validate the core spatial task flow and sense of orientation"
      verify_2="Check that key interactions are reachable, legible, and recoverable"
      verify_3="Confirm immersion effects did not reduce task completion clarity"
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

## Task Class
- ${task_class}

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

## Delivery Gate
- ${gate_1}
- ${gate_2}
- ${gate_3}

## Evolution Loop
- ${evo_1}
- ${evo_2}
- 每次迭代都要比上一个稳定版本更可信

## Squad History
- Initial squad: 由扫描自动生成，初始预设为 \`${preset}\`
- Latest change reason: 尚未记录人工调整
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

## Task Class
- ${task_class_en}

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

## Delivery Gate
- ${gate_en_1}
- ${gate_en_2}
- ${gate_en_3}

## Evolution Loop
- ${evo_en_1}
- ${evo_en_2}
- Make each iteration more trustworthy than the last stable state

## Squad History
- Initial squad: auto-generated from repository scan with initial preset \`${preset}\`
- Latest change reason: no manual re-routing recorded yet
EOF
  fi
}

normalize_token() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

write_dialog_profile() {
  local goal success stack artifact move normalized_goal normalized_stack normalized_artifact normalized_move
  local use_shared_preset_defaults="true"
  local type summary_stack artifacts preset primary support_a support_b support_c upstream_primary upstream_support_a upstream_support_b upstream_support_c
  local current_goal_1 current_goal_2 constraint_1 constraint_2 cue_1 switch_1 cue_2 switch_2 cue_3 switch_3
  local heur_1 heur_2 anti_1 anti_2 handoff_1 handoff_2 verify_1 verify_2 verify_3 evo_1 evo_2
  local task_class task_class_en gate_1 gate_2 gate_3
  local current_goal_en_1 current_goal_en_2 constraint_en_1 constraint_en_2 cue_en_1 switch_en_1 cue_en_2 switch_en_2 cue_en_3 switch_en_3
  local heur_en_1 heur_en_2 anti_en_1 anti_en_2 handoff_en_1 handoff_en_2 verify_en_1 verify_en_2 verify_en_3 evo_en_1 evo_en_2
  local gate_en_1 gate_en_2 gate_en_3

  goal="$(normalize_token "${PROJECT_GOAL:-}")"
  success="$(normalize_token "${SUCCESS_METRIC:-}")"
  stack="$(normalize_token "${STACK_CHOICE:-}")"
  artifact="$(normalize_token "${ARTIFACT_SHAPE:-}")"
  move="$(normalize_token "${FIRST_MOVE:-}")"

  normalized_goal="${goal:-new-project}"
  normalized_stack="${stack:-undecided}"
  normalized_artifact="${artifact:-repo}"
  normalized_move="${move:-clarify-plan}"

  case "${normalized_goal}" in
    website|single-page|presentation|deck|ppt)
      use_shared_preset_defaults="false"
      type="presentation-style web or deck concept"
      summary_stack="new project, ${normalized_stack}"
      artifacts="landing page, deck, or presentation-style deliverable"
      preset="ppt-storytelling"
      primary="Visual Storyteller"
      support_a="UI Designer"
      support_b="Frontend Developer"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/design/design-visual-storyteller.md"
      upstream_support_a="upstream-agents/design/design-ui-designer.md"
      upstream_support_b="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      cue_1="布局、叙事结构、视觉层级"
      switch_1="Visual Storyteller"
      cue_2="页面实现、样式、交互落地"
      switch_2="Frontend Developer"
      cue_3="可交付性、验证、响应式检查"
      switch_3="Reality Checker"
      current_goal_1="先明确故事线、页面结构和交付节奏"
      current_goal_2="围绕“${SUCCESS_METRIC:-更好看}”组织第一轮产出"
      constraint_1="当前为新项目推断 profile，需要随着真实样例持续修正"
      constraint_2="目标交付形态: ${PROJECT_GOAL:-演示页}; 主要产物: ${ARTIFACT_SHAPE:-页面或演示稿}"
      heur_1="先把叙事和信息层级讲清楚，再做局部抛光"
      heur_2="优先产生可看、可讲、可验证的页面骨架"
      anti_1="不要在主线未立住时堆装饰"
      anti_2="不要把页面实现细节误当成故事判断"
      handoff_1="当叙事方向稳定后，切换到 Frontend Developer 做实现"
      handoff_2="当页面可用后，切换到 Reality Checker 做交付验收"
      verify_1="检查首屏和关键区块是否表达核心主张"
      verify_2="验证页面扫读路径是否清晰"
      verify_3="区分提案可讲与成品可交付"
      evo_1="保留能强化故事线和扫读性的调整"
      evo_2="回滚降低说服力的视觉复杂度"
      task_class="medium"
      gate_1="核心叙事和页面骨架已可见可评审"
      gate_2="视觉判断与交付判断已区分"
      gate_3="未落地的实现或验证空白已说明"
      current_goal_en_1="Clarify the story, page structure, and delivery rhythm first"
      current_goal_en_2="Shape the first iteration around the success metric: ${SUCCESS_METRIC:-looks better}"
      constraint_en_1="This profile is inferred from new-project answers and should evolve with real project samples"
      constraint_en_2="Target shape: ${PROJECT_GOAL:-presentation page}; primary artifact: ${ARTIFACT_SHAPE:-page or deck}"
      cue_en_1="layout, narrative structure, and visual hierarchy"
      switch_en_1="Visual Storyteller"
      cue_en_2="page implementation, styling, and interaction delivery"
      switch_en_2="Frontend Developer"
      cue_en_3="readiness, verification, and responsive review"
      switch_en_3="Reality Checker"
      heur_en_1="Make the narrative and information hierarchy clear before polishing"
      heur_en_2="Prefer a visible, reviewable page skeleton early"
      anti_en_1="Do not pile on decoration before the core message stands"
      anti_en_2="Do not confuse implementation detail with narrative judgment"
      handoff_en_1="Switch to Frontend Developer once the narrative direction is stable"
      handoff_en_2="Switch to Reality Checker once the page is ready for delivery validation"
      verify_en_1="Check whether the hero and key sections express the core claim"
      verify_en_2="Validate the scan path and reading flow"
      verify_en_3="Distinguish between a pitch-ready draft and a delivery-ready artifact"
      evo_en_1="Keep changes that strengthen storyline and scanability"
      evo_en_2="Revert visual complexity that weakens persuasion"
      task_class_en="medium"
      gate_en_1="The core narrative and page skeleton are visible and reviewable"
      gate_en_2="Design judgment and delivery judgment are clearly separated"
      gate_en_3="Any implementation or verification gap is stated explicitly"
      ;;
    web-app|app|webapp)
      type="new frontend product or web app"
      summary_stack="new product, ${normalized_stack}"
      artifacts="frontend application, product flows, reusable UI"
      preset="frontend-product"
      primary="Frontend Developer"
      support_a="UI Designer"
      support_b="UX Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-frontend-developer.md"
      upstream_support_a="upstream-agents/design/design-ui-designer.md"
      upstream_support_b="upstream-agents/design/design-ux-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      cue_1="页面、组件、交互流程"
      switch_1="Frontend Developer"
      cue_2="信息架构、流程、体验判断"
      switch_2="UX Architect"
      cue_3="响应式、验收、用户可见行为验证"
      switch_3="Reality Checker"
      current_goal_1="先明确核心用户路径和第一批页面骨架"
      current_goal_2="围绕“${SUCCESS_METRIC:-能上线}”定义最小可验证流程"
      constraint_1="当前为新项目，无稳定代码基线，优先做最小有效结构"
      constraint_2="技术方向: ${STACK_CHOICE:-未定}; 当前第一优先: ${FIRST_MOVE:-先梳理方案}"
      heur_1="先让关键路径走通，再扩展抽象和系统性"
      heur_2="优先处理用户可见的阻塞点"
      anti_1="不要在用户路径未定时过早搭大框架"
      anti_2="不要在没有浏览器验证时宣称体验成立"
      handoff_1="当交互方向不清时，切换到 UX Architect"
      handoff_2="当页面可跑后，切换到 Reality Checker 做用户视角验证"
      verify_1="验证关键用户路径是否可走通"
      verify_2="检查主要视口下的布局和反馈"
      verify_3="确认当前实现支撑了最小可验证闭环"
      evo_1="保留能提升关键路径清晰度的改动"
      evo_2="回滚增加复杂度却不改善体验的实现"
      task_class="medium"
      gate_1="关键用户路径已有最小可验证闭环"
      gate_2="主要页面或视口已有可见验证"
      gate_3="未验证体验点已列出"
      current_goal_en_1="Define the core user path and first page skeletons"
      current_goal_en_2="Build the minimum verifiable flow around the success metric: ${SUCCESS_METRIC:-ready to ship}"
      constraint_en_1="This is a new project without a stable code baseline, so prefer the smallest effective structure"
      constraint_en_2="Stack direction: ${STACK_CHOICE:-undecided}; first priority: ${FIRST_MOVE:-clarify the plan}"
      cue_en_1="pages, components, and interaction flows"
      switch_en_1="Frontend Developer"
      cue_en_2="information architecture, flow design, and UX judgment"
      switch_en_2="UX Architect"
      cue_en_3="responsiveness, acceptance, and user-visible behavior verification"
      switch_en_3="Reality Checker"
      heur_en_1="Make the critical path work before expanding abstraction"
      heur_en_2="Prioritize user-visible blockers first"
      anti_en_1="Do not build a large framework before the user path is defined"
      anti_en_2="Do not claim the UX works without browser evidence"
      handoff_en_1="Switch to UX Architect when the interaction direction is still unclear"
      handoff_en_2="Switch to Reality Checker once the pages are runnable"
      verify_en_1="Validate that the key user path is complete"
      verify_en_2="Check layout and feedback across the main viewports"
      verify_en_3="Confirm the current build supports a minimal verifiable loop"
      evo_en_1="Keep changes that improve critical-path clarity"
      evo_en_2="Revert complexity that does not improve the experience"
      task_class_en="medium"
      gate_en_1="A minimal verifiable loop exists for the core user path"
      gate_en_2="The main page or viewport behavior has visible validation"
      gate_en_3="Any unverified UX point is listed"
      ;;
    api|backend|service|automation-workflow|automation)
      type="new backend service or workflow"
      summary_stack="new service, ${normalized_stack}"
      artifacts="service modules, APIs, automation steps, operational logic"
      preset="backend-service"
      primary="Backend Architect"
      support_a="API Tester"
      support_b="Software Architect"
      support_c="Technical Writer"
      upstream_primary="upstream-agents/engineering/engineering-backend-architect.md"
      upstream_support_a="upstream-agents/testing/testing-api-tester.md"
      upstream_support_b="upstream-agents/engineering/engineering-software-architect.md"
      upstream_support_c="upstream-agents/engineering/engineering-technical-writer.md"
      cue_1="接口设计、模块边界、服务流程"
      switch_1="Backend Architect"
      cue_2="验证输入输出、错误路径、调用约定"
      switch_2="API Tester"
      cue_3="整体结构、模块边界、设计文档"
      switch_3="Software Architect"
      current_goal_1="先定义接口边界、核心流程和可验证输入输出"
      current_goal_2="围绕“${SUCCESS_METRIC:-更稳定}”组织第一版服务结构"
      constraint_1="当前缺少成熟运行证据，先建立可验证接口和最小调用链"
      constraint_2="预期栈: ${STACK_CHOICE:-未定}; 主要交付: ${ARTIFACT_SHAPE:-接口或流程}"
      heur_1="先保证边界清晰和数据流正确，再谈扩展性"
      heur_2="优先引入能被验证的结构，而不是口头上的完整设计"
      anti_1="不要在调用边界未理清时扩大改动"
      anti_2="不要没有接口证据就声称服务稳定"
      handoff_1="当实现进入验证阶段时，切换到 API Tester"
      handoff_2="当局部实现暴露出结构问题时，切换到 Software Architect"
      verify_1="验证关键接口输入输出"
      verify_2="检查错误路径和边界条件"
      verify_3="确认第一版结构支持后续扩展"
      evo_1="保留能提升正确性和可验证性的改动"
      evo_2="回滚扩大风险却没有更清晰边界的设计"
      task_class="large"
      gate_1="关键接口或流程已有验证证据"
      gate_2="边界、风险与未覆盖项已说明"
      gate_3="没有把设计描述误报成已交付能力"
      current_goal_en_1="Define interface boundaries, the core flow, and verifiable inputs and outputs first"
      current_goal_en_2="Shape the first service structure around the success metric: ${SUCCESS_METRIC:-more reliable}"
      constraint_en_1="There is no mature runtime evidence yet, so build a verifiable interface and minimal call chain first"
      constraint_en_2="Expected stack: ${STACK_CHOICE:-undecided}; main artifact: ${ARTIFACT_SHAPE:-API or workflow}"
      cue_en_1="API design, module boundaries, and service flow"
      switch_en_1="Backend Architect"
      cue_en_2="input/output validation, error paths, and calling contracts"
      switch_en_2="API Tester"
      cue_en_3="overall structure, module boundaries, and system design docs"
      switch_en_3="Software Architect"
      heur_en_1="Protect clear boundaries and correct data flow before chasing extensibility"
      heur_en_2="Prefer structures that can be verified, not just described"
      anti_en_1="Do not widen implementation before the calling boundaries are clear"
      anti_en_2="Do not claim service stability without interface evidence"
      handoff_en_1="Switch to API Tester when the implementation enters verification"
      handoff_en_2="Switch to Software Architect when local implementation exposes structural issues"
      verify_en_1="Validate critical interface inputs and outputs"
      verify_en_2="Check error paths and edge conditions"
      verify_en_3="Confirm the first structure can support future extension"
      evo_en_1="Keep changes that improve correctness and verifiability"
      evo_en_2="Revert design expansion that increases risk without clearer boundaries"
      task_class_en="large"
      gate_en_1="Critical interfaces or flows have verification evidence"
      gate_en_2="Boundaries, risks, and uncovered areas are documented"
      gate_en_3="Design description is not being reported as delivered capability"
      ;;
    ai|agent|agents|llm|mcp|ai-tool|agent-workflow)
      type="new AI agent or LLM workflow project"
      summary_stack="AI product or automation, ${normalized_stack}"
      artifacts="agent loops, prompts, tools, evaluations, MCP integrations"
      preset="ai-agent-stack"
      primary="AI Engineer"
      support_a="MCP Builder"
      support_b="Autonomous Optimization Architect"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/engineering/engineering-ai-engineer.md"
      upstream_support_a="upstream-agents/specialized/specialized-mcp-builder.md"
      upstream_support_b="upstream-agents/engineering/engineering-autonomous-optimization-architect.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      cue_1="agent 设计、prompt、tool 调用、上下文策略"
      switch_1="AI Engineer"
      cue_2="MCP、工具接入、外部系统连接"
      switch_2="MCP Builder"
      cue_3="评估、回归、成本稳定性、是否真的有效"
      switch_3="Autonomous Optimization Architect"
      current_goal_1="先定义关键 agent 回路、工具边界和最小可验证样例"
      current_goal_2="围绕“${SUCCESS_METRIC:-more reliable}”建立第一轮评估闭环"
      constraint_1="当前为新项目推断，先追求可解释与可验证，不先堆复杂 orchestration"
      constraint_2="预期栈: ${STACK_CHOICE:-未定}; 主要交付: ${ARTIFACT_SHAPE:-agent 或 workflow}"
      heur_1="先证明 agent 回路和工具调用稳定成立，再扩展能力面"
      heur_2="优先建立失败样例、评估和回归，而不是只追求首轮演示"
      anti_1="不要把一次好结果误当成系统稳定"
      anti_2="不要在没有评估证据时不断堆 prompt 和工具"
      handoff_1="当问题转向工具接入时，切换到 MCP Builder"
      handoff_2="当重点转向评估、成本和长期稳定性时，切换到 Autonomous Optimization Architect"
      verify_1="验证关键 agent 回路和工具调用"
      verify_2="检查失败模式、回退路径和上下文边界"
      verify_3="确认当前能力不是样例偶然"
      evo_1="保留能提升成功率、可解释性和回归稳定性的改动"
      evo_2="回滚增加复杂度却没有更多证据的 agent 设计"
      task_class="large"
      gate_1="关键 agent 回路已有真实样例验证"
      gate_2="失败模式、评估方式与回退路径已说明"
      gate_3="没有把 prompt 想法误报成稳定能力"
      current_goal_en_1="Define the critical agent loop, tool boundaries, and minimum verifiable examples"
      current_goal_en_2="Build the first evaluation loop around the success metric: ${SUCCESS_METRIC:-more reliable}"
      constraint_en_1="This is a new-project inference, so prioritize explainability and verification before orchestration complexity"
      constraint_en_2="Expected stack: ${STACK_CHOICE:-undecided}; main artifact: ${ARTIFACT_SHAPE:-agent or workflow}"
      cue_en_1="agent design, prompts, tool calls, and context strategy"
      switch_en_1="AI Engineer"
      cue_en_2="MCP, tool integration, and external-system connectivity"
      switch_en_2="MCP Builder"
      cue_en_3="evaluation, regression, cost stability, and whether it really works"
      switch_en_3="Autonomous Optimization Architect"
      heur_en_1="Prove the agent loop and tool calls work reliably before expanding capability scope"
      heur_en_2="Prefer failure examples, evaluation, and regression over first-demo success"
      anti_en_1="Do not treat one good result as system stability"
      anti_en_2="Do not keep adding prompts and tools without evaluation evidence"
      handoff_en_1="Switch to MCP Builder when the problem becomes tool integration"
      handoff_en_2="Switch to Autonomous Optimization Architect when the focus becomes evaluation, cost, or long-term stability"
      verify_en_1="Validate the critical agent loop and tool calls"
      verify_en_2="Check failure modes, rollback paths, and context boundaries"
      verify_en_3="Confirm the current capability is not sample luck"
      evo_en_1="Keep changes that improve success rate, explainability, and regression stability"
      evo_en_2="Revert agent design complexity that lacks stronger evidence"
      task_class_en="large"
      gate_en_1="Critical agent loops have real-example verification"
      gate_en_2="Failure modes, evaluation methods, and rollback paths are documented"
      gate_en_3="Prompt ideas are not being reported as stable capability"
      ;;
    game|unity|godot|unreal|roblox)
      type="new game development project"
      summary_stack="game project, ${normalized_stack}"
      artifacts="game systems, scenes, assets, engine-specific workflows"
      preset="game-production"
      primary="Game Designer"
      support_a="Technical Artist"
      support_b="Level Designer"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/game-development/game-designer.md"
      upstream_support_a="upstream-agents/game-development/technical-artist.md"
      upstream_support_b="upstream-agents/game-development/level-designer.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      if [[ "${normalized_stack}" == *"unity"* ]]; then
        primary="Unity Architect"
        upstream_primary="upstream-agents/game-development/unity/unity-architect.md"
      elif [[ "${normalized_stack}" == *"godot"* ]]; then
        primary="Godot Gameplay Scripter"
        upstream_primary="upstream-agents/game-development/godot/godot-gameplay-scripter.md"
      elif [[ "${normalized_stack}" == *"unreal"* ]]; then
        primary="Unreal Systems Engineer"
        upstream_primary="upstream-agents/game-development/unreal-engine/unreal-systems-engineer.md"
      fi
      cue_1="玩法循环、系统设计、任务流程"
      switch_1="${primary}"
      cue_2="美术实现、技术美术、性能和资源管线"
      switch_2="Technical Artist"
      cue_3="关卡、节奏、玩家体验验证"
      switch_3="Level Designer"
      current_goal_1="先定义核心玩法循环、关键场景和第一轮可玩验证"
      current_goal_2="围绕“${SUCCESS_METRIC:-more fun}”组织最小可玩切片"
      constraint_1="当前为新项目推断，先建立可玩证据，不先扩张内容体量"
      constraint_2="目标栈: ${STACK_CHOICE:-未定}; 主要交付: ${ARTIFACT_SHAPE:-可玩原型}"
      heur_1="先让核心循环成立，再扩张系统和内容"
      heur_2="优先用可玩反馈、性能证据和调试可见性判断取舍"
      anti_1="不要在核心反馈未成立时并行铺太多系统"
      anti_2="不要把引擎里能跑误当成玩家体验成立"
      handoff_1="当重点从玩法转向技术美术和性能时，切换到 Technical Artist"
      handoff_2="当重点从系统实现转向节奏与场景体验时，切换到 Level Designer"
      verify_1="验证核心循环或关键场景是否可玩"
      verify_2="检查反馈、可读性和性能是否支持体验"
      verify_3="确认当前切片足以支撑下一步判断"
      evo_1="保留能提升可玩性、可观测性和迭代速度的改动"
      evo_2="回滚增加内容却降低节奏和反馈质量的版本"
      task_class="large"
      gate_1="核心玩法切片已有可玩验证"
      gate_2="性能、反馈或美术实现至少有一项有真实证据"
      gate_3="未验证的平台或内容范围已说明"
      current_goal_en_1="Define the core loop, key scene, and first playable validation"
      current_goal_en_2="Build the minimum playable slice around the success metric: ${SUCCESS_METRIC:-more fun}"
      constraint_en_1="This is a new-project inference, so build playable evidence before expanding content volume"
      constraint_en_2="Target stack: ${STACK_CHOICE:-undecided}; main artifact: ${ARTIFACT_SHAPE:-playable prototype}"
      cue_en_1="core loop, systems design, and task flow"
      switch_en_1="${primary}"
      cue_en_2="visual implementation, technical art, performance, and asset pipeline"
      switch_en_2="Technical Artist"
      cue_en_3="level pacing and player experience validation"
      switch_en_3="Level Designer"
      heur_en_1="Make the core loop work before expanding systems and content"
      heur_en_2="Prefer playable feedback, performance evidence, and debug visibility"
      anti_en_1="Do not spread across too many systems before the core feedback loop works"
      anti_en_2="Do not confuse engine-run success with player-experience validity"
      handoff_en_1="Switch to Technical Artist when the focus shifts to technical art or performance"
      handoff_en_2="Switch to Level Designer when the focus shifts to pacing and scene experience"
      verify_en_1="Validate that the core loop or key scene is playable"
      verify_en_2="Check that feedback, readability, and performance support the experience"
      verify_en_3="Confirm the current slice supports the next decision"
      evo_en_1="Keep changes that improve playability, observability, and iteration speed"
      evo_en_2="Revert versions that add content while weakening pacing or feedback"
      task_class_en="large"
      gate_en_1="The core gameplay slice has playable verification"
      gate_en_2="Performance, feedback, or visual implementation has real evidence"
      gate_en_3="Any unverified platform or content scope is stated"
      ;;
    china|cn-growth|xiaohongshu|douyin|wechat)
      type="new China-market growth or content project"
      summary_stack="China channel strategy, ${normalized_stack}"
      artifacts="localized copy, channel content, publishing and retention workflows"
      preset="china-market-growth"
      primary="China Market Localization Strategist"
      support_a="Xiaohongshu Specialist"
      support_b="Douyin Strategist"
      support_c="WeChat Official Account"
      upstream_primary="upstream-agents/marketing/marketing-china-market-localization-strategist.md"
      upstream_support_a="upstream-agents/marketing/marketing-xiaohongshu-specialist.md"
      upstream_support_b="upstream-agents/marketing/marketing-douyin-strategist.md"
      upstream_support_c="upstream-agents/marketing/marketing-wechat-official-account.md"
      cue_1="本地化定位、渠道策略、内容矩阵"
      switch_1="China Market Localization Strategist"
      cue_2="小红书、抖音等平台内容与节奏"
      switch_2="Xiaohongshu Specialist"
      cue_3="公众号、私域承接、留存链路"
      switch_3="WeChat Official Account"
      current_goal_1="先定义中国市场主张、渠道分工和第一批样例内容"
      current_goal_2="围绕“${SUCCESS_METRIC:-more conversions}”搭出最小渠道闭环"
      constraint_1="当前为新项目推断，先做平台适配和本地化，不先复制海外内容套路"
      constraint_2="主要交付: ${ARTIFACT_SHAPE:-渠道内容}; 当前第一优先: ${FIRST_MOVE:-内容框架}"
      heur_1="先统一本地化主张和渠道角色，再扩展内容量"
      heur_2="优先保证平台语境、转化路径和品牌表达一致"
      anti_1="不要一稿多投所有中文渠道"
      anti_2="不要把发出内容误当成增长成立"
      handoff_1="当工作进入平台内容打磨时，切换到 Xiaohongshu Specialist 或 Douyin Strategist"
      handoff_2="当目标转向承接和留存时，切换到 WeChat Official Account"
      verify_1="检查渠道分工和本地化主张是否清楚"
      verify_2="验证样例内容是否真的符合平台表达习惯"
      verify_3="确认增长判断有实际渠道证据支撑"
      evo_1="保留提升本地化贴合度和渠道匹配度的调整"
      evo_2="回滚热闹但低转化证据的内容扩张"
      task_class="medium"
      gate_1="核心渠道分工和主张已清楚"
      gate_2="至少一个渠道已有样例内容或验证标准"
      gate_3="未验证增长假设已说明"
      current_goal_en_1="Define the China-market message, channel roles, and first sample content"
      current_goal_en_2="Build the smallest channel loop around the success metric: ${SUCCESS_METRIC:-more conversions}"
      constraint_en_1="This is a new-project inference, so adapt for platform fit and localization before reusing global content patterns"
      constraint_en_2="Main artifact: ${ARTIFACT_SHAPE:-channel content}; first priority: ${FIRST_MOVE:-content framing}"
      cue_en_1="localization positioning, channel strategy, and content matrix"
      switch_en_1="China Market Localization Strategist"
      cue_en_2="Xiaohongshu, Douyin, and platform-specific content rhythm"
      switch_en_2="Xiaohongshu Specialist"
      cue_en_3="WeChat, private-domain capture, and retention loops"
      switch_en_3="WeChat Official Account"
      heur_en_1="Align the localized message and channel roles before scaling content volume"
      heur_en_2="Keep platform context, conversion path, and brand expression aligned"
      anti_en_1="Do not broadcast one draft unchanged across every Chinese channel"
      anti_en_2="Do not treat published content as proven growth"
      handoff_en_1="Switch to Xiaohongshu Specialist or Douyin Strategist when execution becomes platform-content shaping"
      handoff_en_2="Switch to WeChat Official Account when the goal becomes retention or private-domain capture"
      verify_en_1="Check whether the channel split and localized message are clear"
      verify_en_2="Validate that sample content actually fits the platform style"
      verify_en_3="Confirm growth claims have real channel evidence"
      evo_en_1="Keep adjustments that improve localization fit and channel-match quality"
      evo_en_2="Revert noisy expansion with weak conversion evidence"
      task_class_en="medium"
      gate_en_1="The core channel split and message are clear"
      gate_en_2="At least one channel has sample content or a validation standard"
      gate_en_3="Any unverified growth assumption is stated"
      ;;
    xr|ar|vr|spatial|visionos)
      type="new spatial computing project"
      summary_stack="spatial computing, ${normalized_stack}"
      artifacts="spatial interactions, immersive flows, 3D interface logic"
      preset="spatial-computing"
      primary="XR Interface Architect"
      support_a="XR Immersive Developer"
      support_b="VisionOS Spatial Engineer"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/spatial-computing/xr-interface-architect.md"
      upstream_support_a="upstream-agents/spatial-computing/xr-immersive-developer.md"
      upstream_support_b="upstream-agents/spatial-computing/visionos-spatial-engineer.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      cue_1="空间交互、心智模型、任务流"
      switch_1="XR Interface Architect"
      cue_2="沉浸实现、环境效果、空间体验细节"
      switch_2="XR Immersive Developer"
      cue_3="visionOS 或设备约束、性能与舒适性"
      switch_3="VisionOS Spatial Engineer"
      current_goal_1="先定义核心空间任务流、方向感和交互模型"
      current_goal_2="围绕“${SUCCESS_METRIC:-more usable}”构建第一轮沉浸验证"
      constraint_1="当前为新项目推断，先解决空间可理解性，不先堆沉浸效果"
      constraint_2="技术方向: ${STACK_CHOICE:-未定}; 主要交付: ${ARTIFACT_SHAPE:-immersive flow}"
      heur_1="先让空间任务流和定向感成立，再扩展沉浸细节"
      heur_2="优先验证可达性、舒适性和任务完成率"
      anti_1="不要把二维界面习惯直接复制到空间里"
      anti_2="不要在交互模型不稳时过早堆视觉奇观"
      handoff_1="当重点转向沉浸实现时，切换到 XR Immersive Developer"
      handoff_2="当重点落到设备与系统约束时，切换到 VisionOS Spatial Engineer"
      verify_1="验证核心空间任务流和定向感"
      verify_2="检查关键交互的可达性、可理解性和恢复能力"
      verify_3="确认沉浸效果没有牺牲任务完成"
      evo_1="保留能提升空间可理解性和交互稳定性的改动"
      evo_2="回滚只增加炫技却削弱方向感的实现"
      task_class="large"
      gate_1="核心空间任务流已有实际验证"
      gate_2="可达性、舒适性或性能至少有一项有证据"
      gate_3="未验证的设备或空间判断已说明"
      current_goal_en_1="Define the core spatial task flow, orientation model, and interaction model first"
      current_goal_en_2="Build the first immersive validation around the success metric: ${SUCCESS_METRIC:-more usable}"
      constraint_en_1="This is a new-project inference, so solve spatial legibility before adding immersive flourish"
      constraint_en_2="Stack direction: ${STACK_CHOICE:-undecided}; main artifact: ${ARTIFACT_SHAPE:-immersive flow}"
      cue_en_1="spatial interaction, mental model, and task flow"
      switch_en_1="XR Interface Architect"
      cue_en_2="immersive implementation, environmental effects, and spatial experience details"
      switch_en_2="XR Immersive Developer"
      cue_en_3="visionOS or device constraints, performance, and comfort"
      switch_en_3="VisionOS Spatial Engineer"
      heur_en_1="Make the spatial task flow and orientation model work before adding immersive detail"
      heur_en_2="Prioritize reachability, comfort, and task completion evidence"
      anti_en_1="Do not copy flat-screen habits directly into space"
      anti_en_2="Do not add spectacle before the interaction model is stable"
      handoff_en_1="Switch to XR Immersive Developer when the focus becomes immersive implementation"
      handoff_en_2="Switch to VisionOS Spatial Engineer when device or OS constraints dominate"
      verify_en_1="Validate the core spatial task flow and orientation model"
      verify_en_2="Check reachability, legibility, and recovery for key interactions"
      verify_en_3="Confirm immersion effects did not reduce task completion clarity"
      evo_en_1="Keep changes that improve spatial legibility and interaction stability"
      evo_en_2="Revert spectacle that weakens orientation"
      task_class_en="large"
      gate_en_1="The core spatial task flow has real validation"
      gate_en_2="Reachability, comfort, or performance has evidence"
      gate_en_3="Any unverified device or spatial judgment is stated"
      ;;
    content|marketing|brand)
      type="new content or marketing workspace"
      summary_stack="content-led project, ${normalized_stack}"
      artifacts="content assets, brand language, campaign or publishing outputs"
      preset="marketing-site"
      primary="Content Creator"
      support_a="Brand Guardian"
      support_b="Visual Storyteller"
      support_c="SEO Specialist"
      upstream_primary="upstream-agents/marketing/marketing-content-creator.md"
      upstream_support_a="upstream-agents/design/design-brand-guardian.md"
      upstream_support_b="upstream-agents/design/design-visual-storyteller.md"
      upstream_support_c="upstream-agents/marketing/marketing-seo-specialist.md"
      cue_1="主张、文案、内容框架"
      switch_1="Content Creator"
      cue_2="品牌一致性、视觉叙事"
      switch_2="Brand Guardian"
      cue_3="搜索表现、SEO、传播验证"
      switch_3="SEO Specialist"
      current_goal_1="先定义核心主张、受众和第一批内容结构"
      current_goal_2="围绕“${SUCCESS_METRIC:-更快完成}”组织最小传播闭环"
      constraint_1="当前为新项目内容假设，后续需要依据真实渠道和素材修正"
      constraint_2="内容形态: ${ARTIFACT_SHAPE:-文案或营销资产}; 第一优先: ${FIRST_MOVE:-先写文案}"
      heur_1="先把主张讲清楚，再扩展内容量"
      heur_2="优先让内容、品牌和转化动作对齐"
      anti_1="不要内容越写越多却更模糊"
      anti_2="不要为了堆词破坏品牌一致性"
      handoff_1="当内容框架稳定后，切换到 Brand Guardian 或 Visual Storyteller"
      handoff_2="当目标转向搜索和分发验证时，切换到 SEO Specialist"
      verify_1="检查核心主张是否一眼可见"
      verify_2="验证内容与预期动作是否一致"
      verify_3="确认扩展没有削弱品牌和转化意图"
      evo_1="保留能提升清晰度和传播效率的改动"
      evo_2="回滚拉长内容却削弱力度的版本"
      task_class="lightweight"
      gate_1="核心主张和预期动作已清晰可见"
      gate_2="品牌与转化目标未互相打架"
      gate_3="未验证渠道效果的部分已说明"
      current_goal_en_1="Define the core claim, audience, and first content structure"
      current_goal_en_2="Build the smallest distribution loop around the success metric: ${SUCCESS_METRIC:-faster to complete}"
      constraint_en_1="This profile is based on new-project content assumptions and should evolve with real channels and assets"
      constraint_en_2="Content shape: ${ARTIFACT_SHAPE:-copy or marketing asset}; first priority: ${FIRST_MOVE:-write copy}"
      cue_en_1="messaging, copy, and content framing"
      switch_en_1="Content Creator"
      cue_en_2="brand consistency and visual narrative"
      switch_en_2="Brand Guardian"
      cue_en_3="search performance, SEO, and distribution validation"
      switch_en_3="SEO Specialist"
      heur_en_1="Clarify the message before expanding content volume"
      heur_en_2="Keep content, brand, and conversion action aligned"
      anti_en_1="Do not let more content make the message blurrier"
      anti_en_2="Do not damage brand consistency for keyword stuffing"
      handoff_en_1="Switch to Brand Guardian or Visual Storyteller once the content frame is stable"
      handoff_en_2="Switch to SEO Specialist once the goal becomes search or distribution validation"
      verify_en_1="Check whether the core claim is obvious at a glance"
      verify_en_2="Validate that the content aligns with the intended action"
      verify_en_3="Confirm expansion did not weaken brand or conversion intent"
      evo_en_1="Keep changes that improve clarity and distribution efficiency"
      evo_en_2="Revert versions that lengthen content while weakening force"
      task_class_en="lightweight"
      gate_en_1="The core claim and intended action are clear"
      gate_en_2="Brand and conversion goals are not fighting each other"
      gate_en_3="Any unverified channel-effect assumption is stated"
      ;;
    *)
      type="zero-to-one product workspace"
      summary_stack="new project, ${normalized_stack}"
      artifacts="mixed repository assets, early prototypes, planning docs"
      preset="zero-to-one-startup"
      primary="Product Manager"
      support_a="Rapid Prototyper"
      support_b="Project Shepherd"
      support_c="Reality Checker"
      upstream_primary="upstream-agents/product/product-product-manager.md"
      upstream_support_a="upstream-agents/engineering/engineering-rapid-prototyper.md"
      upstream_support_b="upstream-agents/project-management/project-management-project-shepherd.md"
      upstream_support_c="upstream-agents/testing/testing-reality-checker.md"
      cue_1="目标、范围、优先级、路线"
      switch_1="Product Manager"
      cue_2="快速原型、第一版实现、方向验证"
      switch_2="Rapid Prototyper"
      cue_3="验收、现实校验、是否真的有进展"
      switch_3="Reality Checker"
      current_goal_1="先把目标、成功标准和最小下一步说清楚"
      current_goal_2="围绕“${SUCCESS_METRIC:-更易扩展}”形成第一轮最小验证方案"
      constraint_1="当前仓库样本不足，profile 主要基于对话推断"
      constraint_2="项目目标: ${PROJECT_GOAL:-新产品}; 第一优先: ${FIRST_MOVE:-先梳理方案}"
      heur_1="先减少不确定性，再增加建设量"
      heur_2="优先做能证明方向的最小结果"
      anti_1="不要把忙碌误当成前进"
      anti_2="不要在问题未定义稳之前过度建设"
      handoff_1="当方向需要快速验证时，切换到 Rapid Prototyper"
      handoff_2="当产物需要现实校验时，切换到 Reality Checker"
      verify_1="确认当前方案是否真的降低了不确定性"
      verify_2="检查下一步是否因此更明确"
      verify_3="区分讨论进展与实际进展"
      evo_1="保留能减少不确定性的推进"
      evo_2="回滚扩大范围却没有更强证据的工作"
      task_class="lightweight"
      gate_1="当前输出确实降低了一个关键不确定性"
      gate_2="下一步决策所需证据已说明"
      gate_3="没有把讨论误报成进展"
      current_goal_en_1="Clarify the goal, success metric, and smallest next step first"
      current_goal_en_2="Create a minimum validation path around the success metric: ${SUCCESS_METRIC:-easier to extend}"
      constraint_en_1="There is not enough repository evidence yet, so this profile is mostly dialogue-derived"
      constraint_en_2="Project goal: ${PROJECT_GOAL:-new product}; first priority: ${FIRST_MOVE:-clarify the plan}"
      cue_en_1="goal setting, scope, priorities, and roadmap"
      switch_en_1="Product Manager"
      cue_en_2="rapid prototypes, first implementation, and direction validation"
      switch_en_2="Rapid Prototyper"
      cue_en_3="acceptance, reality checks, and whether progress is real"
      switch_en_3="Reality Checker"
      heur_en_1="Reduce uncertainty before increasing construction"
      heur_en_2="Prefer the smallest output that proves direction"
      anti_en_1="Do not confuse busyness with progress"
      anti_en_2="Do not overbuild before the problem is actually defined"
      handoff_en_1="Switch to Rapid Prototyper when the direction needs fast validation"
      handoff_en_2="Switch to Reality Checker when the output needs a reality check"
      verify_en_1="Confirm the current plan actually reduced uncertainty"
      verify_en_2="Check whether the next move is now clearer"
      verify_en_3="Distinguish discussion progress from actual progress"
      evo_en_1="Keep moves that reduce uncertainty"
      evo_en_2="Revert work that expands scope without stronger proof"
      task_class_en="lightweight"
      gate_en_1="The current output genuinely reduced a key uncertainty"
      gate_en_2="The next evidence needed for a decision is stated"
      gate_en_3="Discussion is not being reported as progress"
      ;;
  esac

  if [[ "${use_shared_preset_defaults}" == "true" ]]; then
    local -a preset_zh=()
    local -a preset_en=()

    while IFS= read -r line; do
      preset_zh+=("${line}")
    done < <(read_preset_defaults "${preset}" "zh")
    while IFS= read -r line; do
      preset_en+=("${line}")
    done < <(read_preset_defaults "${preset}" "en")

    primary="${preset_zh[0]:-}"
    support_a="${preset_zh[1]:-}"
    support_b="${preset_zh[2]:-}"
    support_c="${preset_zh[3]:-}"
    upstream_primary="${preset_zh[4]:-}"
    upstream_support_a="${preset_zh[5]:-}"
    upstream_support_b="${preset_zh[6]:-}"
    upstream_support_c="${preset_zh[7]:-}"
    task_class="${preset_zh[8]:-}"
    cue_1="${preset_zh[9]:-}"
    cue_2="${preset_zh[10]:-}"
    cue_3="${preset_zh[11]:-}"
    switch_1="${preset_zh[12]:-}"
    switch_2="${preset_zh[13]:-}"
    switch_3="${preset_zh[14]:-}"
    gate_1="${preset_zh[15]:-}"
    gate_2="${preset_zh[16]:-}"
    gate_3="${preset_zh[17]:-}"

    task_class_en="${preset_en[8]:-}"
    cue_en_1="${preset_en[9]:-}"
    cue_en_2="${preset_en[10]:-}"
    cue_en_3="${preset_en[11]:-}"
    switch_en_1="${preset_en[12]:-}"
    switch_en_2="${preset_en[13]:-}"
    switch_en_3="${preset_en[14]:-}"
    gate_en_1="${preset_en[15]:-}"
    gate_en_2="${preset_en[16]:-}"
    gate_en_3="${preset_en[17]:-}"
  fi

  if [[ "${preset}" == "game-production" ]]; then
    case "${normalized_stack}" in
      *unity*)
        primary="Unity Architect"
        upstream_primary="upstream-agents/game-development/unity/unity-architect.md"
        ;;
      *godot*)
        primary="Godot Gameplay Scripter"
        upstream_primary="upstream-agents/game-development/godot/godot-gameplay-scripter.md"
        ;;
      *unreal*)
        primary="Unreal Systems Engineer"
        upstream_primary="upstream-agents/game-development/unreal-engine/unreal-systems-engineer.md"
        ;;
    esac
    switch_1="${primary}"
    switch_en_1="${primary}"
  fi

  if [[ "${PROFILE_LANG}" == "zh" ]]; then
    cat > "${PROFILE_FILE}" <<EOF
# Project Profile

## Summary
- Type: ${type}
- Stack: ${summary_stack}
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
- If user asks for: ${cue_1}
- Switch to: \`${switch_1}\`
- If user asks for: ${cue_2}
- Switch to: \`${switch_2}\`
- If user asks for: ${cue_3}
- Switch to: \`${switch_3}\`

## Current Goals
- ${current_goal_1}
- ${current_goal_2}

## Constraints
- ${constraint_1}
- ${constraint_2}

## Working Style
- 先基于对话建立最小可执行方向，再随着样例和代码增长更新 profile
- 优先使用最小有效 squad，避免在新项目阶段过早膨胀

## Task Class
- ${task_class}

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

## Delivery Gate
- ${gate_1}
- ${gate_2}
- ${gate_3}

## Evolution Loop
- ${evo_1}
- ${evo_2}
- 每次迭代都要比上一个稳定版本更可信

## Squad History
- Initial squad: 由新项目对话生成，初始预设为 \`${preset}\`
- Latest change reason: 尚未记录人工调整
EOF
  else
    cat > "${PROFILE_FILE}" <<EOF
# Project Profile

## Summary
- Type: ${type}
- Stack: ${summary_stack}
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
- If user asks for: ${cue_en_1}
- Switch to: \`${switch_en_1}\`
- If user asks for: ${cue_en_2}
- Switch to: \`${switch_en_2}\`
- If user asks for: ${cue_en_3}
- Switch to: \`${switch_en_3}\`

## Current Goals
- ${current_goal_en_1}
- ${current_goal_en_2}

## Constraints
- ${constraint_en_1}
- ${constraint_en_2}

## Working Style
- Start from a dialogue-derived execution direction, then refine the profile as code and artifacts appear
- Prefer the smallest useful squad before expanding early-project scope

## Task Class
- ${task_class_en}

## Decision Heuristics
- ${heur_en_1}
- ${heur_en_2}

## Anti-Patterns
- ${anti_en_1}
- ${anti_en_2}

## Handoff Triggers
- ${handoff_en_1}
- ${handoff_en_2}

## Escalation Policy
- Switch to high-agency mode after 2 repeated failures on the same path
- Require verifiable evidence before claiming completion

## Verification Protocol
- ${verify_en_1}
- ${verify_en_2}
- ${verify_en_3}

## Delivery Gate
- ${gate_en_1}
- ${gate_en_2}
- ${gate_en_3}

## Evolution Loop
- ${evo_en_1}
- ${evo_en_2}
- Make each iteration more trustworthy than the last stable state

## Squad History
- Initial squad: generated from new-project dialogue with initial preset \`${preset}\`
- Latest change reason: no manual re-routing recorded yet
EOF
  fi
}

write_dialog_files() {
  cp "${DIALOG_TEMPLATE_FILE}" "${INTAKE_FILE}"
  if [[ -n "${PROJECT_GOAL}${SUCCESS_METRIC}${STACK_CHOICE}${ARTIFACT_SHAPE}${FIRST_MOVE}" ]]; then
    write_dialog_profile
  else
    cp "${TEMPLATE_FILE}" "${PROFILE_FILE}"
  fi
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
