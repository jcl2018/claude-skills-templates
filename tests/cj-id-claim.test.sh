#!/usr/bin/env bash
# tests/cj-id-claim.test.sh — test for scripts/cj-id-claim.sh (F000048 / S000084).
#
# The atomic-claim engine that closes the scaffold-before-push ID race. mkdir is
# the CAS; the claim dir lives under the SHARED `.git` common-dir so sibling
# worktrees see one root. These cases exercise the three engine phases (reap →
# same-branch reuse → atomic claim loop) plus the load-bearing properties: the
# looped concurrent race, both reap modes, prefix isolation, and cwd-independent
# common-dir resolution from a linked worktree + a nested subdir.
#
# Cases (map to S000084_TEST-SPEC.md smoke rows S1-S6 + the design's 7 cases):
#   (1) single claim above floor → floor+1                       [AC-1 / S1]
#   (2) LOOPED concurrent race (20+ rounds) → distinct IDs       [AC-2 / S2]
#   (3) reap on origin (ID merged on origin/main is removed)     [AC-3 / S3]
#   (4) reap on TTL (mtime older than --ttl-hours is removed)    [AC-4 / S4]
#   (5) prefix isolation (F vs S independent)                    [AC-7 / S6a]
#   (6) same-branch reuse + regressions:                         [AC-5 / S5]
#       6.0 happy path (re-run, live claim, no work-item dir → same ID)
#       6a  BLOCKER-1: 20 concurrent reusers of 1 live candidate → reused <=1x (.reuse-owner CAS)
#       6b  BLOCKER-2: a live claim below --floor is NOT reused (mints above floor)
#       6c  MINOR: --dry-run creates ZERO directories
#   (7) cwd-independence (common-dir resolves to the shared root [AC-7 / S6b]
#       from a linked worktree AND from a nested subdir)
#   (8) SLUG-LESS feature tracker `${id}_TRACKER.md` is matched on   [D-regress]
#       BOTH reap paths (regression for the reap regex/glob that
#       required a `_<slug>_` segment and so never matched a merged
#       FEATURE claim → stale claims accrued → next scaffold re-handed
#       an already-used F/S ID):
#       8a  reap-on-origin: a feature ID whose `${id}_TRACKER.md` is on
#           origin/main IS reaped (id_on_origin optional-slug regex)
#       8b  materialized-dir: once `${id}_TRACKER.md` exists locally the
#           same-branch reuse ADVANCES (id_has_workitem_dir two-name find)
#
# Harness style mirrors tests/cj-worktree-init.test.sh: ok/fail_test counters,
# a per-case temp git sandbox, subshell-per-case with _rc accounting, and a
# PASS/FAIL summary with a non-zero exit on any failure. Pure smoke — every claim
# happens inside a throwaway sandbox repo, so the live workbench `.git` is never
# touched.

set -euo pipefail

ERRORS=0
ok()        { echo "  OK:   $1"; }
# fail_test returns non-zero so a case subshell that ends with `... else fail_test
# ...; fi` exits non-zero — the parent's `case_N_rc=$?; [ ... -ne 0 ] && ERRORS++`
# then counts it (subshell-local ERRORS increments do NOT propagate to the parent).
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); return 1; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
HELPER="$REPO_ROOT/scripts/cj-id-claim.sh"

[ -x "$HELPER" ] || { echo "FAIL: $HELPER not executable"; exit 1; }

# ---------- Sandbox helpers ----------
#
# Each sandbox is an isolated git repo on branch `main` with one seed commit.
# The helper resolves CLAIM_ROOT under $PWD's git-common-dir, so running it from
# inside the sandbox keeps every claim dir under the sandbox's own `.git`.

mk_sandbox() {
  local dir
  dir=$(mktemp -d -t cj-id-claim-test.XXXXXX)
  (
    cd "$dir"
    git init -q
    git config user.email "test@test"
    git config user.name "test"
    git checkout -q -b main 2>/dev/null || true
    mkdir -p work-items
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
  )
  printf '%s' "$dir"
}

