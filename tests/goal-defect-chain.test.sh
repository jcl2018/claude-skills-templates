#!/usr/bin/env bash
# tests/goal-defect-chain.test.sh — CI-nightly chain drill for the `defect`
# verb's DETERMINISTIC helper chain (goal-defect topic, CI-nightly point).
#
# Where the CI-push smoke (tests/cj-goal-defect-smoke.test.sh) probes each
# helper phase in isolation with --dry-run, this drill drives the defect verb's
# helper chain END TO END in ONE hermetic temp sandbox — a REAL worktree is
# created, the D-ID claim engine previews its mint, and the LAND TAIL seams
# (recap before+after pair, post-land sync preview, janitor preview) run in
# pipeline order. Heavier than the per-PR budget, so it is registered in
# scripts/test.sh UNDER the TEST_FAST=1 guard (the test-deploy pattern): the
# per-PR gate (validate.yml, TEST_FAST=1) SKIPs it; the nightly full suite
# (.github/workflows/nightly.yml, no flag) runs it every night.
#
# Chain steps (the /CJ_goal_defect pipeline's deterministic seams, in order):
#   (1) cj-worktree-init.sh --caller defect (REAL run) → state=created,
#       cj-def-* branch, worktree dir exists (the worktree entry)
#   (2) scripts/cj-id-claim.sh --prefix D --floor <N> --dry-run (inside the
#       worktree) → CLAIMED_ID=D[0-9]{6} preview, exit 0, NO claim dir created
#       (the atomic D-ID mint the defect promotion step uses; dry-run mutates
#       nothing by contract)
#   (3) cj-goal-common.sh --phase pr-check --mode defect → exit 0,
#       PHASE=pr-check, PHASE_RESULT in {ok, skipped} (read-only; skipped when
#       gh is offline — both are the documented exit-0 contract)
#   (4) cj-goal-common.sh --phase recap --mode defect --when before, then
#       --when after → the true BEFORE+AFTER recap pair the landing verbs emit
#       around /land-and-deploy: "=== About to land ===" then
#       "=== Landed / PR opened ===", each with the three labelled sections,
#       PHASE_RESULT=ok (F000068)
#   (5) POST_LAND_SYNC_MANIFEST=<temp fixture> post-land-sync.sh --dry-run →
#       exit 0, resolves the fixture .source, prints the would-run
#       `git ... pull --ff-only` + `skills-deploy install` commands, and mutates
#       NOTHING (the defect verb's post-land local-sync tail, previewed against
#       a throwaway fixture manifest — never the real ~/.claude)
#   (6) scripts/cj-worktree-cleanup.sh --dry-run → RESULT in {ok, skipped},
#       mutates NOTHING (the worktree created in (1) still exists)
#
# Hermetic: everything runs in a mktemp git sandbox + a temp fixture manifest
# (the post-land-sync.test.sh idiom); no real repo, ~/.claude, or network
# mutation. The /CJ_goal_defect skill (agent prose) and the gstack /investigate,
# /ship + /land-and-deploy tails are never invoked — helper SCRIPTS are the
# deterministic ceiling.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
WT_HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"
ID_CLAIM="$REPO_ROOT/scripts/cj-id-claim.sh"
PLS="$REPO_ROOT/scripts/post-land-sync.sh"
CLEANUP_HELPER="$REPO_ROOT/scripts/cj-worktree-cleanup.sh"

for h in "$WT_HELPER" "$COMMON" "$ID_CLAIM" "$PLS" "$CLEANUP_HELPER"; do
  [ -x "$h" ] || { echo "FAIL: $h not executable"; exit 1; }
done

# Hermetic sandbox: a fresh throwaway git repo — the whole chain runs inside it.
SBX=$(mktemp -d -t goal-defect-chain.XXXXXX)
cleanup() {
  if [ -n "${SBX:-}" ] && [ -d "$SBX" ]; then
    (cd "$SBX" 2>/dev/null && git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
      [ "$wt" != "$SBX" ] && git worktree remove --force "$wt" 2>/dev/null || true
    done) || true
    rm -rf "$SBX"
  fi
}
trap cleanup EXIT
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

# || true: under `set -euo pipefail` a no-match grep would otherwise kill the
# drill on a bare `VAR=$(getkey ...)` assignment — return empty instead.
getkey() { printf '%s\n' "$2" | grep "^$1=" | head -1 | cut -d= -f2- || true; }

# ---------- Step 1: worktree entry (REAL) — --caller defect → cj-def-* ----------

