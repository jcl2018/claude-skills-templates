#!/usr/bin/env bash
# tests/post-land-sync.test.sh
#
# Unit/integration-shape test for scripts/post-land-sync.sh (F000041 / S000074).
#
# CRITICAL ISOLATION INVARIANT: this test must NEVER touch the operator's real
# ~/.claude and must NEVER run a real `git pull` or `skills-deploy install`. It
# exercises the helper exclusively via:
#   - `--dry-run` (mutates nothing by contract), AND
#   - a POST_LAND_SYNC_MANIFEST override pointing at a TEMP manifest whose
#     `.source` is a throwaway temp git repo built inside this test.
# The real manifest is never read or written.
#
# Asserts (≥6):
#   1. Helper exists + is executable.
#   2. --dry-run against a clean-on-main fixture exits 0, resolves `.source`,
#      and prints the current collection_version.
#   3. --dry-run prints the would-run `git ... pull --ff-only` command (S3 shape).
#   4. --dry-run prints the would-run `skills-deploy install` command (S3 shape).
#   5. --dry-run mutates NOTHING (fixture repo HEAD + tree unchanged; no pull/install).
#   6. Guard: missing `.source` → non-zero exit + a GUARD-FAILED message.
#   7. Guard: `.source` not on `main` → non-zero exit + a "not on branch 'main'" message.
#   8. Guard: `.source` dirty tree → non-zero exit + a "dirty working tree" message.
#   9. Guard: `.source` not a git repo → non-zero exit + a "not a git repository" message.
#  10. Untracked-only files in `.source` do NOT trip the dirty guard (--dry-run still exits 0).
#
# Prints RESULT: PASS / RESULT: FAIL.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/post-land-sync.sh"

echo "=== post-land-sync.test.sh: helper + --dry-run + guards (no real ~/.claude mutation) ==="

# Record the REAL manifest's collection_version up front so we can prove at the
# end the test did not mutate it (belt-and-suspenders; the test never points the
# helper at the real manifest, but this catches an accidental real-path call).
REAL_MANIFEST="$HOME/.claude/.skills-templates.json"
REAL_CV_BEFORE=""
if [ -f "$REAL_MANIFEST" ]; then
  REAL_CV_BEFORE=$(command jq -r '.collection_version // empty' "$REAL_MANIFEST" 2>/dev/null | tr -d '\r' || echo "")
fi

# ── Sandbox ────────────────────────────────────────────────────────────────
# One temp dir holds: a throwaway "source" git repo + the fixture manifests.
TMP=$(mktemp -d -t post-land-sync-test-XXXXXX)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FIXTURE_SRC="$TMP/source-repo"
mkdir -p "$FIXTURE_SRC"
(
  cd "$FIXTURE_SRC"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  # Force the default branch to be 'main' regardless of the host git's init.defaultBranch.
  git checkout -q -b main 2>/dev/null || git branch -q -m main 2>/dev/null || true
  printf '6.0.10\n' > VERSION
  mkdir -p scripts
  printf '#!/usr/bin/env bash\necho "fake skills-deploy $*"\n' > scripts/skills-deploy
  chmod +x scripts/skills-deploy
  git add -A
  git commit -q -m "fixture: initial"
) || { echo "RESULT: FAIL (could not build fixture repo)"; exit 1; }

# A clean-on-main manifest pointing at the fixture source repo.
GOOD_MANIFEST="$TMP/good-manifest.json"
cat > "$GOOD_MANIFEST" <<EOF
{
  "source": "$FIXTURE_SRC",
  "collection_version": "6.0.10"
}
EOF

# ── 1. Helper exists + is executable ─────────────────────────────────────────
if [ -f "$HELPER" ]; then
  ok "scripts/post-land-sync.sh exists"
else
  fail_test "scripts/post-land-sync.sh missing"
fi
if [ -x "$HELPER" ]; then
  ok "scripts/post-land-sync.sh is executable"
