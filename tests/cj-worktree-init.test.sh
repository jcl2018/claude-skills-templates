#!/usr/bin/env bash
# tests/cj-worktree-init.test.sh — test for scripts/cj-worktree-init.sh.
#
# Per F000025/S000054 design (Decision Audit Trail #10): replaces the "one grep
# is theatrical" assertion with real behavior tests for the worktree helper.
# Extended by T000033 with the 8 --assert-isolated verdict cases + two pipeline.md
# static-grep regression assertions (Step 5 gate; --no-worktree marker-file wiring).
# Extended by F000027/S000057 with the caller→prefix matrix block: asserts the two
# NEW callers (feature→cj-feat, defect→cj-def) resolve + exit 0, AND that the three
# existing callers (run→cj-run, todo→cj-todo) resolve unchanged
# (non-regression — SPEC P1 #4).
#
# Mutating-mode cases (F000025):
#   (1) on-main + clean → state=created (via --dry-run to avoid mutation)
#   (2) in-worktree → state=detected
#   (3) --no-worktree → state=opted_out
#   (4) --force-create bypasses in-worktree detection (via --dry-run)
#   (5) dirty-check halts (interactive) / skips (--quiet)
#
# --assert-isolated verdict-mode cases (T000033; read-only, no fs mutation):
#   (a)  in worktree → isolated / 0
#   (b)  clean main, no worktree → not_isolated / ≠0
#   (c)  dirty on a feature branch → dirty / ≠0 (dirty wins over branch rule)
#   (d)  clean feature branch → isolated / 0
#   (e1) --no-worktree + clean → isolated / 0
#   (e2) --no-worktree + dirty → dirty / ≠0 (hatch is NOT a bypass)
#   (f)  not a repo → not_a_repo / ≠0
#   (g)  detached HEAD on primary checkout → not_isolated / ≠0
#
# caller→prefix matrix (F000027/S000057; --dry-run, no fs mutation):
#   (h1) --caller feature     → state=created, cj-feat-* branch  (NEW)
#   (h2) --caller defect      → state=created, cj-def-*  branch  (NEW)
#   (h3) --caller run         → state=created, cj-run-*  branch  (non-regression)
#   (h4) --caller todo        → state=created, cj-todo-* branch  (non-regression)
#   (h6) --caller bogus       → state=failed, exit 1            (validator still rejects unknown)
#
# Plus a static-grep regression assertion that pipeline.md Step 5 wires the
# --assert-isolated gate AND the draft-aware resume_cmd (F000025's
# one-grep-per-SKILL.md idiom, applied to pipeline.md here).
#
# Pure smoke: uses --dry-run for the F000025 "create" cases so no real
# worktrees are left behind. The --assert-isolated cases are inherently
# read-only. Real worktree creation is exercised manually via the E2E rows
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

# ============================================================================
# T000033: --assert-isolated verdict-mode cases (read-only; no fs mutation)
# ============================================================================
#
# verdict_case <label> <expected_state> <expected_exit_kind: zero|nonzero> -- <cmd...>
# Runs the helper, asserts JSON .state and exit-code class. Helper exits
# non-zero on dirty/not_a_repo/not_isolated, so `|| true` captures rc.

assert_verdict() {
  local label="$1" want_state="$2" want_exit="$3"; shift 3
  # "$@" is the full argv to the helper (already includes --assert-isolated).
  local out rc state
  out=$("$@" 2>&1) && rc=0 || rc=$?
  state=$(echo "$out" | jq -r '.state' 2>/dev/null || echo "")
  local exit_ok=0
  if [ "$want_exit" = "zero" ] && [ "$rc" -eq 0 ]; then exit_ok=1; fi
  if [ "$want_exit" = "nonzero" ] && [ "$rc" -ne 0 ]; then exit_ok=1; fi
  if [ "$state" = "$want_state" ] && [ "$exit_ok" -eq 1 ]; then
    ok "$label: state=$state exit=$rc"
  else
    fail_test "$label: expected state=$want_state exit=$want_exit; got state=$state rc=$rc out=$out"
  fi
}

# ---------- Case (a): in a linked worktree → isolated / 0 ----------

