#!/usr/bin/env bash
set -euo pipefail

# /CJ_goal_todo_fix — auto-resolve a TODOS.md row into a shipped PR.
# Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260514-162927.md
# Work-item: work-items/features/ops/F000019_cj_goal_todo_bridge/S000041_skill_skeleton/

# ---- Preamble -----------------------------------------------------------------

# Collection update check (silent if no update; banner if newer version available).
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null || true)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true

# Repo-root detection. Fail loud if not in a git repo.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: /CJ_goal_todo_fix must be run inside a git repo (git rev-parse --show-toplevel failed)." >&2
  exit 1
}
cd "$REPO_ROOT"

TODOS="TODOS.md"
WORKITEMS_DIR="work-items"

# Run-time identity.
RUN_ID="${RUN_ID:-$(date +%Y%m%d-%H%M%S)-$$}"
START_EPOCH=$(date +%s)
SKIP_FILE="/tmp/cj-goal-skip-${RUN_ID}.txt"
TELEMETRY="$HOME/.gstack/analytics/CJ_goal_todo_fix.jsonl"
mkdir -p "$(dirname "$TELEMETRY")"

# Capture TODOS.md pre-image hash for Step 5 hash-verify (covers the
# multi-minute pipeline + ship + deploy window between Step 0 and Step 5).
PRE_HASH=""
if [ -f "$TODOS" ]; then
  PRE_HASH=$(shasum -a 256 "$TODOS" | awk '{print $1}')
fi

# Count invocation lines in the telemetry file. Used by sunset trip-wire
# calibration. Read-only; never writes.
# shellcheck disable=SC2329  # intentionally exposed for external sunset consumers
telemetry_invocation_count() {
  local n=0
  if [ -f "$TELEMETRY" ]; then
    n=$(wc -l < "$TELEMETRY" | tr -d ' ')
  fi
  echo "$n"
}

# Telemetry writer. Called from every exit path; idempotent within a run.
# Reads $QUIET (set by --quiet flag below) to emit `scheduled_run` field per
# S000047 (v4.3.0). The field is always present (true/false) so retro tooling
# can grep without conditionals.
TELEMETRY_WRITTEN=0
write_telemetry() {
  local end_state="$1"
  local todo_heading="${2:-}"
  local t_id="${3:-}"
  local pr_url="${4:-}"
  local now_epoch
  now_epoch=$(date +%s)
  local duration_s=$(( now_epoch - START_EPOCH ))
  if [ "$TELEMETRY_WRITTEN" -eq 1 ]; then
    return 0
  fi
  TELEMETRY_WRITTEN=1
  # scheduled_run: true when --quiet (cron / /schedule pattern); false otherwise.
  # Defaults to false if QUIET is unset (interactive operator-driven run).
  local scheduled_run_bool
  if [ "${QUIET:-0}" = "1" ]; then
    scheduled_run_bool=true
  else
    scheduled_run_bool=false
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg todo_heading "$todo_heading" \
      --arg t_id "$t_id" \
      --arg end_state "$end_state" \
      --arg pr_url "$pr_url" \
      --argjson duration_s "$duration_s" \
      --arg parent_skill "CJ_goal_todo_fix" \
      --argjson scheduled_run "$scheduled_run_bool" \
      '{ts:$ts,todo_heading:$todo_heading,t_id:$t_id,end_state:$end_state,pr_url:$pr_url,duration_s:$duration_s,parent_skill:$parent_skill,scheduled_run:$scheduled_run}' \
      >> "$TELEMETRY" 2>/dev/null || true
  else
    # Sanitized fallback: strip backslashes + double-quotes.
    local _h _i _u
    _h=$(printf '%s' "$todo_heading" | tr -d '\\"')
    _i=$(printf '%s' "$t_id" | tr -d '\\"')
    _u=$(printf '%s' "$pr_url" | tr -d '\\"')
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"todo_heading\":\"$_h\",\"t_id\":\"$_i\",\"end_state\":\"$end_state\",\"pr_url\":\"$_u\",\"duration_s\":$duration_s,\"parent_skill\":\"CJ_goal_todo_fix\",\"scheduled_run\":$scheduled_run_bool}" >> "$TELEMETRY" 2>/dev/null || true
  fi
}

# Schedule-friendly journal-entry writer (S000047, v4.3.0).
# Replaces the orchestrator-side Phase 3 summary AUQ when --quiet is set.
# Writes `[scheduled-drain-summary]` to a session-level log readable post-cron.
# Path: ~/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl (append-only).
write_scheduled_drain_summary() {
  local summary="$1"  # human-readable summary string (no newlines)
  local session_log="$HOME/.gstack/analytics/CJ_goal_todo_fix-sessions.jsonl"
  mkdir -p "$(dirname "$session_log")"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if command -v jq >/dev/null 2>&1; then
    jq -nc \
      --arg ts "$ts" \
      --arg run_id "$RUN_ID" \
      --arg summary "$summary" \
      --arg marker "scheduled-drain-summary" \
      '{ts:$ts,run_id:$run_id,marker:$marker,summary:$summary}' \
      >> "$session_log" 2>/dev/null || true
  else
    local _s
    _s=$(printf '%s' "$summary" | tr -d '\\"')
    echo "{\"ts\":\"$ts\",\"run_id\":\"$RUN_ID\",\"marker\":\"scheduled-drain-summary\",\"summary\":\"$_s\"}" >> "$session_log" 2>/dev/null || true
  fi
}

