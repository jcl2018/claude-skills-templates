#!/usr/bin/env bash
# Smoke test S2 — RCA section-heading mapping contract.
#
# Validates that pipeline.md declares the full RCA heading set in the correct
# order. The actual write logic is model-driven (Step 7.5), so this test guards
# the contract spec, not a binary.
#
# Exit 0 on pass, non-zero on fail.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE_MD="$SKILL_DIR/pipeline.md"

[ -f "$PIPELINE_MD" ] || { echo "FAIL: pipeline.md not found at $PIPELINE_MD"; exit 1; }

EXPECTED_HEADINGS=(
  "## Symptom"
  "## Reproduction Steps"
  "## Investigation Trail"
  "## Root Cause"
  "## Affected Components"
  "## Fix Description"
  "## Regression Risk"
)

FAIL=0
LAST_LINE=0
for heading in "${EXPECTED_HEADINGS[@]}"; do
  # Look for the heading literal inside the mapping table. The table format is
  # `... | \`## Heading\` |` (markdown code-quoted heading inside a table cell).
  LINE=$(grep -nF "\`$heading\`" "$PIPELINE_MD" | head -1 | cut -d: -f1)
  if [ -z "$LINE" ]; then
    echo "FAIL: pipeline.md does not declare heading '$heading' in the RCA mapping table"
    FAIL=1
    continue
  fi
  if [ "$LINE" -lt "$LAST_LINE" ]; then
    echo "FAIL: heading '$heading' (line $LINE) appears before previous heading (line $LAST_LINE) — order violated"
    FAIL=1
  fi
  LAST_LINE=$LINE
done

if [ "$FAIL" = 0 ]; then
  echo "PASS: all 7 RCA headings declared in correct order in pipeline.md"
fi
exit $FAIL
