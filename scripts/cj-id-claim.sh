#!/usr/bin/env bash
# cj-id-claim.sh — atomic scaffold-time work-item ID claim (F000048 / S000084).
#
# A 4th ID source layered on top of /CJ_scaffold-work-item Step 5.1's existing
# three (local tree / open PRs / origin/main): an atomic CLAIM DIRECTORY created
# with `mkdir` under the SHARED `.git` common-dir. `mkdir` is the compare-and-swap
# — it fails atomically if the dir already exists — so two concurrent same-machine
# worktrees (which share one `.git`) can never mint the same next ID, closing the
# scaffold-before-push race Sources 2+3 cannot see (an unpushed sibling is invisible
# to open-PR / origin checks).
#
# Contract:
#   cj-id-claim.sh --prefix <F|S|T|D> --floor <N> [--ttl-hours 72] [--dry-run]
#   stdout on success: CLAIMED_ID=<PREFIXNNNNNN>   ; exit 0
#   stderr + non-zero exit on a usage error or a (pathological) exhausted loop.
#
# Three phases (in order):
#   1. REAP (lazy, conservative) — remove a claim dir IF its ID is already on
#      origin/main (merged → permanently taken) OR its mtime is older than
#      ttl_hours*3600 (a crashed/abandoned run). REAP INVARIANT: never reap a
#      claim that is neither merged nor older than TTL — so a live competing
#      winner is never deleted and concurrent-distinct-IDs holds even with reap
#      interleaved.
#   2. SAME-BRANCH REUSE (idempotency) — if a LIVE claim's meta records the
#      current branch AND no work-item dir exists yet for that ID, reuse it
#      (refresh its mtime), print its CLAIMED_ID, exit 0. Makes a re-run of a
#      crashed scaffold a NO-OP rather than advancing the number.
#   3. ATOMIC CLAIM LOOP (bounded ~100) — new_id = max(floor, max-live-claim)+1;
#      `mkdir "$CLAIM_ROOT/$new_id"` (fails-if-exists = the lock). On success
#      write a meta file {branch,pid,iso-ts} and echo CLAIMED_ID; on EEXIST a
#      sibling won the slot — re-read the live max and retry.
#
# --dry-run: run reap + same-branch reuse READ-ONLY (no mtime refresh, no reap
# delete), print the would-be CLAIMED_ID, create NOTHING. Mutates no filesystem.
#
# Portability: POSIX bash + LF (.gitattributes pins eol=lf). The only atomic
# primitive is `mkdir` (Git-Bash/Windows-safe). Claim-dir mtime → epoch via a
# probe of GNU `stat -c %Y` vs BSD/macOS `stat -f %m` (the repo's probe-then-branch
# idiom — see date_to_epoch in suggest.sh / windows-smoke.sh); no GNU-only
# `date -d`/`date -r` flags. No eval; no shell-injection surface.
#
# Located via the CALLER's worktree (`git rev-parse --show-toplevel`/scripts/),
# but the claim dir lives under the SHARED `.git` (`git rev-parse
# --git-common-dir`) so every sibling worktree sees one claim root. CLAIM_ROOT is
# NORMALIZED to absolute (`cd "$(...)" && pwd`): `--git-common-dir` may print a
# RELATIVE path, and a relative root would give agents with different cwd
# different roots — silently breaking the cross-worktree CAS.

set -euo pipefail

# ---- Arg parsing -------------------------------------------------------------

PREFIX=""
FLOOR=""
TTL_HOURS=72
DRY_RUN=0

usage() {
  echo "usage: cj-id-claim.sh --prefix <F|S|T|D> --floor <N> [--ttl-hours 72] [--dry-run]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    PREFIX="${2:-}"; shift 2 ;;
    --floor)     FLOOR="${2:-}"; shift 2 ;;
    --ttl-hours) TTL_HOURS="${2:-}"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)   usage ;;
    *)           echo "cj-id-claim.sh: unknown arg '$1'" >&2; usage ;;
  esac
done

# Validate --prefix (closed set, mirrors scaffold.md's F/S/T/D).
case "$PREFIX" in
  F|S|T|D) ;;
  *) echo "cj-id-claim.sh: --prefix must be one of F S T D (got '$PREFIX')" >&2; usage ;;
