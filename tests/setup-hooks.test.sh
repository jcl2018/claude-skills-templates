#!/usr/bin/env bash
# tests/setup-hooks.test.sh — test for scripts/setup-hooks.sh.
#
# F000028 / S000061: doc-sync trigger block (post-merge + post-rewrite).
# Six rows covering the parent design Success Criteria + SPEC AC list:
#   (a) main-moving merge writes marker
#   (b) same HEAD is idempotent (no new marker, silent)
#   (c) doc-only merge skips the marker
#   (d) DOC_SYNC_FORCE=1 overrides triviality filter
#   (e) initial-commit edge case (no prior _LAST_SYNCED, no HEAD^) → empty-tree fallback
#   (f) post-rewrite writes the same marker shape as post-merge
#
# Pattern: per-case sandbox via mktemp -d. setup-hooks.sh resolves REPO_ROOT
# from its own dirname, so we cannot invoke it directly against a sandbox.
# Instead, render the hook bodies once by invoking setup-hooks.sh against the
# real workbench `.git/hooks/` (Smoke 0), then copy those installed hooks into
# every sandbox's `.git/hooks/`. The hooks themselves are pure shell — they
# resolve `git rev-parse --git-common-dir` etc. against `$PWD` at runtime.
# Each sandbox runs hooks under a scoped HOME so the marker dir
# ~/.gstack/doc-sync-pending/ is sandbox-local.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SETUP_HOOKS="$REPO_ROOT/scripts/setup-hooks.sh"

[ -x "$SETUP_HOOKS" ] || { echo "FAIL: $SETUP_HOOKS not executable"; exit 1; }

# ---------- Smoke 0: setup-hooks.sh installs both hooks ----------
#
# Runs setup-hooks.sh against the real workbench `.git/hooks/`. The script is
# idempotent (sentinel-aware re-install) so this is safe to run repeatedly.
# Also captures the rendered hook bodies for downstream sandboxes.

echo ""
echo "Smoke 0: setup-hooks.sh installs post-merge + post-rewrite with marker comment..."
"$SETUP_HOOKS" >/dev/null 2>&1 || { fail_test "Smoke 0: setup-hooks.sh exited non-zero"; exit 1; }

