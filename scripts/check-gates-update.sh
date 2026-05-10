#!/usr/bin/env bash
# F000011 / S000020: Phase 3 lifecycle-gate auto-update inference engine.
#
# Reads external state (gh PR + git log + recursive child trackers), writes
# [x] to inferable Phase 3 gates in a work-item TRACKER.md. Additive-only:
# never downgrades [x] to [ ]. Skips `E2E walked manually` entirely (purely
# human-driven; no external signal).
#
# Usage:
#   scripts/check-gates-update.sh <work-item-dir>
#
# Called from:
#   - skills/CJ_personal-workflow/check.md Step 13.5 (when --update flag passed)
#   - .git/hooks/post-merge (auto-fires after git pull on main)
#
# Best-effort contract: prints warnings on partial failure (e.g., gh offline),
# but exits 0 unless the input is fundamentally invalid.

set -uo pipefail

WORK_ITEM_DIR="${1:-}"

if [ -z "$WORK_ITEM_DIR" ]; then
  echo "Usage: $0 <work-item-dir>" >&2
  exit 2
fi

if [ ! -d "$WORK_ITEM_DIR" ]; then
  echo "ERROR: not a directory: $WORK_ITEM_DIR" >&2
  exit 2
fi

git rev-parse --show-toplevel >/dev/null 2>&1 || {
  echo "ERROR: not in a git repository" >&2
  exit 2
}

# Find the TRACKER.md in the dir.
TRACKER=$(find "$WORK_ITEM_DIR" -maxdepth 1 \( -name "*_TRACKER.md" -o -name "TRACKER.md" \) 2>/dev/null | head -1)
if [ -z "$TRACKER" ]; then
  echo "ERROR: no TRACKER.md in $WORK_ITEM_DIR" >&2
  exit 2
fi

# Extract work-item ID from TRACKER filename (e.g., S000020_TRACKER.md → S000020).
WORK_ITEM_ID=$(basename "$TRACKER" | sed 's/_TRACKER\.md$//;s/^TRACKER\.md$//')

# Extract branch from TRACKER frontmatter.
BRANCH=$(awk '/^---$/{c++; next} c==1 && /^branch:/{print}' "$TRACKER" \
  | sed 's/^branch:[[:space:]]*//;s/^"//;s/"$//' | head -1)

if [ -z "$BRANCH" ] || [ "$BRANCH" = '""' ]; then
  echo "[$WORK_ITEM_ID] WARN: no branch field in TRACKER frontmatter; gate inference limited"
  BRANCH=""
fi

# Try to find the PR for this work-item. Strategy: search by work-item ID in
# any PR (open + closed + merged), then fall back to branch name match.
PR_NUMBER=""
PR_STATE=""
PR_URL=""
PR_TITLE=""

if command -v gh >/dev/null 2>&1; then
  PR_JSON=$(gh pr list --search "$WORK_ITEM_ID" --state all --json number,state,url,title --limit 1 2>/dev/null) || PR_JSON=""

  if [ -n "$PR_JSON" ] && [ "$PR_JSON" != "[]" ]; then
    PR_NUMBER=$(echo "$PR_JSON" | jq -r '.[0].number // empty' 2>/dev/null)
    PR_STATE=$(echo "$PR_JSON" | jq -r '.[0].state // empty' 2>/dev/null)
    PR_URL=$(echo "$PR_JSON" | jq -r '.[0].url // empty' 2>/dev/null)
    PR_TITLE=$(echo "$PR_JSON" | jq -r '.[0].title // empty' 2>/dev/null)
  fi

  # Fallback: search by branch name if first attempt missed.
  if [ -z "$PR_NUMBER" ] && [ -n "$BRANCH" ]; then
    PR_JSON=$(gh pr list --head "$BRANCH" --state all --json number,state,url,title --limit 1 2>/dev/null) || PR_JSON=""
    if [ -n "$PR_JSON" ] && [ "$PR_JSON" != "[]" ]; then
      PR_NUMBER=$(echo "$PR_JSON" | jq -r '.[0].number // empty' 2>/dev/null)
      PR_STATE=$(echo "$PR_JSON" | jq -r '.[0].state // empty' 2>/dev/null)
      PR_URL=$(echo "$PR_JSON" | jq -r '.[0].url // empty' 2>/dev/null)
      PR_TITLE=$(echo "$PR_JSON" | jq -r '.[0].title // empty' 2>/dev/null)
    fi
  fi
