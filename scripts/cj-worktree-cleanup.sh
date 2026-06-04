#!/usr/bin/env bash
# cj-worktree-cleanup.sh — teardown mirror of cj-worktree-init.sh (T000036).
#
# The post-run JANITOR for the three CJ_goal_* orchestrators. Every run already
# OPENS a worktree at the top (cj-worktree-init.sh); this sweeps the LANDED
# cj-(feat|def|todo)-* worktrees at the bottom, prunes orphaned-dir metadata, and
# refreshes the root checkout back to main. Self-healing: each run sweeps ALL
# landed cj-* worktrees (not just its own), so a hand-merged worktree gets swept
# by the NEXT cj_goal run of any kind — the backlog drains itself over normal use.
#
# Interface:
#   cj-worktree-cleanup.sh [--dry-run] [--caller feature|defect|todo]
#
# Args:
#   --dry-run                 list WOULD-REMOVE / WOULD-SKIP; mutate NOTHING.
#   --caller {feature|defect|todo}
#                             informational only (telemetry / log attribution).
#                             Unlike cj-worktree-init.sh this is NOT required and
#                             NOT validated — cleanup is best-effort and the caller
#                             label never changes behavior. Unknown values are kept
#                             verbatim in the report's CALLER= field.
#
# Stdout (structured report, one KEY=VALUE per line — mirrors cj-goal-common.sh):
#   CALLER=<caller>
#   ROOT=<root working tree path>
#   CURRENT=<current worktree path>
#   REMOVED=<n>
#   REMOVED_PATH=<path>            (zero or more; one per removed worktree)
#   SKIPPED=<n>
#   SKIPPED_PATH=<path> reason=<reason>   (zero or more; one per skipped worktree)
#   PRUNED=<ok|fail|skipped>
#   ROOT_REFRESH=<ok|skipped|fail>
#   RESULT=<ok|skipped>
#
# Under --dry-run the per-worktree lines read WOULD-REMOVE_PATH / WOULD-SKIP_PATH
# and the counters report WOULD_REMOVED / WOULD_SKIPPED instead of REMOVED/SKIPPED.
#
# Exit codes:
#   0 — always for RESULT ∈ {ok, skipped}. Best-effort: returns 0 even when
#       removals were skipped or a removal/prune/refresh failed (the run that
#       called us must NEVER halt on cleanup — design Premise 5).
#   1 — usage error ONLY (an unknown flag is ignored, so in practice this is
#       reserved; there is no removal-failure exit path).
#
# "Landed" is decided by PR STATE, NEVER by local branch ancestry: this is a
# squash-merge repo, so `git merge-base --is-ancestor <branch> origin/main` is
# FALSE for squash-merged branches. The PR-state gate (cj-goal-common.sh
# --phase pr-check) is the SOLE authority on landed. See the decision table below.
#
# Security: stdout is a fixed KEY=VALUE schema. Paths come from `git worktree
# list --porcelain` (git's own output, not caller strings). No eval; the only
# shell-out is to the vetted cj-goal-common.sh helper for the PR-state check.

set -u  # strict on undefined vars; do NOT set -e — every op handles errors explicitly

# ---- arg parsing -------------------------------------------------------------

DRY_RUN=0
CALLER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --caller)  CALLER="${2:-}"; shift 2 ;;
    *)         shift ;;  # ignore unknown args (best-effort; never a usage halt)
  esac
done

# ---- resolve root + current from the INVOKING cwd's git context --------------
#
# NOT from this script's own location: the script may resolve from
# <manifest .source>/scripts/ while cwd is the target repo (exactly like
# cj-worktree-init.sh). _ROOT = the main working tree (the common .git lives at
# <root>/.git, so dirname of git-common-dir is the root). _CURRENT = the worktree
# we are standing in (never removable — can't rm the dir you're in).

_COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null || echo "")
if [ -z "$_COMMON_DIR" ]; then
  # cwd is not a git repo → no-op cleanly (design: emit RESULT=skipped, exit 0).
  echo "CALLER=$CALLER"
  echo "ROOT="
  echo "CURRENT="
  echo "PRUNED=skipped"
  echo "ROOT_REFRESH=skipped"
  echo "RESULT=skipped"
  echo "[cleanup-skip] cwd is not a git repository; nothing to sweep" >&2
  exit 0
fi

