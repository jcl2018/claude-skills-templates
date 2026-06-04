#!/usr/bin/env bash
# run-portability-case.sh — the ONE Layer-2 portability case (F000047 / S000083).
#
# Drives a single leaf skill (default CJ_suggest) via `claude --print` against a
# STRIPPED, .source-neutralized scratch repo and asserts it degrades gracefully
# rather than crashing when the workbench is absent. This is the v1 proof-of-life
# that the `scripts/eval.sh --portability` mode + the fixture-prep helper EXIST.
#
# Three load-bearing corrections over the default eval path (from the F000047
# design's "Layer 2" section):
#   1. .source neutralization — the scratch ~/.claude manifest's `.source` points
#      at the STRIPPED repo (not the real workbench), so any engine `.source`
#      fall-through resolves into the stripped repo. Without this the test is a
#      no-op (the engine reaches the real scripts/).
#   2. Per-skill --allowedTools — read from the skill's `allowed-tools`
#      frontmatter and passed through (the default run-case.sh hardcodes
#      "Bash,Read,Glob,Grep"; CJ_suggest's set is Bash,Read — a subset — but the
#      mechanism generalizes to skills that need Edit/Write/AskUserQuestion).
#   3. HOME/auth carve-out — HOME is NOT scrubbed (macOS OAuth lives there); only
#      the skill-resolution surface is redirected. We point the resolver at the
#      scratch dir via CLAUDE_CONFIG_DIR + --add-dir, leaving auth intact so the
#      subsequent `claude -p` authenticates.
#
# Usage: run-portability-case.sh <repo_root> [<skill_name>]
# Exit 0 = the case ran green (skill degraded gracefully). Exit 1 = failure.

set -euo pipefail

repo_root="${1:?repo_root required}"
skill="${2:-CJ_suggest}"

lib_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fixture_helper="$lib_dir/portability-fixture.sh"
[ -x "$fixture_helper" ] || chmod +x "$fixture_helper" 2>/dev/null || true

skill_md="$repo_root/skills/$skill/SKILL.md"
[ -f "$skill_md" ] || { echo "FAIL: portability/$skill (no SKILL.md at $skill_md)"; exit 1; }

# ---- per-skill --allowedTools from frontmatter -------------------------------
# Parse the `allowed-tools:` YAML list between the first --- pair. Falls back to
# "Bash,Read" (CJ_suggest's set) if none declared.
allowed_tools=$(
  awk '
    /^---$/ { f++; next }
    f == 1 && /^allowed-tools:/ { inlist=1; next }
    f == 1 && inlist && /^[[:space:]]*-[[:space:]]/ {
      line=$0; sub(/^[[:space:]]*-[[:space:]]*/, "", line); sub(/[[:space:]]*$/, "", line)
      tools = tools (tools=="" ? "" : ",") line; next
    }
    f == 1 && inlist && /^[^[:space:]-]/ { inlist=0 }
    END { print tools }
  ' "$skill_md"
)
allowed_tools="${allowed_tools:-Bash,Read}"

echo "Portability case: $skill" >&2
echo "  allowed-tools: $allowed_tools" >&2

command -v claude >/dev/null 2>&1 || {
  echo "FAIL: portability/$skill (claude CLI not found in PATH)"
  echo "       Install: see https://docs.anthropic.com/claude-code." >&2
  exit 1
}

# ---- build the stripped repo + .source-neutralized resolution dir ------------
scratch_repo=$(mktemp -d -t cj-pa-repo-XXXXXX)
scratch_claude=$(mktemp -d -t cj-pa-claude-XXXXXX)
trap 'rm -rf "$scratch_repo" "$scratch_claude"' EXIT INT TERM

CJ_PA_SKILLS="$skill" bash "$fixture_helper" "$repo_root" "$scratch_repo" "$scratch_claude" >&2 || {
  echo "FAIL: portability/$skill (fixture prep failed)"
  exit 1
}

# ---- drive the skill against the stripped repo -------------------------------
# The prompt asks the model to invoke the skill in the stripped repo and report
# whether it degraded GRACEFULLY (a clean message / empty result) versus CRASHED
# (a shell error, an unbound variable, a stack trace). We enforce a strict JSON
# schema so the model's verdict is machine-checkable.
prompt="You are in a STRIPPED scratch repo at $scratch_repo that deliberately has NONE of the workbench's files (no scripts/, no CLAUDE.md, no root config, no TODOS.md, no work-items/). Invoke the /$skill skill here exactly as a user would. The skill SHOULD degrade gracefully — print a clean message (e.g. about a missing TODOS.md or no actionable items) and exit without a crash. It must NOT emit a shell crash, an unbound-variable error, a stack trace, or a non-handled failure. Report your verdict as JSON: {\"degraded_gracefully\": true|false, \"evidence\": \"<one-line quote of the skill's actual output>\"}. degraded_gracefully is true ONLY if the skill produced a clean, handled message (or empty output) with no crash."

schema='{"type":"object","properties":{"degraded_gracefully":{"type":"boolean"},"evidence":{"type":"string"}},"required":["degraded_gracefully","evidence"],"additionalProperties":false}'

# Redirect ONLY the skill-resolution surface. CLAUDE_CONFIG_DIR points the
# resolver at the scratch dir (so its manifest .source — the stripped repo — is
# what any engine falls through to). HOME stays intact for auth.
output=$(
  CLAUDE_CONFIG_DIR="$scratch_claude" \
  claude -p "$prompt" \
    --print \
    --output-format json \
    --json-schema "$schema" \
    --plugin-dir "$repo_root/skills" \
    --add-dir "$scratch_repo" \
    --add-dir "$scratch_claude" \
    --model sonnet \
    --max-budget-usd 0.50 \
    --no-session-persistence \
    --permission-mode bypassPermissions \
    --allowedTools "$allowed_tools" 2>&1
) && claude_rc=0 || claude_rc=$?

verdict=$(echo "$output" | jq -r '.result | fromjson | .degraded_gracefully' 2>/dev/null || echo "parse-error")
evidence=$(echo "$output" | jq -r '.result | fromjson | .evidence' 2>/dev/null || echo "")
cost=$(echo "$output" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo 0)

if [ "$claude_rc" -ne 0 ]; then
  echo "FAIL: portability/$skill (claude exit $claude_rc, subtype: $(echo "$output" | jq -r '.subtype // "unknown"' 2>/dev/null))"
  echo "  cost_usd: $cost" >&2
  echo "  output: $output" >&2
  exit 1
fi

if [ "$verdict" = "true" ]; then
  echo "PASS: portability/$skill (\$$cost) — degraded gracefully: $evidence"
  exit 0
else
  echo "FAIL: portability/$skill (\$$cost) — did NOT degrade gracefully (verdict=$verdict): $evidence"
  echo "  output: $output" >&2
  exit 1
fi
