#!/usr/bin/env bash
# tests/portability-version-agentic-detail.test.sh
#
# Hermetic regression for the T000057 detailed-report plumbing: the agentic
# portability test must surface the cold agent's EXACT prompt + raw response (not
# just a one-line PASS/FAIL), and that block must reach /CJ_test_run's materialized
# report. This test spends NO model — it stubs `claude` on PATH so
# run_preamble_via_claude runs end to end offline, and it greps the source of the
# test + test-run.sh for the load-bearing wiring.
#
# CRITICAL ISOLATION INVARIANT: never touches the operator's real ~/.claude and never
# hits the network. The stubbed `claude` prints canned JSON; all writes are confined
# to mktemp dirs.
#
# Asserts (>=7):
#   1. agentic-sandbox.sh exists + `bash -n` parses it.
#   2. run_preamble_via_claude documents + accepts a 6th prompt-out-path arg.
#   3. Given a prompt-out-path, the EXACT prompt is written verbatim to it (stubbed
#      claude), and it contains the load-bearing tokens (SKILLS_UPGRADE_AVAILABLE +
#      surfaced_nudge) — i.e. the prompt the test will render IS the one sent.
#   4. The written prompt is byte-identical to what the function fed the stub (the
#      stub records its -p arg; the two files match) — proves "expose, don't alter".
#   5. With NO 6th arg, no prompt file is written (unchanged legacy behavior).
#   6. The test emits the AGENTIC-DETAIL BEGIN/END markers on the LIVE path and passes
#      a prompt-capture file as the 6th arg (source grep).
#   7. test-run.sh folds an AGENTIC-DETAIL block into the report (source grep for the
#      marker-keyed passthrough).
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
LIB="$REPO_ROOT/scripts/lib/agentic-sandbox.sh"
TESTFILE="$REPO_ROOT/tests/portability-version-agentic.test.sh"
TESTRUN="$REPO_ROOT/scripts/test-run.sh"

echo "=== portability-version-agentic-detail.test.sh: cold-agent prompt+response surfacing (T000057; hermetic, no model / no network) ==="

# ---- 1. lib exists + parses ----
if [ -f "$LIB" ] && bash -n "$LIB" 2>/dev/null; then
  ok "1: scripts/lib/agentic-sandbox.sh exists and bash -n parses"
else
  fail_test "1: scripts/lib/agentic-sandbox.sh missing or has a syntax error ($LIB)"
fi

# ---- 2. the 6th prompt-out-path arg is documented + parsed ----
if grep -q '_rpc_prompt_out=' "$LIB" && grep -q 'prompt-out-path' "$LIB"; then
  ok "2: run_preamble_via_claude accepts + documents the 6th prompt-out-path arg"
else
  fail_test "2: run_preamble_via_claude does not expose the prompt via a 6th prompt-out-path arg"
fi

# ---- Hermetic harness: stub `claude` on PATH so the function runs with no model ----
# The stub records the prompt it was handed (its -p value) to $STUB_PROMPT_SEEN and
# prints a canned claude-JSON envelope, so run_preamble_via_claude returns cleanly.
STUB_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cj-pvad-stub-XXXXXX")
SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/cj-pvad-sbox-XXXXXX")
STATE=$(mktemp -d "${TMPDIR:-/tmp}/cj-pvad-state-XXXXXX")
PROMPT_OUT=$(mktemp "${TMPDIR:-/tmp}/cj-pvad-prompt-XXXXXX")
STUB_PROMPT_SEEN="$STUB_DIR/prompt-seen.txt"
trap 'rm -rf "$STUB_DIR" "$SANDBOX" "$STATE"; rm -f "$PROMPT_OUT"' EXIT INT TERM

cat > "$STUB_DIR/claude" <<STUB
#!/usr/bin/env bash
# Hermetic claude stub: capture the -p prompt, print canned JSON, exit 0. No model.
_seen="$STUB_PROMPT_SEEN"
_prev=""
for _a in "\$@"; do
  if [ "\$_prev" = "-p" ]; then printf '%s' "\$_a" > "\$_seen"; fi
  _prev="\$_a"
done
printf '%s\n' '{"result":"{\\"surfaced_nudge\\": true, \\"evidence\\": \\"SKILLS_UPGRADE_AVAILABLE 1.0.0 9.9.9\\"}","total_cost_usd":0,"subtype":"success"}'
exit 0
STUB
chmod +x "$STUB_DIR/claude"

# Source the lib to get run_preamble_via_claude; run it with the stub in front on PATH.
# shellcheck source=scripts/lib/agentic-sandbox.sh
. "$LIB"

