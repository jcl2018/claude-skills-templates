#!/usr/bin/env bash
set -euo pipefail

# ---- Platform check: BSD `date -j` only (this-repo / macOS targeted in v1).
# On Linux, `date -j` fails, swallowed by 2>/dev/null, age_days collapses to 0,
# recency penalty silently disabled, ranking wrong. Fail loud instead.
if [ "$(uname -s)" != "Darwin" ]; then
  echo "Error: /suggest requires macOS (uses BSD \`date -j -f\`). Linux/GNU date -d not supported in v1." >&2
  exit 1
fi

# ---- Repo-root detection. Don't silently fall through to pwd — that masks
# "not in a git repo" with a confusing TODOS.md-not-found error downstream.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: /suggest must be run inside a git repo (git rev-parse --show-toplevel failed)." >&2
  exit 1
}
cd "$REPO_ROOT"

TODOS="TODOS.md"
WORKITEMS_DIR="work-items"

# ---- Argument parsing (S000042: --for-skill / --limit) ----------------------
#
# `--for-skill <name>` activates a named-skill predicate block applied at
# ranking time to exclude rows that the named skill would pre-reject. Today
# the only supported name is `cj-goal`; future consumers add named blocks.
# Predicates mirror /CJ_goal_todo_fix preflight gates 3-5 in todo_fix.sh:262-303 (gate 1's
# body-too-vague is excluded — vagueness is a body-content judgement that
# /CJ_suggest applies generically via the recency penalty; gate 2's missing
# (Pn,X) suffix is already handled by suggest.sh's default-P4/M fallback).
#
# `--limit N` extends the top-N output cap beyond the default 5. Default 5
# preserves byte-identical output for un-flagged callers (interactive
# /suggest users); /CJ_goal_todo_fix opts in explicitly via `--limit 15`.
#
# Bash 3.2 compat: no associative arrays in this block; positional flags
# parsed via case statement with explicit shift.
FOR_SKILL=""
LIMIT=5
while [ $# -gt 0 ]; do
  case "$1" in
    --for-skill)
      if [ $# -lt 2 ]; then
        echo "Error: --for-skill requires a value (e.g. --for-skill cj-goal)" >&2
        exit 1
      fi
      FOR_SKILL="$2"
      shift 2
      ;;
    --limit)
      if [ $# -lt 2 ]; then
        echo "Error: --limit requires a numeric value (e.g. --limit 15)" >&2
        exit 1
      fi
      case "$2" in
        ''|*[!0-9]*)
          echo "Error: --limit value must be a positive integer (got: $2)" >&2
          exit 1
          ;;
      esac
      LIMIT="$2"
      shift 2
      ;;
    *)
      echo "Error: unrecognized argument: $1" >&2
      echo "Usage: /CJ_suggest [--for-skill <name>] [--limit N]" >&2
      exit 1
      ;;
  esac
done

# Validate --for-skill value (only cj-goal is implemented in v1).
if [ -n "$FOR_SKILL" ] && [ "$FOR_SKILL" != "cj-goal" ]; then
  echo "Error: --for-skill value '$FOR_SKILL' not supported (v1 supports: cj-goal)" >&2
  exit 1
fi

# extract_body: pull the body for a `### heading` from TODOS.md — all lines
# after this heading up to the next `### `, the next `## `, or EOF. Mirrors
# /CJ_goal_todo_fix todo_fix.sh:152-160 (single source of truth lives there; this is the
# body-content twin needed by --for-skill cj-goal predicates 4-5).
# Tolerates missing TODOS.md (caller already errored) and empty heading.
extract_body() {
  local heading_line="$1"
  [ -z "$heading_line" ] && return 0
  awk -v heading="$heading_line" '
    $0 == heading { capture = 1; next }
    capture && /^### / { exit }
    capture && /^## / { exit }
    capture { print }
  ' "$TODOS"
}

