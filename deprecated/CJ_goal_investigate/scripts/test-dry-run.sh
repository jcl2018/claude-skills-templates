#!/usr/bin/env bash
# Smoke test S4 — --dry-run contract: writes nothing.
#
# Static check on pipeline.md Step 3.5: verifies the dry-run branch is
# documented with "No files written" and "no Agent subagent dispatched"
# clauses. Runtime dry-run behavior is model-driven; this guards the spec.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE_MD="$SKILL_DIR/pipeline.md"

[ -f "$PIPELINE_MD" ] || { echo "FAIL: pipeline.md not found"; exit 1; }

FAIL=0

# Check Step 3.5 exists
if ! grep -q '^## Step 3.5: --dry-run preview branch' "$PIPELINE_MD"; then
  echo "FAIL: pipeline.md missing Step 3.5 --dry-run section"
  FAIL=1
fi

# Check the no-write / no-dispatch contract clauses are present.
# Sentence punctuation varies (period vs semicolon), so match the noun phrase only.
for clause in "No files written" "no Agent subagent dispatched" "no Skill invocations"; do
  if ! grep -qF "$clause" "$PIPELINE_MD"; then
    echo "FAIL: pipeline.md Step 3.5 missing '$clause' contract"
    FAIL=1
  fi
done

if [ "$FAIL" = 0 ]; then
  echo "PASS: --dry-run contract documented in pipeline.md Step 3.5"
fi
exit $FAIL
