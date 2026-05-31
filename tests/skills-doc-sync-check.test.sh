#!/usr/bin/env bash
# tests/skills-doc-sync-check.test.sh — tests for scripts/skills-doc-sync-check.
#
# F000029 / S000062: doc-sync marker pickup AUQ. The script is the detection
# side of the F000028 hook → F000029 AUQ loop. Eight rows covering the parent
# design's Success Criteria + SPEC AC list:
#   (a) silent when no marker
#   (b) emits on present marker
#   (c) snooze suppresses for 24h then re-fires
#   (d) skip suppresses by head_sha (new sha re-fires)
#   (e) --resolved clears state
#   (e2) --resolved is idempotent when marker already gone
#   (f) stale head_sha (unreachable) self-cleans
#   (g) corrupted marker JSON self-cleans via stale-SHA path
#   (h) script remains silent on non-main branches (its only job is "is there a
#       marker"; branch-aware AUQ option ordering lives in SKILL.md prose)
#
# Pattern: per-case sandbox via mktemp -d. Each case creates a fake repo on
# `main` plus a scoped HOME so the marker dir + cache file never touch the
# operator's real state. Pre-script knobs DOC_SYNC_MARKER_DIR + DOC_SYNC_CACHE
# override the default locations; combined with HOME=$tmpdir/.fake-home they
# give us full state isolation per row.

set -uo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
DOC_SYNC_CHECK="$REPO_ROOT/scripts/skills-doc-sync-check"

[ -x "$DOC_SYNC_CHECK" ] || { echo "FAIL: $DOC_SYNC_CHECK not executable"; exit 1; }

# ---------- per-case sandbox factory ----------
#
# Builds an isolated git repo on `main` with a single seed commit. Returns
# the sandbox root path. Inside the sandbox:
#   $sbx/                 — git repo (cwd for `git rev-parse --show-toplevel`)
#   $sbx/.fake-home/      — scoped HOME (the script reads $HOME for cache fallback)
#   $sbx/.fake-home/.gstack/doc-sync-pending/<slug>.json   — marker path
#   $sbx/.fake-home/.gstack/doc-sync-cache.json            — cache path
#
# Slug is the basename of $sbx (the script computes the same via
# `basename $(git rev-parse --show-toplevel)`).

mk_sandbox() {
  local dir slug
  dir=$(mktemp -d -t doc-sync-check-test.XXXXXX)
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
  mkdir -p "$dir/.fake-home/.gstack/doc-sync-pending"
  # Echo the path so the caller can capture it.
  printf '%s' "$dir"
}

