#!/usr/bin/env bash
# tests/setup-hooks.test.sh — test for scripts/setup-hooks.sh.
#
# F000039 / S000072 retired the F000028/F000029 doc-sync marker mechanism. The
# post-merge Section 3 doc-sync trigger block and the entire post-rewrite hook
# are gone. What survives:
#   - pre-commit (validate.sh) hook
#   - post-merge hook with Section 1 (D000013 redeploy) + Section 2 (F000011 gates)
# Smoke 0 asserts that survivor surface installs cleanly, carries the sentinel,
# preserves Sections 1+2, and that NO post-rewrite hook and NO doc-sync trigger
# block are (re)installed.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SETUP_HOOKS="$REPO_ROOT/scripts/setup-hooks.sh"

[ -x "$SETUP_HOOKS" ] || { echo "FAIL: $SETUP_HOOKS not executable"; exit 1; }

# ---------- Smoke 0: setup-hooks.sh installs the surviving hooks ----------
#
# Runs setup-hooks.sh against the real workbench `.git/hooks/`. The script is
# idempotent (sentinel-aware re-install) so this is safe to run repeatedly.

echo ""
echo "Smoke 0: setup-hooks.sh installs pre-commit + post-merge (no post-rewrite, no doc-sync block)..."
"$SETUP_HOOKS" >/dev/null 2>&1 || { fail_test "Smoke 0: setup-hooks.sh exited non-zero"; exit 1; }

WORKBENCH_GIT_DIR=$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2>/dev/null)
case "$WORKBENCH_GIT_DIR" in
  /*) WORKBENCH_HOOK_DIR="$WORKBENCH_GIT_DIR/hooks" ;;
  *)  WORKBENCH_HOOK_DIR="$REPO_ROOT/$WORKBENCH_GIT_DIR/hooks" ;;
esac
PRE_COMMIT_HOOK="$WORKBENCH_HOOK_DIR/pre-commit"
POST_MERGE_HOOK="$WORKBENCH_HOOK_DIR/post-merge"
POST_REWRITE_HOOK="$WORKBENCH_HOOK_DIR/post-rewrite"

# pre-commit + post-merge present, both carry the sentinel.
if [ -f "$PRE_COMMIT_HOOK" ] && [ -f "$POST_MERGE_HOOK" ] \
   && grep -qF '# Auto-installed by scripts/setup-hooks.sh' "$PRE_COMMIT_HOOK" \
   && grep -qF '# Auto-installed by scripts/setup-hooks.sh' "$POST_MERGE_HOOK"; then
  ok "Smoke 0: pre-commit + post-merge present with sentinel"
else
  fail_test "Smoke 0: missing pre-commit/post-merge hook or sentinel"
  exit 1
fi

# pre-commit runs validate.sh.
if grep -qF './scripts/validate.sh' "$PRE_COMMIT_HOOK"; then
  ok "Smoke 0: pre-commit runs validate.sh"
else
  fail_test "Smoke 0: pre-commit does not run validate.sh"
fi

# The existing D000013 + F000011 sections are still in post-merge
# (sentinel-aware re-install must not backup-thrash or strip).
if grep -qF '[skills-deploy]' "$POST_MERGE_HOOK" \
   && grep -qF 'F000011 Phase 3 lifecycle-gate' "$POST_MERGE_HOOK"; then
  ok "Smoke 0: post-merge sections 1 (D000013) and 2 (F000011) preserved"
else
  fail_test "Smoke 0: D000013 / F000011 sections missing from post-merge"
fi

# The retired doc-sync trigger block must NOT be (re)installed by setup-hooks.sh.
if grep -qF '# doc-sync trigger block' "$POST_MERGE_HOOK"; then
  fail_test "Smoke 0: post-merge still carries the retired doc-sync trigger block"
else
  ok "Smoke 0: post-merge has no doc-sync trigger block (retired)"
fi

# setup-hooks.sh must not install a post-rewrite hook of its own. A pre-existing
# operator-owned post-rewrite (without our sentinel) is none of our business; we
# only assert that if one exists, it is NOT a workbench-installed doc-sync hook.
if [ -f "$POST_REWRITE_HOOK" ] \
   && grep -qF '# Auto-installed by scripts/setup-hooks.sh' "$POST_REWRITE_HOOK" \
   && grep -qF '# doc-sync trigger block' "$POST_REWRITE_HOOK"; then
  fail_test "Smoke 0: a workbench-owned doc-sync post-rewrite hook is still installed"
else
  ok "Smoke 0: no workbench-owned doc-sync post-rewrite hook installed (retired)"
fi

# ---------- Summary ----------

echo ""
echo "=== setup-hooks.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