else
  echo "[$WORK_ITEM_ID] WARN: gh not on PATH; PR-state-dependent gates will be skipped"
fi

if [ -z "$PR_NUMBER" ]; then
  echo "[$WORK_ITEM_ID] INFO: no PR found for $WORK_ITEM_ID (branch=$BRANCH); PR-state gates will be skipped"
fi

# Helper: mark a Phase 3 gate as [x] if it matches the given substring AND is
# currently [ ]. Idempotent + additive: never downgrades [x] to [ ].
# Returns 0 if a change was made; 1 if no change (already checked or not found).
mark_gate() {
  local label_substring="$1"

  local phase3_block
  phase3_block=$(awk '/^### Phase 3:/{f=1; next} f && /^### Phase /{f=0} f' "$TRACKER")

  # Already checked? (idempotent NO-OP)
  if echo "$phase3_block" | grep -qE "^\s*-\s*\[[xX]\].*$label_substring"; then
    return 1
  fi

  # Find the unchecked line; if not found, gate label doesn't match this tracker
  if ! echo "$phase3_block" | grep -qE "^\s*-\s*\[ \].*$label_substring"; then
    return 1
  fi

  # Use awk to flip [ ] → [x] for the first matching line in Phase 3.
  local tmp
  tmp=$(mktemp)
  awk -v substring="$label_substring" '
    /^### Phase 3:/ { in_phase3=1 }
    in_phase3 && /^### Phase / && !/^### Phase 3:/ { in_phase3=0 }
    in_phase3 && !flipped && /^[[:space:]]*-[[:space:]]*\[ \]/ && index($0, substring) {
      sub(/\[ \]/, "[x]"); flipped=1
    }
    { print }
  ' "$TRACKER" > "$tmp"
  mv "$tmp" "$TRACKER"
  return 0
}

# Track changes for journal entry.
CHANGES=()

# Gate 1: /ship — PR created (PR exists)
if [ -n "$PR_NUMBER" ]; then
  if mark_gate "/ship"; then
    CHANGES+=("/ship — PR #$PR_NUMBER")
  fi
fi

# Gate 2: /land-and-deploy — merged and deployed (PR state = MERGED)
if [ -n "$PR_NUMBER" ] && [ "$PR_STATE" = "MERGED" ]; then
  if mark_gate "/land-and-deploy"; then
    CHANGES+=("/land-and-deploy — PR merged")
  fi
fi

# Gate 3: Smoke tests pass in CI (gh pr checks all pass — no fail, no pending)
if [ -n "$PR_NUMBER" ] && command -v gh >/dev/null 2>&1; then
  CHECKS_OUTPUT=$(gh pr checks "$PR_NUMBER" 2>/dev/null) || CHECKS_OUTPUT=""
  if [ -n "$CHECKS_OUTPUT" ]; then
    if ! echo "$CHECKS_OUTPUT" | grep -qiE 'fail|pending'; then
      if mark_gate "Smoke tests pass in CI"; then
        CHANGES+=("Smoke tests pass — all checks green on PR #$PR_NUMBER")
      fi
    fi
  fi
fi

# Gate 4: /CJ_personal-workflow check — validation passed
# DEFERRED in v1: would require invoking the validator with risk of recursion
# when called from check.md Step 13.5. Documented gap; user runs check separately.

