#!/usr/bin/env bash
# tests/cj-goal-pr-body-splice-guard.test.sh
#
# Regression guard for the PR-body splice idiom across the 4 cj_goal orchestrator
# pipeline.md files. T000053 (PR #279) replaced the BSD/macOS-awk-fragile
# `awk -v <var>="$<multi-line-payload>"` PR-body splice with temp-file
# composition + `gh pr edit --body-file` + a post-edit line-count floor in all
# four CJ_goal_* pipeline.md (feature Step 4.6, defect Step 9.5, task Step 6.6,
# todo_fix Step 5.6). That fix shipped DOC-ONLY — the four splice blocks are
# agent-executed prose, and nothing asserted the wiper idiom could not creep back
# into one of the four copies on a future edit.
#
# Why the idiom is dangerous: BSD/macOS awk rejects a newline inside a -v value
# ("newline in string"), which empties the substitution and lets the subsequent
# `gh pr edit` WIPE the PR body. This was a live failure (PR #259, F000059).
#
# The guard asserts that, in each of the 4 pipeline.md, NO executable
# (non-comment) line passes a shell variable through `awk -v` UNLESS the value is
# a filename — a `-v` whose value variable name ends in `_FILE`, the documented
# safe idiom where the multi-line payload is read from the file via `getline`.
# The warning comment lines (which contain the literal `awk -v v="$_INSERT"` /
# `awk -v v="$_VERDICTS"` as the thing NOT to do) are exempt because they are
# shell comments (first non-whitespace char is `#`).
#
# Asserts:
#   1. Each of the 4 pipeline.md files exists.
#   2. No NON-COMMENT `awk -v X="$VAR"` line where VAR does not end in `_FILE`
#      (the dangerous multi-line-payload form) in any of the 4 files.
#   3. Each of the 4 files still contains the safe `gh pr edit --body-file`
#      splice (a positive anchor — so deleting the splice entirely also trips the
#      guard rather than vacuously passing).

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

PIPELINES=(
  "$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
  "$REPO_ROOT/skills/CJ_goal_defect/pipeline.md"
  "$REPO_ROOT/skills/CJ_goal_task/pipeline.md"
  "$REPO_ROOT/skills/CJ_goal_todo_fix/pipeline.md"
)

echo "=== cj-goal-pr-body-splice-guard: no multi-line 'awk -v' payload in 4 pipeline.md ==="

# 1. existence
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  if [ -f "$pf" ]; then ok "exists: $rel"; else fail_test "missing pipeline.md: $rel"; fi
done

# 2. the guard: no dangerous non-comment `awk -v X="$VAR"` (VAR not ending _FILE).
#    grep -n → "LINE:content". Drop shell-comment lines (first non-space char #);
#    match `awk -v ident="$IDENT"`; then allow only values whose var ends _FILE.
for pf in "${PIPELINES[@]}"; do
  [ -f "$pf" ] || continue
  rel="${pf#"$REPO_ROOT"/}"
  hits=$(grep -nE 'awk -v[[:space:]]+[A-Za-z_][A-Za-z0-9_]*="\$[A-Za-z_][A-Za-z0-9_]*"' "$pf" \
           | grep -vE '^[0-9]+:[[:space:]]*#' \
           | grep -vE '="\$[A-Za-z_][A-Za-z0-9_]*_FILE"' || true)
  if [ -n "$hits" ]; then
    fail_test "$rel: dangerous multi-line 'awk -v' payload idiom present (use temp-file + --body-file):"
    printf '%s\n' "$hits" | sed 's/^/        /' >&2
  else
    ok "$rel: no dangerous 'awk -v' payload (only _FILE filename form / comments)"
  fi
done

# 3. positive anchor: the safe --body-file splice is still present in each file.
for pf in "${PIPELINES[@]}"; do
  [ -f "$pf" ] || continue
  rel="${pf#"$REPO_ROOT"/}"
  if grep -qE 'gh pr edit .*--body-file' "$pf"; then
    ok "$rel: safe 'gh pr edit --body-file' splice present"
  else
    fail_test "$rel: safe '--body-file' splice missing (the splice may have regressed)"
  fi
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== PASS: all cj-goal-pr-body-splice-guard cases ==="
  exit 0
else
  echo "=== FAIL: $ERRORS cj-goal-pr-body-splice-guard case(s) ===" >&2
  exit 1
fi
