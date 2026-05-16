#!/usr/bin/env bash
# tests/cj-worktree-init.test.sh — 5-case test for scripts/cj-worktree-init.sh.
#
# Per F000025/S000054 design (Decision Audit Trail #10): replaces the "one grep
# is theatrical" assertion with real behavior tests for the worktree helper.
#
# Cases:
#   (1) on-main + clean → state=created (via --dry-run to avoid mutation)
#   (2) in-worktree → state=detected
#   (3) --no-worktree → state=opted_out
#   (4) --force-create bypasses in-worktree detection (via --dry-run)
#   (5) dirty-check halts (interactive) / skips (--quiet)
#
# Pure smoke: uses --dry-run for the "create" cases so no real worktrees are
# left behind. Real worktree creation is exercised manually via the E2E rows
# in S000054_TEST-SPEC.md.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Locate the helper.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"

[ -x "$HELPER" ] || { echo "FAIL: $HELPER not executable"; exit 1; }

# ---------- Setup an isolated fresh-clone sandbox for each case ----------
#
# We need to test "on-main + clean" without polluting the actual workbench.
# Create a temp git repo per case so dirty-check / branch detection / worktree
# add operate on an isolated checkout. The helper itself doesn't care which
# repo it operates on — it uses `git rev-parse` against $PWD.

mk_sandbox() {
  local dir
  dir=$(mktemp -d -t cj-worktree-init-test.XXXXXX)
  (
    cd "$dir"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
  )
  printf '%s' "$dir"
}

cleanup_sandboxes() {
  for d in "$@"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      # Worktree removal first (if any), then dir.
      (cd "$d" 2>/dev/null && git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
        [ "$wt" != "$d" ] && git worktree remove --force "$wt" 2>/dev/null || true
      done) || true
      rm -rf "$d"
    fi
  done
}

# ---------- Case 1: on-main + clean → state=created (via --dry-run) ----------

echo ""
echo "Case 1: on-main + clean → state=created (--dry-run, no fs mutation)..."
SBX1=$(mk_sandbox)
trap 'cleanup_sandboxes "$SBX1" "${SBX2:-}" "${SBX4:-}" "${SBX5:-}"' EXIT
(
  cd "$SBX1"
  OUT=$(bash "$HELPER" --caller run --dry-run 2>&1)
  STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
  BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
  if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-run-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 1: state=created branch=$BRANCH"
  else
    fail_test "Case 1: expected state=created with cj-run-YYYYMMDD-HHMMSS-PID branch; got: $OUT"
  fi
)
case_1_rc=$?
[ "$case_1_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 2: in-worktree → state=detected ----------

echo ""
echo "Case 2: in-worktree → state=detected (no-op)..."
SBX2=$(mk_sandbox)
(
  cd "$SBX2"
  # Create a worktree we can cd into.
  mkdir -p .claude/worktrees
  git worktree add -q -b test-wt-branch ".claude/worktrees/test-wt" >/dev/null 2>&1
  cd ".claude/worktrees/test-wt"
  OUT=$(bash "$HELPER" --caller run --dry-run 2>&1)
  STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
  if [ "$STATE" = "detected" ]; then
    ok "Case 2: state=detected"
  else
    fail_test "Case 2: expected state=detected; got: $OUT"
  fi
)
case_2_rc=$?
[ "$case_2_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 3: --no-worktree → state=opted_out ----------

echo ""
echo "Case 3: --no-worktree → state=opted_out..."
OUT=$(bash "$HELPER" --caller run --no-worktree 2>&1)
STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
if [ "$STATE" = "opted_out" ]; then
  ok "Case 3: state=opted_out"
else
  fail_test "Case 3: expected state=opted_out; got: $OUT"
fi

# ---------- Case 4: --force-create bypasses in-worktree detection ----------

echo ""
echo "Case 4: --force-create bypasses in-worktree detection (--dry-run)..."
SBX4=$(mk_sandbox)
(
  cd "$SBX4"
  mkdir -p .claude/worktrees
  git worktree add -q -b test-force-branch ".claude/worktrees/test-force" >/dev/null 2>&1
  cd ".claude/worktrees/test-force"
  OUT=$(bash "$HELPER" --caller todo --force-create --dry-run 2>&1)
  STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
  BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
  if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-todo-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 4: state=created branch=$BRANCH (bypassed detection)"
  else
    fail_test "Case 4: expected state=created with cj-todo-... branch despite in-worktree; got: $OUT"
  fi
)
case_4_rc=$?
[ "$case_4_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 5: dirty-check halts (interactive) / skips (--quiet) ----------

echo ""
echo "Case 5: dirty-check halts (interactive) and skips (--quiet)..."
SBX5=$(mk_sandbox)
(
  cd "$SBX5"
  # Dirty the checkout.
  echo "dirty" >> seed.txt

  # 5a: interactive (no --quiet) → state=failed
  OUT_A=$(bash "$HELPER" --caller run --dry-run 2>&1 || true)
  STATE_A=$(echo "$OUT_A" | jq -r '.state' 2>/dev/null || echo "")
  NOTE_A=$(echo "$OUT_A" | jq -r '.note' 2>/dev/null || echo "")
  if [ "$STATE_A" = "failed" ] && echo "$NOTE_A" | grep -q 'dirty checkout'; then
    ok "Case 5a: state=failed interactive (dirty checkout halt)"
  else
    fail_test "Case 5a: expected state=failed on dirty + interactive; got: $OUT_A"
  fi

  # 5b: --quiet → state=skipped (no halt; runs in-place)
  OUT_B=$(bash "$HELPER" --caller run --quiet --dry-run 2>&1 || true)
  STATE_B=$(echo "$OUT_B" | jq -r '.state' 2>/dev/null || echo "")
  if [ "$STATE_B" = "skipped" ]; then
    ok "Case 5b: state=skipped --quiet (dirty checkout, in-place)"
  else
    fail_test "Case 5b: expected state=skipped on dirty + --quiet; got: $OUT_B"
  fi
)
case_5_rc=$?
[ "$case_5_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Summary ----------

echo ""
echo "=== cj-worktree-init.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