# Halt helper: print reason, write telemetry, exit with code 2 (non-zero).
# Special-case end_states that are continue-paths return 0 instead.
halt() {
  local end_state="$1"
  local reason="${2:-}"
  local todo_heading="${3:-}"
  local t_id="${4:-}"
  local pr_url="${5:-}"
  echo "[CJ_goal_todo_fix] end_state=$end_state${reason:+ — $reason}"
  write_telemetry "$end_state" "$todo_heading" "$t_id" "$pr_url"
  case "$end_state" in
    green|idempotent_skip|nothing_to_drain)
      # nothing_to_drain (S000046) is cron-friendly success — "no work today".
      # Exit 0 so scheduled drains don't alert on empty backlogs.
      exit 0
      ;;
    halted_at_preflight|halted_at_sensitive_surface_auto_declined)
      # Skip-list mechanic for /loop: append heading and exit 0 so /loop
      # continues to next iteration. Caller's /loop reads stdout for the
      # skipped: line.
      #
      # `halted_at_sensitive_surface_auto_declined` shares this branch because
      # under bash there is no AUQ tool — the gate auto-defaults regardless of
      # whether a human is present, so `/loop` should defer the row (skip-list)
      # and continue iterating, same as preflight rejections. The
      # `_user_declined` variant is reserved for the future interactive AUQ at
      # the orchestrator layer (it remains STOP via the default branch below).
      if [ -n "$todo_heading" ]; then
        echo "$todo_heading" >> "$SKIP_FILE"
        echo "skipped: $todo_heading (${reason:-preflight})"
      fi
      # exit non-zero so single-shot callers see the halt, but /loop is
      # documented to continue on these end_states. Per design Loop continue
      # set: halted_at_preflight + halted_at_sensitive_surface_auto_declined.
      exit 2
      ;;
    *)
      exit 2
      ;;
  esac
}

# ---- Input parsing ------------------------------------------------------------
#
# Recognized flags/args (any order, no required positional):
#   --dry-run            preview-only; no writes
#   --max-drain N        cap for native drain mode (default 10; 0 → error, use --dry-run)
#   --quiet              schedule-friendly: suppress Phase 3 summary AUQ + start-of-run
#                        stdout banner; write [scheduled-drain-summary] journal entry
#                        instead. Telemetry gains scheduled_run:true. Does NOT suppress
#                        /ship Gate #2 (autonomy ceiling preserved per F000021).
#   <T000NNN>            single-TODO mode by exact T-ID
#   <fragment>           single-TODO mode by fuzzy heading match
#   (no args, no flags)  native drain mode — drain up to --max-drain easy-fix TODOs

ARG=""
DRY_RUN=0
MAX_DRAIN=10        # native-drain cap (S000046 default)
QUIET=0             # schedule-friendly mode (S000047, v4.3.0)
_next_is_max_drain=0
for tok in "$@"; do
  if [ "$_next_is_max_drain" = "1" ]; then
    MAX_DRAIN="$tok"
    _next_is_max_drain=0
    continue
  fi
  case "$tok" in
    --dry-run)    DRY_RUN=1 ;;
    --max-drain)  _next_is_max_drain=1 ;;
    --max-drain=*) MAX_DRAIN="${tok#--max-drain=}" ;;
    --quiet)      QUIET=1 ;;
    --*)
      echo "Error: unknown flag '$tok'" >&2
      exit 1
      ;;
    *)
      if [ -z "$ARG" ]; then
        ARG="$tok"
      else
        echo "Error: only one positional arg (T-ID or fragment) accepted (got extra: '$tok')" >&2
        exit 1
      fi
      ;;
  esac
done
# Export QUIET so write_telemetry / write_scheduled_drain_summary see it.
export QUIET

# Validate MAX_DRAIN.
case "$MAX_DRAIN" in
  ''|*[!0-9]*)
    echo "Error: --max-drain must be a non-negative integer (got: '$MAX_DRAIN')" >&2
    exit 1
    ;;
esac
if [ "$MAX_DRAIN" -eq 0 ]; then
  echo "Error: --max-drain 0 has no effect; use --dry-run for preview instead." >&2
  exit 1
fi

# Determine mode: drain (default, no arg) vs single-TODO (T-ID or fragment).
# DRAIN_MODE=1 enters Phase 1/2/3 below; DRAIN_MODE=0 keeps the existing
# single-TODO v1.1 flow downstream (preserves all halt classes + behaviors).
if [ -z "$ARG" ]; then
  DRAIN_MODE=1
else
  DRAIN_MODE=0
fi

# ---- TODOS.md parser ----------------------------------------------------------

# Extract the candidate set of TODO headings using the same mode-detection
# that /CJ_suggest uses (presence of `## Active work` switches between
# personal-workflow mode and domain-grouped mode).
parse_active_headings() {
  if [ ! -f "$TODOS" ]; then
    echo ""
    return 0
  fi
  if grep -q '^## Active work[[:space:]]*$' "$TODOS"; then
    awk '
      /^## Active work[[:space:]]*$/ {a=1; next}
      /^## / && !/^## Active work[[:space:]]*$/ {a=0}
      a && /^### [^~]/ { print }
    ' "$TODOS"
  else
    awk '
      /^## (Completed|Done|Archive|Archived|Shipped|Deferred work)[[:space:]]*$/ {a=0; next}
      /^## / {a=1}
      a && /^### [^~]/ { print }
    ' "$TODOS"
  fi
}

# Extract the body of a TODO heading from TODOS.md: all lines after this
# `### heading` up to the next `### `, the next `## `, or EOF.
extract_body() {
  local heading_line="$1"
  awk -v heading="$heading_line" '
    $0 == heading { capture = 1; next }
    capture && /^### / { exit }
    capture && /^## / { exit }
    capture { print }
  ' "$TODOS"
}

# ---- Native drain mode (S000046) ---------------------------------------------
#
# When invoked with no positional arg, /CJ_goal_todo_fix enumerates easy-fix
# TODOs via /CJ_suggest --for-skill cj-goal, filters against the per-session
# skip-list and the cross-skill shared lockfile, then emits a
# CJ_GOAL_DRAIN_HANDOFF block listing up to $MAX_DRAIN headings.
#
# The orchestrator parses the block and invokes drain-one-todo.sh per heading,
# which in turn delegates to this same todo_fix.sh in single-TODO mode (the
# T-ID or fragment path below). This keeps the per-TODO chain logic in one
# place — drain mode is purely a Phase 1 enumeration + Phase 3 summary
# wrapper.
#
# Halt classes used here:
#   nothing_to_drain — Phase 1 returns empty (cron-friendly; exit 0)
#   halted_at_resolve — /CJ_suggest itself returned no actionable items
#
# Phase 2 itself runs at the orchestrator layer (Skill chain dispatch); this
# script emits the handoff block and exits 0.

