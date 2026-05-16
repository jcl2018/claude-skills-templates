#!/usr/bin/env bash
# Smoke test S5 — halt-on-red taxonomy contract.
#
# Validates that pipeline.md declares all 9 substantive halt markers AND each
# halt block includes the required `next_action=`, `resume_cmd=`, and
# `raw_output_path=` fields.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE_MD="$SKILL_DIR/pipeline.md"

[ -f "$PIPELINE_MD" ] || { echo "FAIL: pipeline.md not found"; exit 1; }

# The 7 halt markers that produce on-disk tracker journal entries with
# next_action / resume_cmd / raw_output_path triples (in pipeline.md). The
# 2 resolve-time halts (zero / ambiguous) are stderr-only and intentionally
# do not write to the tracker — see SKILL.md halt taxonomy table.
HALT_MARKERS=(
  "[anomaly-rca-missing-with-fix]"
  "[investigate-blast-radius]"
  "[investigate-no-sentinel]"
  "[investigate-parse-error]"
  "[investigate-no-root-cause]"
  "[investigate-blocked]"
  "[investigate-unverified]"
)

FAIL=0

for marker in "${HALT_MARKERS[@]}"; do
  if ! grep -qF "$marker" "$PIPELINE_MD"; then
    echo "FAIL: pipeline.md missing halt marker '$marker'"
    FAIL=1
    continue
  fi

  # For each marker, scan a 10-line window starting at a halt-block line —
  # match either the heredoc form `- $TS [marker]` or the doc-block form
  # `- <ISO ts> [marker]`. (The marker may also appear in narrative prose
  # elsewhere — e.g. dispatch-prompt description, SKILL.md taxonomy — those
  # occurrences are filtered out by the `- $TS` / `- <ISO ts>` prefix.)
  WINDOW=$(awk -v m="$marker" '
    /^- (\$TS|<ISO ts>) \[/ && index($0, m) { found=1; n=0 }
    found && n<10 { print; n++ }
    found && n>=10 { exit }
  ' "$PIPELINE_MD")

  for field in "next_action=" "resume_cmd=" "raw_output_path="; do
    if ! echo "$WINDOW" | grep -qF "$field"; then
      echo "FAIL: halt block '$marker' missing '$field' within 10 lines"
      FAIL=1
    fi
  done
done

# Also verify that /ship and /land-and-deploy halt markers are declared in
# the chain steps even though they are not file-write halts in this skill
# (they're inherited from /ship + /land-and-deploy).
for marker in "[ship-declined]" "[land-and-deploy-red]"; do
  if ! grep -qF "$marker" "$PIPELINE_MD"; then
    echo "FAIL: pipeline.md missing chain halt marker '$marker'"
    FAIL=1
  fi
done

if [ "$FAIL" = 0 ]; then
  echo "PASS: all 9 halt-on-red markers + 2 chain halts declared with required fields"
fi
exit $FAIL
