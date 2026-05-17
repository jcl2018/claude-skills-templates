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
# Auth (F3 / D000023, Approach C):
#   - Scheduled-main CI (GITHUB_REF == refs/heads/main): env auth preserved
#     (ANTHROPIC_API_KEY surfaced from the protected `eval-secrets` Environment
#     in eval-nightly.yml). Cases here are all merged/reviewed; F1's
#     Environment+main-gating is the structural control.
#   - Everything else (non-main CI + local dev): the inherited env is replaced
#     with an explicit allowlist via `env -i` and a fail-closed post-assert
#     aborts the case if any ^ANTHROPIC / *_API_KEY/_TOKEN/_SECRET var survives.
#     Local dev keeps OAuth/keychain auth (~/.claude/.credentials.json), which
#     is NOT an env var, so the scrub does not break local runs.
#   See the scrub block below and tests/eval/lib/plant-test.sh.

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

# ---------------------------------------------------------------------------
# F3 (D000023, Approach C) — env scrub + fail-closed post-assert.
#
# Threat: the model's Bash tool runs with --permission-mode bypassPermissions
# and the prompt/fixture come from tests/eval/<skill>/<case>/, which becomes
# attacker-influenced the moment a malicious case is committed. The OLD code
# kept ANTHROPIC_API_KEY in env (a fail-OPEN selective denylist that also
# missed every unenumerated secret-shaped var). This is replaced with an
# `env -i` / explicit-allowlist scrub plus a fail-closed post-assert.
#
# Trust gate: the SCHEDULED-MAIN run (GITHUB_REF == refs/heads/main) keeps env
# auth — its cases are all merged/reviewed and F1's Environment+main-gating is
# the structural teeth there. EVERY OTHER context (non-main CI, AND local dev)
# takes the scrub + fail-closed assert path. Local dev authenticates via
# OAuth/keychain (~/.claude/.credentials.json), NOT the ANTHROPIC_API_KEY env
# var, so stripping it locally does not break local runs — and the assert
# additionally catches a local misconfig where a key var leaked into env.
#
# Residual risk (Non-goals, Premise 3): this closes the ENV surface only. A
# same-UID model Bash can still reach a credential via files / /proc / open
# FDs / a loopback helper. Full structural closure is Approach B (tracked V2).
# The assert is honest defense-in-depth, not a structural-impossibility claim.
# ---------------------------------------------------------------------------

# Explicit allowlist: the minimum env the claude CLI + its tooling need to run
# a case. Anything NOT on this list is dropped (allowlist, not denylist — a
# denylist fails open on the next unlisted var, which is exactly the bug).
EVAL_ENV_ALLOWLIST="HOME PATH USER LOGNAME SHELL LANG LC_ALL LC_CTYPE TZ TMPDIR \
TERM XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME NODE_PATH NPM_CONFIG_PREFIX \
GITHUB_REF GITHUB_SHA GITHUB_RUN_ID GITHUB_WORKFLOW CI"

if [ "${GITHUB_REF:-}" = "refs/heads/main" ]; then
  # Trusted scheduled-main path: cases are all merged/reviewed. Keep env auth
  # (ANTHROPIC_API_KEY stays available) — F1's Environment + main-gating is the
  # structural control here, per the design. No scrub, no assert on this path.
  scrub_mode="trusted-main (env auth preserved)"
  run_claude() {
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
  }
else
  # Untrusted path (non-main CI OR local dev): build the to-be-exported env
  # from the explicit allowlist only.
  scrub_mode="untrusted (env -i / allowlist scrub + fail-closed assert)"
  scrubbed_assignments=""
  for _k in $EVAL_ENV_ALLOWLIST; do
    if [ -n "${!_k+x}" ]; then
      scrubbed_assignments="$scrubbed_assignments ${_k}=${!_k}"
    fi
  done

  # Fail-closed post-assert (the F3 tripwire — ENG-4, SC3).
  #
  # Semantics: on the untrusted path, abort the case NON-ZERO if the INHERITED
  # environment contains ANY variable matching ^ANTHROPIC or
  # *_API_KEY/_TOKEN/_SECRET. We assert on the inherited env (pre-`env -i`),
  # NOT the post-scrub env, deliberately:
  #   - The mere PRESENCE of a live credential in this process's environment is
  #     the danger signal. Before `env -i` runs, that value was already
  #     reachable to anything the same UID could do (/proc/self/environ, child
  #     setup argv, an FD, a loopback helper). "Scrub it and proceed quietly"
  #     is fail-OPEN reasoning — the design explicitly rejects it (Premise 3 /
  #     ENG-4: a denylist/relocation is not a trust boundary).
  #   - It is the only semantics under which the mandated plant-test is
  #     meaningful: ENG-4 requires "planting ANTHROPIC_FOO=bar asserts the case
  #     aborts". An allowlist `env -i` makes the *scrubbed* env definitionally
  #     clean, so asserting on the scrubbed env can never see the planted var
  #     and the assertion would be vacuous (silently fail-open + untestable).
  # Allowlisted, provably-non-secret vars are excluded from the match so a
  # legitimate run is not falsely aborted (none of the allowlist names match
  # the secret-shaped regex today; the exclusion is belt-and-braces for future
  # allowlist additions).
  inherited_secrets=$(env \
    | grep -E '^(ANTHROPIC[^=]*|[^=]*_(API_KEY|TOKEN|SECRET))=' \
    | cut -d= -f1 \
    | { grep -vxF -f <(printf '%s\n' $EVAL_ENV_ALLOWLIST) || true; } )
  if [ -n "$inherited_secrets" ]; then
    echo "FAIL: $skill/$case_name (fail-closed scrub assert: secret-shaped var(s) present in the inherited env on the untrusted path)"
    echo "  offending variable name(s):" >&2
    echo "$inherited_secrets" | sed 's/^/    - /' >&2
    echo "  This is the F3 fail-closed tripwire (D000023). The eval case runner refuses" >&2
    echo "  to spawn a bypassPermissions model in a context where a live credential is" >&2
    echo "  reachable from the environment. On non-main CI / local dev the case must run" >&2
    echo "  secretless; the scheduled-main path (GITHUB_REF=refs/heads/main) is the only" >&2
    echo "  context that legitimately keeps env auth. If this fired locally, a key var" >&2
    echo "  leaked into your shell env — unset it (local auth is OAuth/keychain, not env)." >&2
    exit 1
  fi

  # Spawn claude with EXACTLY the scrubbed allowlist env (env -i discards the
  # inherited environment as defense-in-depth; the assert above already proved
  # no secret-shaped var was present to begin with on this path).
  run_claude() {
    # shellcheck disable=SC2086  # intentional word-splitting of allowlist assignments
    env -i $scrubbed_assignments \
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
  }
fi

echo "run-case: env scrub mode = $scrub_mode" >&2

output=$(run_claude) && claude_rc=0 || claude_rc=$?

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
