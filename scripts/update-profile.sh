#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
PROFILE_LANG=""
PRESET=""
PRIMARY=""
SUPPORTING=""
UPSTREAM_AGENTS=""
TASK_CLASS=""
REASON=""
UPDATED_BY="router-guard"
CUE_MODE="replace"
CUE_MATCH_MODE="exact"
declare -a CUE_ASKS=()
declare -a CUE_SWITCHES=()
declare -a REMOVE_CUE_ASKS=()
declare -a DELIVERY_GATE_LINES=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/update-profile.sh --project /path/to/repo --reason TEXT [options]

Options:
  --project PATH          Target project directory containing .codex/project-profile.md
  --lang zh|en            Optional explicit profile language override
  --preset VALUE          Replace the Preset line in Default Squad
  --primary VALUE         Replace the Primary line in Default Squad
  --supporting VALUE      Replace the Supporting line, comma-separated
  --upstream VALUE        Replace Upstream agents, newline-separated with literal \n or comma-separated
  --task-class VALUE      Replace the Task Class section with a single value
  --delivery-gate VALUE   Add a Delivery Gate bullet; can be repeated, replaces section if provided
  --cue-mode MODE         Routing cue update mode: replace (default) or append
  --cue-match MODE        Routing cue match mode for append/remove: exact (default) or semantic
  --if-user-asks VALUE    Routing cue ask phrase for the current cue update; can be repeated
  --switch-to VALUE       Matching switch target for the previous --if-user-asks; can be repeated
  --remove-if-user-asks VALUE
                          Remove existing routing cue branches matching this ask phrase; can be repeated
  --reason TEXT           Human-readable reroute reason to append into Squad History
  --updated-by VALUE      Source tag for the history line, default: router-guard
  -h, --help              Show this help message
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
    --preset)
      PRESET="${2:-}"
      shift 2
      ;;
    --primary)
      PRIMARY="${2:-}"
      shift 2
      ;;
    --supporting)
      SUPPORTING="${2:-}"
      shift 2
      ;;
    --upstream)
      UPSTREAM_AGENTS="${2:-}"
      shift 2
      ;;
    --task-class)
      TASK_CLASS="${2:-}"
      shift 2
      ;;
    --delivery-gate)
      DELIVERY_GATE_LINES+=("${2:-}")
      shift 2
      ;;
    --cue-mode)
      CUE_MODE="${2:-}"
      shift 2
      ;;
    --cue-match)
      CUE_MATCH_MODE="${2:-}"
      shift 2
      ;;
    --if-user-asks)
      CUE_ASKS+=("${2:-}")
      shift 2
      ;;
    --switch-to)
      CUE_SWITCHES+=("${2:-}")
      shift 2
      ;;
    --remove-if-user-asks)
      REMOVE_CUE_ASKS+=("${2:-}")
      shift 2
      ;;
    --reason)
      REASON="${2:-}"
      shift 2
      ;;
    --updated-by)
      UPDATED_BY="${2:-}"
      shift 2
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

if [[ -z "${PROJECT_DIR}" || -z "${REASON}" ]]; then
  echo "--project and --reason are required." >&2
  usage >&2
  exit 1
fi

PROFILE_FILE="${PROJECT_DIR}/.codex/project-profile.md"
if [[ ! -f "${PROFILE_FILE}" ]]; then
  echo "Project profile not found: ${PROFILE_FILE}" >&2
  exit 1
fi

if [[ -n "${PROFILE_LANG}" && "${PROFILE_LANG}" != "zh" && "${PROFILE_LANG}" != "en" ]]; then
  echo "Unsupported language: ${PROFILE_LANG}. Use zh or en." >&2
  exit 1
fi

if [[ "${CUE_MODE}" != "replace" && "${CUE_MODE}" != "append" ]]; then
  echo "Unsupported cue mode: ${CUE_MODE}. Use replace or append." >&2
  exit 1
fi

if [[ "${CUE_MATCH_MODE}" != "exact" && "${CUE_MATCH_MODE}" != "semantic" ]]; then
  echo "Unsupported cue match mode: ${CUE_MATCH_MODE}. Use exact or semantic." >&2
  exit 1
fi

