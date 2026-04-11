#!/usr/bin/env bash
# One-time migration: add DESIGN.md, CHANGELOG.md, and version field to existing skills.
# Idempotent — safe to run multiple times.
# Usage: ./scripts/skill-migrate.sh

. "$(dirname "$0")/lib.sh"
init

TEMPLATE="$TEMPLATES_DIR/doc-SKILL-DESIGN.md"
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: template not found: $TEMPLATE" >&2
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
MIGRATED=0
SKIPPED=0

echo "=== Skill Migration ==="

for SKILL_NAME in $(jq -r '.[].name' "$CATALOG"); do
  SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
  DESIGN_FILE="$SKILLS_DIR/$SKILL_NAME/DESIGN.md"
  CHANGELOG_FILE="$SKILLS_DIR/$SKILL_NAME/CHANGELOG.md"

  [ -f "$SKILL_FILE" ] || continue

  echo ""
  echo "--- $SKILL_NAME ---"
  CHANGED=0

  # 1. Create DESIGN.md if missing
  if [ ! -f "$DESIGN_FILE" ]; then
    # Extract description from frontmatter for Purpose
    DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep '^description:' | head -1 | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")

    # Extract first non-frontmatter paragraph for Behavior
    BODY=$(awk '/^---$/{fm++; next} fm>=2{print}' "$SKILL_FILE" | sed '/^$/d' | head -5)

    sed -e "s/{name}/$SKILL_NAME/g" -e "s/{date}/$TODAY/g" "$TEMPLATE" > "$DESIGN_FILE"

    # Replace Purpose placeholder
    if [ -n "$DESC" ] && [ "$DESC" != "TODO: describe what this skill does" ]; then
      sed -i '' "s|What problem does this skill solve? Who uses it and when?|$DESC (retroactively documented)|" "$DESIGN_FILE" 2>/dev/null || \
      sed -i "s|What problem does this skill solve? Who uses it and when?|$DESC (retroactively documented)|" "$DESIGN_FILE"
    fi

    # Replace Behavior placeholder
    if [ -n "$BODY" ]; then
      sed -i '' "s|What does the skill do, step by step?.*|See SKILL.md for full behavior. (retroactively documented)|" "$DESIGN_FILE" 2>/dev/null || \
      sed -i "s|What does the skill do, step by step?.*|See SKILL.md for full behavior. (retroactively documented)|" "$DESIGN_FILE"
    fi

    echo "  Created DESIGN.md"
    CHANGED=1
  else
    echo "  DESIGN.md already exists, skipping"
  fi

  # 2. Create CHANGELOG.md if missing
  if [ ! -f "$CHANGELOG_FILE" ]; then
    cat > "$CHANGELOG_FILE" << EOF
# Changelog: $SKILL_NAME

## [0.1.0] - $TODAY
### Added
- Initial version (retroactively documented)
EOF
    echo "  Created CHANGELOG.md"
    CHANGED=1
  else
    echo "  CHANGELOG.md already exists, skipping"
  fi

  # 3. Add version field to frontmatter if missing
  if ! sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | grep -q '^version:'; then
    # Insert version: 0.1.0 after description line in frontmatter
    awk '
      /^---$/ { fm++; print; next }
      fm == 1 && /^description:/ { print; getline; if ($0 !~ /^version:/) print "version: 0.1.0"; print; next }
      { print }
    ' "$SKILL_FILE" > "$SKILL_FILE.tmp"
    mv "$SKILL_FILE.tmp" "$SKILL_FILE"
    echo "  Added version: 0.1.0 to SKILL.md frontmatter"
    CHANGED=1
  else
    echo "  version field already exists, skipping"
  fi

  if [ "$CHANGED" -eq 1 ]; then
    MIGRATED=$((MIGRATED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo ""
echo "=== Migration Summary ==="
echo "  Migrated: $MIGRATED skill(s)"
echo "  Skipped (already up to date): $SKIPPED skill(s)"
