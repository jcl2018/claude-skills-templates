#!/usr/bin/env bash
# probe-result.sh — S000026 leg (b)
# Goal: Verify whether subagents reliably emit a controlled `RESULT: STATUS=ok`
# final line, or whether they tack on prose afterward.
#
# Method: N trials (default 5) via claude -p. Each trial spawns a fresh session
# that uses the Agent tool to dispatch a subagent with a prompt requiring the
# RESULT-line ending. Raw outputs are captured for inspection.
#
# Usage:
#   tests/spike/subagent-capabilities/probe-result.sh
#   tests/spike/subagent-capabilities/probe-result.sh --trials 10

set -euo pipefail

TRIALS=5
if [[ "${1:-}" == "--trials" && -n "${2:-}" ]]; then
  TRIALS="$2"
fi

echo "================================================================================"
echo "PROBE: RESULT-line reliability across $TRIALS trials (S000026 leg b)"
echo "================================================================================"
echo

if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: claude command not on PATH. Cannot run probe."
  exit 2
fi

PROMPT='Use the Agent tool to spawn a general-purpose subagent with this exact task: count the number of files in the current directory using ls and wc, then end your final assistant message with EXACTLY this line and nothing after it: RESULT: STATUS=ok. The line must be the very last line of your response. Do not add any prose, sign-off, or explanation after the RESULT line. After the subagent finishes, report verbatim the subagent final assistant message so I can verify the contract.'

OUT_DIR="tests/spike/subagent-capabilities/raw-outputs"
mkdir -p "$OUT_DIR"

HITS=0
for i in $(seq 1 "$TRIALS"); do
  OUTFILE="$OUT_DIR/trial-$i.txt"
  echo "Trial $i/$TRIALS..."
  set +e
  timeout 180 claude -p "$PROMPT" > "$OUTFILE" 2>&1
  EXIT=$?
  set -e
  if [[ $EXIT -eq 124 ]]; then
    echo "  Trial $i: TIMEOUT (180s). Counted as miss."
    continue
  fi
  if [[ $EXIT -ne 0 ]]; then
    echo "  Trial $i: claude exited non-zero ($EXIT). Counted as miss."
    continue
  fi
  # Lenient hit-check: does the file's last non-blank line match RESULT: STATUS=ok?
  # We cannot easily isolate just the subagent's final message from claude -p
  # output; the parent's final message often re-quotes the subagent's. Treating
  # the very last non-blank line of overall stdout as the parent's final word.
  LAST_LINE=$(grep -v '^$' "$OUTFILE" | tail -1)
  if [[ "$LAST_LINE" == "RESULT: STATUS=ok" ]]; then
    echo "  Trial $i: HIT (last non-blank line matches RESULT: STATUS=ok)"
    HITS=$((HITS + 1))
  else
    echo "  Trial $i: MISS (last non-blank line: '$LAST_LINE')"
  fi
done

echo
echo "================================================================================"
echo "VERDICT: RESULT_LINE_HITS=$HITS/$TRIALS"
echo "================================================================================"
echo
echo "Raw outputs preserved in $OUT_DIR/"
echo
echo "Interpretation guide (record in findings.md):"
echo "  $TRIALS/$TRIALS HITS  -> contract is reliable. Orchestrator parser can use grep -E '^RESULT: '."
echo "  4/5 or fewer HITS   -> parser must be lenient (last-line matching, fenced output, or instruct subagent to wrap)."
echo "  0/5 HITS            -> orchestrator should not depend on a controlled final line. Use tracker journal entries from subagents instead, or a sentinel file."
echo
echo "Next: record the VERDICT line in findings.md under '## Leg (b): RESULT-line reliability'."