if [ "$DRAIN_MODE" = "1" ]; then
  # S000047 (v4.3.0): suppress start-of-run banner under --quiet so cron output
  # stays empty when there's nothing to report. Halt-on-red entries are
  # unaffected (halt() always echoes its end_state line).
  if [ "$QUIET" -eq 0 ]; then
    echo "[CJ_goal_todo_fix] drain mode: max=$MAX_DRAIN dry_run=$DRY_RUN" >&2
  fi

  # Phase 1: enumerate via /CJ_suggest. Pass --for-skill cj-goal so the
  # preflight-aware ranker (S000042, v3.6.0+) pre-filters P1/L/XL/sensitive/
  # design-keyword rows. Request 2x the cap so we have headroom for lockfile
  # skips and skip-list overlaps.
  SUGGEST_LIMIT=$(( MAX_DRAIN * 2 ))
  [ "$SUGGEST_LIMIT" -lt 5 ] && SUGGEST_LIMIT=5
  SUGGEST_BIN=""
  for p in \
    "$REPO_ROOT/skills/CJ_suggest/scripts/suggest.sh" \
    "$HOME/.claude/skills/CJ_suggest/scripts/suggest.sh"; do
    if [ -x "$p" ]; then SUGGEST_BIN="$p"; break; fi
  done
  if [ -z "$SUGGEST_BIN" ]; then
    halt "halted_at_resolve" "/CJ_suggest script not found (workbench or ~/.claude)"
  fi

  SUGGEST_OUTPUT=""
  if SUGGEST_OUTPUT=$(bash "$SUGGEST_BIN" --for-skill cj-goal --limit "$SUGGEST_LIMIT" 2>&1); then
    :
  else
    halt "halted_at_resolve" "/CJ_suggest failed: $SUGGEST_OUTPUT"
  fi

  if [ -z "$SUGGEST_OUTPUT" ] || echo "$SUGGEST_OUTPUT" | grep -q '^No actionable items\.'; then
    # Empty Phase 1 — distinct end_state for cron consumers.
    # S000047 (v4.3.0): under --quiet, suppress the stdout print and write
    # [scheduled-drain-summary] journal entry to the session log instead.
    # Cron output stays empty; the fact is preserved in the session log.
    if [ "$QUIET" -eq 1 ]; then
      write_scheduled_drain_summary "nothing_to_drain — /CJ_suggest returned no actionable items"
    else
      echo "No easy-fix TODOs available."
    fi
    halt "nothing_to_drain" "/CJ_suggest returned no actionable items"
  fi

  # Parse candidate titles from /CJ_suggest table (column 2).
  CANDIDATES_FILE=$(mktemp)
  trap 'rm -f "$CANDIDATES_FILE"' EXIT
  echo "$SUGGEST_OUTPUT" \
    | awk -F'|' '/^\| [0-9]+ \|/ {
        title=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", title); print title
      }' > "$CANDIDATES_FILE"

  ACTIVE_HEADINGS=$(parse_active_headings)

  # Build the drain list: walk candidates in rank order; for each, recover
  # the full `### Heading (Pn, X)` line; skip if in this-session skip-list
  # or in the cross-skill lockfile.
  DRAIN_LOCK_HELPER=""
  for p in \
    "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh" \
    "$HOME/.claude/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"; do
    if [ -x "$p" ]; then DRAIN_LOCK_HELPER="$p"; break; fi
  done
  # (DRAIN_LOCK_HELPER may be empty in dry-run; that's OK — we skip the
  # lockfile peek in that case.)

  DRAIN_LIST_FILE=$(mktemp)
  trap 'rm -f "$CANDIDATES_FILE" "$DRAIN_LIST_FILE"' EXIT
  DRAIN_COUNT=0
  while IFS= read -r cand_title; do
    [ -z "$cand_title" ] && continue
    [ "$DRAIN_COUNT" -ge "$MAX_DRAIN" ] && break
    full_heading=$(echo "$ACTIVE_HEADINGS" | grep -F -- "$cand_title" | head -1 || true)
    [ -z "$full_heading" ] && continue
    # Strip leading `### ` literal. Bash's ${var#### } is parsed as ${var##}
    # (greedy strip matching empty pattern) — must quote the pattern to make it
    # literal. Confirmed via printf-od trace 2026-05-15 (S000046 dev).
    naked_heading="${full_heading#"### "}"

    # Skip if in this-session skip-list.
    if [ -f "$SKIP_FILE" ] && grep -Fxq "$naked_heading" "$SKIP_FILE"; then
      continue
    fi

    # Skip if currently locked by another session (cross-skill lockfile).
    if [ -n "$DRAIN_LOCK_HELPER" ] && [ "$DRY_RUN" -eq 0 ]; then
      H_HASH=$(printf '%s' "$naked_heading" | awk '{$1=$1; print}' | shasum -a 256 | awk '{print $1}')
      DAILY_LOCKFILE="/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt"
      if [ -f "$DAILY_LOCKFILE" ] && grep -q "^${H_HASH}	" "$DAILY_LOCKFILE"; then
        continue
      fi
    fi

    echo "$naked_heading" >> "$DRAIN_LIST_FILE"
    DRAIN_COUNT=$((DRAIN_COUNT + 1))
  done < "$CANDIDATES_FILE"

  if [ "$DRAIN_COUNT" -eq 0 ]; then
    # S000047 (v4.3.0): same --quiet treatment as the empty-Phase-1 path above.
    if [ "$QUIET" -eq 1 ]; then
      write_scheduled_drain_summary "nothing_to_drain — all candidates filtered by skip-list / lockfile"
    else
      echo "No easy-fix TODOs available."
    fi
    halt "nothing_to_drain" "all candidates filtered by skip-list / lockfile"
  fi

  # Dry-run: print the planned list and exit without invoking drain helper.
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN — no writes will happen."
    echo ""
    echo "Would drain $DRAIN_COUNT TODOs (cap=$MAX_DRAIN):"
    nl -w2 -s'. ' < "$DRAIN_LIST_FILE"
    echo ""
    echo "Run without --dry-run to execute."
    write_telemetry "dry_run" "" ""
    exit 0
  fi

  # Live mode: emit DRAIN_HANDOFF block. Orchestrator parses, then invokes
  # drain-one-todo.sh per heading, capturing PR URLs and halt-on-red status.
  # S000047 (v4.3.0): QUIET=1 line tells the orchestrator to suppress its
  # Phase 3 summary AUQ and instead write a [scheduled-drain-summary] journal
  # entry per drained child's tracker (or the session log when nothing drained).
  # /ship Gate #2 stays interactive per child — the autonomy ceiling.
  echo "CJ_GOAL_DRAIN_HANDOFF_BEGIN"
  echo "MAX_DRAIN=$MAX_DRAIN"
  echo "DRAIN_COUNT=$DRAIN_COUNT"
  echo "SESSION_ID=$RUN_ID"
  echo "QUIET=$QUIET"
  echo "HEADINGS:"
  cat "$DRAIN_LIST_FILE"
  echo "DISPATCH: invoke drain-one-todo.sh dispatch \"<heading>\" \"$RUN_ID\" per HEADING (halt-on-red)"
  echo "CJ_GOAL_DRAIN_HANDOFF_END"

  # Telemetry for the drain enumeration. End_state=drain_handoff_pending; the
  # orchestrator that drives the drain writes a follow-up telemetry line per
  # child (via this same script's single-TODO path) plus a final summary line.
  write_telemetry "drain_handoff_pending" "" ""
  exit 0
