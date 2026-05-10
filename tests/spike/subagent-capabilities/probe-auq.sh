#!/usr/bin/env bash
# probe-auq.sh — S000026 leg (a)
# Goal: Verify whether AskUserQuestion calls inside an Agent subagent reach the
# human user, or whether they fail / hang / auto-cancel.
#
# Why operator-driven: claude -p (headless mode) has no interactive human to
# bubble to, so the question fundamentally requires a live Claude Code session.
# This script prints a prompt the operator pastes into a fresh session and a
# rubric for classifying behavior. --try-headless additionally probes claude -p
# as a secondary signal.
#
# Usage:
#   tests/spike/subagent-capabilities/probe-auq.sh
#   tests/spike/subagent-capabilities/probe-auq.sh --try-headless

set -euo pipefail

cat <<'EOF'
================================================================================
PROBE: AUQ bubble through Agent subagents (S000026 leg a)
================================================================================

GOAL
  Determine whether AskUserQuestion calls executed inside an Agent subagent
  reach the human user (the parent Claude Code session's operator), or whether
  they fail / hang / auto-cancel.

WHY IT MATTERS
  /personal-pipeline (F000014) Phase 2 needs sensitive-surface AUQs to surface
  to the human. If AUQs do bubble, the orchestrator can dispatch the implement
  subagent and let it AUQ directly. If not, the orchestrator must either
  pre-collect potential AUQs from the SPEC before dispatch, or instruct the
  subagent to return RESULT: AUQ_NEEDED=... and exit so the orchestrator
  re-AUQs to the human.

INSTRUCTIONS (operator-driven)
  1. Open a fresh Claude Code session (any project; no sticky context needed).
  2. Paste the prompt below verbatim and submit.
  3. Observe the behavior. Classify per the rubric.

PROMPT TO PASTE
  ----------------------------------------------------------------------------
  Use the Agent tool to spawn a general-purpose subagent. The subagent's task
  is to call AskUserQuestion with this exact question and two options:

    Question: "AUQ-bubble probe: does this question reach you?"
    Options:
      A) "Yes, I see this AUQ"
      B) "No (escape — but I can see this option only because the AUQ surfaced)"

  After the subagent finishes (or errors), report back to me:
    - Whether the AUQ visibly surfaced to me (the parent session's operator)
    - Whether the subagent ran to completion or errored / hung
    - The final assistant message from the subagent
  ----------------------------------------------------------------------------

CLASSIFICATION RUBRIC
  Record exactly one verdict line in findings.md:

    VERDICT: AUQ_BUBBLES=yes
      The AUQ appeared in your session. You picked an option. Subagent
      received your answer. Design as-is.

    VERDICT: AUQ_BUBBLES=no SUBCLASS=hang
      Subagent never returned. Parent session sat waiting indefinitely.
      Redesign Phase 2: pre-collect potential AUQs at orchestrator level.

    VERDICT: AUQ_BUBBLES=no SUBCLASS=error
      Subagent (or parent) reported an error / tool unavailable when AUQ
      was attempted. Same redesign as 'hang'.

    VERDICT: AUQ_BUBBLES=no SUBCLASS=auto-cancel
      Subagent received an auto-cancel / null answer and proceeded
      without you. WORST case — implies sensitive-surface work could
      proceed without operator gate. Redesign Phase 2 + enforce
      AUQ_NEEDED=... return contract on the subagent prompt.
EOF

if [[ "${1:-}" == "--try-headless" ]]; then
  echo
  echo "Running secondary headless probe via claude -p..."
  echo "  (claude -p has no interactive human; this tests how AUQ-from-subagent"
  echo "   degrades when there is nothing to bubble to.)"
  echo
  HEADLESS_PROMPT='Use the Agent tool to spawn a general-purpose subagent. The subagent should call AskUserQuestion with question "headless probe: AUQ" and options "A" / "B". Report back what happened.'
  if command -v claude >/dev/null 2>&1; then
    set +e
    OUTPUT=$(timeout 60 claude -p "$HEADLESS_PROMPT" 2>&1)
    EXIT=$?
    set -e
    echo "----- claude -p output (exit=$EXIT) -----"
    echo "$OUTPUT"
    echo "----- end output -----"
    echo
    echo "Secondary signal (interpret in findings.md):"
    if [[ $EXIT -eq 124 ]]; then
      echo "  HEADLESS: timeout (60s). Suggests AUQ in subagent hangs even in headless mode."
    elif [[ $EXIT -ne 0 ]]; then
      echo "  HEADLESS: error (exit $EXIT). Suggests AUQ-in-subagent surfaces an error in -p mode."
    else
      echo "  HEADLESS: completed cleanly. Inspect output above to see how AUQ degraded."
    fi
  else
    echo "  claude command not on PATH; skipping headless probe."
  fi
else
  echo
  echo "  (re-run with --try-headless to additionally probe \`claude -p\` behavior)"
fi

echo
echo "================================================================================"
echo "Next: paste the verdict line into tests/spike/subagent-capabilities/findings.md"
echo "      under '## Leg (a): AUQ bubble' and proceed to probe-result.sh."
echo "================================================================================"
