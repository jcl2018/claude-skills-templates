#!/usr/bin/env bash
# Ship a skill: validate, commit, tag, and bump collection version.
# Usage: ./scripts/skill-ship.sh <skill-name> [--no-collection-bump]

. "$(dirname "$0")/lib.sh"
init

COLLECTION_BUMP=true
SKILL_NAME=""

for arg in "$@"; do
  case "$arg" in
    --no-collection-bump) COLLECTION_BUMP=false ;;
    *) SKILL_NAME="$arg" ;;
  esac
done

if [ -z "$SKILL_NAME" ]; then
  echo "Usage: $0 <skill-name> [--no-collection-bump]" >&2
  exit 1
fi

validate_skill_name "$SKILL_NAME"

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"

# Check for pre-existing staged changes (would sweep unrelated work)
if ! git diff --cached --quiet 2>/dev/null; then
  echo "ERROR: you have staged changes. Commit or unstage them before shipping a skill." >&2
  echo "  Fix: run 'git diff --cached --name-only' to see staged files, then commit or unstage them." >&2
  exit 1
fi

# Pre-flight: VERSION file must exist and be valid for collection bump
if [ "$COLLECTION_BUMP" = true ]; then
  CURRENT_COLLECTION=$(read_version) || exit 1
  validate_version_string "$CURRENT_COLLECTION" || {
    echo "  Fix: ensure VERSION contains a valid semver string (e.g. 0.1.0)" >&2
    exit 1
  }
fi

# Gate: skill must pass checks
if ! "$REPO_ROOT/scripts/skill-check.sh" "$SKILL_NAME"; then
  echo "ERROR: skill-check failed. Fix issues before shipping." >&2
  echo "  Fix: run './scripts/skill-check.sh $SKILL_NAME' to see what's wrong." >&2
  exit 1
fi

# Read version for tag
VERSION=$(extract_frontmatter_version "$SKILL_FILE")
validate_version_string "$VERSION" || {
  echo "ERROR: skill '$SKILL_NAME' has invalid version in SKILL.md: '$VERSION'" >&2
  echo "  Fix: ensure SKILL.md frontmatter has 'version: X.Y.Z'" >&2
  exit 1
}
TAG_NAME="$SKILL_NAME-v$VERSION"

# Check skill tag doesn't already exist
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "ERROR: git tag '$TAG_NAME' already exists. Bump the version first." >&2
  echo "  Fix: run './scripts/skill-version.sh $SKILL_NAME patch'" >&2
  exit 1
fi

# Bump collection version (before commit, so VERSION is included)
COLLECTION_TAG=""
CHANGELOG_BAK=""
if [ "$COLLECTION_BUMP" = true ]; then
  # Save CHANGELOG for rollback
  CHANGELOG_BAK=$(mktemp "$REPO_ROOT/CHANGELOG.md.bak.XXXXXX")
  cp "$REPO_ROOT/CHANGELOG.md" "$CHANGELOG_BAK" 2>/dev/null || true

  # Rollback trap: restore VERSION + CHANGELOG on any failure after bump
  rollback_collection() {
    echo "Rolling back collection version bump..." >&2
    echo "$CURRENT_COLLECTION" > "$VERSION_FILE"
    [ -f "$CHANGELOG_BAK" ] && mv "$CHANGELOG_BAK" "$REPO_ROOT/CHANGELOG.md"
  }
  trap rollback_collection ERR

  NEW_COLLECTION=$("$REPO_ROOT/scripts/collection-version.sh" bump patch)
  COLLECTION_TAG="v$NEW_COLLECTION"

  # Check collection v-tag doesn't already exist
  if git tag -l "$COLLECTION_TAG" | grep -q "$COLLECTION_TAG"; then
    echo "ERROR: collection tag '$COLLECTION_TAG' already exists." >&2
    echo "  Fix: this usually means the VERSION was bumped but not tagged. Check 'git tag -l v*'." >&2
    rollback_collection
    trap - ERR
    exit 1
  fi
fi

echo "=== Shipping $SKILL_NAME v$VERSION ==="
if [ -n "$COLLECTION_TAG" ]; then
  echo "    Collection: $CURRENT_COLLECTION -> $NEW_COLLECTION"
fi
echo ""

# Stage skill files + collection version files (single commit)
git add "skills/$SKILL_NAME/" "skills-catalog.json"
if [ "$COLLECTION_BUMP" = true ]; then
  git add "$VERSION_FILE" "$REPO_ROOT/CHANGELOG.md"
fi

# Regenerate README if generate-readme.sh exists
if [ -x "$REPO_ROOT/scripts/generate-readme.sh" ]; then
  "$REPO_ROOT/scripts/generate-readme.sh" > "$REPO_ROOT/README.md" 2>/dev/null
  git add README.md 2>/dev/null || true
fi

# Single commit with both skill and collection version changes
if [ "$COLLECTION_BUMP" = true ]; then
  git commit -m "feat(skill): ship $SKILL_NAME v$VERSION (collection v$NEW_COLLECTION)"
else
  git commit -m "feat(skill): ship $SKILL_NAME v$VERSION"
fi

# Tags: skill tag + collection v-tag on the same commit
git tag "$TAG_NAME"
if [ -n "$COLLECTION_TAG" ]; then
  git tag "$COLLECTION_TAG"
fi

# Success: clean up rollback state
trap - ERR
rm -f "$CHANGELOG_BAK" 2>/dev/null

echo ""
echo "=== Shipped $SKILL_NAME v$VERSION ==="
echo "  Commit: $(git rev-parse --short HEAD)"
echo "  Skill tag: $TAG_NAME"
[ -n "$COLLECTION_TAG" ] && echo "  Collection tag: $COLLECTION_TAG"
echo ""
echo "Don't forget: git push && git push --tags"