fi

# ---- TODO resolution ----------------------------------------------------------

# RESOLVED_HEADING is the exact `### Heading (Pn, X)` line. RESOLVED_BODY is
# the body extracted via extract_body. EXISTING_WORK_ITEM_DIR is set only if
# the resolution branched into the idempotent-dispatch path.
RESOLVED_HEADING=""
RESOLVED_BODY=""
EXISTING_WORK_ITEM_DIR=""
IDEMPOTENT_SKIP=0

if [ -z "$ARG" ]; then
  # No-args mode: invoke /CJ_suggest and take top-1.
  # /CJ_suggest is read-only and writes a markdown table to stdout. Column 2
  # contains the heading title (without `### ` prefix). Skip-list filter:
  # exclude any heading present in $SKIP_FILE (per-session continue mechanic
  # for /loop /CJ_goal_todo_fix).
  #
  # S000042 (CJ_suggest v1.1.0): pass --for-skill cj-goal --limit 15 so
  # /CJ_suggest pre-filters rows that would trip /CJ_goal_todo_fix preflight (P1, size
  # L|XL, sensitive-surface, design-needed) AT RANKING TIME and returns up to
  # 15 rows instead of the default 5. Defense-in-depth: /CJ_goal_todo_fix's own
  # preflight (gates 1-5 below) still runs after this — the pre-filter is an
  # optimization, not a replacement.
  SUGGEST_OUTPUT=""
  if SUGGEST_OUTPUT=$(bash "$HOME/.claude/skills/CJ_suggest/scripts/suggest.sh" --for-skill cj-goal --limit 15 2>&1); then
    :
  else
    halt "halted_at_resolve" "no actionable items from /CJ_suggest"
  fi
  if [ -z "$SUGGEST_OUTPUT" ] || echo "$SUGGEST_OUTPUT" | grep -q '^No actionable items\.'; then
    halt "halted_at_resolve" "/CJ_suggest returned no actionable items"
  fi
  # Parse table rows: data rows start with `| <number> | <title> | ...`
  # Filter out rank header + separator. Match titles against the active
  # headings to recover the full `### ... (Pn, X)` line.
  CANDIDATES_FILE=$(mktemp)
  trap 'rm -f "$CANDIDATES_FILE"' EXIT
  echo "$SUGGEST_OUTPUT" \
    | awk -F'|' '/^\| [0-9]+ \|/ {
        title=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", title); print title
      }' > "$CANDIDATES_FILE"

  ACTIVE_HEADINGS=$(parse_active_headings)
  CHOSEN_TITLE=""
  while IFS= read -r cand_title; do
    [ -z "$cand_title" ] && continue
    # Match by substring (the suggest table's title omits the `(Pn, X)` suffix).
    full_heading=$(echo "$ACTIVE_HEADINGS" | grep -F -- "$cand_title" | head -1 || true)
    [ -z "$full_heading" ] && continue
    # Strip leading `### ` for skip-list comparison and reapply for resolution.
    naked_heading=$(echo "$full_heading" | sed 's/^### //')
    if [ -f "$SKIP_FILE" ] && grep -Fxq "$naked_heading" "$SKIP_FILE"; then
      continue
    fi
    CHOSEN_TITLE="$cand_title"
    RESOLVED_HEADING="$full_heading"
    break
  done < "$CANDIDATES_FILE"

  if [ -z "$RESOLVED_HEADING" ]; then
    halt "halted_at_resolve" "all /CJ_suggest candidates filtered by skip-list"
  fi