WORKBENCH_GIT_DIR=$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2>/dev/null)
case "$WORKBENCH_GIT_DIR" in
  /*) WORKBENCH_HOOK_DIR="$WORKBENCH_GIT_DIR/hooks" ;;
  *)  WORKBENCH_HOOK_DIR="$REPO_ROOT/$WORKBENCH_GIT_DIR/hooks" ;;
esac
POST_MERGE_HOOK="$WORKBENCH_HOOK_DIR/post-merge"
POST_REWRITE_HOOK="$WORKBENCH_HOOK_DIR/post-rewrite"

if [ -f "$POST_MERGE_HOOK" ] && [ -f "$POST_REWRITE_HOOK" ] \
   && grep -qF '# doc-sync trigger block' "$POST_MERGE_HOOK" \
   && grep -qF '# doc-sync trigger block' "$POST_REWRITE_HOOK" \
   && grep -qF '# Auto-installed by scripts/setup-hooks.sh' "$POST_MERGE_HOOK" \
   && grep -qF '# Auto-installed by scripts/setup-hooks.sh' "$POST_REWRITE_HOOK"; then
  ok "Smoke 0: both hooks present with doc-sync trigger block + sentinel"
else
  fail_test "Smoke 0: missing hook(s), marker comment, or sentinel"
  exit 1
fi

# Verify the existing D000013 + F000011 sections are still in post-merge
# (sentinel-aware re-install must not backup-thrash or strip).
if grep -qF '[skills-deploy]' "$POST_MERGE_HOOK" \
   && grep -qF 'F000011 Phase 3 lifecycle-gate' "$POST_MERGE_HOOK"; then
  ok "Smoke 0: existing sections 1 (D000013) and 2 (F000011) preserved in post-merge"
else
  fail_test "Smoke 0: existing D000013 / F000011 sections missing from post-merge"
fi

# ---------- Per-case sandbox factory ----------
#
# Builds an isolated git repo on `main` with a single seed commit. Does NOT
# install the hooks yet — callers must call install_sandbox_hooks AFTER any
# merges, so the hook's auto-fire on `git merge` does not pollute the real
# HOME with a marker before the scoped-HOME run. Echoes the sandbox path.

mk_sandbox() {
  local dir
  dir=$(mktemp -d -t setup-hooks-test.XXXXXX)
  (
    cd "$dir"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
  )
  mkdir -p "$dir/.fake-home"
  printf '%s' "$dir"
}

# Install the rendered post-merge + post-rewrite hooks into a sandbox. Call
# AFTER any merge setup so the hook's auto-fire doesn't pollute the real HOME.
install_sandbox_hooks() {
  local dir="$1"
  install -m 0755 "$POST_MERGE_HOOK" "$dir/.git/hooks/post-merge"
  install -m 0755 "$POST_REWRITE_HOOK" "$dir/.git/hooks/post-rewrite"
}

cleanup_sandboxes() {
  for d in "$@"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}

# Helper: invoke the installed hooks in a sandbox under a scoped HOME.
# stderr is captured to stdout for the caller's grep.
run_post_merge() {
  local sbx="$1"
  ( cd "$sbx" && HOME="$sbx/.fake-home" bash "$sbx/.git/hooks/post-merge" ) 2>&1 || true
}

run_post_rewrite() {
  local sbx="$1"
  ( cd "$sbx" && HOME="$sbx/.fake-home" bash "$sbx/.git/hooks/post-rewrite" rebase ) 2>&1 || true
}

# Helper for asserting jq fields on a marker.
marker_field() {
  jq -r "$1" "$2" 2>/dev/null || echo ""
}

# ---------- Case (a): main-moving merge writes marker ----------

echo ""
echo "Case (a): main-moving merge writes marker with expected fields..."
SBXA=$(mk_sandbox)
trap 'cleanup_sandboxes "${SBXA:-}" "${SBXB:-}" "${SBXC:-}" "${SBXD:-}" "${SBXE:-}" "${SBXF:-}"' EXIT
(
  cd "$SBXA"
  git checkout -q -b feat-code
  echo "code" > script.sh
  git add script.sh
  git commit -qm "add script.sh"
  git checkout -q main
  git merge --no-ff -q -m "merge feat-code" feat-code
) >/dev/null 2>&1
install_sandbox_hooks "$SBXA"

STDERR=$(run_post_merge "$SBXA")
MARKER="$SBXA/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXA").json"

if [ ! -f "$MARKER" ]; then
  fail_test "Case (a): marker not written to $MARKER (stderr: $STDERR)"
else
  HEAD_SHA=$(marker_field '.head_sha' "$MARKER")
  ACTUAL_HEAD=$(git -C "$SBXA" rev-parse HEAD)
  REPO=$(marker_field '.repo' "$MARKER")
  EXPECT_REPO=$(basename "$SBXA")
  DIFF_BASE=$(marker_field '.diff_base' "$MARKER")
  MOVED_AT=$(marker_field '.main_moved_at' "$MARKER")
  CHANGED=$(marker_field '.changed_files' "$MARKER")

  # diff_base may be a 40-char SHA (when .doc-sync-last-head was pre-populated),
  # the literal "HEAD^" (first-merge case, falls back to first-parent), or the
  # empty-tree hash (initial-commit case). All three resolve to a valid
  # tree-ish per the SPEC AC-2; assert by re-resolving against the sandbox repo.
  DIFF_BASE_RESOLVED=$(git -C "$SBXA" rev-parse --verify "$DIFF_BASE" 2>/dev/null || echo "")
  if [ "$HEAD_SHA" = "$ACTUAL_HEAD" ] \
     && [ "$REPO" = "$EXPECT_REPO" ] \
     && [ -n "$DIFF_BASE_RESOLVED" ] \
     && echo "$MOVED_AT" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' \
     && [ "$CHANGED" -ge 1 ] 2>/dev/null \
     && echo "$STDERR" | grep -qF '[doc-sync] main moved. Marker written:'; then
    ok "Case (a): marker valid (head_sha=${HEAD_SHA:0:7} repo=$REPO diff_base=$DIFF_BASE -> ${DIFF_BASE_RESOLVED:0:7} changed_files=$CHANGED)"
  else
    fail_test "Case (a): marker fields invalid: head_sha=$HEAD_SHA actual=$ACTUAL_HEAD repo=$REPO diff_base=$DIFF_BASE (resolved=$DIFF_BASE_RESOLVED) moved_at=$MOVED_AT changed=$CHANGED stderr=$STDERR"
  fi
fi

# ---------- Case (b): same HEAD re-run is NO-OP ----------

echo ""
echo "Case (b): same-HEAD re-run is silent NO-OP..."
SBXB=$(mk_sandbox)
(
  cd "$SBXB"
  git checkout -q -b feat-code-b
  echo "code-b" > script-b.sh
  git add script-b.sh
  git commit -qm "add script-b.sh"
  git checkout -q main
  git merge --no-ff -q -m "merge feat-code-b" feat-code-b
) >/dev/null 2>&1
install_sandbox_hooks "$SBXB"

# First run: writes marker.
run_post_merge "$SBXB" >/dev/null
MARKER_B="$SBXB/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXB").json"
if [ ! -f "$MARKER_B" ]; then
  fail_test "Case (b): setup run did not write marker (cannot test idempotency)"
else
  MTIME1=$(stat -f "%m" "$MARKER_B" 2>/dev/null || stat -c "%Y" "$MARKER_B" 2>/dev/null || echo "0")
  sleep 1
  STDERR2=$(run_post_merge "$SBXB")
  MTIME2=$(stat -f "%m" "$MARKER_B" 2>/dev/null || stat -c "%Y" "$MARKER_B" 2>/dev/null || echo "0")
  # Section-1/2 may emit stderr (skills-deploy etc.); we only assert section 3 doesn't.
  if [ "$MTIME1" = "$MTIME2" ] && ! echo "$STDERR2" | grep -qF '[doc-sync]'; then
    ok "Case (b): same-HEAD re-run NO-OP (mtime unchanged, no [doc-sync] stderr)"
  else
    fail_test "Case (b): expected NO-OP; mtime1=$MTIME1 mtime2=$MTIME2 stderr=$STDERR2"
  fi
fi

# ---------- Case (c): doc-only merge skips the marker ----------

echo ""
echo "Case (c): doc-only merge skips the marker..."
SBXC=$(mk_sandbox)
(
  cd "$SBXC"
  git checkout -q -b feat-docs
  echo "# Notes" > README.md
  echo "ch" > CHANGELOG.md
  git add README.md CHANGELOG.md
  git commit -qm "doc-only changes"
  git checkout -q main
  git merge --no-ff -q -m "merge feat-docs" feat-docs
) >/dev/null 2>&1
install_sandbox_hooks "$SBXC"

STDERR_C=$(run_post_merge "$SBXC")
MARKER_C="$SBXC/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXC").json"

if [ ! -f "$MARKER_C" ] \
   && echo "$STDERR_C" | grep -qF '[doc-sync] main moved but only docs changed'; then
  LAST_HEAD=$(cat "$SBXC/.git/.doc-sync-last-head" 2>/dev/null || echo "")
  EXPECT_HEAD_C=$(git -C "$SBXC" rev-parse HEAD)
  if [ "$LAST_HEAD" = "$EXPECT_HEAD_C" ]; then
    ok "Case (c): doc-only merge skipped marker and bumped .doc-sync-last-head"
  else
    fail_test "Case (c): marker correctly skipped but .doc-sync-last-head not bumped (got: $LAST_HEAD, want: $EXPECT_HEAD_C)"
  fi
else
  fail_test "Case (c): expected no marker + 'only docs changed' stderr; marker_exists=$([ -f "$MARKER_C" ] && echo yes || echo no) stderr=$STDERR_C"
fi

# ---------- Case (d): DOC_SYNC_FORCE=1 overrides triviality filter ----------

echo ""
echo "Case (d): DOC_SYNC_FORCE=1 forces marker write on doc-only diff..."
SBXD=$(mk_sandbox)
(
  cd "$SBXD"
  git checkout -q -b feat-docs-d
  echo "# Notes" > README.md
  git add README.md
  git commit -qm "doc-only changes"
  git checkout -q main
  git merge --no-ff -q -m "merge feat-docs-d" feat-docs-d
) >/dev/null 2>&1
install_sandbox_hooks "$SBXD"

STDERR_D=$( ( cd "$SBXD" && HOME="$SBXD/.fake-home" DOC_SYNC_FORCE=1 bash "$SBXD/.git/hooks/post-merge" ) 2>&1 || true )
MARKER_D="$SBXD/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXD").json"

if [ -f "$MARKER_D" ] && echo "$STDERR_D" | grep -qF '[doc-sync] main moved. Marker written:'; then
  ok "Case (d): DOC_SYNC_FORCE=1 wrote marker despite doc-only diff"
else
  fail_test "Case (d): expected marker written under DOC_SYNC_FORCE=1; marker_exists=$([ -f "$MARKER_D" ] && echo yes || echo no) stderr=$STDERR_D"
fi

# ---------- Case (e): initial-commit edge case (empty-tree fallback) ----------

echo ""
echo "Case (e): initial-commit edge case → empty-tree diff_base, marker still valid..."
# Single-commit repo: no prior .doc-sync-last-head, no HEAD^.
SBXE=$(mktemp -d -t setup-hooks-test-e.XXXXXX)
(
  cd "$SBXE"
  git init -q
  git config user.email "test@test"
  git config user.name "test"
  git checkout -q -b main 2>/dev/null || true
  echo "first" > only.sh    # non-doc so triviality filter does not fire
  git add only.sh
  git commit -qm "initial commit"
) >/dev/null 2>&1
install -m 0755 "$POST_MERGE_HOOK" "$SBXE/.git/hooks/post-merge"
install -m 0755 "$POST_REWRITE_HOOK" "$SBXE/.git/hooks/post-rewrite"
mkdir -p "$SBXE/.fake-home"

EMPTY_TREE=$(git -C "$SBXE" hash-object -t tree /dev/null)
STDERR_E=$( ( cd "$SBXE" && HOME="$SBXE/.fake-home" bash "$SBXE/.git/hooks/post-merge" ) 2>&1 || true )
MARKER_E="$SBXE/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXE").json"

if [ ! -f "$MARKER_E" ]; then
  fail_test "Case (e): marker not written on initial-commit (stderr: $STDERR_E)"
else
  DIFF_BASE_E=$(marker_field '.diff_base' "$MARKER_E")
  HEAD_SHA_E=$(marker_field '.head_sha' "$MARKER_E")
  ACTUAL_HEAD_E=$(git -C "$SBXE" rev-parse HEAD)
  if [ "$DIFF_BASE_E" = "$EMPTY_TREE" ] && [ "$HEAD_SHA_E" = "$ACTUAL_HEAD_E" ]; then
    ok "Case (e): empty-tree fallback ($EMPTY_TREE) used as diff_base; head_sha matches"
  else
    fail_test "Case (e): expected diff_base=empty-tree=$EMPTY_TREE; got diff_base=$DIFF_BASE_E head_sha=$HEAD_SHA_E (actual_head=$ACTUAL_HEAD_E)"
  fi
fi
cleanup_sandboxes "$SBXE"

# ---------- Case (f): post-rewrite writes the same marker ----------

echo ""
echo "Case (f): post-rewrite writes the same marker shape as post-merge..."
SBXF=$(mk_sandbox)
(
  cd "$SBXF"
  git checkout -q -b feat-rebase
  echo "rebase-code" > rebase.sh
  git add rebase.sh
  git commit -qm "rebase code"
  git checkout -q main
  # Fast-forward to simulate a clean rebase pull.
  git merge --ff-only -q feat-rebase
) >/dev/null 2>&1
install_sandbox_hooks "$SBXF"

STDERR_F=$(run_post_rewrite "$SBXF")
MARKER_F="$SBXF/.fake-home/.gstack/doc-sync-pending/$(basename "$SBXF").json"

if [ ! -f "$MARKER_F" ]; then
  fail_test "Case (f): post-rewrite did not write marker (stderr: $STDERR_F)"
else
  HEAD_SHA_F=$(marker_field '.head_sha' "$MARKER_F")
  REPO_F=$(marker_field '.repo' "$MARKER_F")
  ACTUAL_HEAD_F=$(git -C "$SBXF" rev-parse HEAD)
  EXPECT_REPO_F=$(basename "$SBXF")
  if [ "$HEAD_SHA_F" = "$ACTUAL_HEAD_F" ] \
     && [ "$REPO_F" = "$EXPECT_REPO_F" ] \
     && echo "$STDERR_F" | grep -qF '[doc-sync] main moved. Marker written:'; then
    ok "Case (f): post-rewrite wrote valid marker (head_sha=${HEAD_SHA_F:0:7} repo=$REPO_F)"
  else
    fail_test "Case (f): post-rewrite marker invalid: head_sha=$HEAD_SHA_F actual=$ACTUAL_HEAD_F repo=$REPO_F stderr=$STDERR_F"
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