if [[ ${#CUE_ASKS[@]} -ne ${#CUE_SWITCHES[@]} ]]; then
  echo "--if-user-asks and --switch-to must be provided in matching pairs." >&2
  exit 1
fi

if [[ -z "${PROFILE_LANG}" ]]; then
  if rg -q "尚未记录人工调整|由扫描自动生成|由新项目对话生成|示例模板初始化" "${PROFILE_FILE}"; then
    PROFILE_LANG="zh"
  else
    PROFILE_LANG="en"
  fi
fi

timestamp="$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S %z')"

CUE_ASKS_PAYLOAD=""
CUE_SWITCHES_PAYLOAD=""
REMOVE_CUE_ASKS_PAYLOAD=""
DELIVERY_GATE_PAYLOAD=""
if (( ${#CUE_ASKS[@]} > 0 )); then
  CUE_ASKS_PAYLOAD="$(printf '%s\n' "${CUE_ASKS[@]}")"
fi
if (( ${#CUE_SWITCHES[@]} > 0 )); then
  CUE_SWITCHES_PAYLOAD="$(printf '%s\n' "${CUE_SWITCHES[@]}")"
fi
if (( ${#REMOVE_CUE_ASKS[@]} > 0 )); then
  REMOVE_CUE_ASKS_PAYLOAD="$(printf '%s\n' "${REMOVE_CUE_ASKS[@]}")"
fi
if (( ${#DELIVERY_GATE_LINES[@]} > 0 )); then
  DELIVERY_GATE_PAYLOAD="$(printf '%s\n' "${DELIVERY_GATE_LINES[@]}")"
fi

PROFILE_FILE="${PROFILE_FILE}" \
PROFILE_LANG="${PROFILE_LANG}" \
PRESET="${PRESET}" \
PRIMARY="${PRIMARY}" \
SUPPORTING="${SUPPORTING}" \
UPSTREAM_AGENTS="${UPSTREAM_AGENTS}" \
TASK_CLASS="${TASK_CLASS}" \
CUE_MODE="${CUE_MODE}" \
REASON="${REASON}" \
UPDATED_BY="${UPDATED_BY}" \
TIMESTAMP="${timestamp}" \
CUE_ASKS_PAYLOAD="${CUE_ASKS_PAYLOAD}" \
CUE_SWITCHES_PAYLOAD="${CUE_SWITCHES_PAYLOAD}" \
REMOVE_CUE_ASKS_PAYLOAD="${REMOVE_CUE_ASKS_PAYLOAD}" \
DELIVERY_GATE_PAYLOAD="${DELIVERY_GATE_PAYLOAD}" \
CUE_MATCH_MODE="${CUE_MATCH_MODE}" \
python3 - <<'PY'
from pathlib import Path
import os
import re

path = Path(os.environ["PROFILE_FILE"])
text = path.read_text()
lang = os.environ["PROFILE_LANG"]
preset = os.environ["PRESET"].strip()
primary = os.environ["PRIMARY"].strip()
supporting = os.environ["SUPPORTING"].strip()
upstream_agents = os.environ["UPSTREAM_AGENTS"].strip()
task_class = os.environ["TASK_CLASS"].strip()
cue_mode = os.environ["CUE_MODE"].strip()
reason = os.environ["REASON"].strip()
updated_by = os.environ["UPDATED_BY"].strip()
timestamp = os.environ["TIMESTAMP"].strip()
cue_asks = [x.strip() for x in os.environ.get("CUE_ASKS_PAYLOAD", "").splitlines() if x.strip()]
cue_switches = [x.strip() for x in os.environ.get("CUE_SWITCHES_PAYLOAD", "").splitlines() if x.strip()]
remove_cue_asks = [x.strip() for x in os.environ.get("REMOVE_CUE_ASKS_PAYLOAD", "").splitlines() if x.strip()]
delivery_gate_lines = [x.strip() for x in os.environ.get("DELIVERY_GATE_PAYLOAD", "").splitlines() if x.strip()]
cue_match_mode = os.environ["CUE_MATCH_MODE"].strip()

def get_section(name: str):
    pattern = rf"(## {re.escape(name)}\n)(.*?)(?=\n## |\Z)"
    match = re.search(pattern, text, flags=re.S)
    if not match:
        raise SystemExit(f"Section not found: {name}")
    return match

def replace_section(name: str, body: str):
    global text
    match = get_section(name)
    replacement = match.group(1) + body.rstrip("\n") + "\n"
    text = text[:match.start()] + replacement + text[match.end():]

def split_lines(body: str):
    return [line for line in body.strip("\n").splitlines() if line.strip()]

def format_supporting(raw: str):
    items = [item.strip() for item in raw.replace("\n", ",").split(",") if item.strip()]
    joiner = "、" if lang == "zh" else ", "
    return joiner.join(f"`{item}`" for item in items)

def format_upstream(raw: str):
    normalized = raw.replace("\\n", "\n").replace(",", "\n")
    items = [item.strip() for item in normalized.splitlines() if item.strip()]
    return [f"- `{item}`" for item in items]

def parse_routing_pairs(lines):
    pairs = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("- If user asks for:"):
            ask = line.split(":", 1)[1].strip()
            switch = ""
            if i + 1 < len(lines) and lines[i + 1].startswith("- Switch to:"):
                switch = lines[i + 1].split(":", 1)[1].strip().strip("`")
                i += 1
            pairs.append((ask, switch))
        i += 1
    return pairs

def render_routing_pairs(pairs):
    lines = []
    for ask, switch in pairs:
        lines.append(f"- If user asks for: {ask}")
        lines.append(f"- Switch to: `{switch}`")
    return "\n".join(lines)

SEMANTIC_GROUPS = {
    "zh": {
        "frontend": {"页面", "前端", "组件", "样式", "ui", "交互", "布局"},
        "ux": {"体验", "流程", "信息架构", "导航", "可用性", "交互流程"},
        "verification": {"验证", "验收", "测试", "qa", "上线", "发布", "交付"},
        "accessibility": {"无障碍", "可访问性", "键盘导航", "读屏", "对比度", "a11y"},
        "backend": {"接口", "后端", "服务", "api", "数据流", "调用链"},
        "content": {"文案", "内容", "品牌", "叙事", "传播", "seo"},
    },
    "en": {
        "frontend": {"frontend", "page", "pages", "component", "components", "styling", "styles", "ui", "interaction", "layout"},
        "ux": {"ux", "flow", "flows", "information", "architecture", "navigation", "usability", "experience"},
        "verification": {"verification", "validate", "validation", "qa", "testing", "release", "readiness", "acceptance", "ship"},
        "accessibility": {"accessibility", "keyboard", "contrast", "screenreader", "screen-reader", "a11y"},
        "backend": {"backend", "api", "service", "services", "data", "pipeline", "callchain", "call-chain"},
        "content": {"copy", "content", "brand", "storytelling", "seo", "messaging"},
    },
}

ROLE_GROUPS = {
    "onboarding": {"codebase onboarding engineer", "technical writer"},
    "frontend": {"frontend developer", "ui designer"},
    "ux": {"ux architect", "ux researcher"},
    "verification": {"reality checker", "api tester", "test results analyzer", "evidence collector"},
    "accessibility": {"accessibility auditor"},
    "backend": {"backend architect", "software architect", "database optimizer", "sre"},
    "content": {"content creator", "brand guardian", "seo specialist", "visual storyteller"},
    "product": {"product manager", "project shepherd", "senior project manager", "rapid prototyper"},
}

def detect_text_lang(value: str):
    return "zh" if re.search(r"[\u4e00-\u9fff]", value) else "en"

def normalize_for_semantics(value: str):
    lowered = value.lower()
    lowered = lowered.replace("&", " ")
    lowered = re.sub(r"[^\w\u4e00-\u9fff]+", " ", lowered)
    tokens = [token for token in lowered.split() if token]
    joined = "".join(tokens) if detect_text_lang(value) == "zh" else None
    lang_groups = SEMANTIC_GROUPS[detect_text_lang(value)]
    semantic_tokens = set(tokens)
    source_text = value if joined is None else f"{value} {joined}"
    for group_name, keywords in lang_groups.items():
        for keyword in keywords:
            if detect_text_lang(value) == "zh":
                if keyword in source_text or keyword in joined:
                    semantic_tokens.add(f"group:{group_name}")
            else:
                if keyword in semantic_tokens:
                    semantic_tokens.add(f"group:{group_name}")
    return semantic_tokens

def semantic_match(a: str, b: str):
    a_tokens = normalize_for_semantics(a)
    b_tokens = normalize_for_semantics(b)
    if not a_tokens or not b_tokens:
        return False
    overlap = len(a_tokens & b_tokens)
    minimum = min(len(a_tokens), len(b_tokens))
    return overlap >= 2 or (minimum > 0 and overlap / minimum >= 0.6)

def canonical_role_group(value: str):
    lowered = value.lower().strip()
    for group_name, roles in ROLE_GROUPS.items():
        if lowered in roles:
            return group_name
    return ""

def infer_intent_groups(value: str):
    return sorted(token.split(":", 1)[1] for token in normalize_for_semantics(value) if token.startswith("group:"))

def intent_signature(ask: str, switch: str):
    groups = infer_intent_groups(ask)
    role_group = canonical_role_group(switch)
    primary_intent = groups[0] if groups else ""
    return {
        "groups": set(groups),
        "primary": primary_intent,
        "role_group": role_group,
    }

def intent_match(existing_ask: str, existing_switch: str, incoming_ask: str, incoming_switch: str):
    existing_sig = intent_signature(existing_ask, existing_switch)
    incoming_sig = intent_signature(incoming_ask, incoming_switch)
    shared_groups = existing_sig["groups"] & incoming_sig["groups"]
    same_role_group = (
        existing_sig["role_group"]
        and incoming_sig["role_group"]
        and existing_sig["role_group"] == incoming_sig["role_group"]
    )

    if existing_sig["primary"] and incoming_sig["primary"] and existing_sig["primary"] == incoming_sig["primary"]:
        if same_role_group or (not existing_sig["role_group"] and not incoming_sig["role_group"]):
            return True

    if same_role_group and shared_groups:
        return True

    if same_role_group and semantic_match(existing_ask, incoming_ask):
        return True

    if existing_sig["primary"] and incoming_sig["primary"] and existing_sig["primary"] == incoming_sig["primary"]:
        if shared_groups and semantic_match(existing_ask, incoming_ask):
            return True

    return False

def find_pair_index(pairs, ask: str, switch: str):
    for index, (existing_ask, _) in enumerate(pairs):
        if existing_ask == ask:
            return index
    if cue_match_mode == "semantic":
        for index, (existing_ask, existing_switch) in enumerate(pairs):
            if intent_match(existing_ask, existing_switch, ask, switch):
                return index
    return None

default_match = get_section("Default Squad")
default_lines = split_lines(default_match.group(2))
new_default = []
upstream_started = False
for line in default_lines:
    if line.startswith("- Preset:"):
        new_default.append(f"- Preset: `{preset}`" if preset else line)
    elif line.startswith("- Primary:"):
        new_default.append(f"- Primary: `{primary}`" if primary else line)
    elif line.startswith("- Supporting:"):
        new_default.append(f"- Supporting: {format_supporting(supporting)}" if supporting else line)
    elif line.startswith("- Upstream agents:"):
        upstream_started = True
        new_default.append(line)
        if upstream_agents:
            new_default.extend(format_upstream(upstream_agents))
    elif upstream_started and line.startswith("- `"):
        if not upstream_agents:
            new_default.append(line)
    else:
        new_default.append(line)
replace_section("Default Squad", "\n".join(new_default))

if task_class:
    replace_section("Task Class", f"- {task_class}")

routing_match = get_section("Routing Cues")
existing_pairs = parse_routing_pairs(split_lines(routing_match.group(2)))

if remove_cue_asks:
    kept_pairs = []
    for ask, switch in existing_pairs:
        should_remove = False
        for remove_ask in remove_cue_asks:
            if ask == remove_ask or (cue_match_mode == "semantic" and intent_match(ask, switch, remove_ask, switch)):
                should_remove = True
                break
        if not should_remove:
            kept_pairs.append((ask, switch))
    existing_pairs = kept_pairs

if cue_asks and cue_switches:
    incoming_pairs = list(zip(cue_asks, cue_switches))
    if cue_mode == "replace":
        updated_pairs = incoming_pairs
    else:
        updated_pairs = list(existing_pairs)
        for ask, switch in incoming_pairs:
            match_index = find_pair_index(updated_pairs, ask, switch)
            if match_index is None:
                updated_pairs.append((ask, switch))
            else:
                updated_pairs[match_index] = (ask, switch)
    replace_section("Routing Cues", render_routing_pairs(updated_pairs))
elif remove_cue_asks:
    replace_section("Routing Cues", render_routing_pairs(existing_pairs))

if delivery_gate_lines:
    replace_section("Delivery Gate", "\n".join(f"- {line}" for line in delivery_gate_lines))

history_match = get_section("Squad History")
history_lines = split_lines(history_match.group(2))
latest_prefix = "- Latest change reason:"
new_history = []
latest_found = False
for line in history_lines:
    if line.startswith(latest_prefix):
      new_history.append(f"{latest_prefix} {reason}")
      latest_found = True
    else:
      new_history.append(line)
if not latest_found:
    new_history.append(f"{latest_prefix} {reason}")
new_history.append(f"- {timestamp} | {updated_by} | {reason}")
replace_section("Squad History", "\n".join(new_history))

path.write_text(text)
PY

echo "Updated project profile at ${PROFILE_FILE}"