# ---- Edge case: missing TODOS.md ----
if [ ! -f "$TODOS" ]; then
  echo "Error: $TODOS not found in $REPO_ROOT. /suggest requires a TODOS.md at the repo root." >&2
  exit 1
fi

TODAY_EPOCH=$(date +%s)

# ---- Step 2: Walk all TRACKER.md files; index id -> {status,blocked_by,updated,name,type}.
# YAML parser: awk extracts key:value lines inside the frontmatter block;
# sed splits on first ": " and strips double-quotes.
#
# FRAGILITY NOTE: this strips all double-quotes and splits on first ": ", so
# a value containing ": " (e.g. `description: "Fix: foo"`) will be truncated.
# The current `name:` field on several trackers contains ": " — but `/suggest`
# only consumes id/status/blocked_by/updated/type (none of which currently
# contain ": "), so the parser is safe in practice. If a consumed field ever
# starts to contain ": ", migrate to yq (premise #6 violation acceptable for
# correctness). Pre-ship sanity check (test 15) — match a key followed by a
# value that itself contains ": " (the actual fragility surface):
#   find work-items -name '*_TRACKER.md' \
#     -exec awk '/^---$/{f=!f;next} f && /^[a-z_]+:.*: /' {} +
# Output is non-empty today (the `name:` field), but no consumed field is
# affected.

TRACKER_INDEX=$(mktemp)
trap 'rm -f "$TRACKER_INDEX"' EXIT

if [ -d "$WORKITEMS_DIR" ]; then
  while IFS= read -r tracker; do
    [ -z "$tracker" ] && continue
    # Parse frontmatter into key=value lines (single-line scalars only).
    fm=$(awk '/^---$/{f=!f; next} f && /^[a-z_]+:/' "$tracker" \
         | sed 's/: */=/' | sed 's/"//g')
    id=$(echo "$fm"     | awk -F= '$1=="id"     {print $2; exit}')
    status=$(echo "$fm" | awk -F= '$1=="status" {print $2; exit}')
    blocked=$(echo "$fm"| awk -F= '$1=="blocked_by" {print $2; exit}')
    updated=$(echo "$fm"| awk -F= '$1=="updated"{print $2; exit}')
    type=$(echo "$fm"   | awk -F= '$1=="type"   {print $2; exit}')
    # Skip trackers without an id (defensive — every well-formed tracker has one).
    [ -z "$id" ] && continue
    # Tab-separated record: id<TAB>status<TAB>blocked<TAB>updated<TAB>type
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$status" "$blocked" "$updated" "$type" >> "$TRACKER_INDEX"
    # Skip hidden subdirs (defensive — find -not -path bound below skips them upstream).
  done < <(find "$WORKITEMS_DIR" -type f -name '*_TRACKER.md' -not -path '*/.*' 2>/dev/null)
fi

NO_TRACKERS=0
[ ! -s "$TRACKER_INDEX" ] && NO_TRACKERS=1

# ---- Step 1: Band-pass TODOS.md to the active section, extract heading rows.
# Active section = lines after `## Active work` and before `## Deferred work`.
# Heading regex: `^### {title} (P{1-4}, {S|M|L})` with NO leading `~~`
# (strikethrough = DONE/RETIRED).

