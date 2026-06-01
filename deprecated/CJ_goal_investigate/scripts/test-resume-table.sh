#!/usr/bin/env bash
# Smoke test S3 — 5-row idempotency resume table contract.
#
# Validates that pipeline.md's Step 3 declares all 5 canonical (R, F, P, M)
# combinations and that SKILL.md's resume-table section enumerates the same
# 5 rows.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE_MD="$SKILL_DIR/pipeline.md"
SKILL_MD="$SKILL_DIR/SKILL.md"

[ -f "$PIPELINE_MD" ] || { echo "FAIL: pipeline.md not found"; exit 1; }
[ -f "$SKILL_MD" ] || { echo "FAIL: SKILL.md not found"; exit 1; }

FAIL=0

# Check each of the 5 RESUME_ROW values is assigned in pipeline.md Step 3
for row in 1 2 3 4 5; do
  if ! grep -qE "RESUME_ROW=$row" "$PIPELINE_MD"; then
    echo "FAIL: pipeline.md missing RESUME_ROW=$row assignment"
    FAIL=1
  fi
done

# Check SKILL.md resume table has 5 rows: count `^| [1-5]   |` style lines
ROW_COUNT=$(grep -cE '^\| [1-5]   \|' "$SKILL_MD" || echo 0)
if [ "$ROW_COUNT" -ne 5 ]; then
  echo "FAIL: SKILL.md resume table has $ROW_COUNT rows, expected 5"
  FAIL=1
fi

# ---------------------------------------------------------------------------
# v1.1 — zero-match draft capture + promote (S000055). Structural contract
# assertions: the binding C1-C7 implementation contract + the 13th end-state
# must be present in pipeline.md / SKILL.md. Same grep-based assertion style
# as the 5-row table check above (this harness asserts the doc-as-contract,
# not behavioral execution — see TEST-SPEC S1-S10).
# ---------------------------------------------------------------------------

# S1 (AC-1): zero-match 0) body creates a NON-CANONICAL .inbox draft, not a halt.
if ! grep -qE 'INBOX="\$DEFECTS_ROOT/\.inbox"' "$PIPELINE_MD"; then
  echo "FAIL: S1/AC-1 — pipeline.md Step 2 0) body missing .inbox draft-dir creation"
  FAIL=1
fi
if grep -qE '^\s*echo "Halt: no defect matches' "$PIPELINE_MD"; then
  echo "FAIL: S1/AC-1 — pipeline.md still has the v1.0 zero-match 'Halt: no defect matches' (should be replaced by draft capture)"
  FAIL=1
fi

# S2/E1 (AC-2, AC-7 / C5): existing-draft branch echoes the stored fragment.
if ! grep -qE 'STORED_FRAGMENT=' "$PIPELINE_MD"; then
  echo "FAIL: S2/AC-7 (C5) — pipeline.md draft-resume branch does not echo the stored fragment"
  FAIL=1
fi

# S3 (AC-3 / C1): the post-case TRACKER/RCA_PATH/TEST_PLAN_PATH recompute is
# guarded by an IS_DRAFT check so the draft vars are not clobbered.
if ! grep -qE 'if \[ "\$\{IS_DRAFT:-0\}" != "1" \]; then' "$PIPELINE_MD"; then
  echo "FAIL: S3/AC-3 (C1) — pipeline.md missing the IS_DRAFT!=1 guard around the post-case TRACKER/RCA_PATH/TEST_PLAN_PATH recompute"
  FAIL=1
fi

# S4 (AC-4 / C2): every Step 7 halt resume_cmd uses the fragment, not an empty
# $DEFECT_ID, for drafts. Assert the shared C2 contract block is present.
if ! grep -qE 'resume_cmd=/CJ_goal_investigate "\$DRAFT_FRAGMENT"' "$PIPELINE_MD"; then
  echo "FAIL: S4/AC-4 (C2) — pipeline.md missing the fragment-based resume_cmd for the draft halt path"
  FAIL=1
fi

# S5 (AC-5 / C3): atomic promotion — DRAFT_OLD captured first, canonical
# TRACKER written as the durable commit point before rm -rf of the draft.
if ! grep -qE 'DRAFT_OLD="\$DEFECT_DIR"' "$PIPELINE_MD"; then
  echo "FAIL: S5/AC-5 (C3) — pipeline.md Step 7.4 missing DRAFT_OLD capture before rebind"
  FAIL=1
fi
if ! grep -qE 'rm -rf "\$DRAFT_OLD" 2>/dev/null' "$PIPELINE_MD"; then
  echo "FAIL: S5/AC-5 (C3) — pipeline.md Step 7.4 missing the executable rm -rf of the saved DRAFT_OLD path"
  FAIL=1
