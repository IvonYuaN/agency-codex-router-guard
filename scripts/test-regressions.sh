#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_SCRIPT="${SOURCE_DIR}/scripts/init-project.sh"
UPDATE_SCRIPT="${SOURCE_DIR}/scripts/update-profile.sh"

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
run_dialog_game_case
run_preset_reroute_case

echo "Regression tests passed."
