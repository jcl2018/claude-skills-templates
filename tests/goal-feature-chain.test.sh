#!/usr/bin/env bash
# tests/goal-feature-chain.test.sh — CI-nightly chain drill for the `feature`
# verb's DETERMINISTIC helper chain (goal-feature topic, CI-nightly point).
#
# Where the CI-push smoke (tests/cj-goal-feature-smoke.test.sh) probes each
# helper phase in isolation with --dry-run, this drill drives the feature verb's
# helper chain END TO END in ONE hermetic temp sandbox — a REAL worktree is
# created, each phase runs against it in pipeline order, and each phase's
# documented contract fields are asserted. Heavier than the per-PR budget, so it
# is registered in scripts/test.sh UNDER the TEST_FAST=1 guard (the test-deploy
# pattern): the per-PR gate (validate.yml, TEST_FAST=1) SKIPs it; the nightly
# full suite (.github/workflows/nightly.yml, no flag) runs it every night.
#
# Chain steps (the /CJ_goal_feature pipeline's deterministic seams, in order):
#   (1) cj-worktree-init.sh --caller feature (REAL run) → state=created,
#       cj-feat-* branch, worktree dir exists; then --assert-isolated from
#       INSIDE the new worktree → state=isolated (the isolation gate verdict)
#   (2) cj-goal-common.sh --phase sync --mode feature --no-sync →
#       PHASE_RESULT=skipped + SYNC_RAN=0 (the operator's opt-out short-circuit;
#       hermetic — no install is ever attempted)
#   (3) cj-goal-common.sh --phase pr-check --mode feature → exit 0, PHASE=pr-check,
#       PHASE_RESULT in {ok, skipped} (read-only; skipped when gh is offline —
#       both are the documented exit-0 contract)
#   (4) scripts/cj-e2e-gate.sh --gate design-gate → AUTO=inactive with NO guards
#       set, then AUTO=continue under the double guard (CJ_GOAL_E2E_AUTO=1 + a
#       .cj-e2e-sandbox marker at the sandbox root) — the design-gate seam of
#       the feature pipeline, both verdicts
#   (5) cj-goal-common.sh --phase recap --when after --field delivered/e2e/next →
#       the at-PR 3-part recap: "=== Landed / PR opened ===" header + the three
#       labelled sections rendered verbatim, PHASE_RESULT=ok (the feature verb's
#       PR-stop recap, F000068)
#   (6) scripts/cj-worktree-cleanup.sh --dry-run → RESULT in {ok, skipped},
#       mutates NOTHING (the worktree created in (1) still exists — dry-run is
#       the preview contract)
#
# Hermetic: everything runs in a mktemp git sandbox; no real repo, ~/.claude, or
# network mutation ((2) short-circuits before any install; (3) is read-only and
# tolerates offline; (6) is --dry-run). The /CJ_goal_feature skill (agent prose)
# is never invoked — helper SCRIPTS are the deterministic ceiling.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
WT_HELPER="$REPO_ROOT/scripts/cj-worktree-init.sh"
COMMON="$REPO_ROOT/scripts/cj-goal-common.sh"
E2E_GATE="$REPO_ROOT/scripts/cj-e2e-gate.sh"
CLEANUP_HELPER="$REPO_ROOT/scripts/cj-worktree-cleanup.sh"

for h in "$WT_HELPER" "$COMMON" "$E2E_GATE" "$CLEANUP_HELPER"; do
  [ -x "$h" ] || { echo "FAIL: $h not executable"; exit 1; }
done

# Hermetic sandbox: a fresh throwaway git repo (the temp-clone idiom the sibling
# helper tests use) — the whole chain runs inside it.
SBX=$(mktemp -d -t goal-feature-chain.XXXXXX)
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

# ---------- Step 1: worktree entry (REAL) + --assert-isolated ----------

echo ""
echo "Step 1: cj-worktree-init.sh --caller feature (REAL) → created + cj-feat-* worktree, then --assert-isolated inside it..."
WT_PATH=""
OUT=$(cd "$SBX" && bash "$WT_HELPER" --caller feature 2>/dev/null | tail -1)
STATE=$(echo "$OUT" | jq -r '.state' 2>/dev/null || echo "")
BRANCH=$(echo "$OUT" | jq -r '.branch' 2>/dev/null || echo "")
WT_PATH=$(echo "$OUT" | jq -r '.path' 2>/dev/null || echo "")
if [ "$STATE" = "created" ] && echo "$BRANCH" | grep -qE '^cj-feat-[0-9]{8}-[0-9]{6}-[0-9]+$' && [ -d "$WT_PATH" ]; then
  ok "Step 1a: state=created branch=$BRANCH, worktree dir exists (real worktree entry)"
else
  fail_test "Step 1a: expected a REAL created cj-feat-* worktree; got: $OUT"
fi

if [ -d "$WT_PATH" ]; then
  AI_OUT=$(cd "$WT_PATH" && bash "$WT_HELPER" --caller feature --assert-isolated 2>/dev/null | tail -1) && AI_RC=0 || AI_RC=$?
  AI_STATE=$(echo "$AI_OUT" | jq -r '.state' 2>/dev/null || echo "")
  if [ "$AI_RC" -eq 0 ] && [ "$AI_STATE" = "isolated" ]; then
    ok "Step 1b: --assert-isolated inside the new worktree → state=isolated, exit 0 (the isolation-gate verdict)"
  else
    fail_test "Step 1b: expected state=isolated exit 0 inside the worktree; got rc=$AI_RC: $AI_OUT"
  fi
else
  fail_test "Step 1b: no worktree dir to assert isolation in (Step 1a failed)"
fi

