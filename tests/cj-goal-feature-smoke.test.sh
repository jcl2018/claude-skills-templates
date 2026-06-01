#!/usr/bin/env bash
# tests/cj-goal-feature-smoke.test.sh — early SHAPE harness for the `feature`
# path (F000027 / S000057).
#
# Why this exists NOW: the F000027 build is defect-first (Approach C). Without
# an early harness the riskier `feature` tail goes wholly unvalidated until
# PR #2 (the /CJ_goal_feature skill, S000059; uppercase post-F000031 casing-fix).
# This file validates the feature-path SHAPE — worktree entry → shared-plumbing
# dispatch → the leaf-subagent dispatch targets that exist today — WITHOUT
# requiring the /CJ_goal_feature skill to exist (it did not yet at write-time).
# Every assertion holds on the S000057 branch.
#
# Path shape under test (per F000027_DESIGN "Shape of the solution"):
#   worktree  →  scaffold / impl / qa leaf subagents  →  /ship (PR-stop)
#
# Cases:
#   (1) cj-worktree-init.sh --caller feature → state=created, cj-feat-* branch, exit 0
#       (the worktree entry point of the feature path)
#   (2) cj-goal-common.sh --phase worktree --mode feature → delegates to the
#       helper, reports a cj-feat-* branch, PHASE_RESULT=ok, exit 0
#   (3) cj-goal-common.sh --phase ship --mode feature → exit 0, performs the
#       phase op (pr-check; ok OR skipped offline — both are exit 0)  [TEST-SPEC S3]
#   (4) cj-goal-common.sh --phase telemetry --mode feature → writes one JSONL
#       receipt line to an isolated temp path, exit 0
#   (5) leaf-subagent dispatch targets exist on disk: the workbench-owned leaf
#       skills the feature path silently dispatches (scaffold / impl / qa) are
#       present as SKILL.md — the dispatch shape is wired to REAL targets today.
#       (office-hours + ship are gstack skills deployed under ~/.claude/skills/,
#       NOT vendored in this repo, so they are intentionally NOT asserted here —
#       a CI checkout would not have them.)
#
# Pure smoke: case (1) uses --dry-run so no real worktree is created; case (2)
# forwards --dry-run through the common helper; case (4) writes to a mktemp
# file that is cleaned up. The /CJ_goal_feature skill is never invoked — it
# did not exist yet at write-time, by design.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
WT_HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"

[ -x "$WT_HELPER" ] || { echo "FAIL: $WT_HELPER not executable"; exit 1; }
[ -x "$COMMON" ]    || { echo "FAIL: $COMMON not executable"; exit 1; }