echo ""
echo "Step 1: cj-worktree-init.sh --caller defect (REAL) → state=created, cj-def-* worktree..."
OUT=$(cd "$SBX" && bash "$WT_HELPER" --caller defect 2>/dev/null | tail -1)
STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
WT_PATH=$(echo "$OUT" | jq -r '.path' 2>/dev/null || echo "")
if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-def-[0-9]{8}-[0-9]{6}-[0-9]+$' && [ -d "$WT_PATH" ]; then
  ok "Step 1: state=created branch=$BRANCH, worktree dir exists (real defect worktree entry)"
else
  fail_test "Step 1: expected a REAL created cj-def-* worktree; got: $OUT"
fi

# ---------- Step 2: cj-id-claim.sh --prefix D --floor <N> --dry-run ----------
# The atomic D-ID claim engine (the defect promotion's ID source #4), previewed:
# dry-run prints the would-be CLAIMED_ID and creates NOTHING under the shared
# .git claim root. Run from INSIDE the worktree (the claim root is the SHARED
# git-common-dir, the cross-worktree CAS property).

echo ""
echo "Step 2: cj-id-claim.sh --prefix D --floor 7 --dry-run (in the worktree) → CLAIMED_ID=D... preview, no claim dir..."
OUT=$(cd "$WT_PATH" && bash "$ID_CLAIM" --prefix D --floor 7 --dry-run 2>/dev/null) && RC=0 || RC=$?
CLAIMED=$(getkey CLAIMED_ID "$OUT")
# Normalize the shared claim root to absolute (git may print a RELATIVE
# --git-common-dir); an absent/empty root counts as zero claims.
CLAIM_ROOT=$( (cd "$SBX" && cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd) || true)
N_CLAIMS=0
if [ -n "$CLAIM_ROOT" ] && [ -d "$CLAIM_ROOT/cj-id-claims" ]; then
  N_CLAIMS=$(find "$CLAIM_ROOT/cj-id-claims" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -c . || true)
fi
if [ "$RC" -eq 0 ] && echo "$CLAIMED" | grep -qE '^D[0-9]{6}$' && [ "${N_CLAIMS:-0}" = "0" ]; then
  ok "Step 2: dry-run previews CLAIMED_ID=$CLAIMED (floor honored, D-prefix) and creates NO claim dir"
else
  fail_test "Step 2: expected exit 0 + CLAIMED_ID=D<6 digits> + zero claim dirs; got rc=$RC claimed='$CLAIMED' claims=$N_CLAIMS: $OUT"
fi

# ---------- Step 3: --phase pr-check --mode defect → exit 0, documented fields ----------

echo ""
echo "Step 3: cj-goal-common.sh --phase pr-check --mode defect → exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped}..."
OUT=$(cd "$SBX" && bash "$COMMON" --phase pr-check --mode defect 2>/dev/null) && RC=0 || RC=$?
PC=$(getkey PHASE "$OUT"); PCR=$(getkey PHASE_RESULT "$OUT")
if [ "$RC" -eq 0 ] && [ "$PC" = "pr-check" ] && { [ "$PCR" = "ok" ] || [ "$PCR" = "skipped" ]; }; then
  ok "Step 3: exit 0, PHASE=pr-check, PHASE_RESULT=$PCR (read-only, offline-tolerant)"
else
  fail_test "Step 3: expected exit 0 + PHASE=pr-check + PHASE_RESULT in {ok,skipped}; got rc=$RC: $OUT"
fi

# ---------- Step 4: recap BEFORE + AFTER pair (the landing-verb bracket) ----------

echo ""
echo "Step 4: cj-goal-common.sh --phase recap --mode defect --when before, then --when after → the land bracket..."
OUT_B=$(bash "$COMMON" --phase recap --mode defect --when before \
  --field "delivered=defect chain delivered line" \
  --field "e2e=defect chain e2e line" \
  --field "next=defect chain next line" 2>/dev/null) && RC_B=0 || RC_B=$?
OUT_A=$(bash "$COMMON" --phase recap --mode defect --when after \
  --field "delivered=defect chain delivered line" \
  --field "e2e=defect chain e2e line" \
  --field "next=defect chain next line" 2>/dev/null) && RC_A=0 || RC_A=$?
if [ "$RC_B" -eq 0 ] && [ "$(getkey WHEN "$OUT_B")" = "before" ] \
   && [ "$(getkey PHASE_RESULT "$OUT_B")" = "ok" ] \
   && echo "$OUT_B" | grep -qF "=== About to land ===" \
   && echo "$OUT_B" | grep -qF "Delivered:" && echo "$OUT_B" | grep -qF "defect chain delivered line"; then
  ok "Step 4a: BEFORE recap renders '=== About to land ===' + labelled sections, PHASE_RESULT=ok"