# Gate 5: All children shipped (recursive — direct children only in v1)
CHILDREN=$(find "$WORK_ITEM_DIR" -mindepth 2 -maxdepth 2 -name "*_TRACKER.md" 2>/dev/null)
if [ -n "$CHILDREN" ]; then
  ALL_CHILDREN_SHIPPED=1
  while IFS= read -r child_tracker; do
    [ -z "$child_tracker" ] && continue
    child_phase3=$(awk '/^### Phase 3:/{f=1; next} f && /^### Phase /{f=0} f' "$child_tracker")
    if ! echo "$child_phase3" | grep -qE "^\s*-\s*\[[xX]\].*\/land-and-deploy"; then
      ALL_CHILDREN_SHIPPED=0
      break
    fi
  done <<< "$CHILDREN"

  if [ "$ALL_CHILDREN_SHIPPED" = "1" ]; then
    if mark_gate "All children shipped"; then
      CHANGES+=("All children shipped — verified via child-tracker recursion")
    fi
  fi
fi

# Gate 6: /document-release (heuristic: docs: commit on main since PR merge)
if [ -n "$PR_NUMBER" ] && [ "$PR_STATE" = "MERGED" ] && command -v gh >/dev/null 2>&1; then
  MERGE_SHA=$(gh pr view "$PR_NUMBER" --json mergeCommit --jq '.mergeCommit.oid' 2>/dev/null) || MERGE_SHA=""
  if [ -n "$MERGE_SHA" ]; then
    DOCS_COMMIT=$(git log --grep "^docs" --format=%h "$MERGE_SHA"..origin/main 2>/dev/null | head -1) || DOCS_COMMIT=""
    if [ -n "$DOCS_COMMIT" ]; then
      if mark_gate "/document-release"; then
        CHANGES+=("/document-release — found docs: commit $DOCS_COMMIT after merge")
      fi
    fi
  fi
fi

# E2E walked manually: NEVER auto-mark. Documented contract.

# Step 13.6 equivalent: Append PR link to ## PRs section if not already there.
if [ -n "$PR_NUMBER" ] && [ -n "$PR_URL" ]; then
  if ! grep -qF "$PR_URL" "$TRACKER"; then
    tmp=$(mktemp)
    awk -v pr_num="$PR_NUMBER" -v pr_url="$PR_URL" -v pr_state="$PR_STATE" -v pr_title="$PR_TITLE" '
      /^## PRs/ {
        print
        in_prs = 1
        printed = 0
        next
      }
      in_prs && /^## / && !/^## PRs/ {
        if (!printed) {
          print "- [PR #" pr_num ": " pr_title "](" pr_url ") — " pr_state
          printed = 1
          print ""
        }
        in_prs = 0
      }
      { print }
      END {
        if (in_prs && !printed) {
          print "- [PR #" pr_num ": " pr_title "](" pr_url ") — " pr_state
        }
      }
    ' "$TRACKER" > "$tmp"
    mv "$tmp" "$TRACKER"
    CHANGES+=("PRs section: linked PR #$PR_NUMBER ($PR_STATE)")
  fi
fi

# Step 13.7 equivalent: Append [gates-update] journal entry if any changes.
if [ ${#CHANGES[@]} -gt 0 ]; then
  TODAY=$(date +%Y-%m-%d)
  CHANGES_JOINED=$(IFS=', '; printf '%s' "${CHANGES[*]}")
  JOURNAL_LINE="- $TODAY [gates-update] Phase 3: $CHANGES_JOINED."

  tmp=$(mktemp)
  awk -v line="$JOURNAL_LINE" '
    /^## Journal/ { in_journal = 1; print; next }
    in_journal && /^## / && !/^## Journal/ {
      if (!added) {
        print line
        print ""
        added = 1
      }
      in_journal = 0
    }
    { print }
    END {
      if (in_journal && !added) {
        print line
      }
    }
  ' "$TRACKER" > "$tmp"
  mv "$tmp" "$TRACKER"

  echo "[$WORK_ITEM_ID] gates-update: ${#CHANGES[@]} change(s) — ${CHANGES_JOINED}"
else
  echo "[$WORK_ITEM_ID] gates-update: no changes (already converged or no inferable gates with positive signal)"
fi

exit 0
