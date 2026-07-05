#!/usr/bin/env bash
# post-land-sync.sh — reconcile the local ~/.claude install after a REMOTE merge.
#
# The workbench's merge convention is `gh pr merge` (a remote merge). The local
# post-merge auto-sync hook (setup-hooks.sh → skills-deploy install) only fires on
# a local `git pull`/`merge`, so after a skill PR lands on `main` the operator's
# ~/.claude/skills/ and the manifest `collection_version` go stale until a manual
# `skills-deploy install`. This helper collapses that ritual into one correct
# command: resolve `.source` from the manifest, guard it, `git pull --ff-only`,
# then run `skills-deploy install` FROM `.source` (not from a worktree — a
# worktree-invoked install skips foreign-owned skills), publish the `v<VERSION>`
# release tag to origin if absent (via scripts/tag-release.sh — fail-soft), and
# report the collection_version before→after.
#
# The tag step exists because scripts/skills-update-check reads the newest published
# `v<X.Y.Z>` tag via `git ls-remote` to decide whether to nudge consumers. The land
# flow bumps VERSION but never tagged, so origin's newest tag stayed v1.1.0 and the
# nudge was inert on every machine. Tagging at LAND (here) — not per-PR (VERSION is
# bumped in the PR before the tag exists, so a per-PR gate would always fail) — is
# what makes the notification actually fire.
#
# F000049 / S4 (S000088) — install == clone: under the in-place install model the
# manifest `.source` IS the dev checkout (install_mode: in-place), so this helper's
# pull+install operates on that same checkout. It is REFRAMED, not retired, by S4: a
# `gh pr merge` is a REMOTE merge, so a post-merge `git pull` of the checkout is still
# required — deleting it would break that refresh.
#
# Guards (each → clear message + non-zero exit, NO pull/install):
#   - `.source` missing/empty in the manifest
#   - `.source` is not a git repository
#   - `.source` is not on branch `main`
#   - `.source` working tree is dirty (TRACKED changes; untracked files are OK)
#
# Usage:
#   ./scripts/post-land-sync.sh             # guarded pull + install + version report
#   ./scripts/post-land-sync.sh --dry-run   # resolve + guard + print would-run cmds; mutate NOTHING
#   ./scripts/post-land-sync.sh --help
#
# Test/override hook:
#   POST_LAND_SYNC_MANIFEST=<path>          # override the manifest path (for tests/fixtures)
#
# Exit codes:
#   0 — success (real run reconciled, or --dry-run printed the plan)
#   1 — bad invocation (unknown flag)
#   2 — a guard failed (bad `.source` state); nothing was pulled or installed
set -euo pipefail

MANIFEST="${POST_LAND_SYNC_MANIFEST:-$HOME/.claude/.skills-templates.json}"

# Strip CRLF from jq output on Windows (jq.exe writes \r\n). No-op on Unix.
# Mirrors scripts/skills-update-check's wrapper.
jq() { command jq "$@" | tr -d '\r'; }

DRY_RUN=0

usage() {
  cat <<'USAGE'
post-land-sync.sh — reconcile the local ~/.claude install after a remote merge.

Usage:
  ./scripts/post-land-sync.sh             # guarded git pull --ff-only + skills-deploy install + version report
  ./scripts/post-land-sync.sh --dry-run   # resolve + guard + print would-run commands; mutate nothing
  ./scripts/post-land-sync.sh --help

Environment:
  POST_LAND_SYNC_MANIFEST=<path>          # override manifest path (default: ~/.claude/.skills-templates.json)

Exit codes:
  0 success · 1 bad invocation · 2 guard failed (nothing pulled/installed)
USAGE
}

# Read a top-level string field from the manifest. Empty if absent/unreadable.
manifest_field() {
  local field="$1"
  [ -f "$MANIFEST" ] || { echo ""; return 0; }
  jq -r --arg k "$field" '.[$k] // empty' "$MANIFEST" 2>/dev/null || echo ""
}

# --- arg parsing ---
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "post-land-sync: unknown argument '$1'" >&2
      echo "  see --help" >&2
      exit 1
      ;;
  esac
done

