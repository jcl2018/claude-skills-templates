#!/usr/bin/env bash
# tests/cj-task-scaffold.test.sh — test for skills/CJ_goal_task/scripts/cj-task-scaffold.sh.
#
# F000054: the topic-driven `type: task` scaffold + the HARD complexity gate that
# fronts /CJ_goal_task. Behavior coverage:
#
#   Complexity gate (HARD refusal, exit 2, routes to the right verb):
#     (1) design-rework topic   → too-complex, SUGGEST=/CJ_goal_feature
#     (2) bug/investigation     → too-complex, SUGGEST=/CJ_goal_defect
#     (3) explicit-large-scope  → too-complex, SUGGEST=/CJ_goal_feature
#     (4) "refine the design doc" is ALLOWED (bare 'design' must NOT trip the gate)
#
#   Scaffold:
#     (5) --dry-run small task  → CJ_TASK_RESULT=dry-run, plans a T-ID, NO writes
#     (6) live scaffold         → CJ_TASK_RESULT=ok + handoff block; TRACKER +
#                                 test-plan written; topic injected; footer present
#     (7) idempotency           → re-run same topic → IDEMPOTENT_SKIP=1, same dir,
#                                 no second T-ID minted
#     (8) --topic required      → usage error, exit 1
#
# Sandbox: a temp git repo with the real templates staged under
# templates/CJ_personal-workflow/ + a work-items/tasks/ tree, so the live scaffold
# runs end-to-end with zero real-repo mutation (and zero network — gh has no
# remote in the sandbox, so the PR-side ID probe is a clean no-op).

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SCAFFOLD="$REPO_ROOT/skills/CJ_goal_task/scripts/cj-task-scaffold.sh"

[ -x "$SCAFFOLD" ] || { echo "FAIL: $SCAFFOLD not executable"; exit 1; }

# ---------- sandbox builder (stages the real templates) ----------
SBX=""
mk_sandbox() {
  SBX=$(mktemp -d -t cj-task-scaffold.XXXXXX)
  (
    cd "$SBX"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
    mkdir -p templates/CJ_personal-workflow work-items/tasks
  )
  cp "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" "$SBX/templates/CJ_personal-workflow/"
  cp "$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md" "$SBX/templates/CJ_personal-workflow/"
}
ALL=()
trap 'for d in "${ALL[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done' EXIT

getkey() { printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -1; }

# ============================================================================
# Complexity gate — HARD refusals
# ============================================================================

echo ""
echo "Case 1: design-rework topic → too-complex → /CJ_goal_feature..."
OUT=$(bash "$SCAFFOLD" --topic "redesign the cleanup flow" --repo "$REPO_ROOT" 2>&1) && RC=0 || RC=$?
if [ "$RC" -eq 2 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "too-complex" ] \
   && [ "$(getkey SUGGEST "$OUT")" = "/CJ_goal_feature" ]; then
  ok "Case 1: refused design topic (exit 2, SUGGEST=/CJ_goal_feature)"
else
  fail_test "Case 1: expected too-complex→/CJ_goal_feature exit 2; rc=$RC out=$OUT"
fi

echo ""
echo "Case 2: bug/investigation topic → too-complex → /CJ_goal_defect..."
OUT=$(bash "$SCAFFOLD" --topic "investigate why the build hangs" --repo "$REPO_ROOT" 2>&1) && RC=0 || RC=$?
if [ "$RC" -eq 2 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "too-complex" ] \
   && [ "$(getkey SUGGEST "$OUT")" = "/CJ_goal_defect" ]; then
  ok "Case 2: refused bug topic (exit 2, SUGGEST=/CJ_goal_defect)"
else
  fail_test "Case 2: expected too-complex→/CJ_goal_defect exit 2; rc=$RC out=$OUT"
fi

echo ""
echo "Case 3: explicit-large-scope topic → too-complex → /CJ_goal_feature..."
OUT=$(bash "$SCAFFOLD" --topic "an epic overhaul of the worktree system" --repo "$REPO_ROOT" 2>&1) && RC=0 || RC=$?
if [ "$RC" -eq 2 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "too-complex" ] \
   && [ "$(getkey SUGGEST "$OUT")" = "/CJ_goal_feature" ]; then
  ok "Case 3: refused large-scope topic (exit 2, SUGGEST=/CJ_goal_feature)"
