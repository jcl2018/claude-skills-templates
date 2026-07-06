#!/usr/bin/env bash
# tests/goal-task-chain.test.sh — CI-nightly chain drill for the `task` verb's
# DETERMINISTIC helper chain (goal-task topic, CI-nightly point).
#
# Where the CI-push scaffold suite (tests/cj-task-scaffold.test.sh) probes the
# scaffolder's gate/dry-run/idempotency cases in isolation, this drill drives
# the task verb's helper chain END TO END in ONE hermetic temp sandbox — a REAL
# worktree is created, the REAL bash scaffolder mints a T-ID work-item inside
# it, and the land-tail seams run in pipeline order. Heavier than the per-PR
# budget, so it is registered in scripts/test.sh UNDER the TEST_FAST=1 guard
# (the test-deploy pattern): the per-PR gate (validate.yml, TEST_FAST=1) SKIPs
# it; the nightly full suite (.github/workflows/nightly.yml, no flag) runs it.
#
# Chain steps (the /CJ_goal_task pipeline's deterministic seams, in order):
#   (1) cj-worktree-init.sh --caller task (REAL run) → state=created,
#       cj-task-* branch, worktree dir exists (the worktree entry)
#   (2) skills/CJ_goal_task/scripts/cj-task-scaffold.sh --topic "<small task>"
#       --repo <worktree> (REAL run) → CJ_TASK_RESULT=ok handoff, a T-ID is
#       minted (T[0-9]{6}), the work-item dir exists with <TID>_TRACKER.md
#       (frontmatter `type: "task"`) + test-plan.md — the no-design bash
#       scaffold that replaces /office-hours on the task path
#   (3) cj-goal-common.sh --phase recap --mode task --when after → the at-PR
#       3-part recap: "=== Landed / PR opened ===" header + the three labelled
#       sections rendered verbatim, PHASE_RESULT=ok (the task verb's PR-stop
#       recap, F000068)
#   (4) scripts/cj-worktree-cleanup.sh --dry-run → RESULT in {ok, skipped},
#       mutates NOTHING (the worktree + scaffolded work-item still exist)
#
# Hermetic: everything runs in a mktemp git sandbox that stages the two real
# task templates (the cj-task-scaffold.test.sh idiom); no real repo, ~/.claude,
# or network mutation. The /CJ_goal_task skill (agent prose) is never invoked —
# helper SCRIPTS are the deterministic ceiling.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
WT_HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"
SCAFFOLD="$REPO_ROOT/skills/CJ_goal_task/scripts/cj-task-scaffold.sh"
CLEANUP_HELPER="$REPO_ROOT/scripts/cj-worktree-cleanup.sh"

for h in "$WT_HELPER" "$COMMON" "$SCAFFOLD" "$CLEANUP_HELPER"; do
  [ -x "$h" ] || { echo "FAIL: $h not executable"; exit 1; }
done

# Hermetic sandbox: a fresh throwaway git repo staging the REAL task templates
# (the cj-task-scaffold.test.sh idiom) so the scaffolder resolves them in-repo.
SBX=$(mktemp -d -t goal-task-chain.XXXXXX)
cleanup() {
  if [ -n "${SBX:-}" ] && [ -d "$SBX" ]; then
    (cd "$SBX" 2>/dev/null && git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
      [ "$wt" != "$SBX" ] && git worktree remove --force "$wt" 2>/dev/null || true
    done) || true
    rm -rf "$SBX"
  fi
}
trap cleanup EXIT
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

# || true: under `set -euo pipefail` a no-match grep would otherwise kill the
# drill on a bare `VAR=$(getkey ...)` assignment — return empty instead.
getkey() { printf '%s\n' "$2" | grep "^$1=" | head -1 | cut -d= -f2- || true; }

# ---------- Step 1: worktree entry (REAL) — --caller task → cj-task-* ----------

echo ""
echo "Step 1: cj-worktree-init.sh --caller task (REAL) → state=created, cj-task-* worktree..."
OUT=$(cd "$SBX" && bash "$WT_HELPER" --caller task 2>/dev/null | tail -1)
STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
WT_PATH=$(echo "$OUT" | jq -r '.path' 2>/dev/null || echo "")
if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-task-[0-9]{8}-[0-9]{6}-[0-9]+$' && [ -d "$WT_PATH" ]; then
  ok "Step 1: state=created branch=$BRANCH, worktree dir exists (real task worktree entry)"
else
  fail_test "Step 1: expected a REAL created cj-task-* worktree; got: $OUT"
fi

