#!/usr/bin/env bash
# Scaffold a new skill with SKILL.md, doc triplet, and catalog entry.
# Usage: ./scripts/create-skill.sh my-new-skill

. "$(dirname "$0")/lib.sh"
init

if [ $# -ne 1 ]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 1
fi

SKILL_NAME="$1"
validate_skill_name "$SKILL_NAME"

# Check if SKILL.md already exists (directory may exist from skill-design.sh)
if [ -f "$SKILLS_DIR/$SKILL_NAME/SKILL.md" ]; then
  echo "ERROR: SKILL.md already exists: skills/$SKILL_NAME/SKILL.md" >&2
  exit 1
fi

# Check DESIGN.md exists (must run skill-design.sh first)
if [ ! -f "$SKILLS_DIR/$SKILL_NAME/DESIGN.md" ]; then
  echo "ERROR: DESIGN.md not found. Run skill-design.sh first:" >&2
  echo "  ./scripts/skill-design.sh $SKILL_NAME" >&2
  exit 1
fi

if jq -e --arg name "$SKILL_NAME" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
  echo "ERROR: skill '$SKILL_NAME' already exists in skills-catalog.json" >&2
  exit 1
fi

# Cleanup on failure (preserve DESIGN.md since it was created separately)
cleanup() {
  rm -f "$SKILLS_DIR/$SKILL_NAME/SKILL.md" "$SKILLS_DIR/$SKILL_NAME/CHANGELOG.md"
  # Restore catalog if we modified it
  if [ -f "$CATALOG.bak" ]; then
    mv "$CATALOG.bak" "$CATALOG"
  fi
}
trap cleanup ERR

# Create SKILL.md skeleton (directory already exists from skill-design.sh)
cat > "$SKILLS_DIR/$SKILL_NAME/SKILL.md" << EOF
---
name: $SKILL_NAME
description: "TODO: describe what this skill does"
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# /$SKILL_NAME

TODO: Add skill instructions here.
EOF

echo "  Created skills/$SKILL_NAME/SKILL.md"

# Create CHANGELOG.md
TODAY=$(date +%Y-%m-%d)
cat > "$SKILLS_DIR/$SKILL_NAME/CHANGELOG.md" << EOF
# Changelog: $SKILL_NAME

## [0.1.0] - $TODAY
### Added
- Initial implementation
EOF

echo "  Created skills/$SKILL_NAME/CHANGELOG.md"

# Append catalog entry
cp "$CATALOG" "$CATALOG.bak"
jq --arg name "$SKILL_NAME" \
  '. + [{
    name: $name,
    version: "0.1.0",
    description: "TODO: describe what this skill does",
    source: "local",
    depends: { skills: [], tools: [] },
    portability: "standalone",
    files: ["skills/\($name)/SKILL.md"],
    templates: ["doc-PRD.md", "doc-ARCHITECTURE.md", "doc-TEST-SPEC.md"],
    status: "experimental"
  }]' "$CATALOG.bak" > "$CATALOG"
rm -f "$CATALOG.bak"

echo "  Added '$SKILL_NAME' to skills-catalog.json"
echo ""
echo "Skill '$SKILL_NAME' created successfully!"
echo "Next steps:"
echo "  1. Edit skills/$SKILL_NAME/SKILL.md with your skill instructions"
echo "  2. Run ./scripts/skill-check.sh $SKILL_NAME to validate"
echo "  3. Run ./scripts/skill-version.sh $SKILL_NAME patch to bump when ready"
