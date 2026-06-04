#!/usr/bin/env bash
# cj-goal-common.sh — deterministic shared plumbing for the two CJ_goal verb
# skills (/CJ_goal_feature, /CJ_goal_defect — F000027 / casing-fix F000031).
#
# The common, deterministic work that would otherwise be duplicated as
# LLM-followed prose in both verb skills lives here as testable bash, gated by
# explicit --phase / --mode flags. Skill-tool invocations (office-hours,
# scaffold, impl, qa, ship) stay INLINE in each verb skill (Approach A,
# F000027_DESIGN Big Decision #4); only the drift-prone deterministic trio is
# centralized.
#
# The trio (the agreed floor per S000057_SPEC Open Question — deliberately
# MINIMAL, do not over-build):
#   1. worktree   — delegate to cj-worktree-init.sh (--caller feature|defect)
#   2. telemetry  — append one JSON line audit-receipt to
#                   ~/.gstack/analytics/cj-goal-<mode>.jsonl
#   3. pr-check   — deterministic PR-existence check (gh pr list); read-only
#   4. cleanup    — delegate to cj-worktree-cleanup.sh (--caller feature|defect);
#                   the post-run worktree janitor (T000036). Best-effort: emits
#                   PHASE_RESULT=ok|skipped, NEVER failed (cleanup must not give a
#                   caller any reason to halt).
#
# Args:
#   --phase {worktree|telemetry|pr-check|ship|cleanup}   required; selects the op
#                                                 ('ship' is an alias for pr-check —
#                                                 the PR-creation seam where the
#                                                 verb skills run the PR check)
#   --mode  {feature|defect}                      required; verb context
#   --dry-run                                     emit output only; no fs / git mutation
#   --no-worktree                                 (worktree phase) forward opt-out to helper
#   --branch NAME                                 (pr-check phase) --head fallback for gh pr list
#   --repo PATH                                   repo root override (default: git toplevel)
#   --receipt-file PATH                           (telemetry phase) override receipt path (test hook)
#   --field KEY=VALUE                             (telemetry phase) repeatable; extra receipt fields
#
# Stdout (always emitted, one line per field, KEY=VALUE — mirrors
# scripts/cj-handoff-gate.sh):
#   PHASE=<phase>
#   MODE=<mode>
#   <phase-specific fields, see each phase below>
#   PHASE_RESULT=<ok|skipped|failed>
#
# Stderr (only on failure / skip):
#   [common-<phase>-<reason>] one-line description
#
# Exit codes:
#   0 — PHASE_RESULT ∈ {ok, skipped}; caller continues
#   1 — bad usage (unknown/missing --phase or --mode)
#   2 — PHASE_RESULT == failed; caller halts
#
# Security: stdout is a fixed KEY=VALUE schema; the telemetry receipt is written
# via jq for JSON-safe escaping (sanitized-echo fallback when jq is absent). No
# eval; no shell-injection surface. The worktree phase shells out only to the
# vetted cj-worktree-init.sh helper, never to caller-supplied strings.

set -u  # strict on undefined vars; do NOT set -e — phase ops handle errors explicitly

# ---- defaults ----------------------------------------------------------------

PHASE=""
MODE=""
DRY_RUN=0
NO_WORKTREE=0
BRANCH=""
REPO_OVERRIDE=""
RECEIPT_FILE=""
EXTRA_FIELDS=()

# ---- arg parsing -------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --phase)        PHASE="${2:-}"; shift 2 ;;
    --mode)         MODE="${2:-}"; shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    --no-worktree)  NO_WORKTREE=1; shift ;;
    --branch)       BRANCH="${2:-}"; shift 2 ;;
    --repo)         REPO_OVERRIDE="${2:-}"; shift 2 ;;
    --receipt-file) RECEIPT_FILE="${2:-}"; shift 2 ;;
    --field)        EXTRA_FIELDS+=("${2:-}"); shift 2 ;;
    *)              shift ;;  # ignore unknown args (callers may forward "$@")
  esac
done

# ---- validate --mode (shared by all phases) ---------------------------------

case "$MODE" in
  feature|defect) ;;
  *)
    echo "[common-usage-mode] --mode required (one of: feature, defect)" >&2
    exit 1
    ;;
esac

# ---- validate --phase --------------------------------------------------------

# 'ship' is an alias for pr-check (the PR-creation seam). Normalize early so the
# dispatch + stdout PHASE field both report the canonical phase.
case "$PHASE" in
  ship) PHASE="pr-check" ;;
