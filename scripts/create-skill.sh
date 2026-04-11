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

# Check if skill already exists
if [ -d "$SKILLS_DIR/$SKILL_NAME" ]; then
  echo "ERROR: skill directory already exists: skills/$SKILL_NAME" >&2
  exit 1
fi

if jq -e --arg name "$SKILL_NAME" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
  echo "ERROR: skill '$SKILL_NAME' already exists in skills-catalog.json" >&2
  exit 1
fi

# Cleanup on failure
cleanup() {
  rm -rf "$SKILLS_DIR/$SKILL_NAME" "$DOCS_DIR/$SKILL_NAME"
  # Restore catalog if we modified it
  if [ -f "$CATALOG.bak" ]; then
    mv "$CATALOG.bak" "$CATALOG"
  fi
}
trap cleanup ERR

# Create skill directory with SKILL.md skeleton
mkdir -p "$SKILLS_DIR/$SKILL_NAME"
cat > "$SKILLS_DIR/$SKILL_NAME/SKILL.md" << EOF
---
name: $SKILL_NAME
description: "TODO: describe what this skill does"
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

# Create doc triplet from templates
mkdir -p "$DOCS_DIR/$SKILL_NAME"

for tmpl in doc-PRD.md doc-ARCHITECTURE.md doc-TEST-SPEC.md; do
  src="$TEMPLATES_DIR/$tmpl"
  # Derive output name: doc-PRD.md -> PRD.md
  dest_name="${tmpl#doc-}"
  if [ -f "$src" ]; then
    cp "$src" "$DOCS_DIR/$SKILL_NAME/$dest_name"
    echo "  Created docs/$SKILL_NAME/$dest_name"
  else
    echo "  WARNING: template $tmpl not found, skipping" >&2
  fi
done

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
echo "  2. Fill in docs/$SKILL_NAME/PRD.md, ARCHITECTURE.md, TEST-SPEC.md"
echo "  3. Run ./scripts/validate.sh to verify"
