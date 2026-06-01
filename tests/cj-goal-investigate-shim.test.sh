#!/usr/bin/env bash
# tests/cj-goal-investigate-shim.test.sh
#
# Regression test for T000035 (v5.0.15, F000027 closure): /CJ_goal_investigate
# retired as a thin alias shim under deprecated/CJ_goal_investigate/. The shim
# contract has 3 load-bearing behaviors that this test asserts via grep against
# the shim source (no Skill-tool runtime — pure static check):
#
#   1. Banner extraction. The shim SKILL.md contains the deprecation banner
#      mirroring the /CJ_goal_run banner shape — `[DEPRECATED]
#      /CJ_goal_investigate is deprecated; use /CJ_goal_defect instead. Sunsets
#      in v6.0.0.`
#
#   2. D-id rejection. The shim contains the D-id regex `^D[0-9]{6}$`
#      (case-insensitive — `-qiE` in the routing block) AND the rejection error
#      message pointing the operator to
#      `skills-deploy install --include-deprecated` for resuming an existing
#      D-id. Without this branch, a bare D-id forwarded to /CJ_goal_defect
#      would be slugged as a description and a NEW D-id minted, corrupting
#      work-item tracking.
#
#   3. Non-D-id delegation. The shim contains a `Skill: CJ_goal_defect` line
#      (the routing block's verbatim delegation pattern used by the other
#      F000027/F000031 shims at deprecated/cj_goal_feature/SKILL.md +
#      deprecated/cj_goal_defect/SKILL.md). Without this, fragments + free-text
#      descriptions have no live route.
#
# The test is pure static grep against the SKILL.md source — no shell
# invocation of the shim runtime, no fixture trees. Mirrors the assertion
# shape used by tests/cj-goal-doc-sync-auq-recommendation.test.sh.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SHIM="$REPO_ROOT/deprecated/CJ_goal_investigate/SKILL.md"

echo "=== cj-goal-investigate-shim: T000035 deprecation shim contract ==="

[ -f "$SHIM" ] || { fail_test "shim SKILL.md missing at deprecated/CJ_goal_investigate/SKILL.md"; echo "FAIL"; exit 1; }

# (1) Deprecation banner present. Must include the literal `[DEPRECATED]`
# prefix + the /CJ_goal_defect replacement + the v6.0.0 sunset target.
if grep -q '\[DEPRECATED\] /CJ_goal_investigate is deprecated; use /CJ_goal_defect instead\. Sunsets in v6\.0\.0\.' "$SHIM"; then
  ok "shim emits deprecation banner (matches /CJ_goal_run + casing-fix shim shape)"
else
  fail_test "shim missing the literal '[DEPRECATED] /CJ_goal_investigate is deprecated; use /CJ_goal_defect instead. Sunsets in v6.0.0.' banner"
fi

# (2a) D-id regex present. Must use ^D[0-9]{6}$ (case-insensitive via -qiE in
# the routing block). The regex is the load-bearing rejection trigger.
if grep -qE '\^D\[0-9\]\{6\}\$' "$SHIM"; then
  ok "shim contains D-id regex ^D[0-9]{6}\$"
else
  fail_test "shim missing D-id regex ^D[0-9]{6}\$ (would let bare D-id args slip through to /CJ_goal_defect and mint a new D-id)"
fi

# (2b) D-id rejection error message present. Must point operator to
# `skills-deploy install --include-deprecated` for resuming an existing D-id
# (the recovery path documented in the design doc Success Criterion #2).
if grep -q 'skills-deploy install --include-deprecated' "$SHIM"; then
  ok "shim names skills-deploy install --include-deprecated recovery path for D-id args"
else
  fail_test "shim missing 'skills-deploy install --include-deprecated' recovery path in rejection error"
fi

# (2c) D-id rejection error text. The verbatim rejection message from the
# design doc Success Criterion #2 — `D-id args cannot be forwarded to
# /CJ_goal_defect (would slug as description and mint a new D-id)`.
if grep -q 'D-id args cannot be forwarded to /CJ_goal_defect' "$SHIM"; then
  ok "shim emits 'D-id args cannot be forwarded to /CJ_goal_defect' rejection text"
else
  fail_test "shim missing 'D-id args cannot be forwarded to /CJ_goal_defect' rejection text"
fi

# (3) Non-D-id delegation to /CJ_goal_defect via the Skill tool. Pattern
# matches the F000027/F000031 shim convention.
if grep -q 'Skill: CJ_goal_defect' "$SHIM"; then
  ok "shim delegates non-D-id args to /CJ_goal_defect via the Skill tool"
else
  fail_test "shim missing 'Skill: CJ_goal_defect' delegation line for non-D-id args"
fi

# Frontmatter sanity: name + status + uppercase canonical preserved. The shim
# keeps the original name CJ_goal_investigate (route surface stays intact under
# --include-deprecated installs); the catalog entry independently flips
# status: deprecated. Asserting name + allowed-tools (Skill,Bash) here gives a
# second-line guard against accidental SKILL.md rewrites that drop the routing
# tools.
if grep -q '^name: CJ_goal_investigate$' "$SHIM"; then
  ok "shim frontmatter preserves 'name: CJ_goal_investigate'"
else
  fail_test "shim frontmatter missing 'name: CJ_goal_investigate'"
fi

if grep -q '^  - Skill$' "$SHIM" && grep -q '^  - Bash$' "$SHIM"; then
  ok "shim frontmatter allowed-tools includes Skill + Bash"
else
  fail_test "shim frontmatter allowed-tools missing Skill and/or Bash (needed for D-id-branch + delegation)"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-goal-investigate-shim"
  exit 0
else
  echo "FAIL: cj-goal-investigate-shim ($ERRORS error(s))"
  exit 1
fi