esac

case "$PHASE" in
  worktree|telemetry|pr-check|cleanup) ;;
  *)
    echo "[common-usage-phase] --phase required (one of: worktree, telemetry, pr-check, ship, cleanup)" >&2
    exit 1
    ;;
esac

# ---- resolve repo root -------------------------------------------------------

if [ -n "$REPO_OVERRIDE" ]; then
  REPO_ROOT="$REPO_OVERRIDE"
else
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
fi

# ---- helper: sanitize a note/string to a JSON-safe single line --------------

sanitize() {
  printf '%s' "${1:-}" | tr '\n\r\t' '   ' | tr -d -c '[:print:]' | tr -d '\\"' | cut -c1-200
}

# ---- helper: resolve cj-worktree-init.sh (2-level probe) --------------------
#
# Mirrors the resolution convention used by drain-one-todo.sh / todo_fix.sh:
#   (1) sibling in this script's own dir (workbench self-dev — the common case
#       when both helpers ship together in scripts/);
#   (2) <manifest .source>/scripts/cj-worktree-init.sh (deployed ~/.claude/
#       context, where repo-root scripts/ are NOT copied — the .source field in
#       ~/.claude/.skills-templates.json points back at the user's clone).
resolve_worktree_helper() {
  local self_dir cand src
  self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  cand="$self_dir/cj-worktree-init.sh"
  if [ -x "$cand" ]; then printf '%s' "$cand"; return 0; fi
  src=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || echo "")
  if [ -n "$src" ] && [ -x "$src/scripts/cj-worktree-init.sh" ]; then
    printf '%s' "$src/scripts/cj-worktree-init.sh"; return 0
  fi
  return 1
}

# ---- helper: resolve cj-worktree-cleanup.sh (same 2-level probe) -------------
#
# Identical resolution shape to resolve_worktree_helper, for the cleanup janitor
# (T000036). Sibling-in-scripts/ first (workbench self-dev), then manifest .source.
resolve_cleanup_helper() {
  local self_dir cand src
  self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  cand="$self_dir/cj-worktree-cleanup.sh"
  if [ -x "$cand" ]; then printf '%s' "$cand"; return 0; fi
  src=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || echo "")
  if [ -n "$src" ] && [ -x "$src/scripts/cj-worktree-cleanup.sh" ]; then
    printf '%s' "$src/scripts/cj-worktree-cleanup.sh"; return 0
  fi
  return 1
}

# =============================================================================
# Phase: worktree — delegate to cj-worktree-init.sh
# =============================================================================
#
# Stdout fields: WT_STATE, WT_PATH, WT_BRANCH (verbatim from the helper JSON).
# --mode maps directly to the helper's --caller (feature→cj-feat, defect→cj-def).

if [ "$PHASE" = "worktree" ]; then
  echo "PHASE=worktree"
  echo "MODE=$MODE"

  HELPER=$(resolve_worktree_helper || echo "")
  if [ -z "$HELPER" ]; then
    echo "WT_STATE=unavailable"
    echo "WT_PATH="
    echo "WT_BRANCH="
    echo "PHASE_RESULT=failed"
    echo "[common-worktree-unavailable] cj-worktree-init.sh not found (sibling dir nor manifest .source)" >&2
    exit 2
  fi

  WT_ARGS=(--caller "$MODE")
  [ "$NO_WORKTREE" = "1" ] && WT_ARGS+=(--no-worktree)
  [ "$DRY_RUN" = "1" ] && WT_ARGS+=(--dry-run)

  WT_OUT=$(bash "$HELPER" "${WT_ARGS[@]}" 2>/dev/null) && WT_RC=0 || WT_RC=$?
  WT_STATE=$(printf '%s' "$WT_OUT" | jq -r '.state // ""' 2>/dev/null || echo "")
  WT_PATH=$(printf '%s' "$WT_OUT" | jq -r '.path // ""' 2>/dev/null || echo "")
  WT_BRANCH=$(printf '%s' "$WT_OUT" | jq -r '.branch // ""' 2>/dev/null || echo "")

  echo "WT_STATE=$WT_STATE"
  echo "WT_PATH=$WT_PATH"
  echo "WT_BRANCH=$WT_BRANCH"

  # The helper's own exit code is authoritative: 0 = caller continues
  # (created/detected/skipped/opted_out); non-zero = failed.
  if [ "$WT_RC" -eq 0 ]; then
    echo "PHASE_RESULT=ok"
    exit 0
  else
    echo "PHASE_RESULT=failed"
    echo "[common-worktree-failed] cj-worktree-init.sh exited $WT_RC (state=$WT_STATE)" >&2
    exit 2
  fi
