#!/usr/bin/env bash
# Reverses setup-gstack-symlink.sh: restores ~/.gstack/projects/<slug>/ to a real directory.
# Same MAIN-repo resolution as setup, so teardown works from main or any worktree.
set -euo pipefail

COMMON_DIR=$(git rev-parse --path-format=absolute --git-common-dir)
MAIN_REPO=$(dirname "$COMMON_DIR")

# Extract SLUG via regex instead of eval to prevent arbitrary code execution.
SLUG=$(~/.claude/skills/gstack/bin/gstack-slug | sed -n 's/^SLUG=\([a-zA-Z0-9._/-]\{1,\}\)$/\1/p' | head -1)
: "${SLUG:?gstack-slug did not emit a valid SLUG=... line}"

SRC="$HOME/.gstack/projects/$SLUG"
DEST="$MAIN_REPO/.gstack"

[ -L "$SRC" ] || { echo "$SRC is not a symlink — nothing to revert"; exit 0; }
CURRENT=$(readlink "$SRC")
[ "$CURRENT" = "$DEST" ] || { echo "ERR: $SRC points to $CURRENT, not $DEST — refusing to revert blindly"; exit 1; }

rm "$SRC"
rsync -a "$DEST/" "$SRC/"
echo "Restored $SRC from $DEST. The repo's $DEST is unchanged — delete it manually if you want to remove all traces."
