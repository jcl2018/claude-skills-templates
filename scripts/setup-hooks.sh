#!/usr/bin/env bash
# Install per-machine git hooks for the skill workbench.
# - pre-commit: runs validate.sh + per-skill checks
# - post-merge: re-deploys skills + templates after pulls that touch them (D000013).
# Usage: ./scripts/setup-hooks.sh
#
# NOTE: the F000011 post-merge "Phase 3 lifecycle-gate auto-update" block was
# removed (F000011 fix, Approach A). A post-merge hook cannot cleanly mutate a
# tracked _TRACKER.md on main: any edit either dirties the working tree (breaking
# post-land-sync.sh's `pull --ff-only` and re-arming cj-worktree-init.sh's
# dirty-checkout guard) or, if committed, creates a local-ahead commit that
# diverges main. scripts/check-gates-update.sh survives as a MANUAL operator tool
# only; it is no longer auto-invoked by this hook.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The clobber-safe hook-install primitive + the SENTINEL now live in ONE shared,
# sourceable lib (F000069 / S000117) so this script and scripts/skills-deploy share
# a single implementation instead of two drifting copies. Source it; fall back to
# the deployed _cj-shared copy if the repo-local one is missing (defensive).
if [ -f "$REPO_ROOT/scripts/cj-hook-lib.sh" ]; then
  # shellcheck source=scripts/cj-hook-lib.sh
  . "$REPO_ROOT/scripts/cj-hook-lib.sh"
elif [ -f "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/cj-hook-lib.sh" ]; then
  # shellcheck disable=SC1091
  . "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/cj-hook-lib.sh"
else
  echo "ERROR: cannot find scripts/cj-hook-lib.sh (the shared hook-install lib)" >&2
  exit 1
fi

# --git-common-dir resolves to the shared .git for both regular checkouts and
# worktrees (where $REPO_ROOT/.git is a file, not a directory). cj_resolve_hook_dir
# normalizes the relative-in-main / absolute-in-worktree path to an absolute hooks
# dir.
HOOK_DIR="$(cj_resolve_hook_dir "$REPO_ROOT")"

if [ -z "$HOOK_DIR" ] || [ ! -d "$HOOK_DIR" ]; then
  echo "ERROR: cannot resolve git hooks directory. Are you in a git repo?" >&2
  exit 1
fi

# The sentinel embedded in every hook body this script writes (see the heredocs
# below) is the shared lib's $CJ_HOOK_SENTINEL — kept byte-identical so a
# sentinel match (grep -F substring) recognizes our own prior install.

# install_hook <name>   (hook body on stdin)
# Thin wrapper over the shared cj_install_hook, pinned to this script's $HOOK_DIR,
# so the existing call sites + the `|| echo WARN >&2` guards stay unchanged. The
# clobber-safe atomic-install + back-up-non-workbench-hook safety lives in the
# shared lib (sourced above).
install_hook() {
  cj_install_hook "$HOOK_DIR" "$1"
}

rc=0

if install_hook pre-commit << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh
# Runs repo-wide validation. Per-skill skill-check.sh was retired (see TODOS.md);
# validate.sh + scripts/test.sh now cover skill-level invariants.

./scripts/validate.sh || exit 1
HOOK
then
  echo "Pre-commit hook installed at .git/hooks/pre-commit"
  echo "Commits will now run validate.sh."
else
  rc=1
fi

if install_hook post-merge << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh.
# Post-merge handler:
#   - D000013: re-deploy skills + templates if relevant files changed
# Closes D000012 Option C2: deploy is the per-machine sync-up. Templates are ready
# at ~/.claude/ before the next skill invocation needs them.
#
# The former F000011 "Phase 3 lifecycle-gate auto-update" section was removed:
# a post-merge hook cannot cleanly mutate a tracked _TRACKER.md on main without
# dirtying the tree (or diverging main if committed). check-gates-update.sh is
# now a manual operator tool only.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

# Section 1: D000013 re-deploy on relevant file change
CHANGED=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
  | grep -E '^(templates/|skills/|skills-catalog\.json|rules/)' || true)
if [ -n "$CHANGED" ]; then
  echo "[skills-deploy] templates/skills/catalog/rules changed — re-deploying..."
  "$REPO_ROOT/scripts/skills-deploy" install --overwrite
fi

# Best-effort: always exit 0 to avoid blocking git operations.
exit 0
HOOK
then
  echo "Post-merge hook installed at .git/hooks/post-merge"
  echo "  - Pulls that change templates/skills/catalog/rules auto-redeploy ~/.claude/."
else
  rc=1
fi

exit $rc
