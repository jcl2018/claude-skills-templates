#!/usr/bin/env bash
# drain-one-todo.sh — shared per-TODO drain helper.
#
# Extracted from /CJ_goal_todo_fix and /CJ_goal_run Phase 5 inline duplicates
# (F000021 / S000046). Both call this single helper so the per-TODO inner
# loop has one source of truth.
#
# Contract:
#   Args: <heading_or_t_id>            (positional, required)
#         (env) DRY_RUN=1              optional, propagates through to todo_fix.sh
#         (env) DRAIN_SESSION_ID=<id>  optional, shared lockfile session id
#         (env) DRAIN_LOG=<path>       optional, append per-call result lines
#
#   Returns RESULT line on stdout (last line of output, per CJ_personal-pipeline contract):
#     RESULT: STATUS=green; PR_URL=<url>; HEADING=<heading>; T_ID=<id>
#     RESULT: STATUS=lock_skip; HEADING=<heading>; OWNER=<run_id>
#     RESULT: STATUS=halted; STAGE=<preflight|scaffold|pipeline|ship|deploy|todos_md>; HEADING=<heading>
#     RESULT: STATUS=dry_run; HEADING=<heading>; T_ID=<id>
#
#   Exit codes:
#     0 — green | lock_skip | dry_run (continuable)
#     2 — halted (caller decides whether to stop the drain loop)
#
# Lockfile lifecycle:
#   Path:   /tmp/cj-goal-active-headings-$(date +%Y%m%d).txt
#   Format: <heading-sha256>\t<run_id>\t<acquired-at-iso8601>
#   TTL:    per-day (file replaces daily; no GC needed).
#
# This helper performs the lock acquire/release and emits the RESULT line.
# The actual preflight + scaffold + pipeline + ship + deploy + TODOS-mark
# chain remains in todo_fix.sh (delegated below). drain-one-todo.sh is the
# thin per-TODO wrapper; todo_fix.sh still owns the full chain because the
# chain itself requires orchestrator-layer Skill-tool invocations
# (/CJ_personal-pipeline, /ship, /land-and-deploy) that pure bash cannot
# synchronously dispatch.
#
# Therefore: this helper's "Returns RESULT line" contract is implemented in
# two halves:
#   1. Pre-dispatch half (this script): lock + delegate to todo_fix.sh in
#      single-TODO mode. todo_fix.sh emits the CJ_GOAL_HANDOFF_BEGIN/END block
#      that the orchestrator parses to drive the Skill-tool chain.
#   2. Post-chain half (orchestrator): after the chain completes, the
#      orchestrator releases the lock entry and writes the final RESULT line
#      to DRAIN_LOG.
#
# Callers (/CJ_goal_todo_fix Phase 2, /CJ_goal_run Phase 5) must therefore
# read the handoff block emitted by this script's delegated todo_fix.sh
# invocation, drive the Skill chain themselves, then call this script's
# `release` subcommand to drop the lock.

set -euo pipefail

# ---- Constants ---------------------------------------------------------------

LOCKFILE="/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt"
LOCKFILE_LOCK="${LOCKFILE}.lock"  # mutex for atomic lockfile edits

# ---- Helpers -----------------------------------------------------------------

# Compute a stable hash for a heading (case-sensitive; whitespace-stripped).
heading_hash() {
  local heading="$1"
  printf '%s' "$heading" | awk '{$1=$1; print}' | shasum -a 256 | awk '{print $1}'
}

# Atomic mkdir-based mutex (portable across macOS + Linux; no flock dependency).
# Returns 0 on acquire, 1 if already held. Caller MUST mutex_release.
mutex_acquire() {
  local tries=0
  while ! mkdir "$LOCKFILE_LOCK" 2>/dev/null; do
    tries=$((tries + 1))
    if [ "$tries" -gt 50 ]; then
      # ~5s of contention; bail. Caller treats as lock-skip.
      return 1
    fi
    sleep 0.1
  done
  return 0
}

mutex_release() {
  rmdir "$LOCKFILE_LOCK" 2>/dev/null || true
}

# Acquire a lockfile entry for a heading. Prints "OK" on success, "BUSY <owner>"
# if another run already holds the heading.
lock_acquire() {
  local heading="$1"
  local session_id="${2:-${DRAIN_SESSION_ID:-${RUN_ID:-$(date +%Y%m%d-%H%M%S)-$$}}}"
  local h
  h=$(heading_hash "$heading")
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  if ! mutex_acquire; then
    echo "BUSY mutex-contention"
    return 1
  fi

  # Check if heading is already locked.
  if [ -f "$LOCKFILE" ] && grep -q "^${h}	" "$LOCKFILE"; then
    local owner
    owner=$(grep "^${h}	" "$LOCKFILE" | head -1 | awk -F'\t' '{print $2}')
    mutex_release
    echo "BUSY ${owner}"
    return 1
  fi

  # Acquire.
  printf '%s\t%s\t%s\n' "$h" "$session_id" "$now" >> "$LOCKFILE"
  mutex_release
  echo "OK"
  return 0
}

