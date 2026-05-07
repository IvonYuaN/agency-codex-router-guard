#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PRESET_DEFAULTS_FILE="${SOURCE_DIR}/references/preset-defaults.json" \
python3 - <<'PY'
from pathlib import Path
import json
import os
import sys

path = Path(os.environ["PRESET_DEFAULTS_FILE"])
data = json.loads(path.read_text())
required_groups = {"reroute", "dialog"}
required_presets = {
    "frontend-product",
    "backend-service",
    "marketing-site",
    "ppt-storytelling",
    "zero-to-one-startup",
    "ai-agent-stack",
    "game-production",
    "china-market-growth",
    "spatial-computing",
}
allowed_group_differences = {
    "ppt-storytelling",
}

for group in required_groups:
    if group not in data:
        raise SystemExit(f"missing group: {group}")
    missing = required_presets - set(data[group])
    if missing:
        raise SystemExit(f"missing presets in {group}: {sorted(missing)}")
    for preset_name, preset in data[group].items():
        if len(preset.get("supporting", [])) != 3:
            raise SystemExit(f"{group}/{preset_name}: supporting must have 3 items")
        if len(preset.get("upstream", [])) != 4:
            raise SystemExit(f"{group}/{preset_name}: upstream must have 4 items")
        for lang in ("zh", "en"):
            routing = preset.get("routing", {}).get(lang, [])
            delivery = preset.get("delivery_gate", {}).get(lang, [])
            task_class = preset.get("task_class", {}).get(lang)
            if len(routing) != 3:
                raise SystemExit(f"{group}/{preset_name}/{lang}: routing must have 3 branches")
            if len(delivery) != 3:
                raise SystemExit(f"{group}/{preset_name}/{lang}: delivery gate must have 3 items")
            if not task_class:
                raise SystemExit(f"{group}/{preset_name}/{lang}: task_class missing")

for preset_name in required_presets:
    reroute_preset = data["reroute"][preset_name]
    dialog_preset = data["dialog"][preset_name]
    if preset_name in allowed_group_differences:
        continue
    if reroute_preset != dialog_preset:
        raise SystemExit(f"{preset_name}: reroute/dialog should match unless explicitly allowed to differ")

reroute_ppt = data["reroute"]["ppt-storytelling"]["supporting"]
dialog_ppt = data["dialog"]["ppt-storytelling"]["supporting"]
if reroute_ppt == dialog_ppt:
    raise SystemExit("ppt-storytelling should preserve different reroute/dialog supporting squads")

sys.stdout.write("preset json validated\n")
PY