fi

# =============================================================================
# Phase: cleanup — delegate to cj-worktree-cleanup.sh (the post-run janitor)
# =============================================================================
#
# T000036: the teardown mirror of the worktree phase. Shells to
# cj-worktree-cleanup.sh passing --caller "$MODE" (feature|defect — both
# already-valid modes; there is NO --mode todo, and we deliberately do NOT
# introduce one: todo wires the cleanup helper directly, same as its create
# step). --dry-run forwards.
#
# Stdout: PHASE=cleanup, then the helper's full structured report verbatim,
# then PHASE_RESULT. CRITICAL: cleanup is best-effort and must NEVER hand a
# caller a reason to halt, so PHASE_RESULT is ALWAYS ok (helper ran) or skipped
# (helper unreachable) — NEVER failed. Exit 0 in every case.

if [ "$PHASE" = "cleanup" ]; then
  echo "PHASE=cleanup"
  echo "MODE=$MODE"

  CLEAN_HELPER=$(resolve_cleanup_helper || echo "")
  if [ -z "$CLEAN_HELPER" ]; then
    echo "PHASE_RESULT=skipped"
    echo "[common-cleanup-unavailable] cj-worktree-cleanup.sh not found (sibling dir nor manifest .source); skipping janitor" >&2
    exit 0
  fi

  CLEAN_ARGS=(--caller "$MODE")
  [ "$DRY_RUN" = "1" ] && CLEAN_ARGS+=(--dry-run)

  # Pass through the helper's report verbatim. The helper itself returns 0 for
  # ok/skipped; even on an unexpected non-zero we still emit ok (best-effort).
  bash "$CLEAN_HELPER" "${CLEAN_ARGS[@]}" 2>/dev/null || true
  echo "PHASE_RESULT=ok"
  exit 0
fi

# =============================================================================
# Phase: telemetry — append a one-line JSON audit receipt
# =============================================================================
#
# Receipt path: ~/.gstack/analytics/cj-goal-<mode>.jsonl (per-verb stream,
# mirrors ~/.gstack/analytics/CJ_goal_auto.jsonl). --receipt-file overrides
# (test hook). Each --field KEY=VALUE adds a string field to the JSON object.
# Always carries ts (UTC ISO-8601), mode, and phase.
#
# Stdout fields: RECEIPT_FILE, RECEIPT_WRITTEN.

if [ "$PHASE" = "telemetry" ]; then
  echo "PHASE=telemetry"
  echo "MODE=$MODE"

  if [ -n "$RECEIPT_FILE" ]; then
    RCPT="$RECEIPT_FILE"
  else
    RCPT="$HOME/.gstack/analytics/cj-goal-${MODE}.jsonl"
  fi
  echo "RECEIPT_FILE=$RCPT"

  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  if [ "$DRY_RUN" = "1" ]; then
    echo "RECEIPT_WRITTEN=0"
    echo "PHASE_RESULT=ok"
    exit 0
  fi

  if ! mkdir -p "$(dirname "$RCPT")" 2>/dev/null; then
    echo "RECEIPT_WRITTEN=0"
    echo "PHASE_RESULT=failed"
    echo "[common-telemetry-mkdir] could not create $(dirname "$RCPT")" >&2
    exit 2
  fi

  # Build the JSON object. Base fields first, then each --field KEY=VALUE pair
  # (split on the FIRST '='; value JSON-escaped via jq --arg).
  if command -v jq >/dev/null 2>&1; then
    JQ_ARGS=(--arg ts "$TS" --arg mode "$MODE" --arg phase "telemetry")
    # shellcheck disable=SC2016  # $ts/$mode/$phase are jq program variables (jq expands them via --arg), not bash expansions
    JQ_OBJ='{ts:$ts,mode:$mode,phase:$phase'
    _i=0
    for kv in "${EXTRA_FIELDS[@]:-}"; do
      [ -z "$kv" ] && continue
      _k="${kv%%=*}"
      _v="${kv#*=}"
      # Drop keys that aren't safe identifiers (defensive; keep the schema clean).
      case "$_k" in
        ''|*[!a-zA-Z0-9_]*) continue ;;
      esac
      JQ_ARGS+=(--arg "f$_i" "$_v")
      JQ_OBJ="$JQ_OBJ,\"$_k\":\$f$_i"
      _i=$((_i + 1))
    done
    JQ_OBJ="$JQ_OBJ}"
    if jq -nc "${JQ_ARGS[@]}" "$JQ_OBJ" >> "$RCPT" 2>/dev/null; then
      echo "RECEIPT_WRITTEN=1"
      echo "PHASE_RESULT=ok"
      exit 0
    else
      echo "RECEIPT_WRITTEN=0"
      echo "PHASE_RESULT=failed"
      echo "[common-telemetry-jq] jq failed to write receipt to $RCPT" >&2
      exit 2
    fi
  else
    # jq-absent fallback: sanitized echo. Base fields only (extra fields are
    # best-effort dropped to keep the JSON well-formed without jq escaping).
    if echo "{\"ts\":\"$TS\",\"mode\":\"$(sanitize "$MODE")\",\"phase\":\"telemetry\"}" >> "$RCPT" 2>/dev/null; then
      echo "RECEIPT_WRITTEN=1"
      echo "PHASE_RESULT=ok"
      exit 0
    else
      echo "RECEIPT_WRITTEN=0"
      echo "PHASE_RESULT=failed"
      echo "[common-telemetry-write] could not append receipt to $RCPT" >&2
      exit 2
    fi
  fi