else
  fail_test "scripts/post-land-sync.sh is not executable (chmod +x)"
fi

# Capture fixture-repo state BEFORE any helper invocation (for the no-mutation check).
SRC_HEAD_BEFORE=$(git -C "$FIXTURE_SRC" rev-parse HEAD 2>/dev/null || echo "")
SRC_STATUS_BEFORE=$(git -C "$FIXTURE_SRC" status --porcelain 2>/dev/null || echo "")

# ── 2-4. --dry-run against clean-on-main fixture ─────────────────────────────
DRY_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$HELPER" --dry-run 2>&1)
DRY_RC=$?

if [ "$DRY_RC" -eq 0 ]; then
  ok "--dry-run exits 0 against a clean-on-main fixture"
else
  fail_test "--dry-run should exit 0 against a clean fixture (rc=$DRY_RC); output: $DRY_OUT"
fi

if printf '%s' "$DRY_OUT" | grep -qF "$FIXTURE_SRC"; then
  ok "--dry-run resolves and prints .source ($FIXTURE_SRC)"
else
  fail_test "--dry-run did not print resolved .source; output: $DRY_OUT"
fi

if printf '%s' "$DRY_OUT" | grep -q "6.0.10"; then
  ok "--dry-run prints the current collection_version (6.0.10)"
else
  fail_test "--dry-run did not print collection_version; output: $DRY_OUT"
fi

if printf '%s' "$DRY_OUT" | grep -qE 'git .*pull --ff-only'; then
  ok "--dry-run prints would-run 'git ... pull --ff-only' (S3 command shape)"
else
  fail_test "--dry-run missing 'git ... pull --ff-only' command shape; output: $DRY_OUT"
fi

if printf '%s' "$DRY_OUT" | grep -q 'skills-deploy.*install'; then
  ok "--dry-run prints would-run 'skills-deploy install' (S3 command shape)"
else
  fail_test "--dry-run missing 'skills-deploy install' command shape; output: $DRY_OUT"
fi

# ── 5. --dry-run mutated nothing ─────────────────────────────────────────────
SRC_HEAD_AFTER=$(git -C "$FIXTURE_SRC" rev-parse HEAD 2>/dev/null || echo "")
SRC_STATUS_AFTER=$(git -C "$FIXTURE_SRC" status --porcelain 2>/dev/null || echo "")
if [ "$SRC_HEAD_BEFORE" = "$SRC_HEAD_AFTER" ] && [ "$SRC_STATUS_BEFORE" = "$SRC_STATUS_AFTER" ]; then
  ok "--dry-run mutated nothing (fixture HEAD + tree unchanged; no pull/install ran)"
else
  fail_test "--dry-run mutated the fixture repo (HEAD or tree changed) — isolation broken"
fi

# ── 6. Guard: missing .source ────────────────────────────────────────────────
NOSRC_MANIFEST="$TMP/nosrc-manifest.json"
printf '{ "collection_version": "6.0.10" }\n' > "$NOSRC_MANIFEST"
NOSRC_OUT=$(POST_LAND_SYNC_MANIFEST="$NOSRC_MANIFEST" bash "$HELPER" --dry-run 2>&1)
NOSRC_RC=$?
if [ "$NOSRC_RC" -ne 0 ] && printf '%s' "$NOSRC_OUT" | grep -qiE 'GUARD FAILED.*source.*(missing|empty)'; then
  ok "guard: missing .source → non-zero exit ($NOSRC_RC) + named GUARD-FAILED message"
else
  fail_test "guard: missing .source should fail loud (rc=$NOSRC_RC); output: $NOSRC_OUT"
fi

# ── 7. Guard: .source not on main ────────────────────────────────────────────
# Move the fixture repo to a non-main branch.
git -C "$FIXTURE_SRC" checkout -q -b feature-x 2>/dev/null || true
NOTMAIN_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$HELPER" --dry-run 2>&1)
NOTMAIN_RC=$?
if [ "$NOTMAIN_RC" -ne 0 ] && printf '%s' "$NOTMAIN_OUT" | grep -qiE "not on branch 'main'"; then
  ok "guard: .source not on main → non-zero exit ($NOTMAIN_RC) + \"not on branch 'main'\" message"