elif echo "$ARG" | grep -qE '^T[0-9]{6}$'; then
  # T-ID mode: lookup an existing tracker; if found, jump straight to dispatch.
  T_ID_ARG="$ARG"
  TRACKER_MATCH=$(find "$WORKITEMS_DIR" -name "${T_ID_ARG}_TRACKER.md" -path "*/tasks/*" 2>/dev/null | head -1)
  if [ -z "$TRACKER_MATCH" ]; then
    halt "halted_at_resolve" "T-ID $T_ID_ARG not found under $WORKITEMS_DIR/tasks/"
  fi
  EXISTING_WORK_ITEM_DIR=$(dirname "$TRACKER_MATCH")
  IDEMPOTENT_SKIP=1
  # Recover RESOLVED_HEADING from the traceability footer if present.
  FOOTER=$(grep -E '^<!-- Source: TODOS\.md ### ' "$TRACKER_MATCH" 2>/dev/null | head -1 || true)
  if [ -n "$FOOTER" ]; then
    RESOLVED_HEADING="### $(echo "$FOOTER" | sed -E 's|^<!-- Source: TODOS\.md ### (.*) -->$|\1|')"
  fi
else
  # Fragment mode: grep `^### ` headings for the fragment (case-insensitive).
  FRAGMENT="$ARG"
  ACTIVE_HEADINGS=$(parse_active_headings)
  MATCHES=$(echo "$ACTIVE_HEADINGS" | grep -iF -- "$FRAGMENT" || true)
  MATCH_COUNT=$(echo "$MATCHES" | grep -c '^### ' || true)
  if [ "$MATCH_COUNT" -eq 0 ]; then
    halt "halted_at_resolve" "no active TODO matches fragment: $FRAGMENT"
  elif [ "$MATCH_COUNT" -eq 1 ]; then
    RESOLVED_HEADING="$MATCHES"
  else
    # Multi-match: surface AUQ via stdout marker — caller harness interprets.
    # Since pure-bash can't open an AUQ, we exit with a structured prompt that
    # the wrapping skill SKILL.md harness or the user re-invokes with a more
    # specific fragment.
    echo "Error: $MATCH_COUNT TODOs match fragment '$FRAGMENT'. Re-run with a more specific fragment:" >&2
    echo "$MATCHES" | head -4 | sed 's/^/  /' >&2
    halt "halted_at_resolve" "ambiguous fragment match ($MATCH_COUNT results)"
  fi
fi

# At this point: RESOLVED_HEADING is set. Extract body unless we already have an existing tracker.
if [ "$IDEMPOTENT_SKIP" -eq 0 ]; then
  RESOLVED_BODY=$(extract_body "$RESOLVED_HEADING")
fi

# ---- Pre-flight gates ---------------------------------------------------------

# Strip leading `### ` for parsing.
NAKED_HEADING=$(echo "$RESOLVED_HEADING" | sed 's/^### //')

if [ "$IDEMPOTENT_SKIP" -eq 0 ]; then
  # Gate 1: body extraction — too vague (< 50 chars).
  BODY_LEN=$(echo -n "$RESOLVED_BODY" | wc -c | tr -d ' ')
  if [ "$BODY_LEN" -lt 50 ]; then
    halt "halted_at_preflight" "too vague (body $BODY_LEN < 50 chars)" "$NAKED_HEADING"
  fi

  # Gate 2: suffix parse `(P[1-4], [SMLX]+)`.
  PRI=""
  SIZE=""
  if echo "$NAKED_HEADING" | grep -qE '\(P[1-4], [SMLX]+\)'; then
    PRI=$(echo "$NAKED_HEADING" | sed -nE 's/.* \(P([1-4]), [SMLX]+\).*/P\1/p')
    SIZE=$(echo "$NAKED_HEADING" | sed -nE 's/.* \(P[1-4], ([SMLX]+)\).*/\1/p')
  else
    halt "halted_at_preflight" "missing priority/size suffix (Pn, X)" "$NAKED_HEADING"
  fi

  # Gate 3: priority/size cap. P1 OR size in {L, XL} → halt.
  case "$PRI" in
    P1) halt "halted_at_preflight" "too big — run /office-hours instead (P1)" "$NAKED_HEADING" ;;
  esac
  case "$SIZE" in
    L|XL) halt "halted_at_preflight" "too big — run /office-hours instead (size $SIZE)" "$NAKED_HEADING" ;;
  esac

  # Gate 4: sensitive-surface scan (body regex). On match, AUQ default = halt.
  # v1.2 (S000044, v3.6.5): added `skills/[^/]+/.+\.md` to catch markdown skill
  # definition files (SKILL.md, pipeline.md, scaffold.md, implement.md, etc.)
  # which are just as load-bearing as scripts under skills/*/scripts/. Surfaced
  # by /loop /CJ_goal_todo_fix iter 3 on 2026-05-15 — T000031 picked skill-pipeline
  # work which lives in a pipeline.md (no scripts/ subdir) and didn't trip the gate.
  SENSITIVE_MATCH=""
  if echo "$RESOLVED_BODY" | grep -qE 'skills-catalog\.json|[a-z_-]+-artifact-manifests\.json|scripts/(validate|test|test-deploy)\.sh|skills/[^/]+/scripts/|skills/[^/]+/.+\.md|\.git/hooks/|templates/CJ_personal-workflow/'; then
    SENSITIVE_MATCH=$(echo "$RESOLVED_BODY" | grep -oE 'skills-catalog\.json|[a-z_-]+-artifact-manifests\.json|scripts/(validate|test|test-deploy)\.sh|skills/[^/]+/scripts/[^[:space:]]*|skills/[^/]+/[^[:space:]]+\.md|\.git/hooks/[^[:space:]]*|templates/CJ_personal-workflow/[^[:space:]]*' | head -3 | tr '\n' ' ')
    # bash-script context: pure-stdin AUQ is unavailable. Default to halt
    # (the secure choice). If the harness wants to override, --dry-run shows
    # the surface match and the user re-runs with a sensitive-surface-aware
    # entry point (manual scaffold).
    echo "[CJ_goal_todo_fix] sensitive surface in TODO body: $SENSITIVE_MATCH" >&2
    halt "halted_at_sensitive_surface_auto_declined" "TODO touches sensitive surface(s): $SENSITIVE_MATCH — manual scaffold recommended" "$NAKED_HEADING"
  fi

  # Gate 5: design-needed keywords.
  # v1.2 (S000044, v3.6.5): added `redesign|re-?do|re-?ground|rewrite|rescope`
  # plus the literal `/office-hours` command reference to catch "this needs
  # design rework, not implementation" signals. T000031 (a "Re-do brief-mode"
  # TODO) had step (1) literally say `/office-hours from a
  # new worktree` but slipped past the original regex (only caught bare-word
  # `investigate|spike|unclear|...`). Surfaced by /loop /CJ_goal_todo_fix iter 3 on
  # 2026-05-15. NB: re-?do matches `redo|re-do` not `rename|refactor` (keeps
  # scope to genuine re-design signals).
  if echo "$RESOLVED_BODY" | grep -qiE '\b(needs design|figure out|investigate|spike|unclear|need to decide|TBD|redesign|re-?do|re-?ground|rewrite|rescope)\b|/office-hours\b'; then
    KW=$(echo "$RESOLVED_BODY" | grep -oiE '\b(needs design|figure out|investigate|spike|unclear|need to decide|TBD|redesign|re-?do|re-?ground|rewrite|rescope)\b|/office-hours\b' | head -1)
    halt "halted_at_preflight" "needs design (matched: $KW)" "$NAKED_HEADING"
  fi

  # Gate 6: idempotency check. Look for a tracker referencing this exact heading.
  # Footer shape: `<!-- Source: TODOS.md ### {NAKED_HEADING} -->`
  FOOTER_PATTERN="<!-- Source: TODOS.md ### ${NAKED_HEADING} -->"
  EXISTING_MATCH=""
  if [ -d "$WORKITEMS_DIR/tasks" ]; then
    EXISTING_MATCH=$(grep -rlF "$FOOTER_PATTERN" "$WORKITEMS_DIR/tasks/" 2>/dev/null | head -1 || true)
  fi
  if [ -n "$EXISTING_MATCH" ]; then
    EXISTING_WORK_ITEM_DIR=$(dirname "$EXISTING_MATCH")
    IDEMPOTENT_SKIP=1
  fi