# Release a lockfile entry for a heading owned by this session_id.
lock_release() {
  local heading="$1"
  local session_id="${2:-${DRAIN_SESSION_ID:-${RUN_ID:-}}}"
  [ -z "$session_id" ] && return 0  # nothing to release
  [ ! -f "$LOCKFILE" ] && return 0
  local h
  h=$(heading_hash "$heading")

  if ! mutex_acquire; then
    return 1
  fi

  # Filter out the row for this heading+session_id.
  local tmp
  tmp=$(mktemp)
  awk -F'\t' -v h="$h" -v s="$session_id" '$1 != h || $2 != s { print }' "$LOCKFILE" > "$tmp" || true
  mv "$tmp" "$LOCKFILE"

  mutex_release
  return 0
}

# ---- Subcommand dispatch -----------------------------------------------------

# Subcommand interface (callers from /CJ_goal_run Phase 5 and
# /CJ_goal_todo_fix Phase 2):
#
#   drain-one-todo.sh acquire <heading_or_t_id> [session_id]
#       -> "OK" or "BUSY <owner>" on stdout; exit 0 on OK, 1 on BUSY
#
#   drain-one-todo.sh release <heading_or_t_id> [session_id]
#       -> exit 0 always (idempotent)
#
#   drain-one-todo.sh dispatch <heading_or_t_id>
#       -> acquire lock; delegate to todo_fix.sh; emit RESULT line.
#          If lock BUSY: emit RESULT: STATUS=lock_skip and exit 0.
#          Otherwise: emit todo_fix.sh's CJ_GOAL_HANDOFF block + a RESULT:
#          STATUS=handoff_pending line. Caller orchestrator parses the
#          handoff, drives the Skill chain, then calls `release` itself.
#
# Default (no subcommand): treat positional arg as `dispatch <heading>` for
# backwards compatibility with simple callers.

SUBCMD="${1:-dispatch}"
case "$SUBCMD" in
  acquire|release|dispatch)
    shift
    ;;
  *)
    SUBCMD="dispatch"
    # First positional is the heading; do not shift.
    ;;
esac

HEADING="${1:-}"
SESSION_ID="${2:-${DRAIN_SESSION_ID:-${RUN_ID:-$(date +%Y%m%d-%H%M%S)-$$}}}"

if [ -z "$HEADING" ]; then
  echo "Usage: drain-one-todo.sh [acquire|release|dispatch] <heading_or_t_id> [session_id]" >&2
  exit 1
fi