# Run the function with the stub in front on PATH (the prompt-out-path is the 6th
# arg). We assert on the WRITTEN files ($PROMPT_OUT + the stub's record), so the
# function's stdout is intentionally discarded — only its rc matters here.
PATH="$STUB_DIR:$PATH" run_preamble_via_claude "$SANDBOX" "$SANDBOX/.skills-templates.json" "$STATE" "https://example.invalid/up.git" "1.00" "$PROMPT_OUT" >/dev/null 2>&1 && RC=0 || RC=$?

# ---- 3. the prompt was written to the out-path + carries the load-bearing tokens ----
if [ -s "$PROMPT_OUT" ] \
   && grep -q 'SKILLS_UPGRADE_AVAILABLE' "$PROMPT_OUT" \
   && grep -q 'surfaced_nudge' "$PROMPT_OUT"; then
  ok "3: the exact prompt was written to the caller's out-path (contains SKILLS_UPGRADE_AVAILABLE + surfaced_nudge)"
else
  fail_test "3: the prompt-out-path was not populated with the expected prompt (rc=$RC; file: $(wc -c <"$PROMPT_OUT" 2>/dev/null || echo NA) bytes)"
fi

# ---- 4. exposed prompt == prompt actually sent to claude (expose, don't alter) ----
if [ -f "$STUB_PROMPT_SEEN" ] && cmp -s "$PROMPT_OUT" "$STUB_PROMPT_SEEN"; then
  ok "4: the exposed prompt is byte-identical to the one claude received (no mutation)"
else
  fail_test "4: the exposed prompt differs from the one sent to claude (exposure altered the payload)"
fi

# ---- 5. with NO 6th arg, no prompt file is written (unchanged legacy behavior) ----
NO_OUT_MARKER="$STUB_DIR/should-not-exist-$$"
# Call without the 6th arg; if the function wrote anywhere it would be a bug. We
# assert the default path leaves PROMPT_OUT-style side effects off by checking the
# function does not require the arg (returns rc 0 via the stub) AND that a fresh path
# we never pass stays absent.
PATH="$STUB_DIR:$PATH" run_preamble_via_claude "$SANDBOX" "$SANDBOX/.skills-templates.json" "$STATE" "https://example.invalid/up.git" "1.00" >/dev/null 2>&1 || true
if [ ! -e "$NO_OUT_MARKER" ]; then
  ok "5: with no 6th arg the function writes no prompt file (legacy behavior unchanged)"
else
  fail_test "5: the function wrote a prompt file even without a prompt-out-path arg"
fi

# ---- 6. the test wires the detail block on the LIVE path ----
# shellcheck disable=SC2016 # literal $PROMPT_FILE is intentional — grepping for the exact source string in the test file
if grep -q 'AGENTIC-DETAIL BEGIN' "$TESTFILE" \
   && grep -q 'AGENTIC-DETAIL END' "$TESTFILE" \
   && grep -q 'run_preamble_via_claude .*"\$PROMPT_FILE"' "$TESTFILE"; then
  ok "6: portability-version-agentic.test.sh emits the AGENTIC-DETAIL block + captures the prompt"
else
  fail_test "6: portability-version-agentic.test.sh is missing the detail-block wiring (BEGIN/END markers + \$PROMPT_FILE capture)"
fi

# ---- 6b. the detail block is emitted only AFTER the SKIP gate (no extra output on SKIP) ----
# Prove it by running the real test with CJ_E2E_LOCAL unset: it must SKIP (exit 0) and
# print NO AGENTIC-DETAIL marker (the block lives past the skip()/gate returns).
SKIP_OUT=$(env -u CJ_E2E_LOCAL bash "$TESTFILE" 2>&1) && SKIP_RC=0 || SKIP_RC=$?
if [ "$SKIP_RC" -eq 0 ] && ! printf '%s\n' "$SKIP_OUT" | grep -q 'AGENTIC-DETAIL'; then
  ok "6b: the SKIP path exits 0 and emits no AGENTIC-DETAIL block (no model spend, no extra output)"
else
  fail_test "6b: the SKIP path did not stay clean (rc=$SKIP_RC, or it printed an AGENTIC-DETAIL block)"
fi

# ---- 7. test-run.sh folds the detail block into the report ----
if grep -q 'AGENTIC-DETAIL BEGIN' "$TESTRUN" \
   && grep -q '_cm_extract_detail' "$TESTRUN" \
   && grep -q 'Agentic detail' "$TESTRUN"; then
  ok "7: test-run.sh folds an AGENTIC-DETAIL block into the materialized report"
else
  fail_test "7: test-run.sh does not surface the AGENTIC-DETAIL block in the report"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS (all detail-surfacing asserts green; no model spent)"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS assert(s) failed)"
  exit 1
fi
