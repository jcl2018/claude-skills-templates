#!/usr/bin/env bash
# tests/e2e-local.test.sh — deterministic smoke for the local-E2E harness
# (scripts/e2e-local.sh + tests/e2e-local/lib/{sandbox,report}.sh).
#
# F000071 Part B / S000121. This asserts ONLY the harness's DETERMINISTIC half —
# no Claude, no gstack, no API key needed, so it is CI-green:
#   C1  SKIP path — CJ_E2E_LOCAL unset → exit 0, prints SKIP, never reaches claude
#   C2  prereq gate — CJ_E2E_LOCAL=1 but a prerequisite missing → still SKIP (exit 0)
#   C3  sandbox provision — clone + .cj-e2e-sandbox marker + LOCAL bare origin
#   C4  sandbox teardown — the mktemp base is removed
#   C5  report generator (green evidence) — DETERMINISTIC/claude-print rows, all pass, json sibling
#   C6  report generator (missing evidence) — the unbacked rows render `unverified`, not `pass`
#   C7  gitignore posture — reports/ ignored except a tracked EXAMPLE.md
#   C8  auth gate — not logged in + no key → SKIP (fake claude stub)
#   C9  auth gate — ANTHROPIC_API_KEY set → api-key path, no probe, proceeds
#   C10 auth gate — logged-in but the live probe 401s → SKIP (no false pass)
#   C11 auth gate — logged-in + probe ok → claude-login path, proceeds
#
# The REAL /CJ_goal_task run is a LOCAL manual E2E (needs gstack + a claude login
# [ANTHROPIC_API_KEY or `claude auth login`] + gh + budget); it is NOT run here.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HARNESS="$REPO_ROOT/scripts/e2e-local.sh"
SANDBOX_LIB="$REPO_ROOT/tests/e2e-local/lib/sandbox.sh"
REPORT_LIB="$REPO_ROOT/tests/e2e-local/lib/report.sh"

for f in "$HARNESS" "$SANDBOX_LIB" "$REPORT_LIB"; do
  [ -f "$f" ] || { echo "FAIL: missing $f"; exit 1; }
done

echo "== C1: SKIP path (CJ_E2E_LOCAL unset) =="
_c1_out=$(env -u CJ_E2E_LOCAL bash "$HARNESS" 2>&1) && _c1_rc=0 || _c1_rc=$?
if [ "${_c1_rc:-1}" -eq 0 ] && printf '%s' "$_c1_out" | grep -q "SKIP: e2e-local"; then
  ok "flag unset → exit 0 + SKIP line (no claude invoked)"
else
  fail_test "flag unset should SKIP with exit 0; rc=${_c1_rc:-?}, out: $_c1_out"
fi

echo "== C2: prereq gate (flag set, prerequisite missing) =="
_fakehome=$(mktemp -d -t cj-e2e-home.XXXXXX)   # no ~/.claude/skills/gstack here
_c2_out=$(env -u ANTHROPIC_API_KEY CJ_E2E_LOCAL=1 HOME="$_fakehome" bash "$HARNESS" 2>&1) && _c2_rc=0 || _c2_rc=$?
rm -rf "$_fakehome"
if [ "${_c2_rc:-1}" -eq 0 ] && printf '%s' "$_c2_out" | grep -q "SKIP: e2e-local"; then
  ok "flag set + missing prereq → exit 0 + SKIP (never reaches claude)"
else
  fail_test "flag set + missing prereq should SKIP; rc=${_c2_rc:-?}, out: $_c2_out"
fi

echo "== C3/C4: sandbox provision + teardown =="
# A throwaway source repo to clone from.
SRC=$(mktemp -d -t cj-e2e-src.XXXXXX)
(
  cd "$SRC"
  git init -q
  git config user.email "test@test"; git config user.name "test"
  git checkout -q -b main 2>/dev/null || true
  echo "seed" > seed.txt; git add seed.txt; git commit -qm seed
)
# shellcheck source=/dev/null
. "$SANDBOX_LIB"
CLONE=$(e2e_sandbox_provision "$SRC")
if [ -d "$CLONE" ] && [ -f "$CLONE/.cj-e2e-sandbox" ] && [ -d "$(dirname "$CLONE")/origin.git" ]; then
  ok "C3: provision made a clone + .cj-e2e-sandbox marker + a local bare origin"
else
  fail_test "C3: provision incomplete (clone=$CLONE)"