esac

# Validate --floor (non-negative integer; octal-safe parse downstream).
case "$FLOOR" in
  ''|*[!0-9]*) echo "cj-id-claim.sh: --floor must be a non-negative integer (got '$FLOOR')" >&2; usage ;;
esac

# Validate --ttl-hours (positive integer).
case "$TTL_HOURS" in
  ''|*[!0-9]*) echo "cj-id-claim.sh: --ttl-hours must be a positive integer (got '$TTL_HOURS')" >&2; usage ;;
esac
[ "$TTL_HOURS" -gt 0 ] 2>/dev/null || { echo "cj-id-claim.sh: --ttl-hours must be > 0" >&2; usage; }

# ---- Resolve the SHARED, ABSOLUTE claim root --------------------------------
#
# Located via the caller's worktree toplevel for $REPO_ROOT context, but the
# claim dir lives under the SHARED `.git` common-dir so sibling worktrees share
# one root. ABSOLUTE normalization (`cd "$(...)" && pwd`) is load-bearing.

if ! GIT_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null); then
  echo "cj-id-claim.sh: not inside a git repository" >&2
  exit 1
fi
# Normalize to absolute — --git-common-dir may be relative (e.g. ".git").
if ! GIT_COMMON_ABS=$(cd "$GIT_COMMON_DIR" 2>/dev/null && pwd); then
  echo "cj-id-claim.sh: cannot resolve git-common-dir '$GIT_COMMON_DIR'" >&2
  exit 1
fi
CLAIM_ROOT="$GIT_COMMON_ABS/cj-id-claims"
# Create the claim root only on a REAL claim/reuse path. Under --dry-run the
# script must mutate NOTHING (create zero directories), so we defer this mkdir to
# ensure_claim_root, called lazily right before a real mkdir/touch. The read-only
# scans below tolerate an absent CLAIM_ROOT (the globs simply don't match).
_CLAIM_ROOT_READY=0
ensure_claim_root() {
  [ "$_CLAIM_ROOT_READY" = "1" ] && return 0
  mkdir -p "$CLAIM_ROOT"
  _CLAIM_ROOT_READY=1
}

# Toplevel of the CALLER's worktree — used to scan local work-items for the
# same-branch-reuse "no work-item dir yet" test.
TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

# Current branch — recorded in claim meta + matched for same-branch reuse.
CUR_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# Base-10-coerced floor — computed up here (not at the atomic loop) because the
# Phase-2 reuse gate needs it: a reuse candidate is valid ONLY if its id >= floor
# (else reuse would hand back an id below the caller's floor — BLOCKER 2).
FLOOR_N=$((10#$FLOOR))

NOW=$(date +%s)
TTL_SECS=$((TTL_HOURS * 3600))

# ---- Helper: claim-dir mtime → epoch (portable) -----------------------------
#
# GNU coreutils: `stat -c %Y`. BSD/macOS: `stat -f %m`. Probe once. Mirrors the
# repo's date_to_epoch probe-then-branch idiom (suggest.sh / windows-smoke.sh).
# On a probe miss returns 0 (treated as "very old" by the TTL test — fail toward
# reaping an unreadable dir, which is conservative: a freshly-mkdir'd live claim
# is always stat-able, so this never reaps a live winner).
# Probe against $GIT_COMMON_ABS (always exists) rather than $CLAIM_ROOT — under
# --dry-run CLAIM_ROOT is never created, so probing it would always miss and force
# _STAT_KIND=none, corrupting the dry-run reap-discount math.
if stat -c %Y "$GIT_COMMON_ABS" >/dev/null 2>&1; then
  _STAT_KIND="gnu"
elif stat -f %m "$GIT_COMMON_ABS" >/dev/null 2>&1; then
  _STAT_KIND="bsd"
else
  _STAT_KIND="none"
fi
dir_mtime_epoch() {
  # $1 = dir path. Echo epoch seconds, or 0 if unreadable.
  case "$_STAT_KIND" in
    gnu) stat -c %Y "$1" 2>/dev/null || echo 0 ;;
    bsd) stat -f %m "$1" 2>/dev/null || echo 0 ;;
    *)   echo 0 ;;
  esac
}

