#!/usr/bin/env bash
# Install pre-commit hook that runs validate.sh.
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
