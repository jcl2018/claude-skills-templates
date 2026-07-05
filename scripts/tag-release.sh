#!/usr/bin/env bash
# tag-release.sh — publish the `v<VERSION>` release tag to origin at LAND time.
#
# Why this exists (D-fix for the inert version-notification):
#   scripts/skills-update-check nudges consumers when origin publishes a newer
#   release, by reading the max `v<X.Y.Z>` tag via `git ls-remote --tags`. But the
#   land flow bumps VERSION + collection_version + CHANGELOG on every ship and NEVER
#   created a matching `v<VERSION>` git tag — so the newest tag anywhere on origin
#   stayed `v1.1.0` while VERSION marched to 6.0.x. The compare was therefore always
#   `remote(1.1.0) < local` → the no-downgrade-nudge branch → silent forever. This
#   helper closes that gap: at LAND (post-merge, from post-land-sync.sh) it ensures
#   the current VERSION is published as a `v<VERSION>` tag on origin.
#
# TIMING — this runs at LAND, not per-PR. VERSION is bumped IN a PR (before the tag
#   exists), so a per-PR "a tag for VERSION exists on origin" gate would fail on every
#   PR. The recurrence guard therefore lives here (post-land / advisory), never as a
#   per-PR hard gate.
#
# Contract:
#   - Reads VERSION from the repo root (or --version <X.Y.Z>).
#   - If `v<VERSION>` already exists on the remote, it is a NO-OP (idempotent) —
#     re-running a land never re-pushes or errors on an existing tag.
#   - Otherwise it creates an annotated tag `v<VERSION>` at the given commit
#     (default HEAD) and `git push <remote> v<VERSION>`.
#   - Fail-soft by default: a push failure (offline / no perms) prints a WARN and
#     exits 0 so it NEVER halts a land. Pass --strict to make failures exit non-zero
#     (used by the hermetic test, which controls a local bare origin).
#
# Usage:
#   ./scripts/tag-release.sh                         # tag v<VERSION> on 'origin' if absent, then push (fail-soft)
#   ./scripts/tag-release.sh --dry-run               # resolve + report would-run; mutate nothing
#   ./scripts/tag-release.sh --remote <name>         # push to a different remote (default: origin)
#   ./scripts/tag-release.sh --version <X.Y.Z>       # override the VERSION read
#   ./scripts/tag-release.sh --ref <commit>          # tag a specific commit (default: HEAD)
#   ./scripts/tag-release.sh --strict                # exit non-zero on a create/push failure
#   ./scripts/tag-release.sh --help
#
# Exit codes:
#   0 — tag published, or already present (no-op), or --dry-run, or a fail-soft skip
#   1 — bad invocation (unknown flag / bad VERSION)
#   2 — a create/push failure UNDER --strict (fail-soft mode returns 0 with a WARN)
set -euo pipefail

REMOTE="origin"
DRY_RUN=0
STRICT=0
VERSION_OVERRIDE=""
REF="HEAD"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the repo root from the git toplevel so the helper works from any subdir /
# worktree; fall back to the script's parent dir when git can't answer.
# NOTE: keep the fallback in its OWN command so `|| ... && pwd` precedence can't append
# a stray second line to REPO_ROOT (`(A || B) && pwd` runs pwd even when A succeeded).
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$REPO_ROOT" ] || REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
tag-release.sh — publish the v<VERSION> release tag to origin at land time.

Usage:
  ./scripts/tag-release.sh                    # tag v<VERSION> on 'origin' if absent + push (fail-soft)
  ./scripts/tag-release.sh --dry-run          # resolve + print would-run; mutate nothing
  ./scripts/tag-release.sh --remote <name>    # push to a different remote (default: origin)
  ./scripts/tag-release.sh --version <X.Y.Z>  # override the VERSION read
  ./scripts/tag-release.sh --ref <commit>     # tag a specific commit (default: HEAD)
  ./scripts/tag-release.sh --strict           # exit non-zero on a create/push failure
  ./scripts/tag-release.sh --help

Exit codes:
  0 published / already-present / dry-run / fail-soft skip · 1 bad invocation · 2 failure under --strict