fi
if git -C "$CLONE" remote get-url origin 2>/dev/null | grep -q "origin.git"; then
  ok "C3: clone origin repointed to the local bare origin (no GitHub remote)"
else
  fail_test "C3: clone origin not repointed to the bare origin"
fi
_base=$(dirname "$CLONE")
e2e_sandbox_teardown "$CLONE"
if [ ! -d "$_base" ]; then
  ok "C4: teardown removed the mktemp base"
else
  fail_test "C4: teardown left $_base behind"
  rm -rf "$_base"
fi
rm -rf "$SRC"

echo "== C5: report generator (green evidence → all pass) =="
# shellcheck source=/dev/null
. "$REPORT_LIB"
OUTD=$(mktemp -d -t cj-e2e-rep.XXXXXX)
EVG="$OUTD/ev-green.txt"
cat > "$EVG" <<'EOF'
topic=trivial scratch note
sandbox=/tmp/cj-e2e-x/clone
head_sha=abc1234
end_state=halted_at_ship
task_dir_created=yes
diff_nonempty=yes
branch_pushed=yes
pr_blocked=yes
seam_qa_audit=continue
seam_nonallowlisted=inactive
budget=$8.00
duration=6:00
tokens=123456
EOF
MDG=$(e2e_report_render "$OUTD" "task" "20260630T000000Z" "$EVG")
if [ -f "$MDG" ] && [ -f "${MDG%.md}.json" ]; then
  ok "C5: wrote both a .md and a .json sibling"
else
  fail_test "C5: missing md or json ($MDG)"
fi
if grep -q "DETERMINISTIC" "$MDG" && grep -q "claude --print" "$MDG" && grep -q "## Legend" "$MDG"; then
  ok "C5: report carries the DETERMINISTIC-vs-claude-print rows + legend"
else
  fail_test "C5: report missing the layer labelling / legend"
fi
if grep -q "Result: PASS" "$MDG" && ! grep -qE '\| unverified \|' "$MDG"; then
  ok "C5: green evidence → Result PASS with no unverified rows"
else
  fail_test "C5: green evidence should be all-pass"
fi

echo "== C6: report generator (missing evidence → unverified, not pass) =="
EVM="$OUTD/ev-missing.txt"
cat > "$EVM" <<'EOF'
topic=trivial scratch note
sandbox=/tmp/cj-e2e-y/clone
head_sha=def5678
end_state=
task_dir_created=
diff_nonempty=
branch_pushed=no
pr_blocked=yes
seam_qa_audit=continue
seam_nonallowlisted=inactive
EOF
MDM=$(e2e_report_render "$OUTD" "task" "20260630T111111Z" "$EVM")
if grep -qE '\| unverified \|' "$MDM" && grep -q "Result: INCONCLUSIVE" "$MDM"; then
  ok "C6: absent evidence renders unverified rows + an INCONCLUSIVE result (never a false pass)"
else
  fail_test "C6: missing evidence should yield unverified rows + INCONCLUSIVE result"
fi
rm -rf "$OUTD"

echo "== C7: gitignore posture (reports/ ignored except EXAMPLE.md) =="
if git -C "$REPO_ROOT" check-ignore -q "tests/e2e-local/reports/task-20260630T000000Z.md"; then
  ok "C7: a generated report path is gitignored"
else
  fail_test "C7: generated report path should be gitignored"
fi
if git -C "$REPO_ROOT" check-ignore -q "tests/e2e-local/reports/EXAMPLE.md"; then
  fail_test "C7: EXAMPLE.md must NOT be gitignored (it is the committed sample)"
else
  ok "C7: EXAMPLE.md is tracked (un-ignored) so the format is reviewable"
fi

# ---- C8–C11: the auth gate (fake claude/gh stubs — still no real Claude) ----
# A fake HOME carries a gstack dir so the _missing gate passes; fake claude + gh on
# PATH satisfy the command checks; the fake claude scripts the `auth status` JSON
# and the `-p` probe result so the whole auth matrix is deterministic.
_AUTH_HOME=$(mktemp -d -t cj-e2e-authhome.XXXXXX); mkdir -p "$_AUTH_HOME/.claude/skills/gstack"
_mk_stub_bin() { # $1=dir  $2=loggedIn(true|false)  $3=probe-output
  mkdir -p "$1"
  # Unquoted heredoc: $2/$3 expand from THIS function's args; \$1 \$2 \$* stay
  # literal so they are the stub's own runtime positional args.
  cat > "$1/claude" <<EOF
#!/bin/sh
[ "\$1" = "auth" ] && [ "\$2" = "status" ] && { echo '{"loggedIn": $2}'; exit 0; }
[ "\$1" = "-p" ] && { echo '$3'; exit 0; }
echo "stub-claude unexpected: \$*" >&2; exit 1
EOF
  printf '#!/bin/sh\nexit 0\n' > "$1/gh"
  chmod +x "$1/claude" "$1/gh"
}

