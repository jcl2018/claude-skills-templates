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

if [ "$FAIL" = 0 ]; then
  echo "PASS: 5-row idempotency table fully declared in pipeline.md + SKILL.md"
fi
exit $FAIL