fi
# Durable-commit-point ordering: the canonical TRACKER write must appear
# BEFORE the rm -rf of the draft within pipeline.md. Match the ACTUAL code
# lines (heredoc `<<TRK` for the TRACKER write; the `2>/dev/null`-suffixed
# executable form for the rm) — NOT the backtick-wrapped prose mentions of
# `rm -rf "$DRAFT_OLD"` in the C3 contract description above the snippet.
TRK_LINE=$(grep -n 'cat > "\$CANON_DIR/\${DEFECT_ID}_TRACKER.md" <<TRK' "$PIPELINE_MD" | head -1 | cut -d: -f1)
RM_LINE=$(grep -n 'rm -rf "\$DRAFT_OLD" 2>/dev/null' "$PIPELINE_MD" | head -1 | cut -d: -f1)
if [ -z "$TRK_LINE" ] || [ -z "$RM_LINE" ] || [ "$TRK_LINE" -ge "$RM_LINE" ]; then
  echo "FAIL: S5/AC-5 (C3) — canonical TRACKER write (line ${TRK_LINE:-?}) must precede rm -rf draft (line ${RM_LINE:-?}) — durable commit point order"
  FAIL=1
fi

# S6 (AC-5 / C3): crash-before-TRACKER leaves a harmless non-duplicate orphan;
# the highest-N scan counts it. Assert the highest-N allocation is inside the
# mkdir-lock (the LOCK_DIR mkdir precedes the HIGHEST find).
if ! grep -qE 'LOCK_DIR="\$DEFECTS_ROOT/\.scaffold\.lock\.d"' "$PIPELINE_MD"; then
  echo "FAIL: S6/AC-5 (C3) — pipeline.md Step 7.4 missing the mkdir-based D-ID allocation lock"
  FAIL=1
fi

# S7 (AC-10): --dry-run on a zero-match fragment prints the plan + the pinned
# C7 dry-run message and writes nothing (exit 0 before the create branch).
if ! grep -qE 'DRY RUN: writes nothing\. Re-running the same phrase' "$PIPELINE_MD"; then
  echo "FAIL: S7/AC-10 — pipeline.md 0) body missing the pinned C7 --dry-run no-side-effects message"
  FAIL=1
fi

# S8 (AC-6 / C4): lock-timeout halt has full bookkeeping — [promote-lock-timeout]
# journal marker + the 13th end-state in pipeline.md AND SKILL.md.
if ! grep -qE '\[promote-lock-timeout\]' "$PIPELINE_MD"; then
  echo "FAIL: S8/AC-6 (C4) — pipeline.md Step 7.4 missing the [promote-lock-timeout] journal entry"
  FAIL=1
fi
if ! grep -qE 'halted_at_promote_lock_timeout' "$SKILL_MD"; then
  echo "FAIL: S8/AC-6 (C4) — SKILL.md halt-taxonomy table missing the 13th end-state halted_at_promote_lock_timeout"
  FAIL=1
fi

# S9 (AC-8 / C6): the slug-isolation lowercasing comment is present in the
# Step 2 0) body (load-bearing for resolver isolation).
if ! grep -qiE 'load-bearing' "$PIPELINE_MD"; then
  echo "FAIL: S9/AC-8 (C6) — pipeline.md 0) body missing the load-bearing slug-lowercasing comment"
  FAIL=1
fi

# S10 (AC-12): the canonical TRACKER carries the two promotion frontmatter
# keys; the validator is pass-through (no manifest change). Assert both keys
# appear in the Step 7.4 TRACKER heredoc.
if ! grep -qE '^auto_scaffolded: true' "$PIPELINE_MD"; then
  echo "FAIL: S10/AC-12 — pipeline.md Step 7.4 canonical TRACKER missing auto_scaffolded frontmatter key"
  FAIL=1
fi
if ! grep -qE '^promoted_from_draft: \.inbox/' "$PIPELINE_MD"; then
  echo "FAIL: S10/AC-12 — pipeline.md Step 7.4 canonical TRACKER missing promoted_from_draft frontmatter key"
  FAIL=1
fi

# E4 (AC-13): SKILL.md frontmatter is bumped to 1.1.0 and the ad-hoc-bug
# line is a v1.1 feature (no longer "Out of scope ... (v2.0)").
if ! grep -qE '^version: 1\.1\.0' "$SKILL_MD"; then
  echo "FAIL: E4/AC-13 — SKILL.md frontmatter version not bumped to 1.1.0"
  FAIL=1
fi
if grep -qE 'Ad-hoc bugs without scaffolded defect dir \(v2\.0\)' "$SKILL_MD"; then
  echo "FAIL: E4/AC-13 — SKILL.md still lists ad-hoc bugs as out-of-scope (v2.0); should be a v1.1 feature"
  FAIL=1
fi

if [ "$FAIL" = 0 ]; then
  echo "PASS: 5-row idempotency table + v1.1 zero-match draft/promote contract (C1-C7, S1-S10, 13th end-state) fully declared in pipeline.md + SKILL.md"
fi
exit $FAIL
