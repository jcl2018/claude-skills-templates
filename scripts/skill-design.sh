#!/usr/bin/env bash
# Scaffold a DESIGN.md for a new skill.
# Usage: ./scripts/skill-design.sh my-new-skill

. "$(dirname "$0")/lib.sh"
init

if [ $# -ne 1 ]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 1
fi

SKILL_NAME="$1"
validate_skill_name "$SKILL_NAME"

DESIGN_FILE="$SKILLS_DIR/$SKILL_NAME/DESIGN.md"

if [ -f "$DESIGN_FILE" ]; then
  echo "ERROR: DESIGN.md already exists: skills/$SKILL_NAME/DESIGN.md" >&2
  exit 1
fi

TEMPLATE="$TEMPLATES_DIR/doc-SKILL-DESIGN.md"
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: template not found: $TEMPLATE" >&2
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

mkdir -p "$SKILLS_DIR/$SKILL_NAME"
sed -e "s/{name}/$SKILL_NAME/g" -e "s/{date}/$TODAY/g" "$TEMPLATE" > "$DESIGN_FILE"

echo "  Created skills/$SKILL_NAME/DESIGN.md"
echo ""
echo "Next steps:"
echo "  1. Fill in Purpose and Behavior sections (required)"
echo "  2. Fill in other sections as needed (N/A is OK for simple skills)"
echo "  3. Run ./scripts/create-skill.sh $SKILL_NAME to scaffold the skill"
