#!/usr/bin/env bash
# Install per-machine git hooks for the skill workbench.
# - pre-commit: runs validate.sh + per-skill checks
# - post-merge: re-deploys skills + templates after pulls that touch them (D000013)
# Usage: ./scripts/setup-hooks.sh

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
    while IFS= read -r tracker_path; do
      [ -z "$tracker_path" ] && continue
      dir=$(dirname "$tracker_path")

      # Guard: only fire on trackers whose Phase 2 implementer-owned gates
      # transitioned from [ ] to [x] in this merge. Pure tracker-edit changes
      # (journal cleanup, doc edits on sibling-story trackers) MUST NOT
      # trigger Phase 3 gate inference. The engine resolves PRs via
      # `gh pr list --search <id>`, which matches the work-item ID anywhere
      # in title OR body — producing false positives when one PR references
      # multiple sibling stories (observed twice: PR #99 marked S036/S037/S039
      # gates while shipping only S038; PR #100 re-corrupted S037/S039 while
      # shipping only S036). /CJ_implement-from-spec marks Phase 2 gates [x]
      # only when it writes code, so a Phase 2 [x]-count delta is a strong
      # proxy for "this work-item shipped code in this merge."
      before=$(git show "ORIG_HEAD:$tracker_path" 2>/dev/null \
        | awk '/^### Phase 2:/{f=1; next} f && /^### Phase /{f=0} f' \
        | grep -cE '^[[:space:]]*-[[:space:]]*\[[xX]\]')
      [ -z "$before" ] && before=0
      after=$(awk '/^### Phase 2:/{f=1; next} f && /^### Phase /{f=0} f' "$tracker_path" 2>/dev/null \
        | grep -cE '^[[:space:]]*-[[:space:]]*\[[xX]\]')
      [ -z "$after" ] && after=0

      if [ "$after" -le "$before" ]; then
        echo "  [skip] $dir: Phase 2 [x]-count $before -> $after (no shipped code in this merge)"
        continue
      fi

      if [ -x "$REPO_ROOT/scripts/check-gates-update.sh" ]; then
        "$REPO_ROOT/scripts/check-gates-update.sh" "$dir" 2>&1 | sed 's/^/  /' || \
          echo "  [WARN] check-gates-update.sh failed for $dir; run manually" >&2
      fi
    done <<< "$TOUCHED_TRACKERS"
  fi
fi

# Best-effort: always exit 0 to avoid blocking git operations.
exit 0
HOOK

chmod +x "$HOOK_DIR/post-merge"
echo "Post-merge hook installed at .git/hooks/post-merge"
echo "  - Pulls that change templates/skills/catalog/rules auto-redeploy ~/.claude/."
echo "  - Pulls on main that touch work-items/**/*_TRACKER.md auto-update Phase 3 gates."
