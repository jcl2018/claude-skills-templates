#!/usr/bin/env bash
# tests/cj-goal-doc-sync-wiring.test.sh
#
# Integration-shape regression test for the Step 5.5 doc-sync wiring across
# the 4 cj_goal orchestrators. The wiring is identical-modulo-verb across
# /CJ_goal_feature, /CJ_goal_defect, /CJ_goal_task, and /CJ_goal_todo_fix —
# this test asserts the symmetry mechanically so future edits keep it intact.
#
# F000064 (post-sync-authoritative-audit reorder): doc-sync now runs BEFORE the
# post-sync doc/test audit + the QA-audit checkpoint, so the canonical pipeline
# sequence is QA → pre-doc-sync commit → doc-sync → post-sync audit → QA-audit
# checkpoint → ship. The SOURCE OF TRUTH for the gate order is the
# `gates:` array in spec/test-spec-custom.md (doc-sync order < qa-audit order),
# cross-checked by validate.sh Check 24. This test asserts the DERIVED ordering
# in the orchestrator docs.
#
# Asserts (≥6):
#   1. Step 5.5: Doc-sync subsection present in all 4 pipeline.md (H2 or H3)
#   2. [doc-sync-red] halt marker present in all 4 pipeline.md (the halt path)
#   3. [doc-sync-non-doc-write] halt marker present in all 4 pipeline.md
#   4. All 4 SKILL.md halt-taxonomy tables have a [doc-sync-red] row
#      (halt class halted_at_doc_sync)
#   5. All 4 SKILL.md halt-taxonomy tables have a [doc-sync-non-doc-write] row
#      (halt class halted_at_doc_sync_non_doc_write)
#   6. NEW-ORDER row ordering: in all 4 SKILL.md halt-taxonomy tables, the
#      qa-audit row appears BEFORE the doc-sync row (the table lists gates in
#      run order: qa → qa-audit → doc-sync → ship), AND doc-sync still sits
#      before the ship row.
#   7. NEW-ORDER post-sync semantics: in all 4 SKILL.md, the halted_at_qa_audit
#      row states the audit runs AFTER doc-sync (the F000064 reorder — the
#      checkpoint decides on the POST-sync docs).

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

SKILLS=(
  "$REPO_ROOT/skills/CJ_goal_feature/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_defect/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_task/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md"
)

echo "=== cj-goal-doc-sync-wiring: 4 pipeline.md + 4 SKILL.md halt-taxonomy ==="

# 1. Step 5.5: Doc-sync in every pipeline.md (H2 `##` or H3 `###`)
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  if [ ! -f "$pf" ]; then
    fail_test "$rel: file missing"
    continue
  fi
  if grep -qE '^#+ Step 5\.5: Doc-sync' "$pf"; then
    ok "$rel: contains 'Step 5.5: Doc-sync'"
  else
    fail_test "$rel: missing 'Step 5.5: Doc-sync' subsection"
  fi
done

# 2. [doc-sync-red] halt marker in every pipeline.md
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  [ -f "$pf" ] || continue
  if grep -qF '[doc-sync-red]' "$pf"; then
    ok "$rel: contains [doc-sync-red] halt marker"
  else
    fail_test "$rel: missing [doc-sync-red] halt marker in Step 5.5"
  fi
done

# 3. [doc-sync-non-doc-write] halt marker in every pipeline.md
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  [ -f "$pf" ] || continue
  if grep -qF '[doc-sync-non-doc-write]' "$pf"; then
    ok "$rel: contains [doc-sync-non-doc-write] halt marker"
  else
    fail_test "$rel: missing [doc-sync-non-doc-write] halt marker in Step 5.5"
  fi
done

# 4. [doc-sync-red] row in every SKILL.md halt-taxonomy table
for sf in "${SKILLS[@]}"; do
  rel="${sf#"$REPO_ROOT"/}"
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
  rel="${sf#"$REPO_ROOT"/}"
  [ -f "$sf" ] || continue
  if grep -qF '[doc-sync-non-doc-write]' "$sf" && grep -q 'halted_at_doc_sync_non_doc_write' "$sf"; then
    ok "$rel: halt-taxonomy contains halted_at_doc_sync_non_doc_write / [doc-sync-non-doc-write] row"
  else
    fail_test "$rel: halt-taxonomy missing halted_at_doc_sync_non_doc_write / [doc-sync-non-doc-write] row"
  fi
