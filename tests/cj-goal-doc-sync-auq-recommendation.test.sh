#!/usr/bin/env bash
# tests/cj-goal-doc-sync-auq-recommendation.test.sh
#
# Regression test for D000026 (v5.0.14): the cj_goal orchestrator preamble
# AUQ templates labelled option A ("Run /document-release now") as
# "recommended on main", but upstream gstack /document-release Step 1
# hard-aborts on the base branch ("You're on the base branch. Run from a
# feature branch."). On main, A always aborts; B (snooze) is the only path
# that works. The fix flips the branch-aware recommendation:
#   - on main: B is recommended; A is flagged as "WILL ABORT on main"
#   - on a feature branch: A is recommended (that's exactly where
#     /document-release runs)
#
# This test asserts the literal text in the live cj_goal SKILL.md files matches
# the corrected polarity. It does NOT exercise the runtime AUQ (no Skill
# invocation) — pure grep against source.
#
# Covers the 2 live cj_goal SKILL.md files (feature + defect) on the corrected
# polarity.
#
# Pattern: per-file string-presence + string-absence assertions. The "absence"
# assertions catch a regression that re-introduces the pre-fix wording.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

SKILLS=(
  "$REPO_ROOT/skills/CJ_goal_feature/SKILL.md"
  "$REPO_ROOT/skills/CJ_goal_defect/SKILL.md"
)

echo "=== cj-goal-doc-sync-auq-recommendation: 2 SKILL.md preambles ==="

for skill in "${SKILLS[@]}"; do
  rel="${skill#$REPO_ROOT/}"
  [ -f "$skill" ] || { fail_test "$rel: missing"; continue; }

  # POSITIVE assertions — the corrected polarity must be present.

  # (1) Option A label flags "WILL ABORT on main" and recommends feature
  # branch. Match must be in the AUQ template block (inside the fenced ``` block
  # that surfaces the question), so anchor on "A) Run /document-release now".
  if grep -q "A) Run /document-release now (recommended on a feature branch; WILL ABORT on main" "$skill"; then
    ok "$rel: A) flags 'WILL ABORT on main' + 'recommended on a feature branch'"
  else
    fail_test "$rel: A) does NOT flag 'WILL ABORT on main' (regression — pre-fix recommended A on main)"
  fi

  # (2) Option B label is explicitly recommended on main.
  if grep -q "B) Snooze 1h.*recommended on main" "$skill"; then
    ok "$rel: B) is 'recommended on main'"
  else
    fail_test "$rel: B) is NOT labeled 'recommended on main' (regression — pre-fix had no per-branch label on B)"
  fi

  # (3) Prose header (the sentence above the fenced AUQ block) names B as
  # the on-main recommendation. Pre-fix wording said the opposite.
  if grep -q 'On \*\*main\*\*, "B" is recommended' "$skill"; then
    ok "$rel: prose header names B as on-main recommendation"
  else
    fail_test "$rel: prose header does NOT name B as on-main recommendation"
  fi

  # NEGATIVE assertions — the pre-fix wording must be gone.

  # (4) Pre-fix label "(recommended on main; NOT recommended on feature branch)"
  # — this was the exact inverted recommendation on option A.
  if grep -q "(recommended on main; NOT recommended on feature branch)" "$skill"; then
    fail_test "$rel: pre-fix label '(recommended on main; NOT recommended on feature branch)' still present on A"
  else
    ok "$rel: pre-fix inverted A label is gone"
  fi

  # (5) Pre-fix prose header "On **main**, \"A\" is recommended" — replaced
  # with the corrected B-on-main wording above.
  if grep -q 'On \*\*main\*\*, "A" is recommended' "$skill"; then
    fail_test "$rel: pre-fix prose 'On **main**, \"A\" is recommended' still present"
  else
    ok "$rel: pre-fix inverted prose header is gone"
  fi
done

# CLAUDE.md mechanism-doc check — the workbench's narrative reference for the
# F000029 mechanism must match the corrected polarity. Pre-fix said
# "A on main, B on a feature branch"; corrected says "B on main, A on a
# feature branch".
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  if grep -q "branch-aware option ordering (B on main, A on a feature branch" "$CLAUDE_MD"; then
    ok "CLAUDE.md: branch-aware ordering note says 'B on main, A on a feature branch'"
  else
    fail_test "CLAUDE.md: branch-aware ordering note does NOT match corrected polarity"
  fi
  if grep -q "branch-aware option ordering (A on main, B on a feature branch" "$CLAUDE_MD"; then
    fail_test "CLAUDE.md: pre-fix wording 'A on main, B on a feature branch' still present"
  else
    ok "CLAUDE.md: pre-fix wording is gone"
  fi
else
  fail_test "CLAUDE.md: missing"
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: cj-goal-doc-sync-auq-recommendation"
  exit 0
else
  echo "FAIL: cj-goal-doc-sync-auq-recommendation ($ERRORS error(s))"
  exit 1
fi
