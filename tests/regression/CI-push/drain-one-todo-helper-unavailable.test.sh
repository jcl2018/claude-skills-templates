#!/usr/bin/env bash
# tests/regression/CI-push/drain-one-todo-helper-unavailable.test.sh
#
# Regression test for the "drain-one-todo.sh silent in-place scaffold when
# cj-worktree-init.sh unavailable" defect (distinct from D000021).
#
# Bug: in drain dispatch context, when cj-worktree-init.sh is genuinely
# unreachable ($_WT_HELPER empty: manifest .source missing/empty/non-exec AND
# the BASH_SOURCE-relative in-repo fallback also not executable), the OLD code
# at drain-one-todo.sh:246-248 was a pure comment — execution SILENTLY fell
# through to the todo_fix.sh delegation and scaffolded the drained TODO into
# the CURRENT (possibly dirty, possibly unrelated) branch, destroying the
# F000025/S000054 per-TODO worktree isolation. D000021 fixed only the path
# resolution and its RCA Insights explicitly scoped this silent-fallthrough
# out.
#
# Fix: the unavailable-helper case in drain dispatch now FAILS LOUD —
# release lock, emit `RESULT: STATUS=halted; STAGE=preflight; HEADING=...;
# REASON=worktree-helper-unavailable`, exit 2 — consistent with the adjacent
# worktree-cd-failed and todo_fix.sh-not-found halt exits. The orchestrator
# treats exit 2 as a halt and STOPS the drain loop; no in-place scaffold runs.
#
# Cases:
#   (1) Static: drain-one-todo.sh contains a fail-loud guard on an
#       unreachable worktree helper in the dispatch path (halt RESULT +
#       worktree-helper-unavailable REASON), NOT a silent comment-only
#       fallthrough.
#   (2) Behavioral: from a SIMULATED DEPLOYED layout where the manifest has
#       NO usable .source and the helper is NOT reachable via the in-repo
#       fallback, invoking `drain-one-todo.sh dispatch` exits NON-ZERO, emits
#       the halted RESULT line with REASON=worktree-helper-unavailable, and
#       does NOT delegate to todo_fix.sh (no in-place scaffold). Pre-fix this
#       case fails: the dispatch silently proceeds into todo_fix.sh and
#       exits without the halted/worktree-helper-unavailable RESULT.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)  # tests/regression/CI-push/ -> repo root
DRAIN="$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"

[ -f "$DRAIN" ] || { echo "FAIL: $DRAIN not found"; exit 1; }

# ---------- Case 1: static — fail-loud guard present ----------

echo ""
echo "Case 1: drain-one-todo.sh fails loud (halt RESULT) when worktree helper unreachable in dispatch..."
if grep -q 'REASON=worktree-helper-unavailable' "$DRAIN" \
   && grep -qE 'if \[ ! -x "\$_WT_HELPER" \]; then' "$DRAIN" \
   && grep -qE 'RESULT: STATUS=halted;.*REASON=worktree-helper-unavailable' "$DRAIN"; then
  ok "Case 1: drain-one-todo.sh halts loud (RESULT: STATUS=halted; REASON=worktree-helper-unavailable) on unreachable helper"
else
  fail_test "Case 1: drain-one-todo.sh has no fail-loud guard for an unreachable worktree helper (regression: silent comment-only fallthrough scaffolds in-place on the current branch)"
fi

# ---------- Case 2: behavioral — unreachable helper → halt loud, no scaffold ----------
#
# Build a sandbox that mirrors the real failure surface, but with the helper
# UNREACHABLE (the defect's trigger):
#   $SBX/workbench-norepo/                 <- NOT a git repo, NO scripts/
#     skills/CJ_goal_todo_fix/scripts/     <- where the deployed drain "lives"
#     (deliberately NO scripts/cj-worktree-init.sh anywhere reachable)
#   $SBX/home/.claude/
#     .skills-templates.json               <- {} (NO usable .source)
#     skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh    <- DEPLOYED copy
#     skills/CJ_goal_todo_fix/scripts/todo_fix.sh          <- tripwire stub
#
# The deployed drain is invoked with HOME pointed at the sandbox home. The
# manifest has no .source, and the deployed-location BASH_SOURCE fallback
# (`../../..` from ~/.claude/skills/CJ_goal_todo_fix/scripts/) resolves to
# ~/.claude/scripts/cj-worktree-init.sh which does not exist. So $_WT_HELPER
# is empty -> the fix must halt loud BEFORE delegating to todo_fix.sh.
#
# The todo_fix.sh stub is a TRIPWIRE: if drain ever delegates to it (the
# pre-fix silent fallthrough), it drops a sentinel file. The fix must prevent
# that file from ever being written.

