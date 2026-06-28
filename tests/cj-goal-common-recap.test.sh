#!/usr/bin/env bash
# tests/cj-goal-common-recap.test.sh
#
# Test for the F000068 / S000112 `--phase recap` formatter in
# scripts/cj-goal-common.sh. Covers TEST-SPEC S1–S4:
#   S1 (core)        — --when before with all three fields renders the header +
#                      Delivered / How to E2E-test it / Next step, each carrying
#                      its field content; PHASE_RESULT=ok; exit 0.
#   S2 (core)        — --when before vs --when after produce DIFFERENT headers;
#                      both keep the three labelled body sections.
#   S3 (resilience)  — omitting a --field renders an EMPTY section and still exits
#                      0 with PHASE_RESULT=ok (fail-soft: no error, no mutation).
#   S4 (integration) — a --field value with spaces / special chars / multiple
#                      lines renders VERBATIM (the telemetry-reused parser prints
#                      content without eval or truncation).
#
# The recap phase is a PURE FORMATTER — it mutates nothing, writes no telemetry,
# and shells out to nothing. So this test is trivially hermetic: it just invokes
# the real script and inspects stdout / exit code. No temp repos, no manifest
# overrides, no ~/.claude touch.
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"

echo "=== cj-goal-common-recap.test.sh: --phase recap (pure formatter) — hermetic ==="

[ -x "$COMMON" ] || { echo "RESULT: FAIL ($COMMON not executable)"; exit 1; }

getkey() { printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -1; }

# Assert a labelled section's body line is present in the output. The block
# renders "Label:" on one line, then the field value on the next; we just check
# the label + the expected body both appear.
assert_contains() {
  local label="$1" needle="$2" out="$3"
  if printf '%s\n' "$out" | grep -qF "$needle"; then
    ok "$label"
  else
    fail_test "$label — expected to find: $needle"
  fi
}

# ── S1: --when before with all three fields renders the 3-part labelled block ──
S1_OUT=$(bash "$COMMON" --phase recap --mode feature --when before \
  --field delivered="DELIVERED_CONTENT_S1" \
  --field e2e="E2E_CONTENT_S1" \
  --field next="NEXT_CONTENT_S1" 2>&1)
S1_RC=$?
if [ "$S1_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$S1_OUT")" = "ok" ] && [ "$(getkey PHASE "$S1_OUT")" = "recap" ]; then
  ok "S1: exit 0, PHASE=recap, PHASE_RESULT=ok"
else
  fail_test "S1: expected exit0/PHASE=recap/PHASE_RESULT=ok (rc=$S1_RC); output: $S1_OUT"
fi
assert_contains "S1: 'Delivered:' label present"          "Delivered:"          "$S1_OUT"
assert_contains "S1: 'How to E2E-test it:' label present" "How to E2E-test it:" "$S1_OUT"
assert_contains "S1: 'Next step:' label present"          "Next step:"          "$S1_OUT"
assert_contains "S1: delivered content rendered"          "DELIVERED_CONTENT_S1" "$S1_OUT"
assert_contains "S1: e2e content rendered"                "E2E_CONTENT_S1"       "$S1_OUT"
assert_contains "S1: next content rendered"               "NEXT_CONTENT_S1"      "$S1_OUT"

# ── S2: --when before vs after → DIFFERENT headers, both keep the 3 sections ──
BEFORE_OUT=$(bash "$COMMON" --phase recap --mode feature --when before \
  --field delivered="d" --field e2e="e" --field next="n" 2>&1)
AFTER_OUT=$(bash "$COMMON" --phase recap --mode feature --when after \
  --field delivered="d" --field e2e="e" --field next="n" 2>&1)

BEFORE_HEADER=$(printf '%s\n' "$BEFORE_OUT" | grep -E '^===' | head -1)
AFTER_HEADER=$(printf '%s\n' "$AFTER_OUT"  | grep -E '^===' | head -1)

if [ -n "$BEFORE_HEADER" ] && [ -n "$AFTER_HEADER" ] && [ "$BEFORE_HEADER" != "$AFTER_HEADER" ]; then
  ok "S2: before/after headers differ (before='$BEFORE_HEADER' after='$AFTER_HEADER')"
else
  fail_test "S2: headers should differ — before='$BEFORE_HEADER' after='$AFTER_HEADER'"
