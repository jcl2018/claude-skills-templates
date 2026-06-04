#!/usr/bin/env bash
# tests/setup-hooks.test.sh — test for scripts/setup-hooks.sh.
#
# F000040 / S000073 retired the F000028/F000029 doc-sync marker mechanism. The
# post-merge Section 3 doc-sync trigger block and the entire post-rewrite hook
# are gone.
#
# F000011 fix (Approach A) then removed the post-merge Section 2 "Phase 3
# lifecycle-gate auto-update" block: a post-merge hook cannot cleanly mutate a
# tracked _TRACKER.md on main (it either dirties the tree or diverges main), so
# the auto-tick is disabled and check-gates-update.sh survives as a manual tool.
#
# What survives in the INSTALLED post-merge hook:
#   - pre-commit (validate.sh) hook
#   - post-merge hook with Section 1 (D000013 redeploy) ONLY
# Smoke 0 asserts that survivor surface installs cleanly, carries the sentinel,
# preserves Section 1, that the F000011 Phase-3 / check-gates-update auto-tick is
# NO LONGER present, and that NO post-rewrite hook and NO doc-sync trigger block
# are (re)installed.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SETUP_HOOKS="$REPO_ROOT/scripts/setup-hooks.sh"

[ -x "$SETUP_HOOKS" ] || { echo "FAIL: $SETUP_HOOKS not executable"; exit 1; }

# hook_code <hook-file> — emit only the EXECUTABLE lines of a hook (drop blank
# lines and full-line `#` comments). The F000011-fix hook keeps a descriptive
# comment that *names* the removed Phase-3 block ("...check-gates-update.sh is
# now a manual operator tool only"), so a naive substring grep over the raw file
# would false-match the comment. The absence assertions below grep this filtered
# stream instead, so they prove the AUTO-TICK CODE is gone, not its mention.
hook_code() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

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

# The D000013 redeploy section (Section 1) is still in the installed post-merge
# hook (sentinel-aware re-install must not strip it).
if grep -qF '[skills-deploy]' "$POST_MERGE_HOOK"; then
  ok "Smoke 0: post-merge Section 1 (D000013 redeploy) preserved"
else
  fail_test "Smoke 0: D000013 redeploy section missing from post-merge"
fi

# F000011 fix (Approach A): the installed post-merge hook must NOT auto-edit
# trackers. The check-gates-update.sh invocation, the `if [ "$BRANCH" = "main" ]`
# Phase-3 guard, and the work-items/**_TRACKER.md path filter that gated the
# auto-tick are all removed. Assert none of those EXECUTABLE tokens survive in
# the installed hook (grep the comment-stripped body so the descriptive removal
# comment doesn't false-match). This is the core F000011 regression guard.
if hook_code "$POST_MERGE_HOOK" | grep -qF 'check-gates-update.sh' \
   || hook_code "$POST_MERGE_HOOK" | grep -qF '"$BRANCH" = "main"' \
   || hook_code "$POST_MERGE_HOOK" | grep -qE 'work-items/.*_TRACKER'; then
  fail_test "Smoke 0: post-merge hook still carries the F000011 Phase-3 tracker auto-tick (must be removed — it dirties main)"
else
  ok "Smoke 0: post-merge hook has no Phase-3 / check-gates-update tracker auto-tick (F000011 fix)"
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

# ---------- Smoke 1: F000011 — installed hook does not auto-edit trackers ----------
#
# Installs the hooks into a THROWAWAY temp git repo (never touches the real
# workbench .git/hooks/, per the F000011-fix constraint) and inspects the
# GENERATED .git/hooks/post-merge. The whole point of Approach A is that the
# installed hook can no longer mutate a tracked _TRACKER.md on main, so this
# asserts the generated artifact carries Section 1 (skills-deploy redeploy) but
# NOT the Phase-3 / check-gates-update auto-tick.

echo ""
echo "Smoke 1: F000011 — generated post-merge hook redeploys but never auto-ticks trackers (temp repo)..."

TMP_REPO=$(mktemp -d 2>/dev/null) || { fail_test "Smoke 1: mktemp -d failed"; exit 1; }
trap 'rm -rf "$TMP_REPO"' EXIT

(
  git -C "$TMP_REPO" init -q \
    && git -C "$TMP_REPO" config user.email t@t \
    && git -C "$TMP_REPO" config user.name t \
    && cp "$SETUP_HOOKS" "$TMP_REPO/setup-hooks.sh" \
    && mkdir -p "$TMP_REPO/scripts" \
    && cp "$SETUP_HOOKS" "$TMP_REPO/scripts/setup-hooks.sh"
) >/dev/null 2>&1 || { fail_test "Smoke 1: could not stage temp git repo"; exit 1; }

# Run the copy from the temp repo's scripts/ so its REPO_ROOT resolves to TMP_REPO
# and the generated hook lands in $TMP_REPO/.git/hooks/.
( cd "$TMP_REPO" && bash scripts/setup-hooks.sh ) >/dev/null 2>&1 \
  || { fail_test "Smoke 1: setup-hooks.sh exited non-zero in temp repo"; exit 1; }

TMP_POST_MERGE="$TMP_REPO/.git/hooks/post-merge"
if [ ! -f "$TMP_POST_MERGE" ]; then
  fail_test "Smoke 1: setup-hooks.sh did not generate .git/hooks/post-merge in temp repo"
else
  # Section 1 (D000013 redeploy) MUST be present (executable lines only).
  if hook_code "$TMP_POST_MERGE" | grep -qF '[skills-deploy]' \
     && hook_code "$TMP_POST_MERGE" | grep -qE 'skills-deploy.*install.*--overwrite'; then
    ok "Smoke 1: generated post-merge hook contains Section 1 (skills-deploy redeploy)"
  else
    fail_test "Smoke 1: generated post-merge hook missing Section 1 (skills-deploy redeploy)"
  fi

  # F000011 Phase-3 auto-tick CODE MUST be absent from the generated hook
  # (grep the comment-stripped body; the removal is documented in a comment).
  if hook_code "$TMP_POST_MERGE" | grep -qF 'check-gates-update.sh' \
     || hook_code "$TMP_POST_MERGE" | grep -qF '"$BRANCH" = "main"' \
     || hook_code "$TMP_POST_MERGE" | grep -qE 'work-items/.*_TRACKER'; then
    fail_test "Smoke 1: generated post-merge hook still auto-ticks trackers (F000011 Phase-3 block present — dirties main)"
  else
    ok "Smoke 1: generated post-merge hook has no Phase-3 / check-gates-update tracker auto-tick (F000011 fix)"
  fi
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