USAGE
}

is_semver() {
  printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'
}

# --- arg parsing ---
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --strict)  STRICT=1; shift ;;
    --remote)  REMOTE="${2:-}"; shift 2 ;;
    --version) VERSION_OVERRIDE="${2:-}"; shift 2 ;;
    --ref)     REF="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "tag-release: unknown argument '$1'" >&2
      echo "  see --help" >&2
      exit 1
      ;;
  esac
done

# --- resolve VERSION ---
if [ -n "$VERSION_OVERRIDE" ]; then
  VERSION="$VERSION_OVERRIDE"
else
  VERSION_FILE="$REPO_ROOT/VERSION"
  if [ ! -f "$VERSION_FILE" ]; then
    echo "tag-release: VERSION file not found at $VERSION_FILE" >&2
    exit 1
  fi
  # Trim whitespace/CR (a Windows checkout may carry a trailing CR).
  VERSION="$(tr -d ' \t\r\n' < "$VERSION_FILE")"
fi

if ! is_semver "$VERSION"; then
  echo "tag-release: VERSION is not valid semver (got '$VERSION')" >&2
  exit 1
fi

TAG="v$VERSION"

# --- does the tag already exist on the remote? (idempotency) ---
# ls-remote is anonymous + read-only; a peeled `^{}` ref also counts as "present".
# Fail-soft: if ls-remote itself errors (offline), treat as "unknown" and let the
# create/push arm below handle the failure per the strict/fail-soft policy.
remote_has_tag() {
  local out
  out=$(GIT_TERMINAL_PROMPT=0 \
        git ls-remote --tags "$REMOTE" "$TAG" 2>/dev/null | tr -d '\r') || return 2
  if printf '%s\n' "$out" | grep -qE "refs/tags/${TAG}(\^\{\})?$"; then
    return 0   # present
  fi
  return 1     # absent (ls-remote succeeded, no match)
}

if [ "$DRY_RUN" = "1" ]; then
  echo "tag-release: DRY RUN — no mutation."
  echo "  repo root:   $REPO_ROOT"
  echo "  VERSION:     $VERSION"
  echo "  tag:         $TAG"
  echo "  remote:      $REMOTE"
  echo "  ref:         $REF"
  if remote_has_tag; then
    echo "  state:       tag $TAG ALREADY on $REMOTE → would NO-OP"
  else
    _hrc=$?
    if [ "$_hrc" = "2" ]; then
      echo "  state:       could not reach $REMOTE (ls-remote failed) → would attempt create+push"
    else
      echo "  state:       tag $TAG ABSENT on $REMOTE → would create + push"
    fi
    echo "  would run:   git tag -a $TAG $REF -m \"Release $TAG\""
    echo "  would run:   git push $REMOTE $TAG"
  fi
  exit 0
fi

# --- act ---
if remote_has_tag; then
  echo "tag-release: $TAG already published on $REMOTE — no-op (idempotent)."
  exit 0
fi
_hrc=$?
if [ "$_hrc" = "2" ]; then
  # ls-remote failed (offline / no perms). Fall through to attempt the push; the
  # failure is reported per the strict/fail-soft policy below.
  echo "tag-release: could not read tags from $REMOTE (offline?); attempting create + push anyway." >&2
fi

# Create the annotated tag locally if it isn't already present, then push it.
# A pre-existing local tag (from a prior half-completed land) is reused, not re-created.
if ! git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
  if ! git -C "$REPO_ROOT" tag -a "$TAG" "$REF" -m "Release $TAG" 2>/dev/null; then
    echo "tag-release: WARN — could not create local tag $TAG at $REF." >&2
    [ "$STRICT" = "1" ] && exit 2
    exit 0
  fi
fi

if git -C "$REPO_ROOT" push "$REMOTE" "$TAG" 2>/dev/null; then
  echo "tag-release: published $TAG to $REMOTE."
  exit 0
fi

echo "tag-release: WARN — could not push $TAG to $REMOTE (offline / no permission?). The tag exists locally; push it later with: git push $REMOTE $TAG" >&2
[ "$STRICT" = "1" ] && exit 2
exit 0
