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
# Auto-installed by scripts/setup-hooks.sh (D000013).
# After every git merge/pull, re-deploy skills + templates if relevant files changed.
# Closes D000012 Option C2: deploy is the per-machine sync-up. Templates are ready
# at ~/.claude/ before the next skill invocation needs them.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && exit 0

CHANGED=$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD 2>/dev/null \
  | grep -E '^(templates/|skills/|skills-catalog\.json|rules/)' || true)
[ -z "$CHANGED" ] && exit 0

echo "[skills-deploy] templates/skills/catalog/rules changed — re-deploying..."
"$REPO_ROOT/scripts/skills-deploy" install --overwrite
HOOK

chmod +x "$HOOK_DIR/post-merge"
echo "Post-merge hook installed at .git/hooks/post-merge"
echo "Pulls that change templates/skills/catalog/rules will now auto-redeploy ~/.claude/."
