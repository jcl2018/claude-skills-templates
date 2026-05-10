---
name: CJ_suggest
description: "Print a ranked top-5 of next-up work items from TODOS.md and tracker frontmatter."
version: 1.0.0
allowed-tools:
  - Bash
  - Read
---

## Overview

`/suggest` reads this repo's `TODOS.md` (the candidate set) and joins it
against `work-items/**/*_TRACKER.md` YAML frontmatter (the live `status`,
`blocked_by`, `updated` per work item), scores each row, and prints the
top 5 as a markdown table.

Read-only. Stateless. This-repo only (tied to the CJ_personal-workflow tracker
shape and TODOS.md `(Pn, X)` heading convention).

Scoring (locked in design premise #2):

```
score = pri_w + size_w + unblocked - recency_penalty
  pri_w        = P1=4, P2=3, P3=2, P4=1   (default 1)
  size_w       = S=3,  M=2,  L=1          (default 2)
  unblocked    = +2 if joined tracker has empty blocked_by, OR no tracker join
  recency      = age_days / 14            (integer division; 0 if no tracker)
```

Tie-break: alphabetic ascending by title.

Edge cases (design premise #8):
- Missing `TODOS.md` → exit 1 with a clear stderr message.
- No matching active entries → print `No actionable items.` and exit 0.
- No trackers found → degrade to TODOS-only ranking (no recency penalty;
  every row treated as unblocked).

## Routing

Run the bash block below from the repo root and print its stdout verbatim.
Do not paraphrase or summarize the table; the user wants the raw markdown
to scan.

```bash
set -u

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

# Bound the active band on EITHER `## Deferred work` OR any other top-level
# `## ` heading. Without the second clause, inserting `## Triage` between
# Active and Deferred would leak that section's `### …` rows into the candidate
# set (adversarial review CRITICAL #2).
ACTIVE_HEADINGS=$(awk '
  /^## Active work[[:space:]]*$/ {a=1; next}
  /^## / && !/^## Active work[[:space:]]*$/ {a=0}
  a && /^### [^~]/ { print }
' "$TODOS")

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
  id=$(echo "$raw" | grep -oE '\b[FSTD][0-9]{6}\b' | head -n1)

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
TOP5=$(sort -t$'\t' -k1,1nr -k2,2 "$SCORED" | head -n 5)

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
```

## Notes

- **Surface convention.** Output is markdown to stdout. Same shape as
  `landing-report` so the user can scan-and-pick in under 30 seconds.
- **Heading-only ID extraction.** TODOS body prose often references other
  work items (`Closed by F000014`, etc.). Extracting from the body would
  cause false-positive joins. The regex matches the FIRST
  `\b[FSTD][0-9]{6}\b` in the heading line ONLY.
- **YAML parser fragility.** See FRAGILITY NOTE in the bash body. Pre-ship
  check via test #15 in the test-plan.
- **macOS-compatible date math.** Uses `date -j -f "%Y-%m-%d"` (BSD form),
  not GNU `date -d`.
- **Single-file by design.** No `scripts/suggest.sh` in v1. Promote to
  Approach B (script + eval case) post-soak if needed.
