#!/usr/bin/env bash
# tests/cj-goal-defect-smoke.test.sh — fast CI-push SHAPE smoke for the `defect`
# path: the mirror of tests/cj-goal-feature-smoke.test.sh for /CJ_goal_defect.
#
# Why this exists: the defect verb is one of the three primary cj_goal
# orchestrators, yet until this smoke landed its deterministic plumbing had NO
# per-PR proof at all (the feature + task verbs each had one). This file
# validates the defect-path SHAPE — worktree entry → shared-plumbing dispatch →
# the workbench-owned leaf-dispatch targets — WITHOUT invoking the
# /CJ_goal_defect skill (agent prose is out of deterministic reach; the helper
# scripts are the testable surface).
#
# Path shape under test (per the defect pipeline):
#   worktree  →  /investigate (gstack, not asserted)  →  qa / doc-sync leaf
#   subagents  →  /ship + /land-and-deploy (gstack, not asserted)
#
# Cases:
#   (1) cj-worktree-init.sh --caller defect → state=created, cj-def-* branch, exit 0
#       (the worktree entry point of the defect path)
#   (2) cj-goal-common.sh --phase worktree --mode defect → delegates to the
#       helper, reports a cj-def-* branch, PHASE_RESULT=ok, exit 0
#   (3) cj-goal-common.sh --phase ship --mode defect → exit 0, performs the
#       phase op (pr-check; ok OR skipped offline — both are exit 0)
#   (4) cj-goal-common.sh --phase telemetry --mode defect → writes one JSONL
#       receipt line to an isolated temp path, exit 0
#   (5) leaf-subagent dispatch targets exist on disk: the workbench-owned leaf
#       skills the defect path dispatches (qa / doc-sync) are present as
#       SKILL.md. (/investigate + /ship + /land-and-deploy are gstack skills
#       deployed under ~/.claude/skills/, NOT vendored in this repo, so they are
#       intentionally NOT asserted here — a CI checkout would not have them.)
#
# Pure smoke: case (1) uses --dry-run so no real worktree is created; case (2)
# forwards --dry-run through the common helper; case (4) writes to a mktemp
# file that is cleaned up. The /CJ_goal_defect skill is never invoked.

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