# git-common-dir may be relative (".git") when run from the root itself; resolve
# it to an absolute path before taking dirname so _ROOT is always absolute.
case "$_COMMON_DIR" in
  /*) ;;                                   # already absolute
  *)  _COMMON_DIR=$(cd "$_COMMON_DIR" 2>/dev/null && pwd || echo "$_COMMON_DIR") ;;
esac
_ROOT=$(dirname "$_COMMON_DIR")
_CURRENT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

echo "CALLER=$CALLER"
echo "ROOT=$_ROOT"
echo "CURRENT=$_CURRENT"

# ---- resolve cj-goal-common.sh for the PR-state gate (2-level probe) ---------
#
# Mirrors cj-goal-common.sh's own resolve_worktree_helper: (1) sibling in this
# script's dir (workbench self-dev — both ship together in scripts/); (2)
# <manifest .source>/scripts/ (deployed ~/.claude context). If neither resolves,
# the PR-state gate cannot run → every cj-* worktree SKIPs (conservative: we
# never remove what we cannot prove landed).
_SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_COMMON_HELPER=""
if [ -x "$_SELF_DIR/cj-goal-common.sh" ]; then
  _COMMON_HELPER="$_SELF_DIR/cj-goal-common.sh"
else
  _SRC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || echo "")
  if [ -n "$_SRC" ] && [ -x "$_SRC/scripts/cj-goal-common.sh" ]; then
    _COMMON_HELPER="$_SRC/scripts/cj-goal-common.sh"
  fi
fi

# ---- helper: query PR state for a branch via cj-goal-common.sh --phase pr-check
#
# Echoes three space-free tokens: "<PR_CHECK> <PR_EXISTS> <PR_STATE>".
# When the helper is unreachable, returns "skipped  " (PR_CHECK=skipped) so the
# decision table SKIPs — same disposition as gh offline. --mode feature is an
# arbitrary already-valid mode required by cj-goal-common.sh's usage check; the
# pr-check phase is mode-agnostic (it only reads PHASE + --branch).
pr_state_for_branch() {
  local branch="$1"
  if [ -z "$_COMMON_HELPER" ]; then
    printf 'skipped  '
    return 0
  fi
  local out check exists state
  out=$(bash "$_COMMON_HELPER" --phase pr-check --mode feature --branch "$branch" 2>/dev/null || true)
  check=$(printf '%s\n' "$out"  | sed -n 's/^PR_CHECK=//p'  | head -1)
  exists=$(printf '%s\n' "$out" | sed -n 's/^PR_EXISTS=//p' | head -1)
  state=$(printf '%s\n' "$out"  | sed -n 's/^PR_STATE=//p'  | head -1)
  printf '%s %s %s' "${check:-skipped}" "${exists:-}" "${state:-}"
}

# ---- enumerate worktrees + apply the rails + PR-state gate -------------------
#
# `git worktree list --porcelain` emits records separated by blank lines:
#   worktree <path>
#   HEAD <sha>
#   branch refs/heads/<name>     (absent for detached HEAD)
#   locked [<reason>]            (present only when locked)
#   ...
# We parse path/branch/locked per record, keep only branches matching
# ^cj-(feat|def|todo)-, then apply: local-state rails (current / locked / dirty)
# → PR-state gate. REMOVE only when the gate proves landed.

REMOVED=0
SKIPPED=0
REMOVED_PATHS=()
SKIPPED_LINES=()

wt_path=""
wt_branch=""
wt_locked=0

# Decide + act on one fully-parsed worktree record.
process_record() {
  local path="$wt_path" branch="$wt_branch" locked="$wt_locked"
  # Reset accumulators for the next record (caller re-sets per blank line too).
  [ -n "$path" ] || return 0

  # Scope: ONLY cj-(feat|def|todo)-* branches. Everything else (claude/* Conductor
  # sessions, manual chore/fix/feat branches, the root's main) is out of scope and
  # never even reported.
  case "$branch" in
    cj-feat-*|cj-def-*|cj-todo-*) ;;
    *) return 0 ;;
  esac

  # --- Local-state rails (SKIP, logged reason) ---
  if [ "$path" = "$_CURRENT" ]; then
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=current"); return 0
  fi
  if [ "$locked" = "1" ]; then
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=locked"); return 0
  fi
  # Dirty tree: uncommitted / staged / untracked work present.
  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=dirty"); return 0
  fi
  # NOTE: deliberately NO "unpushed commits" rail. After a squash-merge the
  # upstream tracking branch is deleted, so `git rev-list @{u}..HEAD` errors and a
  # LANDED branch looks "unpushed" forever — that would defeat the janitor. The
  # PR-state gate below is the sole authority on landed; dirty-tree is the only
  # local guard needed (unpushed in-flight work is implicitly protected: no push
  # ⇒ no PR ⇒ PR_EXISTS=0 ⇒ SKIP).

  # --- PR-state gate (the decision table) ---
  #   PR_CHECK | PR_EXISTS | PR_STATE            | action
  #   ok       | 1         | MERGED / CLOSED     | REMOVE
  #   ok       | 1         | OPEN                | SKIP (still in review)
  #   ok       | 0         | (empty)             | SKIP (no PR)
  #   skipped  | -         | -                   | SKIP (gh offline/unauth)
  local triplet check exists state
  triplet=$(pr_state_for_branch "$branch")
  check=$(printf '%s' "$triplet"  | awk '{print $1}')
  exists=$(printf '%s' "$triplet" | awk '{print $2}')
  state=$(printf '%s' "$triplet"  | awk '{print $3}')

  if [ "$check" != "ok" ]; then
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=pr-check-$check"); return 0
  fi
  if [ "$exists" != "1" ]; then
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=no-pr"); return 0
  fi
  case "$state" in
    MERGED|CLOSED) ;;  # landed → fall through to REMOVE
    *)
      SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=pr-${state:-open}"); return 0
      ;;
  esac

  # --- REMOVE (proven landed) ---
  if [ "$DRY_RUN" = "1" ]; then
    REMOVED=$((REMOVED + 1)); REMOVED_PATHS+=("$path"); return 0
  fi
  if git -C "$_ROOT" worktree remove "$path" 2>/dev/null; then
    REMOVED=$((REMOVED + 1)); REMOVED_PATHS+=("$path")
  else
    # Removal failed (e.g. a race left it busy). Best-effort: log + count as
    # skipped, never halt.
    SKIPPED=$((SKIPPED + 1)); SKIPPED_LINES+=("$path reason=remove-failed")
  fi
}

# Stream the porcelain output. A blank line terminates each record.
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      # Start of a new record — process the previous one first.
      process_record
      wt_path="${line#worktree }"
      wt_branch=""
      wt_locked=0
      ;;
    "branch refs/heads/"*)
      wt_branch="${line#branch refs/heads/}"
      ;;
    "locked"|"locked "*)
      wt_locked=1
      ;;
    "")
      # Blank line — end of record.
      process_record
      wt_path=""; wt_branch=""; wt_locked=0
      ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)
# Flush the final record (porcelain output may not end with a blank line).
process_record
wt_path=""; wt_branch=""; wt_locked=0

# ---- emit removed / skipped report ------------------------------------------

if [ "$DRY_RUN" = "1" ]; then
  echo "WOULD_REMOVED=$REMOVED"
  for p in "${REMOVED_PATHS[@]:-}"; do [ -n "$p" ] && echo "WOULD-REMOVE_PATH=$p"; done
  echo "WOULD_SKIPPED=$SKIPPED"
  for l in "${SKIPPED_LINES[@]:-}"; do [ -n "$l" ] && echo "WOULD-SKIP_PATH=$l"; done
else
  echo "REMOVED=$REMOVED"
  for p in "${REMOVED_PATHS[@]:-}"; do [ -n "$p" ] && echo "REMOVED_PATH=$p"; done
  echo "SKIPPED=$SKIPPED"
  for l in "${SKIPPED_LINES[@]:-}"; do [ -n "$l" ] && echo "SKIPPED_PATH=$l"; done
fi

# ---- prune orphaned-dir metadata --------------------------------------------
#
# `git worktree prune` clears registrations for worktree dirs git no longer finds
# (the ~3 untracked orphan dirs). Read-only under --dry-run.

if [ "$DRY_RUN" = "1" ]; then
  echo "PRUNED=skipped"
else
  if git -C "$_ROOT" worktree prune 2>/dev/null; then
    echo "PRUNED=ok"
  else
    echo "PRUNED=fail"
  fi
fi

# ---- guarded root-main refresh ----------------------------------------------
#
# Switch the ROOT checkout back to main + pull --ff-only — but ONLY if the root
# tree is clean (never disturb a dirty root). The current session stays in its own
# worktree; only the root is refreshed. From inside a worktree you cannot check
# out main directly (it is already checked out at the root), which is why this
# operates on $_ROOT via `git -C`. Best-effort; log on failure, never halt.

if [ "$DRY_RUN" = "1" ]; then
  echo "ROOT_REFRESH=skipped"
elif [ -n "$(git -C "$_ROOT" status --porcelain 2>/dev/null)" ]; then
  # Dirty root — leave it alone.
  echo "ROOT_REFRESH=skipped"
  echo "[cleanup-note] root checkout is dirty; skipped main refresh" >&2
else
  if git -C "$_ROOT" checkout main >/dev/null 2>&1 && git -C "$_ROOT" pull --ff-only >/dev/null 2>&1; then
    echo "ROOT_REFRESH=ok"
  else
    echo "ROOT_REFRESH=fail"
    echo "[cleanup-note] root main checkout/pull --ff-only did not complete cleanly (best-effort)" >&2
  fi
fi

# ---- final result ------------------------------------------------------------
# Best-effort contract: RESULT=ok and exit 0 even when removals were skipped or a
# removal/prune/refresh failed. The calling run must NEVER halt on cleanup.

echo "RESULT=ok"
exit 0