cleanup_sandboxes() {
  for d in "$@"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      (cd "$d" 2>/dev/null && git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
        [ "$wt" != "$d" ] && git worktree remove --force "$wt" 2>/dev/null || true
      done) || true
      rm -rf "$d"
    fi
  done
}

claim_root_of() {
  # Echo the absolute CLAIM_ROOT for the repo at $PWD (same resolution as helper).
  echo "$(cd "$(git rev-parse --git-common-dir)" && pwd)/cj-id-claims"
}

SBX1="" ; SBX2="" ; SBX3="" ; SBX4="" ; SBX5="" ; SBX6="" ; SBX7=""
SBX6A="" ; SBX6B="" ; SBX6C="" ; SBX8="" ; SBX8B=""
trap 'cleanup_sandboxes "$SBX1" "$SBX2" "$SBX3" "$SBX4" "$SBX5" "$SBX6" "$SBX7" "$SBX6A" "$SBX6B" "$SBX6C" "$SBX8" "$SBX8B"' EXIT

# ---------- Case 1: single claim above floor → floor+1 ----------

echo ""
echo "Case 1: single claim above floor → floor+1 (F000048 from --floor 47)..."
SBX1=$(mk_sandbox)
(
  cd "$SBX1"
  OUT=$(bash "$HELPER" --prefix F --floor 47 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  if [ "$RC" -eq 0 ] && [ "$ID" = "F000048" ]; then
    ok "Case 1: CLAIMED_ID=$ID, exit 0"
  else
    fail_test "Case 1: expected CLAIMED_ID=F000048 exit 0; got rc=$RC out: $OUT"
  fi
)
case_1_rc=$?
[ "$case_1_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 2: LOOPED concurrent race → distinct IDs ----------
#
# The load-bearing test. Each round: a fresh claim root, two helper invocations
# launched in parallel at the SAME floor, both run to completion. Assert the two
# CLAIMED_IDs are distinct (the mkdir CAS guarantees it). Repeated 25 rounds.

echo ""
echo "Case 2: LOOPED concurrent race (25 rounds), same floor → distinct IDs every round..."
SBX2=$(mk_sandbox)
(
  cd "$SBX2"
  CR=$(claim_root_of)
  ROUNDS=25
  DUPES=0
  BADRC=0
  for r in $(seq 1 "$ROUNDS"); do
    # Fresh claim root each round so floor+1 is the contested slot.
    rm -rf "$CR" 2>/dev/null || true
    F1=$(mktemp -t cj-race-a.XXXXXX)
    F2=$(mktemp -t cj-race-b.XXXXXX)
    # Launch two claims in parallel at the same floor.
    bash "$HELPER" --prefix S --floor 100 > "$F1" 2>&1 &
    P1=$!
    bash "$HELPER" --prefix S --floor 100 > "$F2" 2>&1 &
    P2=$!
    wait "$P1"; RC1=$?
    wait "$P2"; RC2=$?
    ID1=$(sed -n 's/^CLAIMED_ID=//p' "$F1")
    ID2=$(sed -n 's/^CLAIMED_ID=//p' "$F2")
    rm -f "$F1" "$F2"
    if [ "$RC1" -ne 0 ] || [ "$RC2" -ne 0 ] || [ -z "$ID1" ] || [ -z "$ID2" ]; then
      BADRC=$((BADRC + 1))
      echo "    round $r: non-zero/empty (rc1=$RC1 rc2=$RC2 id1='$ID1' id2='$ID2')" >&2
      continue
    fi
    if [ "$ID1" = "$ID2" ]; then
      DUPES=$((DUPES + 1))
      echo "    round $r: DUPLICATE id $ID1" >&2
    fi
  done
  if [ "$DUPES" -eq 0 ] && [ "$BADRC" -eq 0 ]; then
    ok "Case 2: $ROUNDS rounds, 0 duplicate IDs, 0 failed invocations"
  else
    fail_test "Case 2: race produced $DUPES duplicate(s) and $BADRC failed invocation(s) over $ROUNDS rounds"
  fi
)
case_2_rc=$?
[ "$case_2_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 3: reap on origin ----------
#
# Build a fake `origin` remote whose main carries F000048_*_TRACKER.md. Pre-create
# a claim dir F000048 locally. Run the helper at --floor 47: the on-origin reap
# must remove F000048 and NOT count it, so the new claim is also F000048 (the
# reaped slot is free again), proving the dir was reaped and discounted.

echo ""
echo "Case 3: reap on origin (claim whose ID is on origin/main is removed + not counted)..."
SBX3=$(mk_sandbox)
(
  cd "$SBX3"
  # Build a bare origin and push a main that contains an F000048 tracker.
  ORIGIN_DIR=$(mktemp -d -t cj-id-origin.XXXXXX)
  git init -q --bare "$ORIGIN_DIR"
  git remote add origin "$ORIGIN_DIR"
  mkdir -p work-items/features
  echo "tracker" > work-items/features/F000048_demo_TRACKER.md
  git add work-items/features/F000048_demo_TRACKER.md
  git commit -qm "add F000048 tracker"
  git push -q origin main
  # Now REMOVE it from the local working tree so id_has_workitem_dir is false,
  # leaving it only on origin/main (the reap-on-origin signal).
  git rm -q work-items/features/F000048_demo_TRACKER.md
  git commit -qm "remove local tracker (keep on origin)"
  # The local-tree max is now 0; origin still has F000048 but the helper does not
  # consult origin for the FLOOR (the caller passes --floor). Pre-create a stale
  # claim dir for F000048.
  CR=$(claim_root_of)
  mkdir -p "$CR/F000048"
  echo "branch=other" > "$CR/F000048/meta"
  OUT=$(bash "$HELPER" --prefix F --floor 47 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  # The stale F000048 claim must be reaped (so the slot is reusable) AND a fresh
  # claim minted. Because the reaped dir is not counted, floor 47 → F000048 again.
  if [ "$RC" -eq 0 ] && [ "$ID" = "F000048" ] && [ -d "$CR/F000048" ]; then
    # The dir now exists again because it was just re-claimed; assert the meta
    # was rewritten by THIS run (branch == current branch), proving reap+reclaim.
    NEWBRANCH=$(sed -n 's/^branch=//p' "$CR/F000048/meta" | head -1)
    CURB=$(git branch --show-current)
    if [ "$NEWBRANCH" = "$CURB" ]; then
      ok "Case 3: stale on-origin claim reaped + re-minted (meta rewritten to $NEWBRANCH); CLAIMED_ID=$ID"
    else
      fail_test "Case 3: F000048 dir present but meta not rewritten by this run (branch='$NEWBRANCH' want '$CURB')"
    fi
  else
    fail_test "Case 3: expected reap+reclaim CLAIMED_ID=F000048; got rc=$RC out: $OUT"
  fi
  rm -rf "$ORIGIN_DIR"
)
case_3_rc=$?
[ "$case_3_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 4: reap on TTL ----------
#
# Pre-create a claim dir whose mtime is far in the past (touch -t, POSIX). Run
# with --ttl-hours 1. The TTL reap must remove it and NOT count it, so a claim
# at --floor 0 returns F000001 (the stale F000050 is gone), and the F000050 dir
# is deleted.

echo ""
echo "Case 4: reap on TTL (claim older than --ttl-hours is removed + not counted)..."
SBX4=$(mk_sandbox)
(
  cd "$SBX4"
  CR=$(claim_root_of)
  mkdir -p "$CR/F000050"
  echo "branch=stale" > "$CR/F000050/meta"
  # Backdate the dir mtime to the year 2000 (POSIX touch -t CCYYMMDDhhmm).
  touch -t 200001010000 "$CR/F000050" 2>/dev/null || touch -t 200001010000 "$CR/F000050/meta"
  # Re-backdate via the dir itself if the host updated mtime on meta-write order.
  touch -t 200001010000 "$CR/F000050" 2>/dev/null || true
  OUT=$(bash "$HELPER" --prefix F --floor 0 --ttl-hours 1 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  # Stale F000050 must be gone; new claim ignores it → floor 0 → F000001.
  if [ "$RC" -eq 0 ] && [ "$ID" = "F000001" ] && [ ! -d "$CR/F000050" ]; then
    ok "Case 4: stale (year-2000) claim F000050 reaped; new CLAIMED_ID=$ID (not counted)"
  else
    fail_test "Case 4: expected F000050 reaped + CLAIMED_ID=F000001; got rc=$RC id=$ID dir_exists=$([ -d "$CR/F000050" ] && echo yes || echo no) out: $OUT"
  fi
)
case_4_rc=$?
[ "$case_4_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 5: prefix isolation (F vs S independent) ----------
#
# A live F-claim must not advance an S-claim and vice versa. Claim F at floor 10
# (→ F000011), then claim S at floor 10: S must be S000011 (unaffected by the
# F-claim), and a second F at floor 10 must advance past the live F000011 to
# F000012.

echo ""
echo "Case 5: prefix isolation (an F-claim does not advance an S-claim)..."
SBX5=$(mk_sandbox)
(
  cd "$SBX5"
  IDF=$(bash "$HELPER" --prefix F --floor 10 | sed -n 's/^CLAIMED_ID=//p')
  IDS=$(bash "$HELPER" --prefix S --floor 10 | sed -n 's/^CLAIMED_ID=//p')
  if [ "$IDF" = "F000011" ] && [ "$IDS" = "S000011" ]; then
    ok "Case 5: F-claim=$IDF and S-claim=$IDS are independent (S not bumped by F)"
  else
    fail_test "Case 5: expected F000011 + S000011 (independent); got F='$IDF' S='$IDS'"
  fi
)
case_5_rc=$?
[ "$case_5_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 6: same-branch reuse (+ BLOCKER-1/2 + dry-run regressions) ----
#
# 6.0 (happy path, KEPT): a re-run on the same branch with a live same-branch claim
#     and NO work-item dir for that ID REUSES the same ID (idempotent); once the
#     work-item dir materializes, the next run ADVANCES.
# 6a  (BLOCKER-1 regression): with ONE pre-existing live same-branch candidate
#     (>= floor, no work-item dir), launch ~20 concurrent invocations. The
#     `.reuse-owner` mkdir-CAS lets AT MOST ONE win the reuse; the rest fall through
#     and mint fresh IDs. Assert the candidate is returned <=1x (deterministic).
#     WITHOUT the CAS all ~20 returned the SAME candidate ID (the reproduced 14-way
#     dupe). (Global "all distinct" is NOT asserted — see the in-case SCOPE NOTE:
#     a mint-and-exit claim is indistinguishable from a crashed-run claim, so a
#     same-branch BURST can race a minter vs a late reuser; real concurrency is
#     cross-branch/pure-mint, covered deterministically by Case 2 / Case 7.)
# 6b  (BLOCKER-2 regression): a live same-branch claim BELOW the passed --floor is
#     NOT reused — the call returns an ID strictly > floor (minted above the floor).
# 6c  (MINOR / dry-run regression): `--dry-run` creates ZERO directories — neither
#     the claims root nor any candidate dir exists after a dry-run when absent before.

echo ""
echo "Case 6.0: same-branch reuse (re-run with live claim + no work-item dir → same ID)..."
SBX6=$(mk_sandbox)
(
  cd "$SBX6"
  ID_FIRST=$(bash "$HELPER" --prefix S --floor 80 | sed -n 's/^CLAIMED_ID=//p')   # S000081
  ID_REUSE=$(bash "$HELPER" --prefix S --floor 80 | sed -n 's/^CLAIMED_ID=//p')   # reuse → S000081
  if [ "$ID_FIRST" = "S000081" ] && [ "$ID_REUSE" = "$ID_FIRST" ]; then
    # Now materialize the work-item dir for that ID; the next run must advance.
    mkdir -p "work-items/features/${ID_FIRST}_demo"
    echo "t" > "work-items/features/${ID_FIRST}_demo/${ID_FIRST}_demo_TRACKER.md"
    ID_AFTER=$(bash "$HELPER" --prefix S --floor 80 | sed -n 's/^CLAIMED_ID=//p')  # advance → S000082
    if [ "$ID_AFTER" = "S000082" ]; then
      ok "Case 6.0: reuse held ($ID_REUSE == $ID_FIRST); advanced to $ID_AFTER once work-item dir materialized"
    else
      fail_test "Case 6.0: after work-item dir created, expected advance to S000082; got '$ID_AFTER'"
    fi
  else
    fail_test "Case 6.0: expected reuse S000081==S000081; got first='$ID_FIRST' reuse='$ID_REUSE'"
  fi
)
case_6_rc=$?
[ "$case_6_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 6a: BLOCKER-1 — concurrent reusers of one candidate → reused <=1x --

echo ""
echo "Case 6a: BLOCKER-1 — 20 concurrent invocations contend 1 live candidate → it is reused <=1x..."
SBX6A=$(mk_sandbox)
(
  cd "$SBX6A"
  CR=$(claim_root_of)
  CURB=$(git branch --show-current)
  # Pre-create ONE live, same-branch, not-materialized candidate at the floor+1
  # slot (S000101 for --floor 100). Fresh mtime so it is never reaped. This is the
  # EXACT reported BLOCKER-1 shape: N invocations all see this one live claim.
  mkdir -p "$CR/S000101"
  printf 'branch=%s\npid=0\n' "$CURB" > "$CR/S000101/meta"
  N=20
  OUTDIR=$(mktemp -d -t cj-reuse-conc.XXXXXX)
  for i in $(seq 1 "$N"); do
    bash "$HELPER" --prefix S --floor 100 > "$OUTDIR/out.$i" 2>&1 &
  done
  wait || true   # wait for ALL background jobs (guard set -e; rc surfaced via EMPTY/TOTAL)
  # Collect all returned IDs.
  IDS=""
  EMPTY=0
  for i in $(seq 1 "$N"); do
    id=$(sed -n 's/^CLAIMED_ID=//p' "$OUTDIR/out.$i")
    [ -z "$id" ] && EMPTY=$((EMPTY + 1))
    IDS="$IDS$id
"
  done
  TOTAL=$(printf '%s' "$IDS" | grep -c . || true)
  # THE BLOCKER-1 REGRESSION (deterministic): the `.reuse-owner` mkdir-CAS makes
  # AT MOST ONE invocation reuse the pre-existing candidate. WITHOUT the CAS EVERY
  # invocation read+returned it (REUSES==N — the reproduced 14-way+ duplicate);
  # WITH it REUSES<=1 and the other ~19 fall through to MINT fresh ids via the
  # Phase-3 dir-CAS. This <=1 bound is the exact, fully-deterministic fix.
  REUSES=$(printf '%s' "$IDS" | grep -c '^S000101$' || true)
  rm -rf "$OUTDIR"
  # SCOPE NOTE — why we assert REUSES<=1, not global "all N distinct": this script
  # mints-and-exits, so AFTER a process exits its claim (dead meta pid, no work-item
  # dir) is INDISTINGUISHABLE from a crashed prior run that SHOULD be reused (the
  # Case-6.0 idempotency contract). There is no in-band signal separating "a sibling
  # that just minted then exited" from "a crashed earlier run". So a same-branch
  # concurrent BURST can interleave a minter and a late reuser on a just-minted id
  # (one mints S000102, a straggler reuses it) — making global uniqueness inherently
  # racy. That interleave is a TEST-ONLY construct: real concurrency is cross-WORKTREE
  # = DIFFERENT branches, which share no same-branch reuse candidate (pure mint →
  # distinct via the dir-CAS, covered by Case 2 / Case 7). The BLOCKER-1 fix proper —
  # "N invocations no longer all reuse one live claim" — is exactly REUSES<=1.
  if [ "$EMPTY" -eq 0 ] && [ "$TOTAL" -eq "$N" ] && [ "$REUSES" -le 1 ]; then
    ok "Case 6a: $N concurrent invocations → pre-existing candidate reused <=1x (REUSES=$REUSES); was N-way reuse before the .reuse-owner CAS"
  else
    fail_test "Case 6a: expected REUSES<=1 (BLOCKER-1 fix) over $N invocations; got total=$TOTAL reuses=$REUSES empty=$EMPTY"
  fi
)
case_6a_rc=$?
[ "$case_6a_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 6b: BLOCKER-2 — live claim below --floor is NOT reused ----

echo ""
echo "Case 6b: BLOCKER-2 — a same-branch live claim BELOW --floor is not reused (mints above floor)..."
SBX6B=$(mk_sandbox)
(
  cd "$SBX6B"
  CR=$(claim_root_of)
  CURB=$(git branch --show-current)
  # Pre-create a live, same-branch, not-materialized claim at S000050 (fresh mtime).
  mkdir -p "$CR/S000050"
  printf 'branch=%s\npid=0\n' "$CURB" > "$CR/S000050/meta"
  # Call with --floor 200: the S000050 candidate is below the floor, so it must
  # NOT be reused. The atomic loop mints strictly above the floor → S000201.
  OUT=$(bash "$HELPER" --prefix S --floor 200 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  NUM="${ID#S}"
  case "$NUM" in ''|*[!0-9]*) NUM=-1 ;; *) NUM=$((10#$NUM)) ;; esac
  if [ "$RC" -eq 0 ] && [ "$ID" != "S000050" ] && [ "$NUM" -gt 200 ]; then
    ok "Case 6b: below-floor claim S000050 not reused; minted $ID (> floor 200)"
  else
    fail_test "Case 6b: expected an ID > floor 200 (not S000050); got rc=$RC id='$ID' out: $OUT"
  fi
)
case_6b_rc=$?
[ "$case_6b_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 6c: MINOR — --dry-run creates no directories ----

echo ""
echo "Case 6c: MINOR — --dry-run creates ZERO directories (claims root absent after)..."
SBX6C=$(mk_sandbox)
(
  cd "$SBX6C"
  CR=$(claim_root_of)
  # Ensure a clean slate: the claims root must not exist before the dry-run.
  rm -rf "$CR" 2>/dev/null || true
  OUT=$(bash "$HELPER" --prefix S --floor 83 --dry-run 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  # The dry-run must print the would-be ID (floor+1 = S000084) AND create nothing:
  # neither the claims root nor the candidate dir may exist afterward.
  if [ "$RC" -eq 0 ] && [ "$ID" = "S000084" ] && [ ! -d "$CR" ] && [ ! -d "$CR/S000084" ]; then
    ok "Case 6c: --dry-run printed $ID and created no directories (claims root absent)"
  else
    fail_test "Case 6c: expected CLAIMED_ID=S000084 + no dirs; got rc=$RC id='$ID' root_exists=$([ -d "$CR" ] && echo yes || echo no) out: $OUT"
  fi
)
case_6c_rc=$?
[ "$case_6c_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 7: cwd-independence / common-dir from worktree + subdir ----------
#
# The claim root must resolve to the SAME shared `.git/cj-id-claims` whether the
# helper runs from the root checkout, a linked worktree, or a nested subdir.
# Claim from a linked worktree, then assert the claim dir is visible under the
# ROOT checkout's common-dir; and assert a run from a nested subdir resolves the
# same root (does not create a second claim root under the subdir).

echo ""
echo "Case 7: cwd-independence (linked worktree + nested subdir → one shared claim root)..."
SBX7=$(mk_sandbox)
(
  cd "$SBX7"
  ROOT_CR=$(claim_root_of)
  # (a) Run from a linked worktree; the claim must land under the ROOT common-dir.
  git worktree add -q -b wt-branch ".claude/worktrees/wt" >/dev/null 2>&1
  ID_WT=$(cd ".claude/worktrees/wt" && bash "$HELPER" --prefix F --floor 200 | sed -n 's/^CLAIMED_ID=//p')   # F000201
  # The claim dir must be visible from the ROOT checkout's claim root (shared .git).
  if [ "$ID_WT" = "F000201" ] && [ -d "$ROOT_CR/F000201" ]; then
    OK_A=1
  else
    OK_A=0
  fi
  # (b) Run from a nested subdir of the root checkout; must resolve the SAME root
  # and advance past the live F000201 → F000202 (no second claim root created).
  mkdir -p deep/nested/dir
  ID_SUB=$(cd deep/nested/dir && bash "$HELPER" --prefix F --floor 200 | sed -n 's/^CLAIMED_ID=//p')   # F000202
  # Assert no stray claim root was created under the subdir.
  STRAY=0
  [ -d "deep/nested/dir/cj-id-claims" ] && STRAY=1
  [ -d "deep/nested/dir/.git" ] && STRAY=1
  if [ "$OK_A" -eq 1 ] && [ "$ID_SUB" = "F000202" ] && [ "$STRAY" -eq 0 ] && [ -d "$ROOT_CR/F000202" ]; then
    ok "Case 7: worktree claim ($ID_WT) + subdir claim ($ID_SUB) both under one shared root; no stray root"
  else
    fail_test "Case 7: shared-root resolution failed (worktree_ok=$OK_A id_wt='$ID_WT' id_sub='$ID_SUB' stray=$STRAY)"
  fi
)
case_7_rc=$?
[ "$case_7_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Case 8: SLUG-LESS feature tracker matched on both reap paths --------
#
# REGRESSION for the reap regex/glob that REQUIRED a `_<slug>_` segment between the
# work-item ID and `_TRACKER.md` (id_on_origin: `${id}_[^/]*_TRACKER\.md$`;
# id_has_workitem_dir: `find -name "${id}_*_TRACKER.md"`). FEATURE-level trackers
# are named `${id}_TRACKER.md` with NO slug (e.g. F000077_TRACKER.md), so neither
# matcher ever fired for a feature → merged feature claims were never reaped from
# cj-id-claims/, stale claim dirs accrued, and the next scaffold's reuse/next-ID
# math could hand back an already-used F/S ID (parallel builds collided on the same
# ID + VERSION — hit live twice on 2026-07-03). The fix makes the slug OPTIONAL.
#
# These two sub-cases use the SLUG-LESS shape exclusively (Case 3 / Case 6.0 use a
# `_demo_` slug, so they never exercised this path). Each FAILS before the fix and
# PASSES after: 8a — a stale F000048 claim whose `F000048_TRACKER.md` is on
# origin/main is REAPED (so floor 47 → F000048 again); 8b — once `F000048_TRACKER.md`
# materializes locally, same-branch reuse ADVANCES instead of re-handing F000048.

echo ""
echo "Case 8a: reap-on-origin matches a SLUG-LESS feature tracker \${id}_TRACKER.md..."
SBX8=$(mk_sandbox)
(
  cd "$SBX8"
  # Bare origin whose main carries the SLUG-LESS feature tracker F000048_TRACKER.md.
  ORIGIN_DIR=$(mktemp -d -t cj-id-origin8.XXXXXX)
  git init -q --bare "$ORIGIN_DIR"
  git remote add origin "$ORIGIN_DIR"
  mkdir -p work-items/features/ops
  echo "tracker" > work-items/features/ops/F000048_TRACKER.md
  git add work-items/features/ops/F000048_TRACKER.md
  git commit -qm "add slug-less F000048 feature tracker"
  git push -q origin main
  # Remove it locally so id_has_workitem_dir is false, leaving it only on origin.
  git rm -q work-items/features/ops/F000048_TRACKER.md
  git commit -qm "remove local tracker (keep on origin)"
  # Pre-create a stale claim dir for F000048 (a merged feature claim never reaped).
  CR=$(claim_root_of)
  mkdir -p "$CR/F000048"
  echo "branch=other" > "$CR/F000048/meta"
  OUT=$(bash "$HELPER" --prefix F --floor 47 2>&1)
  RC=$?
  ID=$(printf '%s\n' "$OUT" | sed -n 's/^CLAIMED_ID=//p')
  # BEFORE the fix id_on_origin's required-slug regex never matched
  # F000048_TRACKER.md, so the stale claim was NOT reaped and counted toward the
  # live max → the mint ADVANCED to F000049. WITH the fix it is reaped + not
  # counted → floor 47 re-mints F000048, and its meta is rewritten by this run.
  if [ "$RC" -eq 0 ] && [ "$ID" = "F000048" ] && [ -d "$CR/F000048" ]; then
    NEWBRANCH=$(sed -n 's/^branch=//p' "$CR/F000048/meta" | head -1)
    CURB=$(git branch --show-current)
    if [ "$NEWBRANCH" = "$CURB" ]; then
      ok "Case 8a: slug-less on-origin feature claim reaped + re-minted (meta → $NEWBRANCH); CLAIMED_ID=$ID"
    else
      fail_test "Case 8a: F000048 present but meta not rewritten this run (branch='$NEWBRANCH' want '$CURB') — reap regex still requires a slug?"
    fi
  else
    fail_test "Case 8a: expected slug-less feature reap → CLAIMED_ID=F000048 (got rc=$RC id='$ID'). BEFORE-fix symptom: advances to F000049 because \${id}_TRACKER.md never matched the reap regex."
  fi
  rm -rf "$ORIGIN_DIR"
)
case_8a_rc=$?
[ "$case_8a_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

echo ""
echo "Case 8b: materialized SLUG-LESS \${id}_TRACKER.md makes same-branch reuse advance..."
SBX8B=$(mk_sandbox)
(
  cd "$SBX8B"
  # First claim mints F000090 (floor 89); a live same-branch re-run reuses it.
  ID_FIRST=$(bash "$HELPER" --prefix F --floor 89 | sed -n 's/^CLAIMED_ID=//p')   # F000090
  ID_REUSE=$(bash "$HELPER" --prefix F --floor 89 | sed -n 's/^CLAIMED_ID=//p')   # reuse → F000090
  if [ "$ID_FIRST" = "F000090" ] && [ "$ID_REUSE" = "$ID_FIRST" ]; then
    # Materialize the work-item dir with a SLUG-LESS feature tracker
    # ${ID}_TRACKER.md (NOT ${ID}_slug_TRACKER.md). id_has_workitem_dir must now
    # see it so the next same-branch run ADVANCES past F000090.
    mkdir -p "work-items/features/ops/${ID_FIRST}_some_feature"
    echo "t" > "work-items/features/ops/${ID_FIRST}_some_feature/${ID_FIRST}_TRACKER.md"
    ID_AFTER=$(bash "$HELPER" --prefix F --floor 89 | sed -n 's/^CLAIMED_ID=//p')  # advance → F000091
    if [ "$ID_AFTER" = "F000091" ]; then
      ok "Case 8b: slug-less ${ID_FIRST}_TRACKER.md detected → reuse advanced to $ID_AFTER"
    else
      fail_test "Case 8b: after slug-less ${ID_FIRST}_TRACKER.md created, expected advance to F000091; got '$ID_AFTER'. BEFORE-fix symptom: id_has_workitem_dir's \${id}_*_TRACKER.md glob misses the slug-less file, so reuse re-hands $ID_FIRST."
    fi
  else
    fail_test "Case 8b: expected reuse F000090==F000090; got first='$ID_FIRST' reuse='$ID_REUSE'"
  fi
)
case_8b_rc=$?
[ "$case_8b_rc" -ne 0 ] && ERRORS=$((ERRORS + 1))

# ---------- Summary ----------

echo ""
echo "=== cj-id-claim.test.sh Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