cleanup_sandbox() {
  local d="$1"
  [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
}

# Helper: run the doc-sync check from within a sandbox, under scoped HOME.
# Echoes stdout, returns the script's exit code.
run_check() {
  local sbx="$1"; shift
  ( cd "$sbx" && HOME="$sbx/.fake-home" \
    DOC_SYNC_MARKER_DIR="$sbx/.fake-home/.gstack/doc-sync-pending" \
    DOC_SYNC_CACHE="$sbx/.fake-home/.gstack/doc-sync-cache.json" \
    bash "$DOC_SYNC_CHECK" "$@" )
}

# Plant a marker for the sandbox using a given head_sha. If sha is empty,
# defaults to the sandbox's current HEAD (the typical "fresh post-merge" case).
plant_marker() {
  local sbx="$1"
  local sha="${2:-}"
  if [ -z "$sha" ]; then
    sha=$(git -C "$sbx" rev-parse HEAD)
  fi
  local slug
  slug=$(basename "$sbx")
  local marker_path="$sbx/.fake-home/.gstack/doc-sync-pending/${slug}.json"
  cat > "$marker_path" <<EOF
{
  "repo": "$slug",
  "head_sha": "$sha",
  "main_moved_at": "2026-05-30T22:00:00Z",
  "diff_base": "${sha}^",
  "changed_files": 3
}
EOF
  printf '%s' "$marker_path"
}

marker_path_for() {
  local sbx="$1"
  local slug
  slug=$(basename "$sbx")
  printf '%s' "$sbx/.fake-home/.gstack/doc-sync-pending/${slug}.json"
}

cache_path_for() {
  local sbx="$1"
  printf '%s' "$sbx/.fake-home/.gstack/doc-sync-cache.json"
}

# ---------- Case (a): silent when no marker ----------
echo ""
echo "Case (a): silent when no marker..."
SBX_A=$(mk_sandbox)
OUT=$(run_check "$SBX_A" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (a): no marker → silent + exit 0"
else
  fail_test "Case (a): expected silent exit 0, got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_A"

# ---------- Case (b): emits on present marker ----------
echo ""
echo "Case (b): emits DOC_SYNC_PENDING on present marker..."
SBX_B=$(mk_sandbox)
plant_marker "$SBX_B" >/dev/null
OUT=$(run_check "$SBX_B" 2>&1)
RC=$?
EXPECTED_PATH=$(marker_path_for "$SBX_B")
if [ "$RC" -eq 0 ] && [ "$OUT" = "DOC_SYNC_PENDING $EXPECTED_PATH" ]; then
  ok "Case (b): emits 'DOC_SYNC_PENDING <path>' + exit 0"
else
  fail_test "Case (b): expected 'DOC_SYNC_PENDING $EXPECTED_PATH', got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_B"

# ---------- Case (c): snooze suppresses for 24h, then re-fires ----------
echo ""
echo "Case (c): --snooze 24 suppresses for 24h then re-fires..."
SBX_C=$(mk_sandbox)
plant_marker "$SBX_C" >/dev/null
run_check "$SBX_C" --snooze 24 >/dev/null 2>&1 || true
OUT=$(run_check "$SBX_C" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (c.1): post --snooze → silent"
else
  fail_test "Case (c.1): expected silent after --snooze, got rc=$RC output='$OUT'"
fi
# Verify cache has snooze_until set ~24h in the future.
CACHE_C=$(cache_path_for "$SBX_C")
if [ -f "$CACHE_C" ]; then
  SNOOZE=$(jq -r '.snooze_until // empty' "$CACHE_C" 2>/dev/null)
  NOW=$(date +%s)
  EXPECTED_MIN=$(( NOW + 86000 ))  # 24h minus ~6min slop
  EXPECTED_MAX=$(( NOW + 86800 ))  # 24h plus ~6min slop
  if [ -n "$SNOOZE" ] && [ "$SNOOZE" -ge "$EXPECTED_MIN" ] && [ "$SNOOZE" -le "$EXPECTED_MAX" ]; then
    ok "Case (c.2): snooze_until is ~24h ahead"
  else
    fail_test "Case (c.2): snooze_until=$SNOOZE not in [$EXPECTED_MIN, $EXPECTED_MAX]"
  fi
else
  fail_test "Case (c.2): cache file missing after --snooze"
fi
# Simulate expiry by rewriting cache snooze_until to a past timestamp.
PAST=$(( NOW - 60 ))
jq --argjson p "$PAST" '.snooze_until = $p' "$CACHE_C" > "$CACHE_C.tmp" && mv "$CACHE_C.tmp" "$CACHE_C"
OUT=$(run_check "$SBX_C" 2>&1)
RC=$?
EXPECTED_PATH=$(marker_path_for "$SBX_C")
if [ "$RC" -eq 0 ] && [ "$OUT" = "DOC_SYNC_PENDING $EXPECTED_PATH" ]; then
  ok "Case (c.3): after snooze expires → re-fires"
else
  fail_test "Case (c.3): expected re-fire after snooze expiry, got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_C"

# ---------- Case (d): skip suppresses by head_sha; new sha re-fires ----------
echo ""
echo "Case (d): --skip <head_sha> suppresses; new head_sha re-fires..."
SBX_D=$(mk_sandbox)
SHA_D=$(git -C "$SBX_D" rev-parse HEAD)
plant_marker "$SBX_D" "$SHA_D" >/dev/null
run_check "$SBX_D" --skip "$SHA_D" >/dev/null 2>&1 || true
OUT=$(run_check "$SBX_D" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (d.1): post --skip with matching sha → silent"
else
  fail_test "Case (d.1): expected silent after --skip, got rc=$RC output='$OUT'"
fi
# Add a second commit to produce a new HEAD; plant marker with the new sha.
(
  cd "$SBX_D"
  echo "second" > second.txt
  git add second.txt
  git commit -qm "second"
)
NEW_SHA=$(git -C "$SBX_D" rev-parse HEAD)
plant_marker "$SBX_D" "$NEW_SHA" >/dev/null
OUT=$(run_check "$SBX_D" 2>&1)
RC=$?
EXPECTED_PATH=$(marker_path_for "$SBX_D")
if [ "$RC" -eq 0 ] && [ "$OUT" = "DOC_SYNC_PENDING $EXPECTED_PATH" ]; then
  ok "Case (d.2): new head_sha re-fires (skip is per-sha, not global)"
else
  fail_test "Case (d.2): expected re-fire on new head_sha, got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_D"

# ---------- Case (e): --resolved deletes marker + clears cache ----------
echo ""
echo "Case (e): --resolved deletes marker + clears snooze/skip cache..."
SBX_E=$(mk_sandbox)
SHA_E=$(git -C "$SBX_E" rev-parse HEAD)
plant_marker "$SBX_E" "$SHA_E" >/dev/null
# Seed both snooze and skip in the cache to verify both are cleared.
run_check "$SBX_E" --snooze 24 >/dev/null 2>&1 || true
run_check "$SBX_E" --skip "$SHA_E" >/dev/null 2>&1 || true
CACHE_E=$(cache_path_for "$SBX_E")
PRE_SNOOZE=$(jq -r '.snooze_until // empty' "$CACHE_E" 2>/dev/null)
PRE_SKIP=$(jq -r '.skip_head_sha // empty' "$CACHE_E" 2>/dev/null)
if [ -n "$PRE_SNOOZE" ] && [ -n "$PRE_SKIP" ]; then
  ok "Case (e.0): cache pre-seeded with snooze_until + skip_head_sha"
else
  fail_test "Case (e.0): cache seed failed; snooze=$PRE_SNOOZE skip=$PRE_SKIP"
fi
run_check "$SBX_E" --resolved >/dev/null 2>&1 || true
MARKER_E=$(marker_path_for "$SBX_E")
if [ ! -f "$MARKER_E" ]; then
  ok "Case (e.1): marker deleted by --resolved"
else
  fail_test "Case (e.1): marker still present after --resolved"
fi
POST_SNOOZE=$(jq -r '.snooze_until // empty' "$CACHE_E" 2>/dev/null)
POST_SKIP=$(jq -r '.skip_head_sha // empty' "$CACHE_E" 2>/dev/null)
if [ -z "$POST_SNOOZE" ] && [ -z "$POST_SKIP" ]; then
  ok "Case (e.2): snooze_until + skip_head_sha cleared from cache"
else
  fail_test "Case (e.2): cache not cleared; snooze=$POST_SNOOZE skip=$POST_SKIP"
fi
# Next default check should be silent (no marker).
OUT=$(run_check "$SBX_E" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (e.3): post --resolved → default check silent"
else
  fail_test "Case (e.3): expected silent after --resolved, got rc=$RC output='$OUT'"
fi

# ---------- Case (e2): --resolved is idempotent when marker already gone ----------
echo ""
echo "Case (e2): --resolved idempotent silent-success when marker absent..."
OUT=$(run_check "$SBX_E" --resolved 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (e2): second --resolved → silent exit 0 (idempotent)"
else
  fail_test "Case (e2): expected silent idempotent success, got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_E"

# ---------- Case (f): stale head_sha (unreachable) self-cleans ----------
echo ""
echo "Case (f): stale head_sha (unreachable from HEAD) → silent self-delete..."
SBX_F=$(mk_sandbox)
# Plant a marker with a SHA that is not in the repo (40 zeros — guaranteed unreachable).
plant_marker "$SBX_F" "0000000000000000000000000000000000000000" >/dev/null
MARKER_F=$(marker_path_for "$SBX_F")
[ -f "$MARKER_F" ] || fail_test "Case (f.0): planted marker missing"
OUT=$(run_check "$SBX_F" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (f.1): unreachable head_sha → silent + exit 0"
else
  fail_test "Case (f.1): expected silent exit 0, got rc=$RC output='$OUT'"
fi
if [ ! -f "$MARKER_F" ]; then
  ok "Case (f.2): stale marker auto-deleted"
else
  fail_test "Case (f.2): stale marker still present"
fi
cleanup_sandbox "$SBX_F"

# ---------- Case (g): corrupted marker JSON triggers self-clean via stale-SHA path ----------
echo ""
echo "Case (g): corrupted marker JSON → silent self-delete via stale-SHA path..."
SBX_G=$(mk_sandbox)
MARKER_G=$(marker_path_for "$SBX_G")
# Write literal `{` — truncated, non-parseable JSON.
printf '%s' "{" > "$MARKER_G"
OUT=$(run_check "$SBX_G" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (g.1): corrupted JSON → silent + exit 0"
else
  fail_test "Case (g.1): expected silent exit 0, got rc=$RC output='$OUT'"
fi
if [ ! -f "$MARKER_G" ]; then
  ok "Case (g.2): corrupted marker auto-deleted (empty SHA fell into stale path)"
else
  fail_test "Case (g.2): corrupted marker still present"
fi
cleanup_sandbox "$SBX_G"

# ---------- Case (h): script silent on non-main branches too ----------
#
# The script's only job is "is there a marker, and if so, print its path."
# Branch-aware AUQ option ordering (Y on main, Snooze 1h on feature branch)
# lives in the SKILL.md prose, NOT in this script. So on a non-main branch
# with NO marker, the script still exits silent — same as on main.
# With a marker present on a non-main branch, the script still emits
# DOC_SYNC_PENDING (the marker is repo-keyed, not branch-keyed). This row
# asserts the script does NOT silence itself based on branch; the orchestrator
# is the one that downgrades the AUQ recommendation.
echo ""
echo "Case (h): script does not branch-discriminate (silence-on-non-main is SKILL.md prose's job)..."
SBX_H=$(mk_sandbox)
# Branch off main onto a feature branch.
git -C "$SBX_H" checkout -q -b feat/test-branch 2>/dev/null
# (h.1) No marker, non-main branch → silent (same as main behavior).
OUT=$(run_check "$SBX_H" 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "Case (h.1): no marker on non-main branch → silent + exit 0"
else
  fail_test "Case (h.1): expected silent exit 0 on non-main, got rc=$RC output='$OUT'"
fi
# (h.2) Marker present, non-main branch → script STILL emits (it does not
# branch-discriminate). The orchestrator handles branch-aware AUQ ordering.
plant_marker "$SBX_H" >/dev/null
OUT=$(run_check "$SBX_H" 2>&1)
RC=$?
EXPECTED_PATH=$(marker_path_for "$SBX_H")
if [ "$RC" -eq 0 ] && [ "$OUT" = "DOC_SYNC_PENDING $EXPECTED_PATH" ]; then
  ok "Case (h.2): marker on non-main branch → script STILL emits (branch logic = orchestrator's job)"
else
  fail_test "Case (h.2): expected DOC_SYNC_PENDING on non-main, got rc=$RC output='$OUT'"
fi
cleanup_sandbox "$SBX_H"

# ---------- summary ----------
echo ""
echo "================================================================"
if [ "$ERRORS" -eq 0 ]; then
  echo "PASS: all 8 cases (a, b, c, d, e, e2, f, g, h) green"
  exit 0
else
  echo "FAIL: $ERRORS assertion(s) failed across 8 cases"
  exit 1
fi
