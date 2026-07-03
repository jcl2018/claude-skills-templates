#!/usr/bin/env bash
# tests/audit-nightly.test.sh — deterministic half of the nightly doc/test audit
# runner (scripts/audit-nightly.sh, F000076). NO Claude, NO network: the model
# call and gh are stubbed on PATH, so this runs in a normal test.sh with no spend.
#
# Asserts:
#   (1) no ANTHROPIC_API_KEY            → SKIP + exit 0 (a normal run never spends)
#   (2) --dry-run (guards satisfied)    → prints the plan, spends nothing, exit 0
#   (3) unknown arg                     → exit 2
#   (4) findings parse + report emit    → AUDIT_NIGHTLY: doc:N,test:M; report written
#   (5) clean digest, no open issue     → issue=none-clean, gh never creates
#   (6) findings, no open issue         → issue=created (gh issue create called)
#   (7) findings, an open issue exists  → issue=updated#N (gh issue comment called)

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SCRIPT="$REPO_ROOT/scripts/audit-nightly.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT not found"; exit 1; }

TMP=$(mktemp -d -t cj-audit-nightly.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM
BIN="$TMP/bin"; mkdir -p "$BIN"
REPORT="$TMP/report.md"
GH_LOG="$TMP/gh.log"

# --- stub: claude — ignores every flag, emits the canned CLI wrapper JSON whose
#     .result carries the two machine-parsed FINDINGS lines (jq encodes \n back). -
make_claude_stub() {
  local doc="$1" tst="$2"
  cat > "$BIN/claude" <<EOF
#!/usr/bin/env bash
jq -n '{result: "audit done\nDOC_AUDIT_FINDINGS=${doc}\nTEST_AUDIT_FINDINGS=${tst}\n", subtype: "success", is_error: false, total_cost_usd: 0.01}'
EOF
  chmod +x "$BIN/claude"
}

# --- stub: gh — logs each invocation; `issue list` echoes $STUB_EXISTING -------
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "gh \$*" >> "$GH_LOG"
case "\$*" in
  "issue list"*) printf '%s' "\${STUB_EXISTING:-}" ;;
  *) : ;;
esac
exit 0
EOF
chmod +x "$BIN/gh"

# ---------- (1) no key → SKIP ----------
out=$(env -u ANTHROPIC_API_KEY bash "$SCRIPT" 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q '^SKIP:'; then
  ok "no ANTHROPIC_API_KEY → SKIP + exit 0"
else
  fail_test "no-key SKIP: rc=${rc:-?} out='$out'"
fi

# ---------- (2) --dry-run (guards satisfied via stub claude + dummy key) ----------
make_claude_stub 0 0
out=$(PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy bash "$SCRIPT" --dry-run 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q 'DRY-RUN'; then
  ok "--dry-run prints the plan, spends nothing"
else
  fail_test "dry-run: rc=${rc:-?} out='$out'"
fi

# ---------- (3) unknown arg → exit 2 ----------
rc=0; PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy bash "$SCRIPT" --bogus >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then
  ok "unknown argument → exit 2"
else
  fail_test "unknown-arg: expected exit 2, got $rc"
fi

# ---------- (4) findings parse + report emit (no gh) ----------
make_claude_stub 2 0
out=$(PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy AUDIT_REPORT="$REPORT" bash "$SCRIPT" --no-issue 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q '^AUDIT_NIGHTLY: doc:2,test:0 total:2'; then
  ok "findings parsed → AUDIT_NIGHTLY: doc:2,test:0 total:2"
else
  fail_test "parse: rc=${rc:-?} out='$out'"
fi
if [ -f "$REPORT" ] && grep -q 'doc-audit findings:  \*\*2\*\*' "$REPORT"; then
  ok "report file materialized with the parsed counts"
else
  fail_test "report file missing/wrong: $(cat "$REPORT" 2>/dev/null || echo '<none>')"
fi

# ---------- (5) clean digest, no open issue → none-clean, no create ----------
: > "$GH_LOG"
make_claude_stub 0 0
out=$(PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy GH_TOKEN=dummy STUB_EXISTING="" \
      AUDIT_REPORT="$REPORT" bash "$SCRIPT" 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q 'issue=none-clean'; then
  ok "clean digest + no open issue → issue=none-clean"
else
  fail_test "clean: rc=${rc:-?} out='$out'"
fi
if grep -q 'issue create' "$GH_LOG"; then
  fail_test "clean digest must NOT create an issue (gh.log: $(cat "$GH_LOG"))"
else
  ok "clean digest never calls gh issue create"
fi

# ---------- (6) findings, no open issue → created ----------
: > "$GH_LOG"
make_claude_stub 3 1
out=$(PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy GH_TOKEN=dummy STUB_EXISTING="" \
      AUDIT_REPORT="$REPORT" bash "$SCRIPT" 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q 'issue=created'; then
  ok "findings + no open issue → issue=created"
else
  fail_test "create: rc=${rc:-?} out='$out'"
fi
if grep -q 'issue create' "$GH_LOG"; then
  ok "findings path calls gh issue create"
else
  fail_test "findings path did not call gh issue create (gh.log: $(cat "$GH_LOG"))"
fi

# ---------- (7) findings, an open issue exists → updated#N ----------
: > "$GH_LOG"
make_claude_stub 1 0
out=$(PATH="$BIN:$PATH" ANTHROPIC_API_KEY=dummy GH_TOKEN=dummy STUB_EXISTING="42" \
      AUDIT_REPORT="$REPORT" bash "$SCRIPT" 2>&1) && rc=0 || rc=$?
if [ "${rc:-1}" -eq 0 ] && printf '%s\n' "$out" | grep -q 'issue=updated#42'; then
  ok "findings + open issue #42 → issue=updated#42"
else
  fail_test "update: rc=${rc:-?} out='$out'"
fi
if grep -q 'issue comment 42' "$GH_LOG"; then
  ok "findings-with-existing path calls gh issue comment 42"
else
  fail_test "did not comment on the existing issue (gh.log: $(cat "$GH_LOG"))"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "audit-nightly.test.sh: ALL PASS"
  exit 0
else
  echo "audit-nightly.test.sh: $ERRORS FAILURE(S)"
  exit 1
fi
