#!/usr/bin/env bash
# Per-case eval runner. Invoked by scripts/eval.sh under xargs -P 4.
#
# Args (4 positional, set by xargs -L 1 substitution):
#   1. <workbench_skills>      — abs path to <repo>/skills/
#   2. <workbench_templates>   — abs path to <repo>/templates/  (reserved for V2; unused in V1)
#   3. <skill>                 — skill name (e.g., "personal-workflow")
#   4. <case_dir>              — abs path to the case directory
#
# Behavior:
#   1. Seed fixture into a fresh tmpdir (via seed-fixture.sh).
#   2. Spawn `claude -p ...` headless against the tmpdir, with --output-format
#      json + --json-schema for structured output enforcement, --plugin-dir
#      pointing at the in-repo workbench skills.
#   3. Parse the model's response from .result via jq -r '.result | fromjson'.
#   4. Print PASS:/FAIL: line on stdout; non-zero exit on failure.
#
# Per-case cost cap: --max-budget-usd 0.50 (Spike 0 baseline: ~$0.15 for the
# happy path on check-flags-missing-lifecycle; schema-mismatch retry storms
# can push to ~$0.26; 0.50 leaves headroom).
#
# Auth: drops --bare so OAuth/keychain works for local dev. CI relies on
# ANTHROPIC_API_KEY being set as a repo secret — claude CLI reads it
# automatically when keychain auth isn't available.

set -euo pipefail

skills_root="${1:?workbench skills root required}"
# templates_root="${2:-}"  # reserved for V2 (cross-skill cases that need template resolution)
skill="${3:?skill name required}"
case_dir="${4:?case directory required}"
case_name=$(basename "$case_dir")

prompt_file="$case_dir/prompt.md"
fixture_dir="$case_dir/fixture"
schema_file="$case_dir/expected.schema.json"

for required in "$prompt_file" "$schema_file"; do
  [ -f "$required" ] || {
    echo "FAIL: $skill/$case_name (missing required input: $required)"
    exit 1
  }
done

# Resolve the seed-fixture helper relative to this script.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
seed_helper="$script_dir/seed-fixture.sh"
[ -x "$seed_helper" ] || chmod +x "$seed_helper" 2>/dev/null || true

tmpdir=$(mktemp -d)
# Trap on INT/TERM in addition to EXIT so Ctrl-C / SIGTERM during a long
# claude invocation still cleans up the tmpdir. SIGKILL is unrecoverable;
# nightly CI's timeout-then-kill path leaks tmpdirs (V2 needs a /tmp reaper).
trap 'rm -rf "$tmpdir"' EXIT INT TERM

# Step 1: seed fixture (cp -R + git init the tmpdir).
"$seed_helper" "$fixture_dir" "$tmpdir" || {
  echo "FAIL: $skill/$case_name (fixture seed failed)"
  exit 1
}

# Step 2: spawn claude headless. The schema is inlined via $(cat ...) because
# `claude --help` documents --json-schema as inline JSON only (no @file shorthand).
# Spike 0 confirmed: the CLI enforces schema natively and retries until match
# (cap at error_max_structured_output_retries → non-zero exit), so we don't
# need a separate ajv-cli post-validation step.
schema_json=$(cat "$schema_file")
prompt=$(cat "$prompt_file")

# Reject schemas that reference external URLs. A schema with `"$ref": "https://..."`
# could exfiltrate via DNS or pull in attacker-controlled validation rules.
# Internal $refs (`#/...`) are fine and remain allowed.
# shellcheck disable=SC2016  # single-quoted regex is intentional (literal $ref)
if grep -qE '"\$ref"[[:space:]]*:[[:space:]]*"[^#"]' "$schema_file"; then
  echo "FAIL: $skill/$case_name (schema references external \$ref; only internal #/... refs allowed)"
  echo "  schema_file: $schema_file" >&2
  exit 1
fi

# Selective env scrub: unset known CI/dev secrets so the claude subprocess
# (and the Bash tool inside the eval sandbox) can't read them via env. We
# can't `env -i` because OAuth/keychain auth depends on env state we don't
# fully understand on macOS — full scrub breaks login. This list covers the
# common exfiltration targets; V2 should move to a sandboxed execution
# context (Docker / firejail) and a stricter scrub.
unset GITHUB_TOKEN GH_TOKEN NPM_TOKEN
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
unset GOOGLE_APPLICATION_CREDENTIALS GCLOUD_PROJECT
unset DOCKER_PASSWORD DOCKER_USERNAME
unset GITLAB_TOKEN GITLAB_PRIVATE_TOKEN
unset OPENAI_API_KEY HUGGINGFACE_API_TOKEN
unset SLACK_TOKEN DISCORD_TOKEN

output=$(
  claude -p "$prompt" \
    --print \
    --output-format json \
    --json-schema "$schema_json" \
    --plugin-dir "$skills_root" \
    --add-dir "$tmpdir" \
    --model sonnet \
    --max-budget-usd 0.50 \
    --no-session-persistence \
    --permission-mode bypassPermissions \
    --allowedTools "Bash,Read,Glob,Grep" 2>&1
) && claude_rc=0 || claude_rc=$?

# Step 3: parse the model's JSON from the CLI's wrapper response.
# `--output-format json` returns { "result": "<model text>", ... }. When the
# model emits JSON (per our prompt contract + --json-schema enforcement),
# .result is a JSON-encoded string, so `fromjson` parses it into the actual
# object. If the model failed to produce valid JSON (CLI exit-fail above
# already caught this), .result is null and fromjson errors.
output_json="$tmpdir/output.json"
if ! echo "$output" | jq -r '.result | fromjson' >"$output_json" 2>/dev/null; then
  echo "FAIL: $skill/$case_name (no parseable JSON object in .result)"
  echo "  subtype: $(echo "$output" | jq -r '.subtype // "unknown"')" >&2
  echo "  is_error: $(echo "$output" | jq -r '.is_error // "unknown"')" >&2
  echo "  cost_usd: $(echo "$output" | jq -r '.total_cost_usd // 0')" >&2
  exit 1
fi

# Step 4: claude exit takes priority. Non-zero exit means cost cap, auth, or
# error_max_structured_output_retries (schema enforcement gave up).
if [ "$claude_rc" -ne 0 ]; then
  echo "FAIL: $skill/$case_name (claude exit $claude_rc, subtype: $(echo "$output" | jq -r '.subtype // "unknown"'))"
  echo "  cost_usd: $(echo "$output" | jq -r '.total_cost_usd // 0')" >&2
  echo "  output: $(cat "$output_json")" >&2
  exit 1
fi

cost=$(echo "$output" | jq -r '.total_cost_usd // 0')
duration_s=$(echo "$output" | jq -r '(.duration_ms // 0) / 1000 | floor')
echo "PASS: $skill/$case_name (\$$cost, ${duration_s}s)"
exit 0