case "$SUBCMD" in
  acquire)
    lock_acquire "$HEADING" "$SESSION_ID"
    ;;
  release)
    lock_release "$HEADING" "$SESSION_ID"
    ;;
  dispatch)
    # Try to acquire the lock; on BUSY emit lock_skip RESULT and exit 0.
    LOCK_OUTPUT=$(lock_acquire "$HEADING" "$SESSION_ID" 2>&1 || true)
    if echo "$LOCK_OUTPUT" | grep -q '^BUSY'; then
      OWNER=$(echo "$LOCK_OUTPUT" | sed -E 's/^BUSY //')
      echo "[lock-skip] $HEADING locked by RUN_ID=$OWNER"
      echo "RESULT: STATUS=lock_skip; HEADING=$HEADING; OWNER=$OWNER"
      exit 0
    fi

    # F000025/S000054: per-iteration worktree creation.
    # Each drained TODO gets its own .claude/worktrees/cj-todo-{ts}-{pid}/ so
    # /ship Gate #2 (one PR per TODO) can run cleanly without branch collision.
    # --force-create bypasses in-worktree detection (drain typically runs from
    # inside a Conductor parent worktree). --quiet suppresses the [worktree]
    # echo so cron output stays empty.
    #
    # D-fix (drain-one-todo worktree-init path resolution): the helper MUST be
    # resolved via the workbench-source path recorded in
    # ~/.claude/.skills-templates.json (.source) — exactly the convention
    # todo_fix.sh preamble (line ~11), the single-TODO SKILL.md preamble, and
    # the F000009 update-check preamble already use. The original
    # BASH_SOURCE-relative `../../..` resolution only held for the in-repo
    # checkout: skills-deploy symlinks per-skill files into
    # ~/.claude/skills/CJ_goal_todo_fix/scripts/ but NEVER deploys repo-root
    # scripts/ to ~/.claude/scripts/, so from the deployed location
    # `../../..` resolves to ~/.claude and the helper was looked for at the
    # nonexistent ~/.claude/scripts/cj-worktree-init.sh — drain then silently
    # ran every TODO on the current branch (the exact collision S000054 fixes).
    # Manifest .source is primary; BASH_SOURCE-relative is the in-repo /
    # no-manifest fallback (consumer repos without workbench source still
    # degrade gracefully — helper simply unreachable, today's behavior).
    _WT_HELPER=""
    _WT_SRC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || true)
    if [ -n "$_WT_SRC" ] && [ -x "$_WT_SRC/scripts/cj-worktree-init.sh" ]; then
      _WT_HELPER="$_WT_SRC/scripts/cj-worktree-init.sh"
    else
      _WT_FALLBACK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd)/scripts/cj-worktree-init.sh"
      [ -x "$_WT_FALLBACK" ] && _WT_HELPER="$_WT_FALLBACK"
    fi
    if [ -x "$_WT_HELPER" ]; then
      _WT_JSON=$("$_WT_HELPER" --caller todo --force-create --quiet 2>/dev/null || true)
      if [ -n "$_WT_JSON" ]; then
        _WT_STATE=$(echo "$_WT_JSON" | jq -r '.state // "failed"' 2>/dev/null)
        _WT_PATH=$(echo "$_WT_JSON" | jq -r '.path // empty' 2>/dev/null)
        if [ "$_WT_STATE" = "created" ] && [ -n "$_WT_PATH" ]; then
          # cd into the per-TODO worktree before delegating to todo_fix.sh so
          # scaffold writes land in the right tree.
          cd "$_WT_PATH" || {
            lock_release "$HEADING" "$SESSION_ID" >/dev/null 2>&1 || true
            echo "[drain] ERROR: cd $_WT_PATH failed" >&2
            echo "RESULT: STATUS=halted; STAGE=preflight; HEADING=$HEADING; REASON=worktree-cd-failed"
            exit 2
          }
        fi
        # state=failed/detected/skipped/opted_out: continue without cd (drain
        # iteration runs in current tree; matches today's behavior when
        # helper is unavailable).
      fi
    fi
    # If helper missing entirely: drain iteration proceeds on current branch
    # (today's behavior preserved; consumer repos without workbench source
    # silently degrade).

    # Lock acquired. Delegate to todo_fix.sh in single-TODO mode.
    # todo_fix.sh handles preflight, scaffold, and emits the
    # CJ_GOAL_HANDOFF_BEGIN/END block that the orchestrator parses to drive
    # the full Skill chain. drain-one-todo.sh does NOT drive the chain itself.
    TODO_FIX_PATH=""
    for p in \
      "$(git rev-parse --show-toplevel 2>/dev/null)/skills/CJ_goal_todo_fix/scripts/todo_fix.sh" \
      "$HOME/.claude/skills/CJ_goal_todo_fix/scripts/todo_fix.sh"; do
      if [ -x "$p" ]; then TODO_FIX_PATH="$p"; break; fi
    done
    if [ -z "$TODO_FIX_PATH" ]; then
      # Release the lock before erroring out.
      lock_release "$HEADING" "$SESSION_ID" >/dev/null 2>&1 || true
      echo "Error: todo_fix.sh not found in workbench or ~/.claude/" >&2
      echo "RESULT: STATUS=halted; STAGE=preflight; HEADING=$HEADING; REASON=todo_fix.sh-not-found"
      exit 2
    fi

    # If HEADING looks like a T-ID, pass it as such; otherwise pass as fragment.
    # todo_fix.sh's input parser handles both shapes (T-ID exact OR fragment).
    if echo "$HEADING" | grep -qE '^T[0-9]{6}$'; then
      ARG="$HEADING"
    else
      # Strip leading `### ` literal if present (callers may pass naked or full headings).
      # NOTE: ${var#### } without quotes is parsed as ${var##} (greedy empty pattern).
      # Must quote the pattern to make `### ` literal. Verified via printf-od trace.
      ARG="${HEADING#"### "}"
    fi

    # DRY_RUN propagation: drain caller may set DRY_RUN=1 to preview.
    if [ "${DRY_RUN:-0}" = "1" ]; then
      DRY_RUN=1 bash "$TODO_FIX_PATH" --dry-run "$ARG"
      RC=$?
      # Release lock immediately for dry-run (no chain to drive).
      lock_release "$HEADING" "$SESSION_ID" >/dev/null 2>&1 || true
      if [ "$RC" -eq 0 ]; then
        echo "RESULT: STATUS=dry_run; HEADING=$HEADING"
        exit 0
      else
        echo "RESULT: STATUS=halted; STAGE=preflight; HEADING=$HEADING; REASON=dry-run-todo-fix-rc=$RC"
        exit 2
      fi
    fi

    # Live mode: dispatch todo_fix.sh; let it emit the handoff block.
    # Orchestrator parses the handoff block, drives /CJ_personal-pipeline +
    # /ship + /land-and-deploy via Skill tool, then calls
    # `drain-one-todo.sh release "$HEADING"` to drop the lock.
    bash "$TODO_FIX_PATH" "$ARG"
    RC=$?

    # todo_fix.sh exits 0 on green/idempotent_skip (handoff block emitted),
    # 2 on halt. On halt, release the lock now (no chain to drive).
    if [ "$RC" -ne 0 ]; then
      lock_release "$HEADING" "$SESSION_ID" >/dev/null 2>&1 || true
      echo "RESULT: STATUS=halted; STAGE=preflight; HEADING=$HEADING; REASON=todo-fix-rc=$RC"
      exit 2
    fi

    # Green-with-handoff: emit handoff_pending RESULT and exit 0. Orchestrator
    # MUST call `release` after the Skill chain completes.
    echo "RESULT: STATUS=handoff_pending; HEADING=$HEADING; SESSION_ID=$SESSION_ID"
    exit 0
    ;;
esac
