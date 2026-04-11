#!/usr/bin/env bash
# Ship a skill: validate, commit, and tag.
# Usage: ./scripts/skill-ship.sh <skill-name>

. "$(dirname "$0")/lib.sh"
init

if [ $# -ne 1 ]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 1
fi

SKILL_NAME="$1"
validate_skill_name "$SKILL_NAME"

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"

# Check for pre-existing staged changes (would sweep unrelated work)
if ! git diff --cached --quiet 2>/dev/null; then
  echo "ERROR: you have staged changes. Commit or unstage them before shipping a skill." >&2
  echo "  Run: git diff --cached --name-only" >&2
  exit 1
fi

# Gate: skill must pass checks
if ! "$REPO_ROOT/scripts/skill-check.sh" "$SKILL_NAME"; then
  echo "ERROR: skill-check failed. Fix issues before shipping." >&2
  exit 1
fi

# Read version for tag
VERSION=$(extract_frontmatter_version "$SKILL_FILE")
TAG_NAME="$SKILL_NAME-v$VERSION"

# Check tag doesn't already exist
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "ERROR: git tag '$TAG_NAME' already exists. Bump the version first." >&2
  echo "  Run: ./scripts/skill-version.sh $SKILL_NAME patch" >&2
  exit 1
fi

echo "=== Shipping $SKILL_NAME v$VERSION ==="
echo ""

# Show what will be committed
echo "Files to commit:"
git diff --name-only -- "skills/$SKILL_NAME/" "skills-catalog.json" 2>/dev/null
echo ""

# Stage skill files
git add "skills/$SKILL_NAME/" "skills-catalog.json"

# Regenerate README if generate-readme.sh exists (version appears in README table)
if [ -x "$REPO_ROOT/scripts/generate-readme.sh" ]; then
  "$REPO_ROOT/scripts/generate-readme.sh" > "$REPO_ROOT/README.md" 2>/dev/null
  git add README.md 2>/dev/null || true
fi

# Commit
git commit -m "feat(skill): ship $SKILL_NAME v$VERSION"

# Tag
git tag "$TAG_NAME"

echo ""
echo "=== Shipped $SKILL_NAME v$VERSION ==="
echo "  Commit: $(git rev-parse --short HEAD)"
echo "  Tag: $TAG_NAME"
echo ""
echo "Don't forget: git push && git push --tags"
