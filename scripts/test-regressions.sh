#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_SCRIPT="${SOURCE_DIR}/scripts/init-project.sh"
UPDATE_SCRIPT="${SOURCE_DIR}/scripts/update-profile.sh"
VALIDATE_PRESETS_SCRIPT="${SOURCE_DIR}/scripts/validate-preset-defaults.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! rg -F -q -- "$expected" "$file"; then
    echo "Expected to find: $expected" >&2
    echo "In file: $file" >&2
    fail "assert_contains failed"
  fi
}

run_scan_ai_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-ai-XXXXXX)"
  mkdir -p "$tmpdir/project/agents" "$tmpdir/project/skills"
  cat > "$tmpdir/project/package.json" <<'EOF'
{"name":"agent-lab","dependencies":{"openai":"latest","@modelcontextprotocol/sdk":"latest"}}
EOF
  cat > "$tmpdir/project/README.md" <<'EOF'
# Agent Workflow
EOF

  "$INIT_SCRIPT" --project "$tmpdir/project" --mode scan --lang zh --force >/dev/null
  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `ai-agent-stack`'
  assert_contains "$profile" '- Primary: `AI Engineer`'
  assert_contains "$profile" 'upstream-agents/specialized/specialized-mcp-builder.md'
}

run_scan_frontend_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-frontend-XXXXXX)"
  mkdir -p "$tmpdir/project/app" "$tmpdir/project/components"
  cat > "$tmpdir/project/package.json" <<'EOF'
{"name":"frontend-app","dependencies":{"next":"latest","react":"latest"}}
EOF
  cat > "$tmpdir/project/app/page.tsx" <<'EOF'
export default function Page() { return <main>Hello</main>; }
EOF

  "$INIT_SCRIPT" --project "$tmpdir/project" --mode scan --lang zh --force >/dev/null
  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `frontend-product`'
  assert_contains "$profile" '- Primary: `Frontend Developer`'
  assert_contains "$profile" '- Supporting: `UI Designer`、`UX Architect`、`Reality Checker`'
  assert_contains "$profile" '- 关键用户路径已有最小可验证闭环'
}

run_scan_python_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-python-XXXXXX)"
  mkdir -p "$tmpdir/project"
  cat > "$tmpdir/project/pyproject.toml" <<'EOF'
[project]
name = "python-service"
version = "0.1.0"
EOF
  cat > "$tmpdir/project/main.py" <<'EOF'
print("hello")
EOF

  "$INIT_SCRIPT" --project "$tmpdir/project" --mode scan --lang zh --force >/dev/null
  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `backend-service`'
  assert_contains "$profile" '- Primary: `Backend Architect`'
  assert_contains "$profile" '- Supporting: `API Tester`、`Software Architect`、`Technical Writer`'
  assert_contains "$profile" '- 关键接口或流程已有验证证据'
}

run_dialog_game_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-game-XXXXXX)"
  mkdir -p "$tmpdir/project"

  "$INIT_SCRIPT" \
    --project "$tmpdir/project" \
    --mode dialog \
    --lang en \
    --goal "game" \
    --stack "unity" \
    --artifact "playable prototype" \
    --success "more fun" \
    --first-move "build systems" \
    --force >/dev/null

  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `game-production`'
  assert_contains "$profile" '- Primary: `Unity Architect`'
  assert_contains "$profile" '- If user asks for: visual implementation, technical art, performance, and asset pipeline'
}

run_dialog_ppt_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-ppt-XXXXXX)"
  mkdir -p "$tmpdir/project"

  "$INIT_SCRIPT" \
    --project "$tmpdir/project" \
    --mode dialog \
    --lang zh \
    --goal "ppt" \
    --artifact "页面或演示稿" \
    --success "更好看" \
    --first-move "clarify-story" \
    --force >/dev/null

  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `ppt-storytelling`'
  assert_contains "$profile" '- Supporting: `UI Designer`、`Frontend Developer`、`Reality Checker`'
  assert_contains "$profile" '- If user asks for: 页面实现、样式、交互落地'
}

run_ppt_reroute_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-ppt-reroute-XXXXXX)"
  mkdir -p "$tmpdir/project"

  "$INIT_SCRIPT" \
    --project "$tmpdir/project" \
    --mode dialog \
    --lang zh \
    --goal "ppt" \
    --artifact "页面或演示稿" \
    --success "更好看" \
    --first-move "clarify-story" \
    --force >/dev/null

  "$UPDATE_SCRIPT" \
    --project "$tmpdir/project" \
    --preset "ppt-storytelling" \
    --reason "项目已进入 deck 交付与统筹阶段" >/dev/null

  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `ppt-storytelling`'
  assert_contains "$profile" '- Supporting: `Brand Guardian`、`UI Designer`、`Project Shepherd`'
  assert_contains "$profile" '- Latest change reason: 项目已进入 deck 交付与统筹阶段'
}

validate_shared_preset_json() {
  "$VALIDATE_PRESETS_SCRIPT"
}

run_preset_reroute_case() {
  local tmpdir profile
  tmpdir="$(mktemp -d /tmp/router-guard-test-reroute-XXXXXX)"
  mkdir -p "$tmpdir/project/agents" "$tmpdir/project/skills"
  cat > "$tmpdir/project/package.json" <<'EOF'
{"name":"agent-lab","dependencies":{"openai":"latest"}}
EOF
  cat > "$tmpdir/project/README.md" <<'EOF'
# Agent Workflow
EOF

  "$INIT_SCRIPT" --project "$tmpdir/project" --mode scan --lang zh --force >/dev/null
  "$UPDATE_SCRIPT" \
    --project "$tmpdir/project" \
    --preset "china-market-growth" \
    --reason "项目重心切换到中文渠道增长" >/dev/null

  profile="$tmpdir/project/.codex/project-profile.md"

  assert_contains "$profile" '- Preset: `china-market-growth`'
  assert_contains "$profile" '- Primary: `China Market Localization Strategist`'
  assert_contains "$profile" '- If user asks for: 本地化定位、渠道策略、内容矩阵'
  assert_contains "$profile" '- 核心渠道分工和主张已清楚'
  assert_contains "$profile" '- Latest change reason: 项目重心切换到中文渠道增长'
}

bash -n "$INIT_SCRIPT"
bash -n "$UPDATE_SCRIPT"

run_scan_ai_case
run_scan_frontend_case
run_scan_python_case
run_dialog_game_case
run_dialog_ppt_case
run_preset_reroute_case
run_ppt_reroute_case
validate_shared_preset_json

echo "Regression tests passed."