# The scaffold targets the WORKTREE (the pipeline scaffolds inside the isolated
# checkout, never the main checkout). The worktree shares the sandbox's staged
# templates via its own checked-out tree? No — `git worktree add` checks out the
# committed tree, and the templates were staged UNCOMMITTED. Stage them in the
# worktree too so the scaffolder's in-repo template probe resolves.
if [ -d "$WT_PATH" ]; then
  mkdir -p "$WT_PATH/templates/CJ_personal-workflow" "$WT_PATH/work-items/tasks"
  cp "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" "$WT_PATH/templates/CJ_personal-workflow/"
  cp "$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md" "$WT_PATH/templates/CJ_personal-workflow/"
fi

# ---------- Step 2: cj-task-scaffold.sh (REAL) → T-ID mint + type: task shape ----------

echo ""
echo "Step 2: cj-task-scaffold.sh --topic (REAL) in the worktree → T-ID mint + type: task work-item shape..."
TOPIC="tidy the chain-drill scratch note"
OUT=$(bash "$SCAFFOLD" --topic "$TOPIC" --repo "$WT_PATH" 2>&1) && RC=0 || RC=$?
WID=$(getkey WORK_ITEM_DIR "$OUT")
TID=$(getkey T_ID "$OUT")
if [ "$RC" -eq 0 ] && [ "$(getkey CJ_TASK_RESULT "$OUT")" = "ok" ] \
   && echo "$TID" | grep -qE '^T[0-9]{6}$' \
   && [ -f "$WT_PATH/$WID/${TID}_TRACKER.md" ] \
   && [ -f "$WT_PATH/$WID/test-plan.md" ] \
   && grep -qE '^type: *"?task"?' "$WT_PATH/$WID/${TID}_TRACKER.md" \
   && grep -qF "$TOPIC" "$WT_PATH/$WID/${TID}_TRACKER.md"; then
  ok "Step 2: scaffold ok — $TID minted at $WID (TRACKER with type: task + test-plan.md + topic present)"
else
  fail_test "Step 2: expected CJ_TASK_RESULT=ok + T-ID + type: task work-item shape; got rc=$RC wid=$WID tid=$TID: $OUT"
fi

# ---------- Step 3: --phase recap --mode task --when after → the at-PR recap ----------

echo ""
echo "Step 3: cj-goal-common.sh --phase recap --mode task --when after → header + 3 labelled sections, PHASE_RESULT=ok..."
OUT=$(bash "$COMMON" --phase recap --mode task --when after \
  --field "delivered=task chain delivered line" \
  --field "e2e=task chain e2e line" \
  --field "next=task chain next line" 2>/dev/null) && RC=0 || RC=$?
if [ "$RC" -eq 0 ] && [ "$(getkey PHASE "$OUT")" = "recap" ] && [ "$(getkey MODE "$OUT")" = "task" ] \
   && [ "$(getkey WHEN "$OUT")" = "after" ] && [ "$(getkey PHASE_RESULT "$OUT")" = "ok" ] \
   && echo "$OUT" | grep -qF "=== Landed / PR opened ===" \
   && echo "$OUT" | grep -qF "Delivered:" && echo "$OUT" | grep -qF "task chain delivered line" \
   && echo "$OUT" | grep -qF "How to E2E-test it:" && echo "$OUT" | grep -qF "task chain e2e line" \
   && echo "$OUT" | grep -qF "Next step:" && echo "$OUT" | grep -qF "task chain next line"; then
  ok "Step 3: at-PR recap renders the AFTER header + all three sections verbatim, PHASE_RESULT=ok"
else
  fail_test "Step 3: expected the 3-part AFTER recap; got rc=$RC: $OUT"
fi

# ---------- Step 4: cj-worktree-cleanup.sh --dry-run → previews, mutates nothing ----------

echo ""
echo "Step 4: cj-worktree-cleanup.sh --dry-run → RESULT in {ok,skipped}, worktree + work-item untouched..."
OUT=$(cd "$SBX" && bash "$CLEANUP_HELPER" --dry-run --caller task 2>/dev/null) && RC=0 || RC=$?
CRES=$(getkey RESULT "$OUT")
if [ "$RC" -eq 0 ] && { [ "$CRES" = "ok" ] || [ "$CRES" = "skipped" ]; } \
   && [ -d "$WT_PATH" ] && [ -f "$WT_PATH/$WID/${TID}_TRACKER.md" ]; then
  ok "Step 4: dry-run janitor exits 0 (RESULT=$CRES); worktree + scaffolded work-item still exist (no mutation)"
else
  fail_test "Step 4: expected exit 0 + RESULT in {ok,skipped} + untouched worktree/work-item; got rc=$RC: $OUT"
fi

# ---------- Summary ----------

echo ""
echo "=== goal-task-chain.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