echo "== C8: auth — not logged in + no key → SKIP =="
_B8=$(mktemp -d -t cj-e2e-b8.XXXXXX); _mk_stub_bin "$_B8" false "unused"
_c8=$(env -u ANTHROPIC_API_KEY CJ_E2E_LOCAL=1 HOME="$_AUTH_HOME" PATH="$_B8:$PATH" bash "$HARNESS" 2>&1) && _c8rc=0 || _c8rc=$?
if [ "${_c8rc:-1}" -eq 0 ] && printf '%s' "$_c8" | grep -q "no usable claude credentials"; then
  ok "C8: no key + not-logged-in → SKIP 'no usable claude credentials' (exit 0)"
else
  fail_test "C8: expected no-usable-credentials SKIP; rc=${_c8rc:-?} out: $_c8"
fi

echo "== C9: auth — ANTHROPIC_API_KEY set → api-key, no probe, proceeds (dry-run) =="
_c9=$(ANTHROPIC_API_KEY=sk-test CJ_E2E_LOCAL=1 HOME="$_AUTH_HOME" PATH="$_B8:$PATH" bash "$HARNESS" --dry-run 2>&1) && _c9rc=0 || _c9rc=$?
if [ "${_c9rc:-1}" -eq 0 ] && printf '%s' "$_c9" | grep -q "auth: api-key" && printf '%s' "$_c9" | grep -q "DRY-RUN"; then
  ok "C9: ANTHROPIC_API_KEY set → auth: api-key + dry-run (login probe skipped)"
else
  fail_test "C9: expected api-key auth + dry-run; rc=${_c9rc:-?} out: $_c9"
fi

echo "== C10: auth — logged-in but probe 401s → SKIP (no false pass) =="
_B10=$(mktemp -d -t cj-e2e-b10.XXXXXX); _mk_stub_bin "$_B10" true "Failed to authenticate. API Error: 401 Invalid authentication credentials"
_c10=$(env -u ANTHROPIC_API_KEY CJ_E2E_LOCAL=1 HOME="$_AUTH_HOME" PATH="$_B10:$PATH" bash "$HARNESS" 2>&1) && _c10rc=0 || _c10rc=$?
if [ "${_c10rc:-1}" -eq 0 ] && printf '%s' "$_c10" | grep -q "could not authenticate"; then
  ok "C10: logged-in + probe 401 → SKIP 'could not authenticate' (login-status is not trusted blindly)"
else
  fail_test "C10: expected probe-fail SKIP; rc=${_c10rc:-?} out: $_c10"
fi

echo "== C11: auth — logged-in + probe ok → claude-login, proceeds (dry-run) =="
_B11=$(mktemp -d -t cj-e2e-b11.XXXXXX); _mk_stub_bin "$_B11" true "ok"
_c11=$(env -u ANTHROPIC_API_KEY CJ_E2E_LOCAL=1 HOME="$_AUTH_HOME" PATH="$_B11:$PATH" bash "$HARNESS" --dry-run 2>&1) && _c11rc=0 || _c11rc=$?
if [ "${_c11rc:-1}" -eq 0 ] && printf '%s' "$_c11" | grep -q "auth: claude-login" && printf '%s' "$_c11" | grep -q "DRY-RUN"; then
  ok "C11: logged-in + probe ok → auth: claude-login + dry-run (subscription path works)"
else
  fail_test "C11: expected claude-login auth + dry-run; rc=${_c11rc:-?} out: $_c11"
fi
rm -rf "$_AUTH_HOME" "$_B8" "$_B10" "$_B11"

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: tests/e2e-local.test.sh — all deterministic cases green (real run is a local manual E2E)"
  exit 0
else
  echo "FAIL: tests/e2e-local.test.sh — $ERRORS case(s) failed"
  exit 1
fi
