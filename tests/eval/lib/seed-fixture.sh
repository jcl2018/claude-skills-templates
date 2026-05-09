#!/usr/bin/env bash
# Seed an eval-case fixture into a tmpdir.
#
# Behavior:
#   1. Copy fixture/ contents into the target tmpdir (cp -R).
#   2. Initialize the tmpdir as a git repo so skills resolving _REPO_ROOT via
#      `git rev-parse --show-toplevel` get the tmpdir, not the workbench root.
#      Without git init, resolution falls through to ~/.claude/skills/, which
#      contradicts F000013 Premise 4 (test in-repo source, not deployed copy).
#
# Usage: seed-fixture.sh <fixture_src_dir> <tmpdir>
# Exit 0 = success. Exit 1 = either arg invalid or git init failed.

set -euo pipefail

fixture_src="${1:?fixture source dir required}"
tmpdir="${2:?tmpdir target required}"

[ -d "$tmpdir" ] || {
  echo "seed-fixture: tmpdir does not exist: $tmpdir" >&2
  exit 1
}

# Empty fixture/ is allowed — some cases run the skill against an empty workspace.
if [ -d "$fixture_src" ]; then
  # Reject fixtures containing symlinks. A fixture symlink pointing at
  # ~/.ssh/ or /etc/passwd would land inside the tmpdir as a regular file
  # under cp -R (BSD default), exposing host secrets to the model with Bash
  # access. Refusing symlinks at seed time is cheaper than sandboxing.
  if find "$fixture_src" -type l -print -quit 2>/dev/null | grep -q .; then
    echo "seed-fixture: fixture $fixture_src contains symlinks; refusing." >&2
    echo "  Eval fixtures must be regular files only. Replace symlinks with their targets." >&2
    exit 1
  fi
  # cp -RP preserves symlinks as symlinks (won't follow). Combined with the
  # rejection above, this is belt-and-braces.
  cp -RP "$fixture_src/." "$tmpdir/" 2>/dev/null || {
    echo "seed-fixture: copy failed from $fixture_src to $tmpdir" >&2
    exit 1
  }
fi

# Initialize git so _REPO_ROOT resolution lands inside the tmpdir.
# Surface git errors instead of swallowing — silent failure here means the
# eval runs against an uncommitted tree and skill behavior diverges from
# production silently. Loud failure = fixable; silent corruption = not.
(
  cd "$tmpdir"
  git init -q || { echo "seed-fixture: git init failed" >&2; exit 1; }
  git -c user.email=eval@local -c user.name=eval-harness -c commit.gpgsign=false add -A \
    || { echo "seed-fixture: git add failed" >&2; exit 1; }
  git -c user.email=eval@local -c user.name=eval-harness -c commit.gpgsign=false commit -q -m "eval fixture seed" \
    || { echo "seed-fixture: git commit failed" >&2; exit 1; }
) || exit 1

exit 0
