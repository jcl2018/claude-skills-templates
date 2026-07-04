#!/usr/bin/env bash
# tests/cj-goal-doc-sync-wiring.test.sh
#
# Integration-shape regression test for the Step 5.5 doc-sync wiring across
# the 4 cj_goal orchestrators. The wiring is identical-modulo-verb across
# /CJ_goal_feature, /CJ_goal_defect, /CJ_goal_task, and /CJ_goal_todo_fix —
# this test asserts the symmetry mechanically so future edits keep it intact.
#
# F000076 (audit relocated off the inline path; re-homed to on-demand by F000080):
# the orchestrators no longer run an inline post-sync doc/test audit or a QA-audit
# checkpoint — that agent-judged audit now runs on-demand off the build path (the
# former .github/workflows/audit-nightly.yml nightly CI job was removed by F000080).
#
# F000079 (build-gate deterministic-agentic split): the orchestrators also stopped
# running the SLOW inline doc-sync (the /CJ_document-release LLM pass → replaced by
# a deterministic --render-docs regen at Step 5.5) and the agent-judged test-sync
# overlay sweep (QA 8.6a/8.6b, now gated by the DEFER_SYNC dispatch directive). The
# slow agentic doc/test sync defers to the on-demand audit. The canonical build path
# is QA → pre-doc-sync commit → deterministic doc-regen (Step 5.5) → ship. This
# test asserts the "F000079 build-gate deterministic-agentic split" holds
# symmetrically across the 4 orchestrators (it backs the build-gate-no-inline-slow-sync
# behavior; that behavior_coverage row anchors on this exact phrase).
#
# Asserts (9):
#   1. Step 5.5: Doc-sync subsection present in all 4 pipeline.md (H2 or H3)
#   2. [doc-sync-red] halt marker present in all 4 pipeline.md (the halt path)
#   3. [doc-sync-non-doc-write] halt marker present in all 4 pipeline.md
#   4. All 4 SKILL.md halt-taxonomy tables have a [doc-sync-red] row
#      (halt class halted_at_doc_sync)
#   5. All 4 SKILL.md halt-taxonomy tables have a [doc-sync-non-doc-write] row
#      (halt class halted_at_doc_sync_non_doc_write)
#   6. REMOVED-checkpoint guard: NO qa-audit checkpoint machinery remains in any
#      of the 4 pipeline.md or 4 SKILL.md (no halted_at_qa_audit /
#      [qa-audit-declined] / [qa-audit-waived]) — the audit moved to CI-nightly.
#   7. F000079: NO pipeline.md invokes /CJ_document-release on the build path
#      (the slow inline LLM doc-sync is gone).
#   8. F000079: each pipeline.md runs the deterministic --render-docs regen at Step 5.5.
#   9. F000079: all 4 QA dispatches carry DEFER_SYNC: true, AND qa.md gates the
#      8.6a/8.6b agentic sweep on DEFER_SYNC.

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

# 6. REMOVED-checkpoint guard (F000076): the inline QA-audit checkpoint is gone —
# assert none of its markers survive in any of the 4 pipeline.md or 4 SKILL.md.
# The agent-judged audit now runs on-demand off the build path, not inline.
for f in "${PIPELINES[@]}" "${SKILLS[@]}"; do
  rel="${f#"$REPO_ROOT"/}"
  [ -f "$f" ] || continue
  if grep -qE 'halted_at_qa_audit|\[qa-audit-declined\]|\[qa-audit-waived\]' "$f"; then
    fail_test "$rel: stale QA-audit checkpoint marker present (should be removed — audit moved to CI-nightly, F000076)"
  else
    ok "$rel: no inline QA-audit checkpoint machinery (audit relocated to CI-nightly)"
  fi
done

# 7. F000079: NO pipeline invokes /CJ_document-release on the build path — the slow
# inline LLM doc-sync was replaced by the deterministic --render-docs regen. (Prose
# mentions of the name are fine; the INVOCATION verb is what must be gone.)
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  [ -f "$pf" ] || continue
  if grep -qE 'Invoke .*CJ_document-release' "$pf"; then
    fail_test "$rel: still invokes /CJ_document-release on the build path (F000079 replaced it with a deterministic regen)"
  else
    ok "$rel: no inline /CJ_document-release invocation (deterministic doc-regen instead)"
  fi
done

# 8. F000079: each pipeline's Step 5.5 runs the deterministic --render-docs regen.
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  [ -f "$pf" ] || continue
  if grep -qF -- '--render-docs' "$pf"; then
    ok "$rel: Step 5.5 runs the deterministic --render-docs regen"
  else
    fail_test "$rel: missing the deterministic --render-docs regen in Step 5.5 (F000079)"
  fi
done

# 9. F000079: all 4 QA dispatches carry DEFER_SYNC: true, AND qa.md gates the
# 8.6a/8.6b agentic sweep on DEFER_SYNC.
for pf in "${PIPELINES[@]}"; do
  rel="${pf#"$REPO_ROOT"/}"
  [ -f "$pf" ] || continue
  if grep -qF 'DEFER_SYNC: true' "$pf"; then
    ok "$rel: QA dispatch carries DEFER_SYNC: true"
  else
    fail_test "$rel: QA dispatch missing DEFER_SYNC: true (F000079)"
  fi
done
QA_MD="$REPO_ROOT/skills/CJ_qa-work-item/qa.md"
qrel="skills/CJ_qa-work-item/qa.md"
if [ -f "$QA_MD" ] && grep -qF 'DEFER_SYNC' "$QA_MD"; then
  ok "$qrel: gates the 8.6a/8.6b agentic sweep on DEFER_SYNC"
else
  fail_test "$qrel: no DEFER_SYNC gating for the 8.6a/8.6b sweep (F000079)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-goal-doc-sync-wiring"
  exit 0
else
  echo "FAIL: cj-goal-doc-sync-wiring ($ERRORS error(s))"
  exit 1
fi