else
  fail_test "Step 4a: expected the BEFORE recap; got rc=$RC_B: $OUT_B"
fi
if [ "$RC_A" -eq 0 ] && [ "$(getkey WHEN "$OUT_A")" = "after" ] \
   && [ "$(getkey PHASE_RESULT "$OUT_A")" = "ok" ] \
   && echo "$OUT_A" | grep -qF "=== Landed / PR opened ===" \
   && echo "$OUT_A" | grep -qF "How to E2E-test it:" && echo "$OUT_A" | grep -qF "defect chain e2e line" \
   && echo "$OUT_A" | grep -qF "Next step:" && echo "$OUT_A" | grep -qF "defect chain next line"; then
  ok "Step 4b: AFTER recap renders '=== Landed / PR opened ===' + labelled sections, PHASE_RESULT=ok"
else
  fail_test "Step 4b: expected the AFTER recap; got rc=$RC_A: $OUT_A"
fi

# ---------- Step 5: post-land-sync.sh --dry-run against a temp fixture manifest ----------
# The defect verb's post-land tail, previewed HERMETICALLY: a temp manifest whose
# .source is a throwaway clean-on-main git repo (the post-land-sync.test.sh
# idiom). The real ~/.claude manifest is never read or written.

echo ""
echo "Step 5: POST_LAND_SYNC_MANIFEST=<temp fixture> post-land-sync.sh --dry-run → preview, no mutation..."
FIX="$SBX/pls-fixture"
mkdir -p "$FIX/source-repo"
(
  cd "$FIX/source-repo"
  git init -q
  git config user.email "test@test"
  git config user.name "test"
  git checkout -q -b main 2>/dev/null || git branch -q -m main 2>/dev/null || true
  printf '9.9.9\n' > VERSION
  mkdir -p scripts
  printf '#!/usr/bin/env bash\necho "fake skills-deploy %s"\n' '$*' > scripts/skills-deploy
  chmod +x scripts/skills-deploy
  git add -A
  git commit -qm "fixture: initial"
)
cat > "$FIX/manifest.json" <<EOF
{
  "source": "$FIX/source-repo",
  "collection_version": "9.9.9"
}
EOF
FIX_HEAD_BEFORE=$(git -C "$FIX/source-repo" rev-parse HEAD 2>/dev/null || echo "")
OUT=$(POST_LAND_SYNC_MANIFEST="$FIX/manifest.json" bash "$PLS" --dry-run 2>&1) && RC=0 || RC=$?
FIX_HEAD_AFTER=$(git -C "$FIX/source-repo" rev-parse HEAD 2>/dev/null || echo "")
if [ "$RC" -eq 0 ] \
   && printf '%s' "$OUT" | grep -qF "$FIX/source-repo" \
   && printf '%s' "$OUT" | grep -qE 'git .*pull --ff-only' \
   && printf '%s' "$OUT" | grep -q 'skills-deploy.*install' \
   && [ "$FIX_HEAD_BEFORE" = "$FIX_HEAD_AFTER" ]; then
  ok "Step 5: dry-run resolves the fixture .source, prints the would-run pull+install, mutates nothing"
else
  fail_test "Step 5: expected exit 0 + resolved .source + would-run commands + no mutation; got rc=$RC: $OUT"
fi

# ---------- Step 6: cj-worktree-cleanup.sh --dry-run → previews, mutates nothing ----------

echo ""
echo "Step 6: cj-worktree-cleanup.sh --dry-run → RESULT in {ok,skipped}, worktree from Step 1 untouched..."
OUT=$(cd "$SBX" && bash "$CLEANUP_HELPER" --dry-run --caller defect 2>/dev/null) && RC=0 || RC=$?
CRES=$(getkey RESULT "$OUT")
if [ "$RC" -eq 0 ] && { [ "$CRES" = "ok" ] || [ "$CRES" = "skipped" ]; } && [ -d "$WT_PATH" ]; then
  ok "Step 6: dry-run janitor exits 0 (RESULT=$CRES) and the Step-1 worktree still exists (no mutation)"
else
  fail_test "Step 6: expected exit 0 + RESULT in {ok,skipped} + untouched worktree; got rc=$RC: $OUT"
fi

# ---------- Summary ----------

echo ""
echo "=== goal-defect-chain.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
