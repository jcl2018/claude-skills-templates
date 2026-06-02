#!/usr/bin/env bash
# tests/cj-goal-doc-sync-wiring.test.sh
#
# Integration-shape regression test for the F000036 Step 5.5 wiring across
# the 3 cj_goal orchestrators. The wiring is identical-modulo-verb across
# /CJ_goal_feature, /CJ_goal_defect, and /CJ_goal_todo_fix — this test
# asserts the symmetry mechanically so future edits keep it intact.
#
# Asserts (≥5):
#   1. Step 5.5: Doc-sync subsection present in all 3 pipeline.md
#   2. [doc-sync-red] halt marker present in all 3 pipeline.md (the halt path)
#   3. [doc-sync-non-doc-write] halt marker present in all 3 pipeline.md
#   4. All 3 SKILL.md halt-taxonomy tables have a [doc-sync-red] row
#      (halt class halted_at_doc_sync)
#   5. All 3 SKILL.md halt-taxonomy tables have a [doc-sync-non-doc-write] row
#      (halt class halted_at_doc_sync_non_doc_write)
#   6. Row ordering: in all 3 SKILL.md, doc-sync rows appear AFTER the qa row
#      and BEFORE the ship row in the halt-taxonomy table.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

PIPELINES=(
  "$REPO_ROOT/skills/CJ_goal_feature/pipeline.md"
  "$REPO_ROOT/skills/CJ_goal_defect/pipeline.md"
  "$REPO_ROOT/skills/CJ_goal_todo_fix/pipeline.md"
)

SKILLS=(
  "$REPO_ROOT/skills/CJ_goal_feature/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_defect/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md"
)

echo "=== cj-goal-doc-sync-wiring: 3 pipeline.md + 3 SKILL.md halt-taxonomy ==="

# 1. Step 5.5: Doc-sync in every pipeline.md
for pf in "${PIPELINES[@]}"; do
  rel="${pf#$REPO_ROOT/}"
  if [ ! -f "$pf" ]; then
    fail_test "$rel: file missing"
    continue
  fi
  if grep -qE '^### Step 5\.5: Doc-sync' "$pf"; then
    ok "$rel: contains '### Step 5.5: Doc-sync'"
  else
    fail_test "$rel: missing '### Step 5.5: Doc-sync' subsection"
  fi
done

# 2. [doc-sync-red] halt marker in every pipeline.md
for pf in "${PIPELINES[@]}"; do
  rel="${pf#$REPO_ROOT/}"
  [ -f "$pf" ] || continue
  if grep -qF '[doc-sync-red]' "$pf"; then
    ok "$rel: contains [doc-sync-red] halt marker"
  else
    fail_test "$rel: missing [doc-sync-red] halt marker in Step 5.5"
  fi
done

# 3. [doc-sync-non-doc-write] halt marker in every pipeline.md
for pf in "${PIPELINES[@]}"; do
  rel="${pf#$REPO_ROOT/}"
  [ -f "$pf" ] || continue
  if grep -qF '[doc-sync-non-doc-write]' "$pf"; then
    ok "$rel: contains [doc-sync-non-doc-write] halt marker"
  else
    fail_test "$rel: missing [doc-sync-non-doc-write] halt marker in Step 5.5"
  fi
done

# 4. [doc-sync-red] row in every SKILL.md halt-taxonomy table
for sf in "${SKILLS[@]}"; do
  rel="${sf#$REPO_ROOT/}"
  if [ ! -f "$sf" ]; then
    fail_test "$rel: file missing"
    continue
  fi
  if grep -qF '[doc-sync-red]' "$sf" && grep -q 'halted_at_doc_sync' "$sf"; then
    ok "$rel: halt-taxonomy contains halted_at_doc_sync / [doc-sync-red] row"
  else
    fail_test "$rel: halt-taxonomy missing halted_at_doc_sync / [doc-sync-red] row"
  fi
done

# 5. [doc-sync-non-doc-write] row in every SKILL.md halt-taxonomy table
for sf in "${SKILLS[@]}"; do
  rel="${sf#$REPO_ROOT/}"
  [ -f "$sf" ] || continue
  if grep -qF '[doc-sync-non-doc-write]' "$sf" && grep -q 'halted_at_doc_sync_non_doc_write' "$sf"; then
    ok "$rel: halt-taxonomy contains halted_at_doc_sync_non_doc_write / [doc-sync-non-doc-write] row"
  else
    fail_test "$rel: halt-taxonomy missing halted_at_doc_sync_non_doc_write / [doc-sync-non-doc-write] row"
  fi
done

# 6. Row ordering: doc-sync rows appear AFTER qa row and BEFORE ship row WITHIN
# the halt-taxonomy table. SKILL.md files contain BOTH an "Error Handling" table
# AND a "Halt-on-Red Taxonomy" table — the same markers appear in both, so a
# naive first-match grep picks up the Error Handling table's earlier qa/ship
# rows and fails the ordering check incorrectly. The fix: locate the doc-sync
# row, then verify (a) the NEAREST qa row appearing BEFORE it on the same
# (halt-taxonomy) table is qa<doc-sync, and (b) the NEAREST ship row appearing
# AFTER it is doc-sync<ship. Equivalent to "doc-sync sits between a qa and a
# ship row inside the same table region."
for sf in "${SKILLS[@]}"; do
  rel="${sf#$REPO_ROOT/}"
  [ -f "$sf" ] || continue

  DOC_SYNC_LINE=$(grep -n -F '[doc-sync-red]' "$sf" | head -1 | cut -d: -f1)
  if [ -z "$DOC_SYNC_LINE" ]; then
    fail_test "$rel: row ordering check could not locate [doc-sync-red] line"
    continue
  fi

  # Nearest qa row BEFORE doc-sync. Each orchestrator uses a slightly different
  # halt class name (halted_at_qa for feature/defect; halted_at_pipeline_qa for
  # todo_fix), so accept any of the qa-family halt-class names.
  QA_LINE=$(grep -n -E 'halted_at_qa|halted_at_pipeline_qa|halted_at_pipeline_implement' "$sf" \
            | awk -F: -v target="$DOC_SYNC_LINE" '$1 < target {print $1}' | tail -1)

  # Nearest ship row AFTER doc-sync. Look for halted_at_ship (halt-taxonomy
  # table uses that key); the Error Handling table uses [ship-declined] only.
  SHIP_LINE=$(grep -n -E 'halted_at_ship' "$sf" \
              | awk -F: -v target="$DOC_SYNC_LINE" '$1 > target {print $1; exit}')

  if [ -z "$QA_LINE" ] || [ -z "$SHIP_LINE" ]; then
    fail_test "$rel: row ordering check could not locate halt-taxonomy qa-line=$QA_LINE doc-sync-line=$DOC_SYNC_LINE ship-line=$SHIP_LINE"
    continue
  fi

  if [ "$QA_LINE" -lt "$DOC_SYNC_LINE" ] && [ "$DOC_SYNC_LINE" -lt "$SHIP_LINE" ]; then
    ok "$rel: halt-taxonomy row ordering correct (qa@$QA_LINE < doc-sync@$DOC_SYNC_LINE < ship@$SHIP_LINE)"
  else
    fail_test "$rel: halt-taxonomy row ordering wrong (qa@$QA_LINE, doc-sync@$DOC_SYNC_LINE, ship@$SHIP_LINE) — expected qa<doc-sync<ship"
  fi
done

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-goal-doc-sync-wiring"
  exit 0
else
  echo "FAIL: cj-goal-doc-sync-wiring ($ERRORS error(s))"
  exit 1
fi