# Isolated fresh-clone sandbox (same idiom as cj-goal-feature-smoke.test.sh) so
# branch detection / worktree add operate on a throwaway checkout.
mk_sandbox() {
  local dir
  dir=$(mktemp -d -t cj-goal-defect-smoke.XXXXXX)
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

# ---------- Case 1: worktree entry — --caller defect → cj-def-* / created ----------

echo ""
echo "Case 1: cj-worktree-init.sh --caller defect → state=created, cj-def-* (--dry-run)..."
SBX1=$(mk_sandbox)
RCPT_TMP=$(mktemp -t cj-goal-defect-smoke-rcpt.XXXXXX)
trap 'cleanup "$SBX1" "${SBX2:-}"; rm -f "${RCPT_TMP:-}"' EXIT
(
  cd "$SBX1"
  OUT=$(bash "$WT_HELPER" --caller defect --dry-run 2>&1)
  STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
  BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
  if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-def-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 1: state=created branch=$BRANCH (defect worktree entry)"
  else
    fail_test "Case 1: expected state=created with cj-def-YYYYMMDD-HHMMSS-PID branch; got: $OUT"
  fi
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 2: shared plumbing — --phase worktree --mode defect ----------

echo ""
echo "Case 2: cj-goal-common.sh --phase worktree --mode defect → delegates, cj-def-*, PHASE_RESULT=ok..."
SBX2=$(mk_sandbox)
(
  cd "$SBX2"
  OUT=$(bash "$COMMON" --phase worktree --mode defect --dry-run 2>&1) && RC=0 || RC=$?
  WT_STATE=$(echo "$OUT" | grep '^WT_STATE=' | head -1 | cut -d= -f2-)
  WT_BRANCH=$(echo "$OUT" | grep '^WT_BRANCH=' | head -1 | cut -d= -f2-)
  PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
  if [ "$RC" -eq 0 ] && [ "$WT_STATE" = "created" ] && [ "$PHASE_RESULT" = "ok" ] \
     && echo "$WT_BRANCH" | grep -qE '^cj-def-[0-9]{8}-[0-9]{6}-[0-9]+$'; then
    ok "Case 2: PHASE_RESULT=ok WT_STATE=created WT_BRANCH=$WT_BRANCH (common helper delegates to worktree-init)"
  else
    fail_test "Case 2: expected PHASE_RESULT=ok WT_STATE=created cj-def-* branch; got rc=$RC: $OUT"
  fi
)
[ $? -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 3: --phase ship --mode defect → exit 0, performs phase op ----------
# 'ship' aliases pr-check. pr-check is read-only and fail-soft: PHASE_RESULT is
# 'ok' (gh resolved a verdict) OR 'skipped' (gh offline/unauth) — both exit 0.

echo ""
echo "Case 3: cj-goal-common.sh --phase ship --mode defect → exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped}..."
OUT=$(bash "$COMMON" --phase ship --mode defect 2>&1) && RC=0 || RC=$?
PHASE=$(echo "$OUT" | grep '^PHASE=' | head -1 | cut -d= -f2-)
PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
if [ "$RC" -eq 0 ] && [ "$PHASE" = "pr-check" ] && { [ "$PHASE_RESULT" = "ok" ] || [ "$PHASE_RESULT" = "skipped" ]; }; then
  ok "Case 3: exit 0, PHASE=pr-check (ship alias), PHASE_RESULT=$PHASE_RESULT"
else
  fail_test "Case 3: expected exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped}; got rc=$RC: $OUT"
fi

# ---------- Case 4: --phase telemetry --mode defect → writes one JSONL receipt ----------

echo ""
echo "Case 4: cj-goal-common.sh --phase telemetry --mode defect → one JSONL receipt line, exit 0..."
: > "$RCPT_TMP"   # start empty
OUT=$(bash "$COMMON" --phase telemetry --mode defect --receipt-file "$RCPT_TMP" --field run_id=smoke-test 2>&1) && RC=0 || RC=$?
PHASE_RESULT=$(echo "$OUT" | grep '^PHASE_RESULT=' | head -1 | cut -d= -f2-)
WRITTEN=$(echo "$OUT" | grep '^RECEIPT_WRITTEN=' | head -1 | cut -d= -f2-)
LINE_COUNT=$(wc -l < "$RCPT_TMP" | tr -d ' ')
# The written line must be valid JSON carrying mode=defect (jq present in CI).
JSON_MODE=""
if command -v jq >/dev/null 2>&1; then
  JSON_MODE=$(tail -1 "$RCPT_TMP" | jq -r '.mode // ""' 2>/dev/null || echo "")
fi
if [ "$RC" -eq 0 ] && [ "$PHASE_RESULT" = "ok" ] && [ "$WRITTEN" = "1" ] && [ "$LINE_COUNT" = "1" ] \
   && { [ -z "$JSON_MODE" ] || [ "$JSON_MODE" = "defect" ]; }; then
  ok "Case 4: PHASE_RESULT=ok, 1 receipt line, mode=defect"
else
  fail_test "Case 4: expected exit 0, PHASE_RESULT=ok, 1 JSONL line (mode=defect); got rc=$RC lines=$LINE_COUNT json_mode=$JSON_MODE: $OUT"
fi

# ---------- Case 5: leaf-subagent dispatch targets exist on disk ----------
# The defect path dispatches the workbench-owned leaf skills (qa → doc-sync).
# Assert each exists as a SKILL.md so the dispatch shape points at REAL targets.
# (/investigate + /ship + /land-and-deploy are gstack skills under
# ~/.claude/skills/, NOT vendored here — deliberately excluded so this passes
# in a bare CI checkout.)

echo ""
echo "Case 5: workbench-owned leaf dispatch targets (qa/doc-sync) present on disk..."
_missing=""
for s in CJ_qa-work-item CJ_document-release; do
  [ -f "$REPO_ROOT/skills/$s/SKILL.md" ] || _missing="$_missing $s"
done
if [ -z "$_missing" ]; then
  ok "Case 5: qa/doc-sync leaf SKILL.md present (defect dispatch shape wired to real targets)"
else
  fail_test "Case 5: missing workbench leaf dispatch target(s):$_missing"
fi

# ---------- Summary ----------

echo ""
echo "=== cj-goal-defect-smoke.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
