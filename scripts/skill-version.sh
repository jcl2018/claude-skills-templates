#!/usr/bin/env bash
# Bump a skill's version. Updates SKILL.md frontmatter, catalog, and CHANGELOG.md.
# Usage: ./scripts/skill-version.sh <skill-name> <major|minor|patch>

. "$(dirname "$0")/lib.sh"
init

if [ $# -ne 2 ]; then
  echo "Usage: $0 <skill-name> <major|minor|patch>" >&2
  exit 1
fi

SKILL_NAME="$1"
BUMP_TYPE="$2"
validate_skill_name "$SKILL_NAME"

case "$BUMP_TYPE" in
  major|minor|patch) ;;
  *) echo "ERROR: bump type must be major, minor, or patch (got: '$BUMP_TYPE')" >&2; exit 1 ;;
esac

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
CHANGELOG_FILE="$SKILLS_DIR/$SKILL_NAME/CHANGELOG.md"

# Gate: skill must pass checks first
if ! "$REPO_ROOT/scripts/skill-check.sh" "$SKILL_NAME"; then
  echo "ERROR: skill-check failed. Fix issues before bumping version." >&2
  exit 1
fi

# Read current version
CURRENT=$(extract_frontmatter_version "$SKILL_FILE")
if ! validate_version_string "$CURRENT"; then
  exit 1
fi

# Compute new version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Bumping $SKILL_NAME: $CURRENT -> $NEW_VERSION ($BUMP_TYPE)"

# Rollback support: backup files before mutation
cp "$SKILL_FILE" "$SKILL_FILE.bak"
cp "$CATALOG" "$CATALOG.bak"
cp "$CHANGELOG_FILE" "$CHANGELOG_FILE.bak"

rollback() {
  echo "ERROR: version bump failed, rolling back..." >&2
  [ -f "$SKILL_FILE.bak" ] && mv "$SKILL_FILE.bak" "$SKILL_FILE"
  [ -f "$CATALOG.bak" ] && mv "$CATALOG.bak" "$CATALOG"
  [ -f "$CHANGELOG_FILE.bak" ] && mv "$CHANGELOG_FILE.bak" "$CHANGELOG_FILE"
}
trap rollback ERR

# 1. Update SKILL.md frontmatter (sed within frontmatter block only)
# Use awk to only replace version within the frontmatter delimiters
awk -v new="$NEW_VERSION" '
  /^---$/ { fm++; print; next }
  fm == 1 && /^version:/ { print "version: " new; next }
  { print }
' "$SKILL_FILE.bak" > "$SKILL_FILE"

# 2. Update catalog
jq --arg name "$SKILL_NAME" --arg ver "$NEW_VERSION" \
  'map(if .name == $name then .version = $ver else . end)' \
  "$CATALOG.bak" > "$CATALOG"

# 3. Add new version header to CHANGELOG.md
TODAY=$(date +%Y-%m-%d)
NEW_HEADER="## [$NEW_VERSION] - $TODAY"
# Insert after the first line (# Changelog: ...) and any blank lines
awk -v header="$NEW_HEADER" '
  NR == 1 { print; next }
  !inserted && /^## \[/ { print header; print "### Changed"; print "- "; print ""; inserted=1 }
  { print }
  END { if (!inserted) { print ""; print header; print "### Changed"; print "- " } }
' "$CHANGELOG_FILE.bak" > "$CHANGELOG_FILE"

# Cleanup backups on success
rm -f "$SKILL_FILE.bak" "$CATALOG.bak" "$CHANGELOG_FILE.bak"
trap - ERR

echo ""
echo "  Updated skills/$SKILL_NAME/SKILL.md: version: $NEW_VERSION"
echo "  Updated skills-catalog.json: $SKILL_NAME version: $NEW_VERSION"
echo "  Updated skills/$SKILL_NAME/CHANGELOG.md: added ## [$NEW_VERSION]"
echo ""
echo "Next steps:"
echo "  1. Fill in the CHANGELOG.md entry for $NEW_VERSION"
echo "  2. Run ./scripts/skill-ship.sh $SKILL_NAME to commit and tag"