else
  fail_test "guard: non-main .source should fail loud (rc=$NOTMAIN_RC); output: $NOTMAIN_OUT"
fi
# Restore to main for subsequent cases.
git -C "$FIXTURE_SRC" checkout -q main 2>/dev/null || true

# ── 8. Guard: .source dirty (tracked change) ─────────────────────────────────
printf 'dirty\n' >> "$FIXTURE_SRC/VERSION"   # modify a TRACKED file
DIRTY_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$HELPER" --dry-run 2>&1)
DIRTY_RC=$?
if [ "$DIRTY_RC" -ne 0 ] && printf '%s' "$DIRTY_OUT" | grep -qi 'dirty working tree'; then
  ok "guard: dirty .source (tracked change) → non-zero exit ($DIRTY_RC) + 'dirty working tree' message"
else
  fail_test "guard: dirty .source should fail loud (rc=$DIRTY_RC); output: $DIRTY_OUT"
fi
# Restore the tracked file to clean.
git -C "$FIXTURE_SRC" checkout -q -- VERSION 2>/dev/null || true

# ── 9. Guard: .source not a git repo ─────────────────────────────────────────
NONREPO_DIR="$TMP/not-a-repo"
mkdir -p "$NONREPO_DIR"
NONREPO_MANIFEST="$TMP/nonrepo-manifest.json"
cat > "$NONREPO_MANIFEST" <<EOF
{ "source": "$NONREPO_DIR", "collection_version": "6.0.10" }
EOF
NONREPO_OUT=$(POST_LAND_SYNC_MANIFEST="$NONREPO_MANIFEST" bash "$HELPER" --dry-run 2>&1)
NONREPO_RC=$?
if [ "$NONREPO_RC" -ne 0 ] && printf '%s' "$NONREPO_OUT" | grep -qi 'not a git repository'; then
  ok "guard: non-git .source → non-zero exit ($NONREPO_RC) + 'not a git repository' message"
else
  fail_test "guard: non-git .source should fail loud (rc=$NONREPO_RC); output: $NONREPO_OUT"
fi

# ── 10. Untracked-only files do NOT trip the dirty guard ─────────────────────
printf 'scratch\n' > "$FIXTURE_SRC/scratch-untracked.txt"   # UNTRACKED file
UNTRACKED_OUT=$(POST_LAND_SYNC_MANIFEST="$GOOD_MANIFEST" bash "$HELPER" --dry-run 2>&1)
UNTRACKED_RC=$?
if [ "$UNTRACKED_RC" -eq 0 ]; then
  ok "untracked-only files in .source do NOT trip the dirty guard (--dry-run exits 0)"
else
  fail_test "untracked-only .source should NOT trip the dirty guard (rc=$UNTRACKED_RC); output: $UNTRACKED_OUT"
fi
rm -f "$FIXTURE_SRC/scratch-untracked.txt"

# ── Isolation backstop: real ~/.claude collection_version unchanged ──────────
if [ -f "$REAL_MANIFEST" ]; then
  REAL_CV_AFTER=$(command jq -r '.collection_version // empty' "$REAL_MANIFEST" 2>/dev/null | tr -d '\r' || echo "")
  if [ "$REAL_CV_BEFORE" = "$REAL_CV_AFTER" ]; then
    ok "real ~/.claude collection_version unchanged by this test ($REAL_CV_AFTER)"
  else
    fail_test "real ~/.claude collection_version CHANGED ($REAL_CV_BEFORE → $REAL_CV_AFTER) — test mutated the real install!"
  fi
fi

echo
if [ "$ERRORS" -eq 0 ]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL ($ERRORS error(s))"
  exit 1
fi
