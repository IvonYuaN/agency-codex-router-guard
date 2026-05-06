#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=""
PROFILE_LANG=""
PRESET=""
PRIMARY=""
SUPPORTING=""
UPSTREAM_AGENTS=""
REASON=""
UPDATED_BY="router-guard"
declare -a CUE_ASKS=()
declare -a CUE_SWITCHES=()

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
  --if-user-asks VALUE    Add or replace a routing cue ask phrase; can be repeated
  --switch-to VALUE       Matching switch target for the previous --if-user-asks; can be repeated
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
    --if-user-asks)
      CUE_ASKS+=("${2:-}")
      shift 2
      ;;
    --switch-to)
      CUE_SWITCHES+=("${2:-}")
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
if (( ${#CUE_ASKS[@]} > 0 )); then
  CUE_ASKS_PAYLOAD="$(printf '%s\n' "${CUE_ASKS[@]}")"
fi
if (( ${#CUE_SWITCHES[@]} > 0 )); then
  CUE_SWITCHES_PAYLOAD="$(printf '%s\n' "${CUE_SWITCHES[@]}")"
fi

PROFILE_FILE="${PROFILE_FILE}" \
PROFILE_LANG="${PROFILE_LANG}" \
PRESET="${PRESET}" \
PRIMARY="${PRIMARY}" \
SUPPORTING="${SUPPORTING}" \
UPSTREAM_AGENTS="${UPSTREAM_AGENTS}" \
REASON="${REASON}" \
UPDATED_BY="${UPDATED_BY}" \
TIMESTAMP="${timestamp}" \
CUE_ASKS_PAYLOAD="${CUE_ASKS_PAYLOAD}" \
CUE_SWITCHES_PAYLOAD="${CUE_SWITCHES_PAYLOAD}" \
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
reason = os.environ["REASON"].strip()
updated_by = os.environ["UPDATED_BY"].strip()
timestamp = os.environ["TIMESTAMP"].strip()
cue_asks = [x.strip() for x in os.environ.get("CUE_ASKS_PAYLOAD", "").splitlines() if x.strip()]
cue_switches = [x.strip() for x in os.environ.get("CUE_SWITCHES_PAYLOAD", "").splitlines() if x.strip()]

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

if cue_asks and cue_switches:
    routing_lines = []
    for ask, switch in zip(cue_asks, cue_switches):
        routing_lines.append(f"- If user asks for: {ask}")
        routing_lines.append(f"- Switch to: `{switch}`")
    replace_section("Routing Cues", "\n".join(routing_lines))

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