fi
if [ "$(getkey WHEN "$BEFORE_OUT")" = "before" ] && [ "$(getkey WHEN "$AFTER_OUT")" = "after" ]; then
  ok "S2: WHEN key reflects --when (before/after)"
else
  fail_test "S2: WHEN key mismatch — before=$(getkey WHEN "$BEFORE_OUT") after=$(getkey WHEN "$AFTER_OUT")"
fi
# Both keep all three labels.
for _label in "Delivered:" "How to E2E-test it:" "Next step:"; do
  printf '%s\n' "$BEFORE_OUT" | grep -qF "$_label" || fail_test "S2: before block missing label '$_label'"
  printf '%s\n' "$AFTER_OUT"  | grep -qF "$_label" || fail_test "S2: after block missing label '$_label'"
done
ok "S2: both before + after blocks carry all three labelled sections"

# ── S3: omit a --field → empty section, still exit 0 / PHASE_RESULT=ok ────────
# Provide only `delivered`; e2e + next are omitted → their sections render empty.
S3_OUT=$(bash "$COMMON" --phase recap --mode task --when before \
  --field delivered="ONLY_DELIVERED_S3" 2>&1)
S3_RC=$?
if [ "$S3_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$S3_OUT")" = "ok" ]; then
  ok "S3: missing fields → exit 0, PHASE_RESULT=ok (fail-soft)"
else
  fail_test "S3: expected exit0/PHASE_RESULT=ok on missing fields (rc=$S3_RC); output: $S3_OUT"
fi
# The three labels are still ALL present (empty section, not omitted).
for _label in "Delivered:" "How to E2E-test it:" "Next step:"; do
  printf '%s\n' "$S3_OUT" | grep -qF "$_label" || fail_test "S3: label '$_label' should still render even with the field omitted"
done
# The provided field still renders; the omitted ones leave nothing of their own.
assert_contains "S3: provided delivered content still rendered" "ONLY_DELIVERED_S3" "$S3_OUT"
# Confirm the "How to E2E-test it:" label is immediately followed by an empty line
# (the section body is empty). Grab the line after the label and assert it's blank.
E2E_BODY=$(printf '%s\n' "$S3_OUT" | grep -A1 '^How to E2E-test it:$' | sed -n '2p')
if [ -z "$E2E_BODY" ]; then
  ok "S3: omitted e2e field renders an empty section (no body content)"
else
  fail_test "S3: omitted e2e section should be empty, got: '$E2E_BODY'"
fi

# ── S4: special-char / multi-line --field value renders VERBATIM (no eval) ────
# Embed a command substitution, backticks, a $VAR, and a newline. None must be
# evaluated or truncated.
S4_DELIVERED='line-A $(echo SHOULD_NOT_EVAL) `also_not` $HOME_STAYS_LITERAL
line-B after a newline'
S4_OUT=$(bash "$COMMON" --phase recap --mode feature --when after \
  --field delivered="$S4_DELIVERED" \
  --field e2e="cmd --flag='a b c'" \
  --field next="n" 2>&1)
S4_RC=$?
if [ "$S4_RC" -eq 0 ] && [ "$(getkey PHASE_RESULT "$S4_OUT")" = "ok" ]; then
  ok "S4: special-char input → exit 0, PHASE_RESULT=ok"
else
  fail_test "S4: expected exit0/ok on special-char input (rc=$S4_RC); output: $S4_OUT"
fi
# The literal command-substitution text must survive (NOT be replaced by output).
assert_contains "S4: command-substitution text rendered literally" '$(echo SHOULD_NOT_EVAL)' "$S4_OUT"
# Proof of no eval: the WORD "SHOULD_NOT_EVAL" appears, but it must appear INSIDE
# the literal `$(echo SHOULD_NOT_EVAL)` token — never on its own line as output.
if printf '%s\n' "$S4_OUT" | grep -q '^SHOULD_NOT_EVAL$'; then
  fail_test "S4: command substitution was EVALUATED (found a bare 'SHOULD_NOT_EVAL' line)"
else
  ok "S4: command substitution NOT evaluated (no bare output line)"
fi
assert_contains "S4: backticks rendered literally"      '`also_not`'           "$S4_OUT"
assert_contains "S4: \$VAR rendered literally"          '$HOME_STAYS_LITERAL'  "$S4_OUT"
assert_contains "S4: multi-line second line preserved"  'line-B after a newline' "$S4_OUT"

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
