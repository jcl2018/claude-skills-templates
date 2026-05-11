#!/usr/bin/env bash
# Pre-/ship preflight: detect VERSION queue collisions before /ship's
# local-only bump. Reads open PRs via gh, extracts version claims from
# title prefixes, prints next-free slot.
#
# Workbench-side fallback for when gstack's bin/gstack-next-version is
# offline in this repo (the typical state). When that util comes back
# online, this preflight remains useful as a cheap, focused check.
#
# Skip on gh offline/unauthenticated (with a 1-line note). Read-only;
# no mutations.
#
# Usage:
#   ./scripts/check-version-queue.sh           # print next-free slot (human-readable)
#   ./scripts/check-version-queue.sh --json    # machine-readable output
#
# Exit codes:
#   0 — success (or skip on offline)
#   1 — bad invocation (e.g., not a git repo)
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: not in a git repo" >&2; exit 1
}

MODE="${1-}"  # default-empty so set -u doesn't crash on no-args invocation

# Skip on gh missing/unauthenticated (1-line note, exit 0)
command -v gh >/dev/null 2>&1 || { echo "(gh not installed; skipping)"; exit 0; }
gh auth status >/dev/null 2>&1 || { echo "(gh not authenticated; skipping)"; exit 0; }

BASE_VERSION=$(tr -d '[:space:]' < VERSION 2>/dev/null || true)
[ -n "$BASE_VERSION" ] || { echo "(VERSION file missing or empty; skipping)"; exit 0; }

# Scan open PRs targeting main; cap at 5 (matches CJ_scaffold-work-item Step 5 cap).
PRS=$(gh pr list --state open --base main --limit 5 --json number,title 2>/dev/null || echo '[]')

# Validate JSON (jq -e fails on null/non-array)
echo "$PRS" | jq -e 'type == "array"' >/dev/null 2>&1 || PRS='[]'

# Extract version from title PREFIX only (anchored), avoiding embedded versions
# in PR titles like "fix: regression introduced in v1.16.0". The repo convention
# is `v<X.Y.Z> <type>: <summary>` per Step 19 of /ship, so anchoring is correct.
# `|| true` at the end so grep returning 1 (no match — common when no open PRs
# or none claim versions) doesn't trip set -o pipefail.
ALL_CLAIMED=$(echo "$PRS" | jq -r '.[].title' \
  | grep -oE '^v[0-9]+\.[0-9]+\.[0-9]+' \
  | sed 's/^v//' \
  | sort -V || true)

# Filter to claims >= BASE_VERSION. Older claims are stale PRs that need /ship
# rebump; we surface them separately so the agent can investigate, but they
# don't affect next-free arithmetic.
STALE_CLAIMS=""
ACTIVE_CLAIMS=""
for V in $ALL_CLAIMED; do
  if [ "$(printf '%s\n%s\n' "$BASE_VERSION" "$V" | sort -V | tail -1)" = "$V" ]; then
    ACTIVE_CLAIMS="${ACTIVE_CLAIMS}${V} "
  else
    STALE_CLAIMS="${STALE_CLAIMS}${V} "
  fi
done

# Detect duplicate-claim collisions (two open PRs claiming the same VERSION).
# `uniq -d` needs sorted input.
DUP_CLAIMS=$(echo "$ALL_CLAIMED" | sort | uniq -d | tr '\n' ' ' | sed 's/  *$//')

# Next free = max(BASE_VERSION, active claims) + 1 PATCH bump
HIGHEST="$BASE_VERSION"
for V in $ACTIVE_CLAIMS; do
  if [ "$(printf '%s\n%s\n' "$HIGHEST" "$V" | sort -V | tail -1)" = "$V" ]; then
    HIGHEST="$V"
  fi
done
NEXT=$(echo "$HIGHEST" | awk -F. '{print $1"."$2"."($3+1)}')

if [ "$MODE" = "--json" ]; then
  # Guard against empty-string vars: `printf '%s\n' ""` emits a single newline
  # that jq -R reads as "" and jq -s wraps as [""], not []. Use a clean [] when
  # there are no claims.
  to_array() {
    if [ -n "$1" ]; then
      # shellcheck disable=SC2086  # intentional word-splitting: $1 is space-separated versions
      printf '%s\n' $1 | jq -R . | jq -s .
    else
      echo '[]'
    fi
  }
  jq -n --arg base "$BASE_VERSION" --arg highest "$HIGHEST" --arg next "$NEXT" \
    --argjson active "$(to_array "$ACTIVE_CLAIMS")" \
    --argjson stale "$(to_array "$STALE_CLAIMS")" \
    --argjson dup "$(to_array "$DUP_CLAIMS")" \
    '{base:$base, highest:$highest, next:$next, active_claims:$active, stale_claims:$stale, duplicate_claims:$dup}'
else
  echo "Base VERSION:           v$BASE_VERSION"
  echo "Active open-PR claims:  ${ACTIVE_CLAIMS:-(none)}"
  if [ -n "$STALE_CLAIMS" ]; then
    echo "Stale claims (< base):  $STALE_CLAIMS (these PRs need /ship rebump)"
  fi
  echo "Highest in queue:       v$HIGHEST"
  echo "Next free PATCH:        v$NEXT"
  if [ -n "$DUP_CLAIMS" ]; then
    echo ""
    echo "⚠ DUPLICATE CLAIMS detected: $DUP_CLAIMS"
    echo "  Two or more open PRs claim the same version(s). At least one will"
    echo "  collide at /land-and-deploy time. Investigate before /ship."
  fi
  if [ "$BASE_VERSION" != "$HIGHEST" ]; then
    echo ""
    echo "⚠ Open PRs claim version(s) ahead of main. Your /ship should claim v$NEXT."
  fi
fi
