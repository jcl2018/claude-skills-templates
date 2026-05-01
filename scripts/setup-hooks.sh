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
# Runs repo-wide validation + per-skill checks for changed skills.

# 1. Repo-wide validation (orphans, catalog sync, dependencies)
./scripts/validate.sh || exit 1

# 2. Per-skill lifecycle checks for changed skills
CHANGED_SKILLS=$(git diff --cached --name-only | grep '^skills/' | sed 's|^skills/||' | cut -d/ -f1 | sort -u)
if [ -n "$CHANGED_SKILLS" ]; then
  SKILL_ERRORS=0
  for skill in $CHANGED_SKILLS; do
    if [ -f "skills/$skill/SKILL.md" ]; then
      if ! ./scripts/skill-check.sh "$skill"; then
        SKILL_ERRORS=$((SKILL_ERRORS + 1))
      fi
    fi
  done
  if [ "$SKILL_ERRORS" -gt 0 ]; then
    echo "ERROR: $SKILL_ERRORS skill(s) failed lifecycle checks" >&2
    exit 1
  fi
fi
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "Pre-commit hook installed at .git/hooks/pre-commit"
echo "Commits will now run validate.sh + per-skill lifecycle checks."

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