# --- resolve ---
SRC=$(manifest_field "source")
if [ -z "$SRC" ]; then
  echo "post-land-sync: GUARD FAILED — '.source' is missing or empty in the manifest ($MANIFEST)." >&2
  echo "  Install the workbench first: run 'skills-deploy install' from your clone." >&2
  exit 2
fi

# --- guards (no mutation past this point until 'act') ---
if [ ! -d "$SRC/.git" ]; then
  echo "post-land-sync: GUARD FAILED — '.source' is not a git repository: $SRC" >&2
  echo "  Refusing to pull/install. Check the manifest's 'source' field ($MANIFEST)." >&2
  exit 2
fi

SRC_BRANCH=$(git -C "$SRC" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$SRC_BRANCH" != "main" ]; then
  echo "post-land-sync: GUARD FAILED — '.source' is not on branch 'main' (on '${SRC_BRANCH:-unknown}'): $SRC" >&2
  echo "  Refusing to pull/install — would risk a non-ff merge or clobber. Switch '.source' to main first." >&2
  exit 2
fi

# Dirty = TRACKED changes. Untracked files do NOT block (operator may have scratch files).
if [ -n "$(git -C "$SRC" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
  echo "post-land-sync: GUARD FAILED — '.source' has a dirty working tree (tracked changes): $SRC" >&2
  echo "  Refusing to pull/install — would risk a conflict. Commit or stash changes in '.source' first." >&2
  exit 2
fi

# --- report (before) ---
VERSION_BEFORE=$(manifest_field "collection_version")
[ -n "$VERSION_BEFORE" ] || VERSION_BEFORE="(unknown)"

PULL_CMD="git -C \"$SRC\" pull --ff-only"
INSTALL_CMD="\"$SRC/scripts/skills-deploy\" install   (run from $SRC)"
TAG_CMD="\"$SRC/scripts/tag-release.sh\"   (publish v<VERSION> to origin if absent)"

if [ "$DRY_RUN" = "1" ]; then
  echo "post-land-sync: DRY RUN — no mutation."
  echo "  resolved .source:        $SRC"
  echo "  guard: .source on main:  yes"
  echo "  guard: .source clean:    yes (tracked)"
  echo "  collection_version:      $VERSION_BEFORE"
  echo "  would run:               $PULL_CMD"
  echo "  would run:               $INSTALL_CMD"
  echo "  would run:               $TAG_CMD"
  exit 0
fi

# --- act ---
echo "post-land-sync: reconciling local install from .source ($SRC)..."
echo "  collection_version (before): $VERSION_BEFORE"
echo "  + $PULL_CMD"
git -C "$SRC" pull --ff-only

echo "  + skills-deploy install (from $SRC)"
# CRITICAL: run skills-deploy install FROM $SRC (the main checkout), not from a
# worktree — installs invoked from a worktree skip foreign-owned skills.
( cd "$SRC" && "$SRC/scripts/skills-deploy" install )

# --- publish the release tag (fail-soft) ---
# The merged VERSION is now on local main (post-ff-pull above). Publish `v<VERSION>`
# to origin if it isn't there yet, so scripts/skills-update-check's ls-remote read
# can actually see the newest release on every consumer machine. Without this the
# newest origin tag stays stale (v1.1.0) forever and the update nudge is inert.
# tag-release.sh is idempotent (no-op if the tag exists) and fail-soft by default
# (a push failure WARNs + exits 0) — it never turns a successful land into a failure.
if [ -x "$SRC/scripts/tag-release.sh" ]; then
  echo "  + tag-release (publish v<VERSION> to origin if absent)"
  ( cd "$SRC" && "$SRC/scripts/tag-release.sh" ) || true
fi

# --- report (after) ---
VERSION_AFTER=$(manifest_field "collection_version")
[ -n "$VERSION_AFTER" ] || VERSION_AFTER="(unknown)"

echo "  collection_version (after):  $VERSION_AFTER"
if [ "$VERSION_BEFORE" = "$VERSION_AFTER" ]; then
  echo "post-land-sync: done — collection_version $VERSION_AFTER (unchanged; already in sync)."
else
  echo "post-land-sync: done — collection_version $VERSION_BEFORE → $VERSION_AFTER; local skills reinstalled from .source."
fi