# ---- Helper: is this ID already merged on origin/main? ----------------------
#
# Best-effort: look for ${id}_*_TRACKER.md anywhere under origin/main's tree.
# Skips silently (returns 1 = "not merged") if origin/main is absent/offline —
# the TTL arm still reaps abandoned claims, and Sources 2+3 in scaffold.md remain
# the cross-clone backstop. We fetch nothing here (the caller already fetched at
# Step 5.1); a stale origin ref only DELAYS an on-origin reap, never breaks the CAS.
ORIGIN_TREE=""
_origin_tree_loaded=0
load_origin_tree() {
  [ "$_origin_tree_loaded" = "1" ] && return 0
  _origin_tree_loaded=1
  ORIGIN_TREE=$(git ls-tree -r --name-only origin/main 2>/dev/null || echo "")
}
id_on_origin() {
  # $1 = ID (e.g. F000048). Return 0 if a matching TRACKER is on origin/main.
  load_origin_tree
  [ -n "$ORIGIN_TREE" ] || return 1
  printf '%s\n' "$ORIGIN_TREE" | grep -qE "(^|/)${1}_[^/]*_TRACKER\.md$"
}

# ---- Helper: does a local work-item dir already exist for this ID? ----------
#
# Used by same-branch reuse: a live same-branch claim is reused ONLY if scaffold
# has not yet written the work-item dir for it (else the ID is in active use and
# a re-run should advance, per the idempotency contract).
id_has_workitem_dir() {
  # $1 = ID. Return 0 if work-items/**/${id}_*_TRACKER.md exists locally.
  [ -n "$TOPLEVEL" ] || return 1
  [ -d "$TOPLEVEL/work-items" ] || return 1
  find "$TOPLEVEL/work-items" -name "${1}_*_TRACKER.md" 2>/dev/null | grep -q .
}

# ---- Helper: read a field from a claim meta file ----------------------------
#
# meta is a tiny KEY=VALUE file (branch=…, pid=…, iso=…). No eval; grep+cut only.
meta_field() {
  # $1 = claim dir, $2 = key. Echo value or empty.
  local f="$1/meta" key="$2"
  [ -f "$f" ] || { echo ""; return 0; }
  sed -n "s/^${key}=//p" "$f" 2>/dev/null | head -1
}

# ---- Phase 1: REAP (lazy, conservative) -------------------------------------
#
# For each existing claim dir for THIS prefix: remove it IF the ID is on
# origin/main OR (now - mtime) > TTL. REAP INVARIANT: a freshly-created competing
# claim is neither merged nor older than TTL, so it is NEVER in reap range — reap
# can never delete a live winner. Under --dry-run we SKIP deletion entirely
# (read-only contract) but still discount reapable dirs from the live max below.
#
# `set -e` safety: the glob may not match (nullglob is not set), so we guard with
# a `[ -d "$d" ]` test inside the loop and consume grep/stat non-zero exits.

reap_claim_if_dead() {
  # $1 = claim dir. Return 0 if it WAS (or in --dry-run WOULD BE) reaped.
  local d="$1" id base age mtime
  base=$(basename "$d")
  id="$base"
  # On-origin reap.
  if id_on_origin "$id"; then
    [ "$DRY_RUN" = "1" ] || rm -rf "$d" 2>/dev/null || true
    return 0
  fi
  # TTL reap.
  mtime=$(dir_mtime_epoch "$d")
  case "$mtime" in ''|*[!0-9]*) mtime=0 ;; esac
  age=$((NOW - mtime))
  if [ "$age" -gt "$TTL_SECS" ]; then
    [ "$DRY_RUN" = "1" ] || rm -rf "$d" 2>/dev/null || true
    return 0
  fi
  return 1
}

