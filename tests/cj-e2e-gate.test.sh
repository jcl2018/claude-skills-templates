#!/usr/bin/env bash
# tests/cj-e2e-gate.test.sh — deterministic verdict-matrix test for the cj_goal
# local-E2E build-gate auto-answer seam helper (scripts/cj-e2e-gate.sh).
#
# F000071 Part A / S000120. The seam is dormant unless a DOUBLE hard guard holds
# (CJ_GOAL_E2E_AUTO=1 AND a .cj-e2e-sandbox marker at the repo root) AND the gate
# id is in the hardcoded allowlist {design-gate, qa-audit}. The qa-audit
# auto-continue reuses todo_fix --quiet's green-only predicate (continue ONLY on
# doc:ok,test:ok; ANY findings → halt; never auto-waive). NO Claude — pure shell.
#
# Verdict matrix asserted:
#   (1) flag set, NO marker                       → inactive
#   (2) marker present, NO flag                    → inactive
#   (3) both guards + green digest, gate qa-audit  → continue
#   (4) both guards + findings digest, gate qa-audit → halt (doc findings)
#   (5) both guards + findings digest, gate qa-audit → halt (test findings)
#   (6) both guards + empty digest, gate qa-audit  → halt (not green ⇒ never waive)
#   (7) both guards + a non-allowlisted gate id (ship) → inactive
#   (8) both guards + green digest, gate design-gate → continue (feature-only)
#   (9) neither guard, gate qa-audit               → inactive
#
# Sandbox: each case runs in a throwaway temp git repo so the helper's
# `git rev-parse --show-toplevel` marker probe resolves against the temp tree,
# not the real workbench checkout. The helper is copied into the sandbox so the
# repo root it discovers is the sandbox root.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER_SRC="$REPO_ROOT/scripts/cj-e2e-gate.sh"

[ -x "$HELPER_SRC" ] || { echo "FAIL: $HELPER_SRC not found or not executable"; exit 1; }

# ---------- sandbox builder ----------
SBX=""
mk_sandbox() {
  SBX=$(mktemp -d -t cj-e2e-gate.XXXXXX)
  (
    cd "$SBX"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
  )
  cp "$HELPER_SRC" "$SBX/cj-e2e-gate.sh"
  chmod +x "$SBX/cj-e2e-gate.sh"
}
rm_sandbox() { [ -n "$SBX" ] && rm -rf "$SBX"; SBX=""; }

# Run the helper inside the sandbox, returning its single verdict line.
# $1 = "1" to set CJ_GOAL_E2E_AUTO=1 (else unset); $2 = "1" to plant the marker;
# remaining args = passed to the helper verbatim.
run_gate() {
  local set_flag="$1" set_marker="$2"; shift 2
  if [ "$set_marker" = "1" ]; then touch "$SBX/.cj-e2e-sandbox"; else rm -f "$SBX/.cj-e2e-sandbox"; fi
  (
    cd "$SBX"
    if [ "$set_flag" = "1" ]; then
      CJ_GOAL_E2E_AUTO=1 bash ./cj-e2e-gate.sh "$@"
    else
      env -u CJ_GOAL_E2E_AUTO bash ./cj-e2e-gate.sh "$@"
    fi
  )
}

assert_verdict() {
  local desc="$1" expected="$2" got="$3"
  if [ "$got" = "AUTO=$expected" ]; then
    ok "$desc → $got"
  else
    fail_test "$desc: expected AUTO=$expected, got '$got'"
  fi
}

mk_sandbox

# (1) flag set, NO marker → inactive
assert_verdict "flag-only (no marker), qa-audit green" inactive \
  "$(run_gate 1 0 --gate qa-audit --digest doc:ok,test:ok)"

# (2) marker present, NO flag → inactive
assert_verdict "marker-only (no flag), qa-audit green" inactive \
  "$(run_gate 0 1 --gate qa-audit --digest doc:ok,test:ok)"

# (3) both guards + green digest, qa-audit → continue
assert_verdict "both guards + green digest, qa-audit" continue \
  "$(run_gate 1 1 --gate qa-audit --digest doc:ok,test:ok)"

# (4) both guards + doc-findings digest, qa-audit → halt
assert_verdict "both guards + doc-findings digest, qa-audit" halt \
  "$(run_gate 1 1 --gate qa-audit --digest doc:findings:2,test:ok)"

# (5) both guards + test-findings digest, qa-audit → halt
assert_verdict "both guards + test-findings digest, qa-audit" halt \
  "$(run_gate 1 1 --gate qa-audit --digest doc:ok,test:findings:1)"

# (6) both guards + empty digest, qa-audit → halt (not green ⇒ never auto-waive)
assert_verdict "both guards + empty digest, qa-audit" halt \
  "$(run_gate 1 1 --gate qa-audit)"

# (7) both guards + a non-allowlisted gate id (ship) → inactive
assert_verdict "both guards + non-allowlisted gate id (ship)" inactive \
  "$(run_gate 1 1 --gate ship --digest doc:ok,test:ok)"

# Belt-and-suspenders: other non-allowlisted ids never match either.
assert_verdict "both guards + non-allowlisted gate id (merge)" inactive \
  "$(run_gate 1 1 --gate merge --digest doc:ok,test:ok)"
assert_verdict "both guards + non-allowlisted gate id (land)" inactive \
  "$(run_gate 1 1 --gate land --digest doc:ok,test:ok)"

# (8) both guards + green digest, design-gate → continue (feature-only, no digest)
assert_verdict "both guards, design-gate (no digest)" continue \
  "$(run_gate 1 1 --gate design-gate)"

# (9) neither guard, qa-audit → inactive
assert_verdict "neither guard, qa-audit green" inactive \
  "$(run_gate 0 0 --gate qa-audit --digest doc:ok,test:ok)"

# Output well-formedness: the helper prints EXACTLY one AUTO=<verdict> line.
_LINES=$(run_gate 1 1 --gate qa-audit --digest doc:ok,test:ok | wc -l | tr -d ' ')
if [ "$_LINES" = "1" ]; then
  ok "helper prints exactly one verdict line"
else
  fail_test "helper printed $_LINES lines, expected exactly 1"
fi

rm_sandbox

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "cj-e2e-gate.test.sh: ALL PASS"
  exit 0
else
  echo "cj-e2e-gate.test.sh: $ERRORS FAILURE(S)"
  exit 1
fi
