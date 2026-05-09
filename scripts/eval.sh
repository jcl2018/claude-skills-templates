#!/usr/bin/env bash
# Behavioral eval harness — top-level runner.
#
# Spawns the real `claude` CLI headless against scratch worktrees per case,
# validates structured JSON output against per-case schemas. Cadence: nightly
# on main + manual local invocation. V1 covers personal-workflow + system-health.
#
# Usage:
#   bash scripts/eval.sh                              # all skills, all cases
#   bash scripts/eval.sh personal-workflow            # all cases for one skill
#   bash scripts/eval.sh personal-workflow case-name  # single case
#
# Exit 0 = all cases pass. Exit 1 = at least one case failed.
#
# See tests/eval/README.md for case authoring + Spike 0 findings.

set -euo pipefail

. "$(dirname "$0")/lib.sh"

EVAL_ROOT="$REPO_ROOT/tests/eval"
WORKBENCH_SKILLS="$REPO_ROOT/skills"
WORKBENCH_TEMPLATES="$REPO_ROOT/templates"

skill_filter="${1:-}"
case_filter="${2:-}"

[ -d "$EVAL_ROOT" ] || {
  echo "ERROR: $EVAL_ROOT does not exist." >&2
  echo "       The eval harness has no cases yet — author at least one under tests/eval/<skill>/<case>/." >&2
  exit 1
}

command -v claude >/dev/null 2>&1 || {
  echo "ERROR: claude CLI not found in PATH." >&2
  echo "       Install: see https://docs.anthropic.com/claude-code (or your contributor onboarding doc)." >&2
  exit 1
}

# Spike 0 confirmed: --json-schema enforcement is exit-fail on mismatch
# (subtype: error_max_structured_output_retries). No need for ajv-cli
# post-validation in V1. If a future case wants stricter value-level
# assertions (beyond what's economical to put in --json-schema due to retry
# cost), revisit ajv-cli as a layered check.

tmp_results=$(mktemp)
trap 'rm -f "$tmp_results"' EXIT INT TERM

# Aggregate budget cap. Each case caps at $0.50 individually (run-case.sh).
# A regressed skill that fails all cases at the cap could burn N × $0.50;
# this aggregate ceiling protects against runaway nightly cost. Configurable
# via EVAL_TOTAL_BUDGET_USD; default $10 covers ~20 cases at the per-case cap.
EVAL_TOTAL_BUDGET_USD="${EVAL_TOTAL_BUDGET_USD:-10}"

discover_cases() {
  local skill_dir skill case_dir case_name
  for skill_dir in "$EVAL_ROOT"/*/; do
    [ -d "$skill_dir" ] || continue
    skill=$(basename "$skill_dir")
    # Skip the lib/ and schemas/ helper dirs — they aren't skill case roots.
    case "$skill" in lib|schemas) continue ;; esac
    [ -n "$skill_filter" ] && [ "$skill" != "$skill_filter" ] && continue
    # Reject skill names with whitespace — xargs -L 1 splits on whitespace
    # and would mis-route case dirs to the wrong skill silently.
    case "$skill" in *[[:space:]]*)
      echo "ERROR: skill directory contains whitespace: '$skill'" >&2
      exit 1 ;;
    esac
    for case_dir in "$skill_dir"*/; do
      [ -d "$case_dir" ] || continue
      case_name=$(basename "$case_dir")
      [ -n "$case_filter" ] && [ "$case_name" != "$case_filter" ] && continue
      # Reject case_dir paths with whitespace for the same reason. This also
      # catches a TMPDIR with spaces breaking xargs splitting upstream.
      case "$case_dir" in *[[:space:]]*)
        echo "ERROR: case directory contains whitespace: '$case_dir'" >&2
        echo "       Eval case paths must be whitespace-free for xargs -L 1 splitting." >&2
        exit 1 ;;
      esac
      # Space-separated: xargs -L 1 splits on whitespace and appends as
      # separate args after the command's literal args. The whitespace
      # guards above ensure no path produces ambiguous splits.
      printf '%s %s\n' "$skill" "$case_dir"
    done
  done
}

# Discover cases first so we can emit a sane error if no cases match the filters.
case_count=$(discover_cases | wc -l | tr -d ' ')
if [ "$case_count" -eq 0 ]; then
  if [ -n "$skill_filter" ] && [ -n "$case_filter" ]; then
    echo "ERROR: no case matched: $skill_filter/$case_filter" >&2
  elif [ -n "$skill_filter" ]; then
    echo "ERROR: no cases found under tests/eval/$skill_filter/" >&2
  else
    echo "ERROR: no cases found under $EVAL_ROOT/" >&2
  fi
  exit 1
fi

echo "Running $case_count case(s)..." >&2

# Parallelism: xargs -P N runs N cases concurrently. Each case has its own
# scratch tmpdir via run-case.sh's mktemp, so concurrent runs cannot corrupt
# state across cases. N=4 keeps cost predictable and avoids rate-limit clustering.
# `-L 1` reads one line of input per child invocation; appended tokens become
# additional positional args ($3=skill, $4=case_dir on the receiving side).
xargs_rc=0
discover_cases | xargs -P 4 -L 1 \
  bash "$EVAL_ROOT/lib/run-case.sh" "$WORKBENCH_SKILLS" "$WORKBENCH_TEMPLATES" \
  | tee "$tmp_results" || xargs_rc=$?

# Aggregate. xargs exits non-zero if any child did, but we also count PASS/FAIL
# lines in case xargs swallowed a child's exit (it does on macOS for some flag combos).
pass_count=$(grep -c '^PASS:' "$tmp_results" 2>/dev/null || true)
fail_count=$(grep -c '^FAIL:' "$tmp_results" 2>/dev/null || true)
pass_count=${pass_count:-0}
fail_count=${fail_count:-0}

# Sum per-case cost from the PASS/FAIL lines. Each line is shaped like:
#   PASS: skill/case ($0.13209194999999999, 28s)
# Extract the dollar amount, sum across all rows.
total_cost=$(grep -oE '\$[0-9]+\.[0-9]+' "$tmp_results" 2>/dev/null \
  | tr -d '$' \
  | awk 'BEGIN{s=0} {s+=$1} END{printf "%.4f", s}')
total_cost=${total_cost:-0}

echo ""
echo "----"
echo "PASS: $pass_count  FAIL: $fail_count  COST: \$$total_cost (cap: \$$EVAL_TOTAL_BUDGET_USD)"

# Aggregate budget enforcement: warn if observed cost exceeded the cap. This
# is a post-hoc check — the per-case cap is the actual stopgap. Use this to
# tune EVAL_TOTAL_BUDGET_USD or cut cases when CI shows runaway spend.
if awk -v c="$total_cost" -v b="$EVAL_TOTAL_BUDGET_USD" 'BEGIN{exit !(c>b)}'; then
  echo "WARN: total cost \$$total_cost exceeds EVAL_TOTAL_BUDGET_USD=\$$EVAL_TOTAL_BUDGET_USD" >&2
  echo "      Either raise the cap or trim cases to fit." >&2
fi

if [ "$fail_count" -gt 0 ] || [ "$xargs_rc" -ne 0 ]; then
  echo ""
  echo "Failed cases:" >&2
  grep '^FAIL:' "$tmp_results" >&2 || true
  exit 1
fi

exit 0