# ---- Helper: max LIVE claim numeric value for this prefix -------------------
#
# Iterates claim dirs for $PREFIX, reaping dead ones as it goes (Phase 1 folded
# into the scan so the max only ever counts LIVE claims). Octal-safe parse:
# strip the prefix, then `n=$((10#$n))` so a zero-padded "000048" is read base-10
# (bash reads a bare leading-zero string as octal — fails on digits 8/9). Echoes
# the max numeric value (0 if no live claims).
max_live_claim() {
  local d base num max=0
  for d in "$CLAIM_ROOT/$PREFIX"*; do
    [ -d "$d" ] || continue            # nullglob-safe (no match → literal pattern)
    base=$(basename "$d")
    # Strip the leading prefix; the remainder must be all digits.
    num="${base#"$PREFIX"}"
    case "$num" in ''|*[!0-9]*) continue ;; esac
    # Reap dead claims; a reaped dir does NOT count toward the max.
    if reap_claim_if_dead "$d"; then
      continue
    fi
    num=$((10#$num))
    [ "$num" -gt "$max" ] && max="$num"
  done
  echo "$max"
}

# ---- Phase 2: SAME-BRANCH REUSE (idempotency) -------------------------------
#
# Scan LIVE claims for one whose meta.branch == the current branch, has no
# work-item dir yet, AND whose numeric id is >= FLOOR_N (BLOCKER 2: a reuse below
# the caller's floor would hand back a stale id — instead we fall through and let
# the atomic loop mint strictly above the floor). Among the valid candidates we
# take ownership of the HIGHEST one ATOMICALLY: `mkdir "$d/.reuse-owner"` is the
# CAS (BLOCKER 1) — without it, N concurrent same-branch runs would all read+return
# the SAME id. Whoever's mkdir wins reuses that id (refreshes its mtime so it stays
# live); a loser whose mkdir fails (a sibling already owns that candidate's reuse)
# falls to the next-highest candidate, and if none remain returns non-zero so the
# caller's atomic mint loop runs (yielding a fresh id above the live max via the
# Phase-3 dir-CAS). Net: AT MOST ONE invocation reuses any given candidate — so
# N concurrent same-branch invocations no longer all hand back the SAME id (the
# reproduced 14-way duplicate); the losers mint distinct fresh ids.
#
# `.reuse-owner` lives INSIDE the claim dir, so it is NOT a top-level
# $CLAIM_ROOT/$PREFIX* entry and never counts toward max_live_claim / the
# candidate enumeration (both glob top-level dirs only and parse the basename as a
# number). It is reaped automatically with its parent (reap_claim_if_dead's
# `rm -rf "$d"` removes the whole dir).
#
# Under --dry-run we mutate NOTHING: no `.reuse-owner` mkdir, no mtime touch — we
# just report the highest valid would-reuse candidate (read-only).
#
# Run this BEFORE the atomic loop so a crashed-scaffold re-run is a NO-OP.
# Only meaningful when we know the current branch.
try_same_branch_reuse() {
  [ -n "$CUR_BRANCH" ] || return 1
  local d base id b num n cands="" sorted
  # Pass 1: collect VALID candidate numeric ids (live, same-branch, not
  # materialized, id >= FLOOR_N), one per line. Reaping happens here so we never
  # reuse a dir we'd reap.
  for d in "$CLAIM_ROOT/$PREFIX"*; do
    [ -d "$d" ] || continue
    base=$(basename "$d")
    # The basename minus prefix must be all digits (skip a stray dotfile/subdir).
    num="${base#"$PREFIX"}"
    case "$num" in ''|*[!0-9]*) continue ;; esac
    id="$base"
    # Skip dead claims (don't reuse something we'd reap).
    if reap_claim_if_dead "$d"; then
      continue
    fi
    b=$(meta_field "$d" branch)
    [ "$b" = "$CUR_BRANCH" ] || continue
    # Reuse ONLY if scaffold hasn't materialized the work-item dir yet.
    if id_has_workitem_dir "$id"; then
      continue
    fi
    num=$((10#$num))
    # BLOCKER 2: a candidate below the floor is NOT reusable — fall through to mint.
    [ "$num" -ge "$FLOOR_N" ] || continue
    cands="$cands$num"$'\n'
  done
  [ -n "$cands" ] || return 1
  # Pass 2: take the candidates HIGHEST-first and atomically claim reuse ownership.
  # The here-string keeps the while-loop in the CURRENT shell (a pipe would put it
  # in a subshell, where `return 0` could not return from this function).
  sorted=$(printf '%s' "$cands" | sort -rn)
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    id=$(printf '%s%06d' "$PREFIX" "$n")
    d="$CLAIM_ROOT/$id"
    [ -d "$d" ] || continue   # reaped out from under us between passes
    if [ "$DRY_RUN" = "1" ]; then
      # Read-only: report the highest would-reuse id; create nothing.
      echo "CLAIMED_ID=$id"
      return 0
    fi
    # CAS: the first process to mkdir .reuse-owner wins this candidate's reuse.
    # A loser (a sibling already owns this candidate's reuse) tries the next
    # candidate; if none remain, falls through (return 1) so the caller's atomic
    # mint loop runs and mints a fresh DISTINCT id above the live max.
    if mkdir "$d/.reuse-owner" 2>/dev/null; then
      touch "$d" 2>/dev/null || true   # refresh mtime so the reused claim stays live
      echo "CLAIMED_ID=$id"
      return 0
    fi
    # A sibling already owns reuse of this candidate — try the next-highest.
  done <<< "$sorted"
  # Every valid candidate is already reuse-owned by a sibling → fall through to mint.
  return 1
}

if try_same_branch_reuse; then
  exit 0
fi

# ---- Phase 3: ATOMIC CLAIM LOOP ---------------------------------------------
#
# new_id = max(floor, max-live-claim) + 1; mkdir the claim dir (fails-if-exists =
# the CAS). On a winning mkdir write meta + echo CLAIMED_ID. On EEXIST a sibling
# took the slot — re-read max_live_claim (which advances past the now-existing
# sibling) and retry. Bounded at ~100 attempts; on (pathological) exhaustion exit
# non-zero so scaffold.md's fallback mints an ID (worst case: a skipped number).
#
# --dry-run: compute the would-be ID from the current live max and print it
# WITHOUT mkdir (no claim created). FLOOR_N is computed once, up near CUR_BRANCH,
# so the Phase-2 reuse gate can apply the same floor.

if [ "$DRY_RUN" = "1" ]; then
  CLAIM_MAX=$(max_live_claim)
  HIGHEST=$FLOOR_N
  [ "$CLAIM_MAX" -gt "$HIGHEST" ] && HIGHEST=$CLAIM_MAX
  NEW_N=$((HIGHEST + 1))
  printf 'CLAIMED_ID=%s%06d\n' "$PREFIX" "$NEW_N"
  exit 0
fi

# Real mint path — create the claim root now (the lazy mkdir deferred above so
# --dry-run mutates nothing). `mkdir "$CLAIM_DIR"` below has no -p and needs it.
ensure_claim_root

attempt=0
while [ "$attempt" -lt 100 ]; do
  attempt=$((attempt + 1))
  CLAIM_MAX=$(max_live_claim)
  HIGHEST=$FLOOR_N
  [ "$CLAIM_MAX" -gt "$HIGHEST" ] && HIGHEST=$CLAIM_MAX
  NEW_N=$((HIGHEST + 1))
  NEW_ID=$(printf '%s%06d' "$PREFIX" "$NEW_N")
  CLAIM_DIR="$CLAIM_ROOT/$NEW_ID"
  # `mkdir` is the compare-and-swap: it fails atomically if the dir exists.
  if mkdir "$CLAIM_DIR" 2>/dev/null; then
    # Won the slot — record meta (no eval surface; plain KEY=VALUE).
    {
      printf 'branch=%s\n' "$CUR_BRANCH"
      printf 'pid=%s\n' "$$"
      printf 'iso=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
    } > "$CLAIM_DIR/meta" 2>/dev/null || true
    echo "CLAIMED_ID=$NEW_ID"
    exit 0
  fi
  # EEXIST: a sibling won this slot. Loop — max_live_claim now sees the sibling.
done

echo "cj-id-claim.sh: claim loop exhausted after $attempt attempts (prefix $PREFIX, floor $FLOOR)" >&2
exit 1