done

# 6. NEW-ORDER row ordering (F000064): the halt-taxonomy table lists its gate
# rows in canonical run order — qa → qa-audit → doc-sync → ship. After the
# reorder the qa-audit row appears BEFORE the doc-sync row (doc-sync now runs
# before the checkpoint), and doc-sync still appears before the ship row.
#
# SKILL.md files contain BOTH an "Error Handling" table AND a "Halt-on-Red
# Taxonomy" table — the same markers appear in both, so a naive first-match grep
# misfires. The Halt-on-Red Taxonomy table is the one with the halted_at_* halt
# classes (the Error Handling table uses bare [markers] only), so we anchor on
# the halt-class rows: locate the halted_at_doc_sync row, then verify the NEAREST
# halted_at_qa_audit row BEFORE it (same table) and the NEAREST halted_at_ship
# row AFTER it.
for sf in "${SKILLS[@]}"; do
  rel="${sf#"$REPO_ROOT"/}"
  [ -f "$sf" ] || continue

  # Anchor: the doc-sync halt-class row (excludes the _no_config / _non_doc_write
  # variants by requiring an end-of-token boundary right after "doc_sync").
  DOC_SYNC_LINE=$(grep -n -E 'halted_at_doc_sync([^_]|$)' "$sf" | head -1 | cut -d: -f1)
  if [ -z "$DOC_SYNC_LINE" ]; then
    fail_test "$rel: row ordering check could not locate halted_at_doc_sync line"
    continue
  fi

  # Nearest qa-audit row BEFORE doc-sync (the checkpoint now precedes doc-sync in
  # the table's run-order listing).
  QA_AUDIT_LINE=$(grep -n -E 'halted_at_qa_audit' "$sf" \
            | awk -F: -v target="$DOC_SYNC_LINE" '$1 < target {print $1}' | tail -1)

  # Nearest ship row AFTER doc-sync.
  SHIP_LINE=$(grep -n -E 'halted_at_ship' "$sf" \
              | awk -F: -v target="$DOC_SYNC_LINE" '$1 > target {print $1; exit}')

  if [ -z "$QA_AUDIT_LINE" ] || [ -z "$SHIP_LINE" ]; then
    fail_test "$rel: row ordering check could not locate halt-taxonomy qa-audit-line=$QA_AUDIT_LINE doc-sync-line=$DOC_SYNC_LINE ship-line=$SHIP_LINE"
    continue
  fi

  if [ "$QA_AUDIT_LINE" -lt "$DOC_SYNC_LINE" ] && [ "$DOC_SYNC_LINE" -lt "$SHIP_LINE" ]; then
    ok "$rel: halt-taxonomy run-order correct (qa-audit@$QA_AUDIT_LINE < doc-sync@$DOC_SYNC_LINE < ship@$SHIP_LINE)"
  else
    fail_test "$rel: halt-taxonomy run-order wrong (qa-audit@$QA_AUDIT_LINE, doc-sync@$DOC_SYNC_LINE, ship@$SHIP_LINE) — expected qa-audit<doc-sync<ship (F000064 reorder)"
  fi
done

# 7. NEW-ORDER post-sync semantics (F000064): the halted_at_qa_audit row must
# state the audit runs AFTER doc-sync — proving the checkpoint decides on the
# POST-sync docs, not the pre-sync ones. Look for the literal "AFTER doc-sync"
# phrasing on the same line as a POST-sync digest reference.
for sf in "${SKILLS[@]}"; do
  rel="${sf#"$REPO_ROOT"/}"
  [ -f "$sf" ] || continue
  if grep -qiE 'POST-sync.*audit|audit.*AFTER doc-sync|AFTER doc-sync' "$sf"; then
    ok "$rel: halt-taxonomy states the qa-audit checkpoint decides on the POST-sync docs (audit AFTER doc-sync)"
  else
    fail_test "$rel: halt-taxonomy does NOT state the post-sync audit ordering (expected 'POST-sync' / 'AFTER doc-sync' in the halted_at_qa_audit row)"
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