fi

# ---- Scaffold T-task (skip if idempotent_skip) --------------------------------

if [ "$IDEMPOTENT_SKIP" -eq 0 ]; then
  # ID picker — verbatim copy from /CJ_scaffold-work-item Step 5.
  # DRIFT NOTE: keep in sync with skills/CJ_scaffold-work-item/scaffold.md
  # Step 5 until v1.1 extracts to scripts/cj-id-picker.sh.
  PREFIX="T"
  LOCAL_MAX=$(find work-items -name "${PREFIX}*_TRACKER.md" 2>/dev/null \
    | sed "s|.*/${PREFIX}\([0-9]*\)_.*|\1|" \
    | sort -un | tail -1)
  LOCAL_MAX=${LOCAL_MAX:-0}

  PR_MAX=0
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    for PR_NUM in $(gh pr list --state open --base main --limit 5 --json number -q '.[].number' 2>/dev/null || true); do
      while IFS= read -r CLAIMED; do
        case "$CLAIMED" in
          ''|*[!0-9]*) continue ;;
        esac
        [ "$CLAIMED" -gt "$PR_MAX" ] 2>/dev/null && PR_MAX="$CLAIMED"
      done < <(
        gh pr view "$PR_NUM" --json files -q '.files[].path' 2>/dev/null \
          | grep -oE "${PREFIX}[0-9]{6}_[^/]*_TRACKER\.md$" \
          | sed "s|^${PREFIX}\([0-9]*\)_.*|\1|"
      )
    done
  fi

  HIGHEST=$LOCAL_MAX
  [ "$PR_MAX" -gt "$HIGHEST" ] 2>/dev/null && HIGHEST=$PR_MAX
  NEW_ID=$(printf "${PREFIX}%06d" $((10#$HIGHEST + 1)))

  # Domain inference. Heuristic on body; first match wins. Silent default to ops.
  DOMAIN="ops"
  if echo "$RESOLVED_BODY" | grep -qE 'skills/CJ_|templates/CJ_personal-workflow/'; then
    DOMAIN="skills"
  elif echo "$RESOLVED_BODY" | grep -qE 'work-copilot'; then
    DOMAIN="work-copilot"
  elif echo "$RESOLVED_BODY" | grep -qE 'scripts/|setup-hooks|validate\.sh|test\.sh|test-deploy\.sh|eval\.sh'; then
    DOMAIN="ops"
  fi

  # Slug generation. Lowercase; strip `(P[1-4], [SMLX]+)` suffix; non-alnum → _;
  # collapse __; trim _; ≤40 chars at word-boundary; hard truncate if needed.
  SLUG=$(echo "$NAKED_HEADING" \
    | sed -E 's/\(P[1-4], [SMLX]+\)//' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/_/g' \
    | sed -E 's/_+/_/g' \
    | sed -E 's/^_+|_+$//g')
  if [ "${#SLUG}" -gt 40 ]; then
    # Word-boundary truncate at last `_` ≤ 40.
    TRUNCATED=$(echo "$SLUG" | cut -c1-40 | sed -E 's/_[^_]*$//')
    if [ -z "$TRUNCATED" ] || [ "${#TRUNCATED}" -lt 1 ]; then
      SLUG=$(echo "$SLUG" | cut -c1-40)
    else
      SLUG="$TRUNCATED"
    fi
  fi

  WORK_ITEM_DIR="work-items/tasks/${DOMAIN}/${NEW_ID}_${SLUG}"

  # Dry-run output and exit before any writes.
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN — no writes will happen."
    echo ""
    echo "Resolved TODO:    $RESOLVED_HEADING"
    echo "Priority/Size:    $PRI / $SIZE"
    echo "Domain:           $DOMAIN"
    echo "Slug:             $SLUG"
    echo "Planned T-ID:     $NEW_ID"
    echo "Planned dir:      $WORK_ITEM_DIR"
    echo "Body length:      $BODY_LEN chars"
    echo "Dispatch chain:   /CJ_implement-from-spec <dir> → /CJ_qa-work-item <dir>"
    echo "                  → /ship → /land-and-deploy --suppress-readiness-gate"
    write_telemetry "dry_run" "$NAKED_HEADING" "$NEW_ID"
    exit 0
  fi

  # Defensive mkdir -p. work-items/tasks/{ops,skills,work-copilot}/ should exist
  # but harmless to ensure it.
  mkdir -p "$WORK_ITEM_DIR"

  # Resolve template paths. Prefer workbench source over deployed.
  TPL_TRACKER=""
  TPL_TEST_PLAN=""
  for p in \
    "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" \
    "$HOME/.claude/templates/CJ_personal-workflow/tracker-task.md"; do
    if [ -f "$p" ]; then TPL_TRACKER="$p"; break; fi
  done
  for p in \
    "$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md" \
    "$HOME/.claude/templates/CJ_personal-workflow/doc-test-plan.md"; do
    if [ -f "$p" ]; then TPL_TEST_PLAN="$p"; break; fi
  done
  [ -z "$TPL_TRACKER" ] && halt "halted_at_scaffold" "tracker-task.md template not found" "$NAKED_HEADING" "$NEW_ID"
  [ -z "$TPL_TEST_PLAN" ] && halt "halted_at_scaffold" "doc-test-plan.md template not found" "$NAKED_HEADING" "$NEW_ID"

  # Substitution variables.
  TODAY=$(date +%Y-%m-%d)
  AUTHOR=$(git config user.name 2>/dev/null || echo "chjiang")
  BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
  # Tracker template's `{slug}` literal appears inside `git checkout -b feat/{slug}`.
  # Substitute it with our generated SLUG to keep the branch name useful.

  # Write TRACKER.md.
  TRACKER_OUT="$WORK_ITEM_DIR/${NEW_ID}_TRACKER.md"
  sed \
    -e "s|{TASK_NAME}|${NAKED_HEADING//|/\\|}|g" \
    -e "s|{TASK_ID}|${NEW_ID}|g" \
    -e "s|{YYYY-MM-DD}|${TODAY}|g" \
    -e "s|{PARENT_ID}||g" \
    -e "s|{REPO_PATH}|${REPO_ROOT//|/\\|}|g" \
    -e "s|{BRANCH_NAME}|${BRANCH//|/\\|}|g" \
    -e "s|{slug}|${SLUG}|g" \
    "$TPL_TRACKER" > "$TRACKER_OUT"

  # Inject the TODO body into the ## Insights section. Also append the
  # traceability footer at end of file.
  # We rewrite the file in one awk pass: when we hit `## Insights`, print it
  # plus the body content; otherwise pass through unchanged. Then append the
  # footer with `cat >>`.
  #
  # T000028: surgical awk newline fix. awk -v body=...  does not tolerate embedded
  # newlines in the value — it emits `awk: newline in string` and truncates the
  # body. We write the body to a tmpfile and stream it via getline instead of
  # interpolating it into the awk source via -v. RESOLVED_BODY is NOT mutated
  # (it is used in 2 other places: FIRST_SENTENCE derivation at ~line 485 and
  # the sensitive-surface scan at ~line 289-290 — a global sanitize would silently
  # change which TODOs trip Gate 4).
  TRACKER_TMP=$(mktemp)
  BODY_TMP=$(mktemp)
  printf '%s' "$RESOLVED_BODY" > "$BODY_TMP"
  awk -v body_file="$BODY_TMP" '
    /^## Insights[[:space:]]*$/ {
      print $0
      print ""
      print "<!-- Auto-injected from TODOS.md body by /CJ_goal_todo_fix -->"
      print ""
      while ((getline line < body_file) > 0) print line
      close(body_file)
      print ""
      injected = 1
      next
    }
    { print }
  ' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"
  rm -f "$BODY_TMP"
  printf '\n<!-- Source: TODOS.md ### %s -->\n' "$NAKED_HEADING" >> "$TRACKER_OUT"

  # Initial Todos placeholder → a concrete starter row. The template ships with
  # `- [ ] {todo}` which would trip Step 5 placeholder checks downstream. Replace
  # with a single real row derived from the TODO heading.
  TRACKER_TMP=$(mktemp)
  awk -v h="$NAKED_HEADING" '
    /^- \[ \] \{todo\}$/ { print "- [ ] Implement: " h; next }
    { print }
  ' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"

  # Update Log placeholder line.
  TRACKER_TMP=$(mktemp)
  awk -v t="$TODAY" -v h="$NAKED_HEADING" '
    /^- \{YYYY-MM-DD\}: Created\./ { print "- " t ": Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### " h; next }
    /^- [0-9]{4}-[0-9]{2}-[0-9]{2}: Created\. \{brief scope from parent work item\}$/ { print "- " t ": Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### " h; next }
    { print }
  ' "$TRACKER_OUT" > "$TRACKER_TMP" && mv "$TRACKER_TMP" "$TRACKER_OUT"

  # Populate Files section with a single placeholder pointing at the body.
  # /CJ_implement-from-spec's Phase 1 will refine it.
  # (Already template-default: empty.)

  # Write test-plan.md. Template ships with two placeholder rows containing
  # `{...}`. Theme C resolution requires REAL test cases or refuse-to-scaffold.
  # We extract the strongest sentence from the TODO body as the Steps column
  # and frame the Expected Result around it; the test-plan row is a real
  # manual-verification case tied to the TODO body, not a placeholder.
  TEST_PLAN_OUT="$WORK_ITEM_DIR/test-plan.md"
  # First-sentence extraction: up to first `.` or `?` or `\n\n` boundary.
  FIRST_SENTENCE=$(echo "$RESOLVED_BODY" | awk 'BEGIN{RS=""} {gsub(/\n+/," "); print; exit}' | sed -E 's/^[[:space:]]+//' | cut -c1-200)
  [ -z "$FIRST_SENTENCE" ] && FIRST_SENTENCE="Apply the change described in the TODO body and verify behavior matches the heading."

  sed \
    -e "s|{ITEM_ID}|${NEW_ID}|g" \
    -e "s|{ITEM_NAME}|${NAKED_HEADING//|/\\|}|g" \
    -e "s|{YYYY-MM-DD}|${TODAY}|g" \
    -e "s|{author}|${AUTHOR//|/\\|}|g" \
    "$TPL_TEST_PLAN" > "$TEST_PLAN_OUT"

  # Replace the placeholder Regression Test Cases rows with one real row.
  # Then strip the `{author}`-section's `{OS + config}` row's placeholders to
  # avoid Step 5 input-gap halts in /CJ_implement-from-spec. We keep the
  # Environments table structurally present with `n/a` values — real values
  # land during Phase 2.
  TEST_TMP=$(mktemp)
  awk -v fs="${FIRST_SENTENCE//|/\\|}" -v h="${NAKED_HEADING//|/\\|}" '
    BEGIN { case_done = 0 }
    /^\| 1 \| \{original bug scenario\}/ {
      print "| 1 | Manual verification: " h " | " fs " | Behavior matches the TODO body and the heading description | Pending |"
      case_done = 1
      next
    }
    /^\| 2 \| \{related scenario\}/ {
      # Drop the placeholder row 2; /CJ_implement-from-spec adds real rows.
      next
    }
    /^\| \{OS \+ config\} \|/ {
      print "| local macOS | main / current branch | Pending |"
      next
    }
    /^- \[ \] \{additional verification specific to this fix\}$/ {
      # Drop the placeholder verification line.
      next
    }
    { print }
  ' "$TEST_PLAN_OUT" > "$TEST_TMP" && mv "$TEST_TMP" "$TEST_PLAN_OUT"

  # Post-scaffold boundary check is handled downstream by the dispatched leaf
  # phase skills (/CJ_implement-from-spec + /CJ_qa-work-item each run the
  # portable `/CJ_personal-workflow check` at their start/end boundaries — works
  # in any repo). See T000028 / Approach D — the original validate.sh call here
  # was workbench-coupled (exit 127 in downstream repos) and duplicated work the
  # phase skills' boundary checks already do.
fi

# At this point either $WORK_ITEM_DIR (new scaffold) or $EXISTING_WORK_ITEM_DIR
# (idempotent path) is set. Canonicalize.
if [ -n "$EXISTING_WORK_ITEM_DIR" ]; then
  WORK_ITEM_DIR="$EXISTING_WORK_ITEM_DIR"
  # Recover NEW_ID + NAKED_HEADING from the existing dir if not already set.
  if [ -z "${NEW_ID:-}" ]; then
    EXISTING_TRACKER=$(find "$WORK_ITEM_DIR" -maxdepth 1 -name "T*_TRACKER.md" 2>/dev/null | head -1)
    if [ -n "$EXISTING_TRACKER" ]; then
      NEW_ID=$(basename "$EXISTING_TRACKER" | sed 's/_TRACKER\.md$//')
    fi
  fi
fi

# ---- Dispatch chain -----------------------------------------------------------

# The actual dispatch must reach /CJ_implement-from-spec + /CJ_qa-work-item +
# /ship + /land-and-deploy. From inside a bash subshell launched by SKILL.md
# routing, we cannot synchronously invoke /skill commands. Instead,
# /CJ_goal_todo_fix prints a structured handoff block and exits with a marker
# end_state. The wrapping Claude agent (which loaded /CJ_goal_todo_fix via the
# Skill tool) reads stdout, parses the handoff block, dispatches the two leaf
# phase subagents (impl→qa, halt-on-red between — see pipeline.md Step 4), then
# runs /ship + /land-and-deploy.
#
# This is the same flatten /CJ_goal_feature Steps 3.2-3.3 use — the
# orchestration lives at the agent layer, the script emits the directive.
#
# Handoff block contract:
#   CJ_GOAL_HANDOFF_BEGIN
#   WORK_ITEM_DIR=<path>
#   T_ID=<id>
#   HEADING=<heading>
#   IDEMPOTENT_SKIP=<0|1>
#   PRE_HASH=<sha256>
#   CJ_GOAL_HANDOFF_END

echo "CJ_GOAL_HANDOFF_BEGIN"
echo "WORK_ITEM_DIR=$WORK_ITEM_DIR"
echo "T_ID=${NEW_ID:-unknown}"
echo "HEADING=${NAKED_HEADING:-unknown}"
echo "IDEMPOTENT_SKIP=$IDEMPOTENT_SKIP"
echo "PRE_HASH=$PRE_HASH"
echo "DISPATCH_CHAIN=/CJ_implement-from-spec $WORK_ITEM_DIR  (Agent subagent, halt-on-red → halted_at_impl)"
echo "                /CJ_qa-work-item $WORK_ITEM_DIR  (Agent subagent, halt-on-red → halted_at_qa)"
echo "                /ship"
echo "                /land-and-deploy --suppress-readiness-gate #<PR_NUM>"
echo "POST_SUCCESS_TODOS_MD_HEADING=$NAKED_HEADING"
echo "CJ_GOAL_HANDOFF_END"

# Telemetry for the handoff: end_state=handoff_pending. The agent that
# dispatches the chain writes a follow-up telemetry line when the chain
# reaches its terminal state.
write_telemetry "handoff_pending" "${NAKED_HEADING:-}" "${NEW_ID:-}"

exit 0