# Two TODOS.md conventions are supported:
#
# 1. CJ_personal-workflow shape — single `## Active work` section gates the
#    candidate set. Bound the active band on EITHER `## Deferred work` OR any
#    other top-level `## ` heading. Without the second clause, inserting
#    `## Triage` between Active and Deferred would leak that section's `###`
#    rows into the candidate set (adversarial review CRITICAL #2).
#
# 2. Domain-grouped shape (e.g. portfolio repo) — work items live under
#    domain-specific `## ` sections (`## Dispatcher`, `## Alert Rules`, ...)
#    with no `## Active work` gate. Fall back to scanning all `### ` headings
#    except those under terminal/completed buckets. Items without the
#    `(Pn, X)` suffix already default to P4/M downstream (premise #3), so
#    portable TODOs rank by recency/blocked-status alone.
#
# Detection: presence of `## Active work` switches modes.
#
# S000049: skip headings containing `<!--impr-draft-->` (rows emitted by
# /CJ_improve-queue in draft state — invisible-marker convention so promotion
# is a single search-and-replace, no string-prefix typo footgun). Mirrors the
# strikethrough skip already in place.
if grep -q '^## Active work[[:space:]]*$' "$TODOS"; then
  ACTIVE_HEADINGS=$(awk '
    /^## Active work[[:space:]]*$/ {a=1; next}
    /^## / && !/^## Active work[[:space:]]*$/ {a=0}
    a && /^### [^~]/ && !/<!--impr-draft-->/ { print }
  ' "$TODOS")
else
  ACTIVE_HEADINGS=$(awk '
    /^## (Completed|Done|Archive|Archived|Shipped|Deferred work)[[:space:]]*$/ {a=0; next}
    /^## / {a=1}
    a && /^### [^~]/ && !/<!--impr-draft-->/ { print }
  ' "$TODOS")
fi

if [ -z "$ACTIVE_HEADINGS" ]; then
  echo "No actionable items."
  exit 0
fi

# ---- Steps 3-5: Parse each heading, join on tracker, score.
# Output rows as TAB-separated:
#   score<TAB>title<TAB>pri<TAB>size<TAB>status<TAB>why
#
# Heading regex (sed BRE): `^### (.*) \(P([1-4]), ([SML])\)$`
# Default pri=P4, size=M for headings missing the suffix (premise #3).

SCORED=$(mktemp)
trap 'rm -f "$TRACKER_INDEX" "$SCORED"' EXIT

while IFS= read -r heading; do
  [ -z "$heading" ] && continue

  # Strip the leading `### `.
  # NOTE: `${heading#### }` does NOT work — bash parses the leading `##` as
  # the greedy-prefix operator (matching empty), then leaves `## ` literal.
  # Use sed for clarity.
  raw=$(echo "$heading" | sed 's/^### //')

  # Extract title + (Pn, X) suffix as three separate sed captures.
  # Using a single sed with `|` delimiter would corrupt on titles containing
  # `|` (adversarial review CRITICAL #1). Three separate captures is safe.
  title=$(echo "$raw" | sed -nE 's/^(.*) \(P[1-4], [SML]\).*$/\1/p')
  if [ -n "$title" ]; then
    pri=$(echo "$raw" | sed -nE 's/^.* \(P([1-4]), [SML]\).*$/P\1/p')
    size=$(echo "$raw" | sed -nE 's/^.* \(P[1-4], ([SML])\).*$/\1/p')
    has_suffix=1
  else
    # No (Pn, X) suffix — strip any trailing tag like " DONE" / " RETIRED".
    title=$(echo "$raw" | sed -E 's/[[:space:]]+(DONE|RETIRED|PARTIAL.*)$//')
    pri="P4"
    size="M"
    has_suffix=0
  fi

  # Trim trailing whitespace from title.
  title=$(echo "$title" | sed -E 's/[[:space:]]+$//')

  # Extract the FIRST `[FSTD][0-9]{6}` ID token from the heading line ONLY.
  # macOS grep supports -E; -m 1 = first match.
  # `|| true` swallows grep's exit-1-on-no-match so `set -o pipefail` doesn't
  # abort here when a heading has no ID token (orphan rows are valid).
  id=$(echo "$raw" | grep -oE '\b[FSTD][0-9]{6}\b' | head -n1 || true)

  # Join on tracker index (if any).
  status="(orphan)"
  blocked=""
  updated=""
  is_orphan=1
  if [ -n "$id" ] && [ -s "$TRACKER_INDEX" ]; then
    row=$(awk -F'\t' -v id="$id" '$1==id {print; exit}' "$TRACKER_INDEX")
    if [ -n "$row" ]; then
      status=$(echo "$row" | awk -F'\t' '{print $2}')
      blocked=$(echo "$row" | awk -F'\t' '{print $3}')
      updated=$(echo "$row" | awk -F'\t' '{print $4}')
      is_orphan=0
      [ -z "$status" ] && status="(unknown)"
    fi
  fi

  # ---- Step 4: age_days from `updated` (macOS-compatible date math).
  age_days=0
  if [ "$is_orphan" -eq 0 ] && [ -n "$updated" ]; then
    upd_epoch=$(date -j -f "%Y-%m-%d" "$updated" +%s 2>/dev/null || echo "")
    if [ -n "$upd_epoch" ]; then
      age_days=$(( (TODAY_EPOCH - upd_epoch) / 86400 ))
      [ "$age_days" -lt 0 ] && age_days=0
    fi
  fi

  # ---- Step 5: Score.
  case "$pri" in
    P1) pri_w=4 ;;
    P2) pri_w=3 ;;
    P3) pri_w=2 ;;
    P4) pri_w=1 ;;
    *)  pri_w=1 ;;
  esac
  case "$size" in
    S) size_w=3 ;;
    M) size_w=2 ;;
    L) size_w=1 ;;
    *) size_w=2 ;;
  esac

  # Unblocked: +2 if no tracker join OR blocked_by empty.
  if [ "$is_orphan" -eq 1 ] || [ -z "$blocked" ]; then
    unblocked=2
  else
    unblocked=0
  fi

  # Recency penalty: age_days / 14 (integer division). 0 if no tracker.
  if [ "$is_orphan" -eq 1 ] || [ "$NO_TRACKERS" -eq 1 ]; then
    recency=0
  else
    recency=$(( age_days / 14 ))
  fi

  score=$(( pri_w + size_w + unblocked - recency ))

  # ---- Build "why" column.
  # Per design D5 + test-plan #6: orphan rows MUST contain "(orphan)" in Why.
  # Other parts describe score contributors (unblocked, blocked, stale,
  # default-suffix).
  why_parts=""
  if [ "$is_orphan" -eq 1 ]; then
    why_parts="(orphan)"
  fi
  if [ "$unblocked" -eq 2 ] && [ "$is_orphan" -eq 0 ]; then
    why_parts="${why_parts:+$why_parts, }unblocked"
  fi
  if [ "$is_orphan" -eq 0 ] && [ -n "$blocked" ]; then
    why_parts="${why_parts:+$why_parts, }blocked by $blocked"
  fi
  if [ "$recency" -gt 0 ]; then
    why_parts="${why_parts:+$why_parts, }stale ${age_days}d"
  fi
  if [ "$has_suffix" -eq 0 ]; then
    why_parts="${why_parts:+$why_parts, }default P4/M"
  fi
  if [ -z "$why_parts" ]; then
    why_parts="-"
  fi

  # Extra column 7: the raw heading line — needed downstream by --for-skill
  # predicate body lookup (extract_body). Persisted only when --for-skill is
  # active; otherwise an empty column (still output for schema stability).
  printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\n' "$score" "$title" "$pri" "$size" "$status" "$why_parts" "$heading" >> "$SCORED"