echo ""
echo "Case 2: deployed layout, helper UNREACHABLE → dispatch halts loud, no in-place scaffold..."

SBX=$(mktemp -d -t drain-helper-unavail-test.XXXXXX)
trap 'rm -rf "$SBX"' EXIT

# Unique heading per run so the cross-skill daily lockfile
# (/tmp/cj-goal-active-headings-YYYYMMDD.txt — hardcoded, not env-overridable)
# can never collide with a stale entry from a prior run / parallel session and
# short-circuit the dispatch path with a spurious lock_skip BEFORE the
# worktree-resolution code is reached.
UNIQ="helper unavail $$ $(date +%s%N 2>/dev/null || date +%s)"

# --- deployed ~/.claude layout (helper deliberately absent everywhere) ---
HOMEDIR="$SBX/home"
mkdir -p "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts"
cp "$DRAIN" "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"
chmod +x "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"

# Tripwire todo_fix.sh: if drain delegates to it (pre-fix silent fallthrough),
# this writes a sentinel. The fix must halt BEFORE this ever runs.
TRIPWIRE="$SBX/todo_fix_was_called"
cat > "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh" <<TRIPWIRE_EOF
#!/usr/bin/env bash
# Test tripwire stub — should NEVER be reached when the worktree helper is
# unreachable (the fix must halt loud first).
echo "TRIPWIRE: todo_fix.sh delegated — drain scaffolded in-place (the defect)" >&2
touch "$TRIPWIRE"
exit 0
TRIPWIRE_EOF
chmod +x "$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh"

# Manifest with NO usable .source (consumer repo / pre-deploy state).
cat > "$HOMEDIR/.claude/.skills-templates.json" <<MANIFEST_EOF
{"skills": {"CJ_goal_todo_fix": {"path": "skills/CJ_goal_todo_fix/SKILL.md"}}}
MANIFEST_EOF

# Run dir: NOT a git repo, no scripts/ — guarantees the BASH_SOURCE-relative
# in-repo fallback also cannot resolve the helper. (cd here so
# `git rev-parse --show-toplevel` inside drain yields nothing useful.)
RUNDIR="$SBX/workbench-norepo"
mkdir -p "$RUNDIR"

DEPLOYED_DRAIN="$HOMEDIR/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"

set +e
OUT=$(cd "$RUNDIR" && HOME="$HOMEDIR" DRY_RUN=1 bash "$DEPLOYED_DRAIN" dispatch "Drain $UNIQ" "test-session-$$" 2>&1)
RC=$?
set -e

# Best-effort: drop any lock entry this run may have acquired so a re-run in
# the same UTC day is not spuriously lock-skipped.
( HOME="$HOMEDIR" bash "$DEPLOYED_DRAIN" release "Drain $UNIQ" "test-session-$$" >/dev/null 2>&1 ) || true

# Three independent assertions, all must hold for the fix to be proven:
#   (a) non-zero exit (halt, not silent success)
#   (b) RESULT line is STATUS=halted with REASON=worktree-helper-unavailable
#   (c) the todo_fix.sh tripwire was NEVER triggered (no in-place scaffold)
CASE2_OK=1

if [ "$RC" -eq 0 ]; then
  fail_test "Case 2(a): dispatch exited 0 with helper unreachable — silent success (the defect). Output: $OUT"
  CASE2_OK=0
else
  ok "Case 2(a): dispatch exited non-zero ($RC) — halted instead of silently proceeding"
fi

if echo "$OUT" | grep -qE 'RESULT: STATUS=halted;.*REASON=worktree-helper-unavailable'; then
  ok "Case 2(b): emitted RESULT: STATUS=halted; ... REASON=worktree-helper-unavailable"
else
  fail_test "Case 2(b): no halted/worktree-helper-unavailable RESULT line (the defect: silent fallthrough). Output: $OUT"
  CASE2_OK=0
fi

if [ -f "$TRIPWIRE" ]; then
  fail_test "Case 2(c): todo_fix.sh WAS delegated — drain scaffolded in-place on the current branch (the defect)"
  CASE2_OK=0
else
  ok "Case 2(c): todo_fix.sh never delegated — no in-place scaffold (worktree isolation preserved)"
fi

if [ "$CASE2_OK" = "1" ]; then
  ok "Case 2: deployed drain halts loud when cj-worktree-init.sh is unreachable (no silent in-place scaffold)"
fi

# ---------- Summary ----------

echo ""
echo "=== drain-one-todo-helper-unavailable.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
