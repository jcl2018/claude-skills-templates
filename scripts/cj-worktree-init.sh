#!/usr/bin/env bash
# cj-worktree-init.sh — auto-create a .claude/worktrees/cj-{type}-{ts}-{pid}/ worktree
# for /CJ_goal_run, /CJ_goal_investigate (deferred), /CJ_goal_todo_fix.
#
# Output: ONE LINE of JSON on stdout. The caller parses with `jq -r '.field'`.
#   {"state":"created|detected|skipped|opted_out|failed",
#    "path":"<absolute path>",
#    "branch":"<branch name>",
#    "note":"<one-line note>"}
#
# Args:
#   --caller {run|investigate|todo}   required; maps to branch prefix
#   --no-worktree                     opt-out; run on current branch
#   --quiet                           gates [worktree] echo (caller-side); suppresses interactive halt on dirty
#   --dry-run                         emit JSON only; no filesystem mutation
#   --force-create                    bypass in-worktree detection (drain-loop use)
#
# Caller→prefix:  run→cj-run  investigate→cj-inv  todo→cj-todo
#
# Exit codes:
#   0 — state ∈ {created, detected, skipped, opted_out}; caller continues
#   1 — state == failed; caller exits 1
#
# Security: stdout is ALWAYS one line of JSON. `note` is sanitized to ASCII
# printable + safe punctuation, capped at 200 chars. No eval; no shell-injection
# surface even if a future git error path leaks raw bytes into `note`.

set -euo pipefail

# ---- Arg parsing -------------------------------------------------------------

CALLER=""
NO_WORKTREE=0
QUIET=0
DRY_RUN=0
FORCE_CREATE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --caller)        CALLER="${2:-}"; shift 2 ;;
    --no-worktree)   NO_WORKTREE=1; shift ;;
    --quiet)         QUIET=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    --force-create)  FORCE_CREATE=1; shift ;;
    *)               shift ;;  # Ignore unknown args; caller forwards "$@" wholesale
  esac
done

# Validate --caller
case "$CALLER" in
  run|investigate|todo) ;;
  *) printf '{"state":"failed","path":"","branch":"","note":"--caller required (one of: run, investigate, todo)"}\n'; exit 1 ;;
esac

# Explicit caller→prefix map (per design Decision Audit Trail #12)
case "$CALLER" in
  run)         PREFIX="cj-run" ;;
  investigate) PREFIX="cj-inv" ;;
  todo)        PREFIX="cj-todo" ;;
esac

# ---- Helper: sanitize note for JSON-safe single-line output ------------------

# Strip control chars, NULs, quotes; cap at 200 chars. jq -Rs '.' would also work
# but we want a uniform pure-bash sanitizer that works without jq input piping.
sanitize_note() {
  local raw="$1"
  # Replace newlines with spaces, strip non-printable + double-quote + backslash, cap.
  printf '%s' "$raw" | tr '\n\r\t' '   ' | tr -d -c '[:print:]' | tr -d '"\\' | cut -c1-200
}

# Emit one line of JSON. Args: state, path, branch, note
emit_json() {
  local state="$1" path="$2" branch="$3" note="$4"
  # Use jq for JSON-safe quoting of every field.
  jq -nc \
    --arg state "$state" \
    --arg path "$path" \
    --arg branch "$branch" \
    --arg note "$(sanitize_note "$note")" \
    '{state:$state, path:$path, branch:$branch, note:$note}'
}

# ---- Step 1: --no-worktree opt-out -------------------------------------------

if [ "$NO_WORKTREE" = "1" ]; then
  emit_json "opted_out" "$(pwd)" "" "opted out via --no-worktree"
  exit 0
fi

# ---- Step 2: must be in a git repo ------------------------------------------

if ! TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null); then
  emit_json "failed" "$(pwd)" "" "not inside a git repository"
  exit 1
fi

# ---- Step 3: detect in-worktree (unless --force-create) ---------------------

if [ "$FORCE_CREATE" != "1" ]; then
  GITDIR=$(git rev-parse --git-dir 2>/dev/null || echo "")
  COMMON=$(git rev-parse --git-common-dir 2>/dev/null || echo "")
  if [ -n "$GITDIR" ] && [ -n "$COMMON" ] && [ "$GITDIR" != "$COMMON" ]; then
    # Already inside a worktree (Conductor case). No-op.
    WT_NAME=$(basename "$(pwd)")
    emit_json "detected" "$(pwd)" "" "already in worktree $WT_NAME"
    exit 0
  fi
fi

# ---- Step 4: detect on-main (unless --force-create) -------------------------

BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ "$FORCE_CREATE" != "1" ]; then
  case "$BRANCH" in
    main|master) ;;
    *)
      # On a feature branch — respect user's choice; do not auto-wrap.
      emit_json "skipped" "$(pwd)" "$BRANCH" "on feature branch $BRANCH; respecting current checkout"
      exit 0
      ;;
  esac
fi

# ---- Step 5: dirty-state check ----------------------------------------------

if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  if [ "$QUIET" = "1" ]; then
    emit_json "skipped" "$(pwd)" "$BRANCH" "dirty checkout; ran in-place under --quiet"
    exit 0
  else
    emit_json "failed" "$(pwd)" "" "dirty checkout: stash/commit or pass --no-worktree"
    exit 1
  fi
fi

# ---- Step 6: compose name + path --------------------------------------------

TS=$(date +%Y%m%d-%H%M%S)
NAME="${PREFIX}-${TS}-$$"
WT_PATH="${TOPLEVEL}/.claude/worktrees/${NAME}"

# ---- Step 7: --dry-run preview ----------------------------------------------

if [ "$DRY_RUN" = "1" ]; then
  emit_json "created" "$WT_PATH" "$NAME" "(dry-run) would create $NAME"
  exit 0
fi

# ---- Step 8: git worktree add (with one retry on collision) -----------------

mkdir -p "$(dirname "$WT_PATH")"

ERR_LOG=$(mktemp)
trap 'rm -f "$ERR_LOG"' EXIT

if ! git worktree add "$WT_PATH" -b "$NAME" >/dev/null 2>"$ERR_LOG"; then
  # Retry once with extended PID+RANDOM suffix to dodge transient collisions.
  NAME="${PREFIX}-${TS}-$$-${RANDOM}"
  WT_PATH="${TOPLEVEL}/.claude/worktrees/${NAME}"
  if ! git worktree add "$WT_PATH" -b "$NAME" >/dev/null 2>"$ERR_LOG"; then
    GIT_ERR=$(head -c 300 "$ERR_LOG" 2>/dev/null || true)
    emit_json "failed" "$(pwd)" "" "git worktree add failed: $GIT_ERR"
    exit 1
  fi
fi

# ---- Step 9: emit success ----------------------------------------------------

emit_json "created" "$WT_PATH" "$NAME" "created $NAME"
exit 0