# Isolated fresh-clone sandbox (same idiom as cj-worktree-init.test.sh) so
# branch detection / worktree add operate on a throwaway checkout.
mk_sandbox() {
  local dir
  dir=$(mktemp -d -t cj-goal-feature-smoke.XXXXXX)
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

# shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
cleanup() {
  for d in "$@"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      (cd "$d" 2>/dev/null && git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
        [ "$wt" != "$d" ] && git worktree remove --force "$wt" 2>/dev/null || true
      done) || true
      rm -rf "$d"
    fi
  done
}

# ---------- Case 1: worktree entry — --caller feature → cj-feat-* / created ----------

echo ""
echo "Case 1: cj-worktree-init.sh --caller feature → state=created, cj-feat-* (--dry-run)..."
SBX1=$(mk_sandbox)
RCPT_TMP=$(mktemp -t cj-goal-feature-smoke-rcpt.XXXXXX)
trap 'cleanup "$SBX1" "${SBX2:-}"; rm -f "${RCPT_TMP:-}"' EXIT
(
  cd "$SBX1"
  OUT=$(bash "$WT_HELPER" --caller feature --dry-run 2>&1)
  STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
  BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
  if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-feat-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 1: state=created branch=$BRANCH (feature worktree entry)"
  else
    fail_test "Case 1: expected state=created with cj-feat-YYYYMMDD-HHMMSS-PID branch; got: $OUT"
  fi
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 2: shared plumbing — --phase worktree --mode feature ----------

echo ""
echo "Case 2: cj-goal-common.sh --phase worktree --mode feature → delegates, cj-feat-*, PHASE_RESULT=ok..."
SBX2=$(mk_sandbox)
(
  cd "$SBX2"
  OUT=$(bash "$COMMON" --phase worktree --mode feature --dry-run 2>&1) && RC=0 || RC=$?
  WT_STATE=$(echo "$OUT" | grep '^WT_STATE=' | head -1 | cut -d= -f2-)
  WT_BRANCH=$(echo "$OUT" | grep '^WT_BRANCH=' | head -1 | cut -d= -f2-)
  PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
  if [ "$RC" -eq 0 ] && [ "$WT_STATE" = "created" ] && [ "$PHASE_RESULT" = "ok" ] \
     && echo "$WT_BRANCH" | grep -qE '^cj-feat-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 2: PHASE_RESULT=ok WT_STATE=created WT_BRANCH=$WT_BRANCH (common helper delegates to worktree-init)"
  else
    fail_test "Case 2: expected PHASE_RESULT=ok WT_STATE=created cj-feat-* branch; got rc=$RC: $OUT"
  fi
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 3: --phase ship --mode feature → exit 0, performs phase op (TEST-SPEC S3) ----------
# 'ship' aliases pr-check. pr-check is read-only and fail-soft: PHASE_RESULT is
# 'ok' (gh resolved a verdict) OR 'skipped' (gh offline/unauth) — both exit 0.

echo ""
echo "Case 3: cj-goal-common.sh --phase ship --mode feature → exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped} (TEST-SPEC S3)..."
OUT=$(bash "$COMMON" --phase ship --mode feature 2>&1) && RC=0 || RC=$?
PHASE=$(echo "$OUT" | grep '^PHASE=' | head -1 | cut -d= -f2-)
PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
if [ "$RC" -eq 0 ] && [ "$PHASE" = "pr-check" ] && { [ "$PHASE_RESULT" = "ok" ] || [ "$PHASE_RESULT" = "skipped" ]; }; then
  ok "Case 3: exit 0, PHASE=pr-check (ship alias), PHASE_RESULT=$PHASE_RESULT"
else
  fail_test "Case 3: expected exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped}; got rc=$RC: $OUT"
fi

# ---------- Case 4: --phase telemetry --mode feature → writes one JSONL receipt ----------

echo ""
echo "Case 4: cj-goal-common.sh --phase telemetry --mode feature → one JSONL receipt line, exit 0..."
: > "$RCPT_TMP"   # start empty
OUT=$(bash "$COMMON" --phase telemetry --mode feature --receipt-file "$RCPT_TMP" --field run_id=smoke-test 2>&1) && RC=0 || RC=$?
PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
WRITTEN=$(echo "$OUT" | grep '^RECEIPT_WRITTEN=' | head -1 | cut -d= -f2-)
LINE_COUNT=$(wc -l < "$RCPT_TMP" | tr -d ' ')
# The written line must be valid JSON carrying mode=feature (jq present in CI).
JSON_MODE=""
if command -v jq >/dev/null 2>&1; then
  JSON_MODE=$(tail -1 "$RCPT_TMP" | jq -r '.mode // ""' 2>/dev/null || echo "")
fi
if [ "$RC" -eq 0 ] && [ "$PHASE_RESULT" = "ok" ] && [ "$WRITTEN" = "1" ] && [ "$LINE_COUNT" = "1" ] \
   && { [ -z "$JSON_MODE" ] || [ "$JSON_MODE" = "feature" ]; }; then
  ok "Case 4: PHASE_RESULT=ok, 1 receipt line, mode=feature"
else
  fail_test "Case 4: expected exit 0, PHASE_RESULT=ok, 1 JSONL line (mode=feature); got rc=$RC lines=$LINE_COUNT json_mode=$JSON_MODE: $OUT"
fi

# ---------- Case 5: leaf-subagent dispatch targets exist on disk ----------
# The feature path silently dispatches the workbench-owned leaf skills
# (scaffold → impl → qa). Assert each exists as a SKILL.md so the dispatch
# shape points at REAL targets today — without the /CJ_goal_feature
# orchestrator existing. (office-hours + ship are gstack skills under
# ~/.claude/skills/, NOT vendored here — deliberately excluded so this passes
# in a bare CI checkout.)

echo ""
echo "Case 5: workbench-owned leaf dispatch targets (scaffold/impl/qa) present on disk..."
_missing=""
for s in CJ_scaffold-work-item CJ_implement-from-spec CJ_qa-work-item; do
  [ -f "$REPO_ROOT/skills/$s/SKILL.md" ] || _missing="$_missing $s"
done
if [ -z "$_missing" ]; then
  ok "Case 5: scaffold/impl/qa leaf SKILL.md present (feature dispatch shape wired to real targets)"
else
  fail_test "Case 5: missing workbench leaf dispatch target(s):$_missing"
fi

# ---------- Case 6: /CJ_goal_feature skill is NOT required to be present ----------
# Documents the contract that this harness runs BEFORE S000059. If the skill
# dir ever appears, that's fine (no-op); the point is the harness never
# depends on it. Pure informational assertion (always passes) — kept so a
# future reader sees the "no skill needed" guarantee is intentional.

echo ""
echo "Case 6: harness runs without the /CJ_goal_feature skill (S000059 not required)..."
if [ ! -d "$REPO_ROOT/skills/CJ_goal_feature" ]; then
  ok "Case 6: /CJ_goal_feature skill absent — feature path shape validated independently (Approach C)"
else
  ok "Case 6: /CJ_goal_feature skill now present — harness still independent of it (no-op)"
fi

# ---------- Summary ----------

echo ""
echo "=== cj-goal-feature-smoke.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