done <<< "$ACTIVE_HEADINGS"

if [ ! -s "$SCORED" ]; then
  echo "No actionable items."
  exit 0
fi

# ---- Step 5.5: Apply --for-skill predicate block (S000042) ------------------
#
# When --for-skill is active, filter $SCORED to exclude rows that the named
# skill would pre-reject. For cj-goal this mirrors todo_fix.sh:262-303 gates 3-5
# plus heading-level pre-rejects that drain mode halts on at preflight:
#   - Gate 3a: priority is P1                              → exclude
#   - Gate 3b: size is L or XL                             → exclude
#   - Gate 3c: parent ## H2 is a date-trigger section
#              (matches `scheduled|checkpoint`, case-insensitive) → exclude
#   - Gate 3d: heading title begins with `YYYY-MM-DD —`    → exclude
#   - Gate 3e: heading title contains terminal-marker
#              (WON'T FIX / SUPERSEDED / SHIPPED / RESOLVED)  → exclude
#   - Gate 4:  body matches sensitive-surface regex        → exclude
#   - Gate 5:  body matches design-needed keyword          → exclude
# Gates 3c-3e are heading-level (cheap) and fire before body extraction.
#
# Per-row exclusion log line: `[CJ_suggest] excluded: <heading-or-id> reason=<criterion>`
# emitted to stderr (P1 observability requirement). Heading-or-id is the
# extracted T-ID when present, else the title.
#
# Sensitive-surface regex is copied VERBATIM from todo_fix.sh:289 (drift between
# the two would defeat the purpose). When the regex needs to evolve, edit
# both call sites in the same PR — D000017's lessons apply.
if [ -n "$FOR_SKILL" ]; then
  FILTERED=$(mktemp)
  trap 'rm -f "$TRACKER_INDEX" "$SCORED" "$FILTERED"' EXIT
  while IFS=$'\t' read -r f_score f_title f_pri f_size f_status f_why f_heading; do
    [ -z "$f_title" ] && continue
    reason=""
    # Gate 3a: P1 priority
    if [ "$f_pri" = "P1" ]; then
      reason="P1"
    fi
    # Gate 3b: size L or XL (suggest.sh's size parser only emits S|M|L today;
    # XL is documented as future-compat — todo_fix.sh accepts L|XL).
    if [ -z "$reason" ]; then
      case "$f_size" in
        L|XL) reason="size $f_size" ;;
      esac
    fi
    # Gate 3c: heading lives under a date-trigger H2 section (e.g.
    # `## Scheduled checkpoints`). These rows are calendar-anchored
    # follow-ups, not drainable next-ups; /CJ_goal_todo_fix would halt at
    # preflight. Cheap awk pass — find nearest preceding `## ` for $f_heading.
    # Match H2 lines whose text contains `Scheduled` or `Checkpoint`
    # (case-insensitive); intentionally narrow to avoid over-filtering
    # legitimate active sections.
    if [ -z "$reason" ]; then
      parent_h2=$(awk -v h="$f_heading" '
        /^## / { current = $0 }
        $0 == h { print current; exit }
      ' "$TODOS")
      if echo "$parent_h2" | grep -qiE 'scheduled|checkpoint'; then
        reason="date-trigger section ($(echo "$parent_h2" | sed 's/^## //'))"
      fi
    fi
    # Gate 3d: heading text begins with a `YYYY-MM-DD —` date prefix.
    # These are explicit future-trigger rows (e.g. `2026-06-13 — D000002
    # day-30 re-evaluation`) that the drain helper rejects at preflight.
    # Em-dash, en-dash, and hyphen all accepted as the separator.
    if [ -z "$reason" ]; then
      if echo "$f_title" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+(—|–|-)[[:space:]]'; then
        reason="date-trigger prefix"
      fi
    fi
    # Gate 3e: heading contains a terminal-marker literal (WON'T FIX /
    # SUPERSEDED / SHIPPED / RESOLVED). The strikethrough convention
    # (`~~...~~`) is the canonical "done" signal already filtered at heading
    # extraction (line 171 / line 177), but un-strikethrough'd rows that
    # carry a terminal literal in the title are hygiene debt that would
    # otherwise burn a /CJ_goal_todo_fix iteration. Case-sensitive on the
    # literal (these are conventionally uppercase in TODOS.md).
    if [ -z "$reason" ]; then
      if echo "$f_title" | grep -qE "WON'T FIX|SUPERSEDED|SHIPPED|RESOLVED"; then
        matched=$(echo "$f_title" | grep -oE "WON'T FIX|SUPERSEDED|SHIPPED|RESOLVED" | head -1)
        reason="terminal-marker ($matched)"
      fi
    fi
    # Gate 4 + Gate 5 require the body. Only call extract_body if no faster
    # gate already excluded the row.
    if [ -z "$reason" ]; then
      body=$(extract_body "$f_heading")
      if [ -n "$body" ]; then
        # Gate 4: sensitive-surface regex (VERBATIM from todo_fix.sh:289).
        if echo "$body" | grep -qE 'skills-catalog\.json|[a-z_-]+-artifact-manifests\.json|scripts/(validate|test|test-deploy)\.sh|skills/[^/]+/scripts/|\.git/hooks/|templates/CJ_personal-workflow/'; then
          sm=$(echo "$body" | grep -oE 'skills-catalog\.json|[a-z_-]+-artifact-manifests\.json|scripts/(validate|test|test-deploy)\.sh|skills/[^/]+/scripts/[^[:space:]]*|\.git/hooks/[^[:space:]]*|templates/CJ_personal-workflow/[^[:space:]]*' | head -1)
          reason="sensitive-surface ($sm)"
        fi
      fi
    fi
    if [ -z "$reason" ]; then
      if [ -n "$body" ] && echo "$body" | grep -qiE '\b(needs design|figure out|investigate|spike|unclear|need to decide|TBD)\b'; then
        kw=$(echo "$body" | grep -oiE '\b(needs design|figure out|investigate|spike|unclear|need to decide|TBD)\b' | head -1)
        reason="design-needed ($kw)"
      fi
    fi

    if [ -n "$reason" ]; then
      # Recover T-ID-or-title for the log line. Heading shape: `### Title (Pn, X)`
      # may contain a T-ID anywhere in the title; grep extracts the first match.
      log_label=$(echo "$f_heading" | grep -oE '\b[FSTD][0-9]{6}\b' | head -n1 || true)
      [ -z "$log_label" ] && log_label="$f_title"
      echo "[CJ_suggest] excluded: $log_label reason=$reason" >&2
      continue
    fi
    # Row passes all predicates — keep it.
    printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\n' "$f_score" "$f_title" "$f_pri" "$f_size" "$f_status" "$f_why" "$f_heading" >> "$FILTERED"
  done < "$SCORED"
  # Swap SCORED to point at the filtered file for downstream consumption.
  SCORED="$FILTERED"
fi

if [ ! -s "$SCORED" ]; then
  echo "No actionable items."
  exit 0
fi

# ---- Step 6: Sort desc by score, tiebreak ascending alphabetic by title.
# Take top $LIMIT (default 5). Render as markdown table.
#
# `|| true` guards against SIGPIPE/EPIPE on `sort | head` under
# `set -euo pipefail`: when `head` exits after N lines, sort can take SIGPIPE
# and exit non-zero on a closed pipe, aborting the script. For today's data
# sizes (10-50 active items) sort buffers all output and the pipe never
# closes mid-write, so this is forward-compat. (codex adversarial review on
# D000017 PR #TBD.)
TOP5=$(sort -t$'\t' -k1,1nr -k2,2 "$SCORED" | head -n "$LIMIT" || true)

echo "| Rank | Title | Pri | Size | Status | Why |"
echo "|------|-------|-----|------|--------|-----|"
rank=1
# 7th column (raw heading) is the S000042 addition — read into _heading and
# discard. Without an explicit 7th read variable, `set -r` would glue it onto
# the last variable ($why), corrupting the rendered Why column.
while IFS=$'\t' read -r score title pri size status why _heading; do
  [ -z "$title" ] && continue
  # Escape `|` in the title cell to keep markdown table valid.
  # Status/why columns are built from constrained inputs (YAML enum + numeric)
  # that can't contain `|` today, so no escape needed there.
  esc_title=$(echo "$title" | sed 's/|/\\|/g')
  echo "| $rank | $esc_title | $pri | $size | $status | $why |"
  rank=$((rank + 1))
done <<< "$TOP5"