echo ""
echo "Case (a): --assert-isolated in a linked worktree → isolated / 0..."
SBXA=$(mk_sandbox)
trap 'cleanup_sandboxes "$SBX1" "${SBX2:-}" "${SBX4:-}" "${SBX5:-}" "${SBXA:-}" "${SBXB:-}" "${SBXC:-}" "${SBXD:-}" "${SBXE:-}" "${SBXG:-}"' EXIT
(
  cd "$SBXA"
  mkdir -p .claude/worktrees
  git worktree add -q -b ai-wt-branch ".claude/worktrees/ai-wt" >/dev/null 2>&1
  cd ".claude/worktrees/ai-wt"
  assert_verdict "Case (a)" "isolated" "zero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (b): clean main, no worktree → not_isolated / ≠0 ----------

echo ""
echo "Case (b): --assert-isolated clean main, no worktree → not_isolated / ≠0..."
SBXB=$(mk_sandbox)
(
  cd "$SBXB"
  assert_verdict "Case (b)" "not_isolated" "nonzero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (c): dirty on a feature branch → dirty / ≠0 ----------
# Dirty is checked BEFORE the branch rule — proves the ladder order.

echo ""
echo "Case (c): --assert-isolated dirty feature branch → dirty / ≠0 (dirty wins)..."
SBXC=$(mk_sandbox)
(
  cd "$SBXC"
  git checkout -q -b feat/some-work
  echo "dirty" >> seed.txt
  assert_verdict "Case (c)" "dirty" "nonzero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (d): clean feature branch → isolated / 0 ----------

echo ""
echo "Case (d): --assert-isolated clean feature branch → isolated / 0..."
SBXD=$(mk_sandbox)
(
  cd "$SBXD"
  git checkout -q -b feat/clean-work
  assert_verdict "Case (d)" "isolated" "zero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (e1): --no-worktree + clean → isolated / 0 ----------

echo ""
echo "Case (e1): --assert-isolated --no-worktree + clean → isolated / 0..."
SBXE=$(mk_sandbox)
(
  cd "$SBXE"
  assert_verdict "Case (e1)" "isolated" "zero" \
    bash "$HELPER" --caller defect --assert-isolated --no-worktree
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (e2): --no-worktree + dirty → dirty / ≠0 ----------
# The escape hatch is NOT a bypass: dirty wins over --no-worktree.

echo ""
echo "Case (e2): --assert-isolated --no-worktree + dirty → dirty / ≠0 (hatch != bypass)..."
(
  cd "$SBXE"
  echo "dirty" >> seed.txt
  assert_verdict "Case (e2)" "dirty" "nonzero" \
    bash "$HELPER" --caller defect --assert-isolated --no-worktree
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case (f): not a git repo → not_a_repo / ≠0 ----------

echo ""
echo "Case (f): --assert-isolated not a git repo → not_a_repo / ≠0..."
NONGIT=$(mktemp -d -t cj-wi-nongit.XXXXXX)
(
  cd "$NONGIT"
  assert_verdict "Case (f)" "not_a_repo" "nonzero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))
rm -rf "$NONGIT"

# ---------- Case (g): detached HEAD on primary checkout → not_isolated / ≠0 ----------

echo ""
echo "Case (g): --assert-isolated detached HEAD on primary → not_isolated / ≠0..."
SBXG=$(mk_sandbox)
(
  cd "$SBXG"
  _HEAD_SHA=$(git rev-parse HEAD)
  git checkout -q "$_HEAD_SHA" 2>/dev/null   # detach
  assert_verdict "Case (g)" "not_isolated" "nonzero" \
    bash "$HELPER" --caller defect --assert-isolated
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ============================================================================
# F000027 / S000057: caller→prefix matrix (--dry-run; no fs mutation)
# ============================================================================
#
# Asserts the full --caller validator + prefix map in one sandbox:
#   - the TWO NEW callers resolve to their new prefixes and exit 0 (SPEC P0 #1);
#   - the THREE EXISTING callers resolve UNCHANGED (SPEC P1 #4 non-regression);
#   - an unknown caller is still rejected (state=failed / exit 1) — the
#     extension widened the allow-list, it did NOT open it.
#
# All resolution cases use --dry-run so the prefix is reported in the .branch
# field of the emitted JSON without any `git worktree add`.

# assert_caller_prefix <label> <caller> <expected_prefix>
# Runs the helper --dry-run in the matrix sandbox, asserts state=created and the
# branch matches ^<expected_prefix>-YYYYMMDD-HHMMSS-PID$.
assert_caller_prefix() {
  local label="$1" caller="$2" prefix="$3"
  local out state branch
  out=$(bash "$HELPER" --caller "$caller" --dry-run 2>&1) && : || :
  state=$(echo "$out" | jq -r '.state' 2>/dev/null || echo "")
  branch=$(echo "$out" | jq -r '.branch' 2>/dev/null || echo "")
  if [ "$state" = "created" ] && echo "$branch" | grep -qE "^${prefix}-[0-9]{8}-[0-9]{6}-[0-9]+$"; then
    ok "$label: --caller $caller → $prefix (branch=$branch)"
  else
    fail_test "$label: --caller $caller expected state=created with ${prefix}-* branch; got: $out"
  fi
}

echo ""
echo "Case (h): caller→prefix matrix (2 new callers + 3 existing non-regression + unknown reject)..."
SBXH=$(mk_sandbox)
trap 'cleanup_sandboxes "$SBX1" "${SBX2:-}" "${SBX4:-}" "${SBX5:-}" "${SBXA:-}" "${SBXB:-}" "${SBXC:-}" "${SBXD:-}" "${SBXE:-}" "${SBXG:-}" "${SBXH:-}"' EXIT
(
  cd "$SBXH"
  # NEW callers (SPEC P0 #1)
  assert_caller_prefix "Case (h1)" feature     cj-feat
  assert_caller_prefix "Case (h2)" defect      cj-def
  # EXISTING callers — must resolve unchanged (SPEC P1 #4 non-regression)
  assert_caller_prefix "Case (h3)" run         cj-run
  assert_caller_prefix "Case (h4)" todo        cj-todo

  # Unknown caller still rejected: state=failed, exit 1.
  OUT_BOGUS=$(bash "$HELPER" --caller bogus --dry-run 2>&1) && RC_BOGUS=0 || RC_BOGUS=$?
  STATE_BOGUS=$(echo "$OUT_BOGUS" | jq -r '.state' 2>/dev/null || echo "")
  if [ "$STATE_BOGUS" = "failed" ] && [ "$RC_BOGUS" -ne 0 ]; then
    ok "Case (h6): --caller bogus → state=failed exit=$RC_BOGUS (validator still rejects unknown)"
  else
    fail_test "Case (h6): expected state=failed/exit≠0 for unknown caller; got state=$STATE_BOGUS rc=$RC_BOGUS out=$OUT_BOGUS"
  fi
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- CJ_goal_feature/pipeline.md Step 1.9 isolation-gate guard ----------
#
# F000027 parity: the `feature` verb's silent build (Step 3) dispatches
# source-writing scaffold/implement subagents, so it needs the
# --assert-isolated gate. An upstream refactor that drops it silently reopens
# the D000024 in-place-source-write class on the feature path.
# (Post-F000031 casing-fix: the skill dir is now skills/CJ_goal_feature/.)

echo ""
echo "CJ_goal_feature/pipeline.md Step 1.9 regression: --assert-isolated gate + --no-worktree marker present..."
_FEAT_PIPELINE_MD="$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
if grep -qF -- '--assert-isolated' "$_FEAT_PIPELINE_MD" \
   && grep -qF 'scripts/cj-worktree-init.sh' "$_FEAT_PIPELINE_MD" \
   && grep -qF -- '--caller feature --assert-isolated' "$_FEAT_PIPELINE_MD" \
   && grep -qF '/.operator-no-worktree' "$_FEAT_PIPELINE_MD" \
   && grep -qF 'CJ_goal_feature-runs/$RUN_ID/.operator-no-worktree' "$_FEAT_PIPELINE_MD" \
   && ! grep -qF '"${NO_WORKTREE:-0}" = "1"' "$_FEAT_PIPELINE_MD"; then
  ok "CJ_goal_feature/pipeline.md Step 1.9 wires --assert-isolated gate + --no-worktree marker (no dead shell-var read)"
else
  fail_test "CJ_goal_feature/pipeline.md Step 1.9 missing --assert-isolated gate or --no-worktree marker wiring (F000027 isolation-gate regression guard)"
fi

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
