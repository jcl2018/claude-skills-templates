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
# --git-common-dir resolves to the shared .git for both regular checkouts and
# worktrees (where $REPO_ROOT/.git is a file, not a directory). It returns an
# absolute path in worktrees but a relative ".git" in main checkouts, so
# normalize to absolute by prefixing REPO_ROOT when relative.
GIT_COMMON_DIR="$(git -C "$REPO_ROOT" rev-parse --git-common-dir 2>/dev/null)"
case "$GIT_COMMON_DIR" in
  /*) HOOK_DIR="$GIT_COMMON_DIR/hooks" ;;
  *)  HOOK_DIR="$REPO_ROOT/$GIT_COMMON_DIR/hooks" ;;
esac

if [ ! -d "$HOOK_DIR" ]; then
  echo "ERROR: cannot resolve git hooks directory. Are you in a git repo?" >&2
  exit 1
fi

# Sentinel embedded in every hook body this script writes (see the heredocs
# below). Lets install_hook tell a workbench-owned hook from an
# operator/tooling-owned one (Husky, lefthook, a local debug hook) so a custom
# hook is never blindly destroyed. grep -F substring match: tolerates the
# post-merge body's trailing '.' after the sentinel.
SENTINEL='# Auto-installed by scripts/setup-hooks.sh'

# install_hook <name>   (hook body on stdin)
# Clobber-safe, atomic install of .git/hooks/<name>:
#   - Stage the body into a temp file in $HOOK_DIR and chmod +x it BEFORE the
#     target is touched. The live hook is only ever changed by an atomic mv of
#     a fully-written file (same dir => same filesystem => rename(2)), so a
#     mid-write/chmod failure leaves the prior hook intact — never a truncated
#     or non-executable hook (the prior `cat >` truncated the target up front;
#     setup.sh's `|| echo WARN >&2` then masked the partial write).
#   - If an existing hook lacks $SENTINEL it is operator/tooling-owned: back it
#     up to <hook>.bak (timestamped if .bak exists) and warn, instead of
#     silently destroying it. If the backup itself fails, abort WITHOUT
#     clobbering — losing an un-backed custom hook is the one unacceptable
#     outcome.
#   - An existing hook that already carries $SENTINEL is our own prior install:
#     refreshed in place, no backup, so repeated setup.sh runs stay a no-op.
# Returns non-zero on failure so setup.sh's `|| echo WARN >&2` guard fires.
install_hook() {
  hook_name="$1"
  hook_path="$HOOK_DIR/$hook_name"
  tmp="$(mktemp "$HOOK_DIR/.${hook_name}.XXXXXX" 2>/dev/null)" || {
    echo "ERROR: cannot create temp file in $HOOK_DIR for $hook_name hook" >&2
    return 1
  }
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: failed to write $hook_name hook body" >&2
    return 1
  fi
  if ! chmod +x "$tmp"; then
    rm -f "$tmp"
    echo "ERROR: chmod +x failed for $hook_name hook" >&2
    return 1
  fi
  if [ -e "$hook_path" ] && ! grep -qF "$SENTINEL" "$hook_path" 2>/dev/null; then
    backup="$hook_path.bak"
    [ -e "$backup" ] && backup="$hook_path.bak.$(date +%Y%m%d%H%M%S)"
    if ! cp -p "$hook_path" "$backup"; then
      rm -f "$tmp"
      echo "ERROR: existing .git/hooks/$hook_name is not workbench-owned and could not be backed up — refusing to overwrite (your custom hook is untouched)" >&2
      return 1
    fi
    echo "WARN: existing .git/hooks/$hook_name is not workbench-owned — backed up to $(basename "$backup") before installing the workbench hook" >&2
  fi
  if ! mv "$tmp" "$hook_path"; then
    rm -f "$tmp"
    echo "ERROR: failed to install $hook_name hook" >&2
    return 1
  fi
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
