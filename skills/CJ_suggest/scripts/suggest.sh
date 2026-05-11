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
if grep -q '^## Active work[[:space:]]*$' "$TODOS"; then
  ACTIVE_HEADINGS=$(awk '
    /^## Active work[[:space:]]*$/ {a=1; next}
    /^## / && !/^## Active work[[:space:]]*$/ {a=0}
    a && /^### [^~]/ { print }
  ' "$TODOS")
else
  ACTIVE_HEADINGS=$(awk '
    /^## (Completed|Done|Archive|Archived|Shipped|Deferred work)[[:space:]]*$/ {a=0; next}
    /^## / {a=1}
    a && /^### [^~]/ { print }
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

  printf '%d\t%s\t%s\t%s\t%s\t%s\n' "$score" "$title" "$pri" "$size" "$status" "$why_parts" >> "$SCORED"
done <<< "$ACTIVE_HEADINGS"

if [ ! -s "$SCORED" ]; then
  echo "No actionable items."
  exit 0
fi

# ---- Step 6: Sort desc by score, tiebreak ascending alphabetic by title.
# Take top 5. Render as markdown table.
#
# `|| true` guards against SIGPIPE/EPIPE on `sort | head` under
# `set -euo pipefail`: when `head` exits after 5 lines, sort can take SIGPIPE
# and exit non-zero on a closed pipe, aborting the script. For today's data
# sizes (10-50 active items) sort buffers all output and the pipe never
# closes mid-write, so this is forward-compat. (codex adversarial review on
# D000017 PR #TBD.)
TOP5=$(sort -t$'\t' -k1,1nr -k2,2 "$SCORED" | head -n 5 || true)

echo "| Rank | Title | Pri | Size | Status | Why |"
echo "|------|-------|-----|------|--------|-----|"
rank=1
while IFS=$'\t' read -r score title pri size status why; do
  [ -z "$title" ] && continue
  # Escape `|` in the title cell to keep markdown table valid.
  # Status/why columns are built from constrained inputs (YAML enum + numeric)
  # that can't contain `|` today, so no escape needed there.
  esc_title=$(echo "$title" | sed 's/|/\\|/g')
  echo "| $rank | $esc_title | $pri | $size | $status | $why |"
  rank=$((rank + 1))
done <<< "$TOP5"