# ---------- Step 2: --phase sync --no-sync → skipped short-circuit ----------

echo ""
echo "Step 2: cj-goal-common.sh --phase sync --mode feature --no-sync → PHASE_RESULT=skipped, SYNC_RAN=0..."
OUT=$(cd "$SBX" && bash "$COMMON" --phase sync --mode feature --no-sync 2>/dev/null) && RC=0 || RC=$?
if [ "$RC" -eq 0 ] && [ "$(getkey PHASE "$OUT")" = "sync" ] \
   && [ "$(getkey SYNC_RAN "$OUT")" = "0" ] && [ "$(getkey PHASE_RESULT "$OUT")" = "skipped" ]; then
  ok "Step 2: --no-sync short-circuits (PHASE_RESULT=skipped, SYNC_RAN=0 — no install attempted)"
else
  fail_test "Step 2: expected exit 0 + PHASE_RESULT=skipped + SYNC_RAN=0; got rc=$RC: $OUT"
fi

# ---------- Step 3: --phase pr-check → exit 0, documented fields ----------

echo ""
echo "Step 3: cj-goal-common.sh --phase pr-check --mode feature → exit 0, PHASE=pr-check, PHASE_RESULT in {ok,skipped}..."
OUT=$(cd "$SBX" && bash "$COMMON" --phase pr-check --mode feature 2>/dev/null) && RC=0 || RC=$?
PC=$(getkey PHASE "$OUT"); PCR=$(getkey PHASE_RESULT "$OUT")
if [ "$RC" -eq 0 ] && [ "$PC" = "pr-check" ] && { [ "$PCR" = "ok" ] || [ "$PCR" = "skipped" ]; }; then
  ok "Step 3: exit 0, PHASE=pr-check, PHASE_RESULT=$PCR (read-only, offline-tolerant)"
else
  fail_test "Step 3: expected exit 0 + PHASE=pr-check + PHASE_RESULT in {ok,skipped}; got rc=$RC: $OUT"
fi

# ---------- Step 4: design-gate seam — inactive without guards, continue with them ----------

echo ""
echo "Step 4: cj-e2e-gate.sh --gate design-gate → inactive bare; continue under CJ_GOAL_E2E_AUTO=1 + .cj-e2e-sandbox..."
V1=$(cd "$SBX" && env -u CJ_GOAL_E2E_AUTO bash "$E2E_GATE" --gate design-gate 2>/dev/null)
if [ "$V1" = "AUTO=inactive" ]; then
  ok "Step 4a: no guards → AUTO=inactive (a normal run is behavior-unchanged)"
else
  fail_test "Step 4a: expected AUTO=inactive without guards; got: $V1"
fi
touch "$SBX/.cj-e2e-sandbox"
V2=$(cd "$SBX" && CJ_GOAL_E2E_AUTO=1 bash "$E2E_GATE" --gate design-gate 2>/dev/null)
rm -f "$SBX/.cj-e2e-sandbox"
if [ "$V2" = "AUTO=continue" ]; then
  ok "Step 4b: double guard (env flag + sandbox marker) → AUTO=continue (design-gate auto-approves)"
else
  fail_test "Step 4b: expected AUTO=continue under the double guard; got: $V2"
fi

# ---------- Step 5: --phase recap --when after → the at-PR 3-part recap ----------

echo ""
echo "Step 5: cj-goal-common.sh --phase recap --when after → header + 3 labelled sections, PHASE_RESULT=ok..."
OUT=$(bash "$COMMON" --phase recap --mode feature --when after \
  --field "delivered=chain drill delivered line" \
  --field "e2e=chain drill e2e line" \
  --field "next=chain drill next line" 2>/dev/null) && RC=0 || RC=$?
if [ "$RC" -eq 0 ] && [ "$(getkey PHASE "$OUT")" = "recap" ] && [ "$(getkey WHEN "$OUT")" = "after" ] \
   && [ "$(getkey PHASE_RESULT "$OUT")" = "ok" ] \
   && echo "$OUT" | grep -qF "=== Landed / PR opened ===" \
   && echo "$OUT" | grep -qF "Delivered:" && echo "$OUT" | grep -qF "chain drill delivered line" \
   && echo "$OUT" | grep -qF "How to E2E-test it:" && echo "$OUT" | grep -qF "chain drill e2e line" \
   && echo "$OUT" | grep -qF "Next step:" && echo "$OUT" | grep -qF "chain drill next line"; then
  ok "Step 5: at-PR recap renders the AFTER header + all three sections verbatim, PHASE_RESULT=ok"
else
  fail_test "Step 5: expected the 3-part AFTER recap; got rc=$RC: $OUT"
fi

# ---------- Step 6: cj-worktree-cleanup.sh --dry-run → previews, mutates nothing ----------

echo ""
echo "Step 6: cj-worktree-cleanup.sh --dry-run → RESULT in {ok,skipped}, worktree from Step 1 untouched..."
OUT=$(cd "$SBX" && bash "$CLEANUP_HELPER" --dry-run --caller feature 2>/dev/null) && RC=0 || RC=$?
CRES=$(getkey RESULT "$OUT")
if [ "$RC" -eq 0 ] && { [ "$CRES" = "ok" ] || [ "$CRES" = "skipped" ]; } && [ -d "$WT_PATH" ]; then
  ok "Step 6: dry-run janitor exits 0 (RESULT=$CRES) and the Step-1 worktree still exists (no mutation)"
else
  fail_test "Step 6: expected exit 0 + RESULT in {ok,skipped} + untouched worktree; got rc=$RC dir=$([ -d "$WT_PATH" ] && echo yes || echo no): $OUT"
fi

# ---------- Summary ----------

echo ""
echo "=== goal-feature-chain.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
