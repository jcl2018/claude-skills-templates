#!/usr/bin/env bash
# Install per-machine git hooks for the skill workbench.
# - pre-commit: runs validate.sh + per-skill checks
# - post-merge: re-deploys skills + templates after pulls that touch them (D000013)
# Usage: ./scripts/setup-hooks.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$HOOK_DIR" ]; then
  echo "ERROR: .git/hooks directory not found. Are you in a git repo?" >&2
  exit 1
fi

cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh
# Runs repo-wide validation. Per-skill skill-check.sh was retired (see TODOS.md);
# validate.sh + scripts/test.sh now cover skill-level invariants.

./scripts/validate.sh || exit 1
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "Pre-commit hook installed at .git/hooks/pre-commit"
echo "Commits will now run validate.sh."

cat > "$HOOK_DIR/post-merge" << 'HOOK'
#!/usr/bin/env bash
# Auto-installed by scripts/setup-hooks.sh.
# Combined post-merge handler:
#   - D000013: re-deploy skills + templates if relevant files changed
#   - F000011/S000020: auto-update Phase 3 lifecycle gates on touched work-items
# Closes D000012 Option C2: deploy is the per-machine sync-up. Templates are ready
# at ~/.claude/ before the next skill invocation needs them.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

# Section 1: D000013 re-deploy on relevant file change
CHANGED=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
  | grep -E '^(templates/|skills/|skills-catalog\.json|rules/)' || true)
if [ -n "$CHANGED" ]; then
  echo "[skills-deploy] templates/skills/catalog/rules changed — re-deploying..."
  "$REPO_ROOT/scripts/skills-deploy" install --overwrite
fi

# Section 2: F000011 Phase 3 lifecycle-gate auto-update.
# Only fires on main; silently no-ops on feature branches. Best-effort:
# prints warnings but exits 0 to never block git operations.
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ]; then
  TOUCHED_TRACKERS=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
    | grep -E '^work-items/.*_TRACKER\.md$' || true)
  if [ -n "$TOUCHED_TRACKERS" ]; then
    # Dedup to dirs.
    TOUCHED_DIRS=$(echo "$TOUCHED_TRACKERS" | xargs -n1 dirname | sort -u)
    for dir in $TOUCHED_DIRS; do
      if [ -x "$REPO_ROOT/scripts/check-gates-update.sh" ]; then
        "$REPO_ROOT/scripts/check-gates-update.sh" "$dir" 2>&1 | sed 's/^/  /' || \
          echo "  [WARN] check-gates-update.sh failed for $dir; run manually" >&2
      fi
    done
  fi
fi

# Best-effort: always exit 0 to avoid blocking git operations.
exit 0
HOOK

chmod +x "$HOOK_DIR/post-merge"
echo "Post-merge hook installed at .git/hooks/post-merge"
echo "  - Pulls that change templates/skills/catalog/rules auto-redeploy ~/.claude/."
echo "  - Pulls on main that touch work-items/**/*_TRACKER.md auto-update Phase 3 gates."