fi

# =============================================================================
# Phase: pr-check — deterministic PR-existence check (read-only)
# =============================================================================
#
# Uses `gh pr list` to resolve whether a PR exists for the current branch (or
# the --branch override). Read-only; fail-SOFT when gh is offline /
# unauthenticated (PR_CHECK=skipped, exit 0) — mirrors check-version-queue.sh's
# offline tolerance. A hard failure here would block both verb skills whenever
# the network blips; the verb skill treats 'skipped' as "could not determine,
# proceed" the same way /ship + /land-and-deploy do.
#
# Stdout fields: PR_CHECK, PR_EXISTS, PR_NUMBER, PR_STATE.

if [ "$PHASE" = "pr-check" ]; then
  echo "PHASE=pr-check"
  echo "MODE=$MODE"

  emit_pr_skip() {
    echo "PR_CHECK=skipped"
    echo "PR_EXISTS="
    echo "PR_NUMBER="
    echo "PR_STATE="
    echo "PHASE_RESULT=skipped"
    echo "[common-pr-check-skip] $1" >&2
    exit 0
  }

  command -v gh >/dev/null 2>&1 || emit_pr_skip "gh CLI not installed"
  [ -n "$REPO_ROOT" ] || emit_pr_skip "not inside a git repository (no toplevel)"

  # Resolve the branch to query: explicit --branch wins, else current branch.
  QUERY_BRANCH="$BRANCH"
  if [ -z "$QUERY_BRANCH" ]; then
    QUERY_BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "")
  fi
  [ -n "$QUERY_BRANCH" ] || emit_pr_skip "could not resolve a branch to query"

  if [ "$DRY_RUN" = "1" ]; then
    echo "PR_CHECK=ok"
    echo "PR_EXISTS="
    echo "PR_NUMBER="
    echo "PR_STATE="
    echo "PHASE_RESULT=ok"
    exit 0
  fi

  # `gh pr list --head <branch>` is read-only. --state all so a merged/closed PR
  # still resolves (the verb skill decides what to do with the state).
  PR_JSON=$(gh pr list --head "$QUERY_BRANCH" --state all --json number,state --limit 1 2>/dev/null) && GH_RC=0 || GH_RC=$?
  if [ "$GH_RC" -ne 0 ]; then
    emit_pr_skip "gh pr list failed (offline / unauthenticated / repo not on a remote)"
  fi

  PR_NUMBER=$(printf '%s' "$PR_JSON" | jq -r '.[0].number // ""' 2>/dev/null || echo "")
  PR_STATE=$(printf '%s' "$PR_JSON" | jq -r '.[0].state // ""' 2>/dev/null || echo "")

  echo "PR_CHECK=ok"
  if [ -n "$PR_NUMBER" ]; then
    echo "PR_EXISTS=1"
  else
    echo "PR_EXISTS=0"
  fi
  echo "PR_NUMBER=$PR_NUMBER"
  echo "PR_STATE=$PR_STATE"
  echo "PHASE_RESULT=ok"
  exit 0
fi

# Unreachable — phase validation above exits non-zero on any unknown phase.
echo "[common-internal] unhandled phase '$PHASE'" >&2
exit 1
