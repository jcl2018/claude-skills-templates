#!/usr/bin/env bash
# Redirects ~/.gstack/projects/<slug>/ into this repo's .gstack/ via symlink.
# Run once per repo per machine, from the repo root. Idempotent.
# Pass --force to re-point a symlink that currently targets a different repo,
# or to merge into a non-empty existing destination.
set -euo pipefail

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# Resolve MAIN repo (not worktree). Worktrees share the same slug, so the
# symlink can only point to one physical location — main is the right home.
# --path-format=absolute returns an absolute path whether run from main or worktree.
COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
MAIN_REPO=$(dirname "$COMMON_DIR")

# Don't swallow gstack-slug stderr — if the binary isn't installed, you want to see why.
# Extract SLUG via regex instead of eval to prevent arbitrary code execution if
# gstack-slug ever emits unexpected output.
SLUG=$(~/.claude/skills/gstack/bin/gstack-slug | sed -n 's/^SLUG=\([a-zA-Z0-9._/-]\{1,\}\)$/\1/p' | head -1)
: "${SLUG:?gstack-slug did not emit a valid SLUG=... line; check ~/.claude/skills/gstack install}"

SRC="$HOME/.gstack/projects/$SLUG"
DEST="$MAIN_REPO/.gstack"

if [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  if [ -d "$SRC" ] && [ ! -L "$SRC" ]; then
    echo "WARN: $DEST is non-empty AND $SRC has content to migrate."
    echo "  Files with same name in both will be OVERWRITTEN by SRC versions."
    echo "  Existing $DEST contents:"
    # shellcheck disable=SC2012  # ls -la chosen for human-readable diagnostic; DEST holds tame gstack design-doc filenames
    ls -la "$DEST" | head -20
    [ "$FORCE" = "1" ] || { echo "Re-run with --force to proceed."; exit 1; }
  fi
fi

mkdir -p "$DEST"

if [ -d "$SRC" ] && [ ! -L "$SRC" ]; then
  echo "Migrating $SRC → $DEST/"
  # --backup keeps any DEST file overwritten by SRC alongside as <name>.predeploy.bak,
  # so a misjudged --force run is recoverable.
  rsync -a --backup --suffix=.predeploy.bak "$SRC/" "$DEST/"
  mv "$SRC" "$SRC.bak.$(date +%s)"
  echo "Original backed up to $SRC.bak.<timestamp> — delete after verifying"
fi

if [ -L "$SRC" ]; then
  CURRENT=$(readlink "$SRC")
  if [ "$CURRENT" = "$DEST" ]; then
    echo "Symlink already correct: $SRC → $DEST"
    exit 0
  fi
  echo "WARN: $SRC is already a symlink to a DIFFERENT location: $CURRENT"
  echo "  Re-pointing will redirect gstack output AWAY from that other location."
  [ "$FORCE" = "1" ] || { echo "Re-run with --force to re-point."; exit 1; }
  rm "$SRC"
fi

ln -s "$DEST" "$SRC"
echo "Done. ls $SRC now shows $DEST contents."