else
  fail_test "Case 3: expected too-complex→/CJ_goal_feature exit 2; rc=$RC out=$OUT"
fi

echo ""
echo "Case 4: 'refine the design doc' is ALLOWED (bare 'design' must not trip the gate)..."
OUT=$(bash "$SCAFFOLD" --topic "refine the design doc wording" --repo "$REPO_ROOT" --dry-run 2>&1) && RC=0 || RC=$?
if [ "$RC" -eq 0 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "dry-run" ]; then
  ok "Case 4: 'design doc' topic allowed (gate PASS, dry-run)"
else
  fail_test "Case 4: expected dry-run PASS for 'design doc' topic; rc=$RC out=$OUT"
fi

# ============================================================================
# Scaffold
# ============================================================================

echo ""
echo "Case 5: --dry-run small task → plans a T-ID, no writes..."
mk_sandbox; ALL+=("$SBX")
OUT=$(bash "$SCAFFOLD" --topic "refine the readme quick start" --repo "$SBX" --dry-run 2>&1) && RC=0 || RC=$?
COUNT=$(find "$SBX/work-items" -name 'T*_TRACKER.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$RC" -eq 0 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "dry-run" ] \
   && echo "$OUT" | grep -q 'Planned T-ID:' && [ "$COUNT" = "0" ]; then
  ok "Case 5: dry-run plans a T-ID, writes nothing"
else
  fail_test "Case 5: expected dry-run + no writes; rc=$RC count=$COUNT out=$OUT"
fi

echo ""
echo "Case 6: live scaffold → handoff + TRACKER + test-plan + topic + footer..."
mk_sandbox; ALL+=("$SBX")
TOPIC="clean up the stray scratch file"
OUT=$(bash "$SCAFFOLD" --topic "$TOPIC" --repo "$SBX" 2>&1) && RC=0 || RC=$?
WID=$(getkey WORK_ITEM_DIR "$OUT")
TID=$(getkey T_ID "$OUT")
if [ "$RC" -eq 0 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "ok" ] \
   && [ "$(getkey IDEMPOTENT_SKIP "$OUT")" = "0" ] \
   && [ -f "$SBX/$WID/${TID}_TRACKER.md" ] \
   && [ -f "$SBX/$WID/test-plan.md" ] \
   && grep -qF "$TOPIC" "$SBX/$WID/${TID}_TRACKER.md" \
   && grep -qF "<!-- Source: /CJ_goal_task: $TOPIC -->" "$SBX/$WID/${TID}_TRACKER.md"; then
  ok "Case 6: live scaffold ok ($TID at $WID; TRACKER+test-plan+topic+footer present)"
else
  fail_test "Case 6: live scaffold wrong; rc=$RC wid=$WID tid=$TID out=$OUT"
fi

echo ""
echo "Case 7: idempotency → re-run same topic reuses the dir (IDEMPOTENT_SKIP=1)..."
OUT2=$(bash "$SCAFFOLD" --topic "$TOPIC" --repo "$SBX" 2>&1) && RC2=0 || RC2=$?
WID2=$(getkey WORK_ITEM_DIR "$OUT2")
COUNT2=$(find "$SBX/work-items" -name 'T*_TRACKER.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$RC2" -eq 0 ] && [ "$(getkey IDEMPOTENT_SKIP "$OUT2")" = "1" ] \
   && [ "$WID2" = "$WID" ] && [ "$COUNT2" = "1" ]; then
  ok "Case 7: idempotent re-run reused $WID (no second T-ID; count=1)"
else
  fail_test "Case 7: expected idempotent reuse; rc=$RC2 wid2=$WID2 (want $WID) count=$COUNT2 out=$OUT2"
fi

echo ""
echo "Case 8: --topic required → usage error, exit 1..."
OUT=$(bash "$SCAFFOLD" --repo "$REPO_ROOT" 2>&1) && RC=0 || RC=$?
if [ "$RC" -eq 1 ] && echo "$OUT" | grep -q 'topic'; then
  ok "Case 8: missing --topic → exit 1"
else
  fail_test "Case 8: expected exit 1 on missing --topic; rc=$RC out=$OUT"
fi

# ---------- Summary ----------
echo ""
echo "=== cj-task-scaffold.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
