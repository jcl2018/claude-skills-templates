#!/usr/bin/env bash
# Single source of all per-skill validation.
# Usage: ./scripts/skill-check.sh <skill-name>

. "$(dirname "$0")/lib.sh"
init

if [ $# -ne 1 ]; then
  echo "Usage: $0 <skill-name>" >&2
  exit 1
fi

SKILL_NAME="$1"
validate_skill_name "$SKILL_NAME"

SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
DESIGN_FILE="$SKILLS_DIR/$SKILL_NAME/DESIGN.md"
CHANGELOG_FILE="$SKILLS_DIR/$SKILL_NAME/CHANGELOG.md"

ERRORS=0

check_fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
check_ok() { echo "  OK: $1"; }

echo "=== Skill Check: $SKILL_NAME ==="

# 1. DESIGN.md exists
if [ -f "$DESIGN_FILE" ]; then
  check_ok "DESIGN.md exists"

  # 1a. Purpose section is non-empty
  PURPOSE_CONTENT=$(sed -n '/^## Purpose$/,/^## /p' "$DESIGN_FILE" | grep -v '^## ' | grep -v '^$' | head -1)
  if [ -z "$PURPOSE_CONTENT" ] || echo "$PURPOSE_CONTENT" | grep -q "What problem does this skill solve"; then
    check_fail "DESIGN.md Purpose section is empty or template placeholder"
  else
    check_ok "DESIGN.md Purpose section has content"
  fi

  # 1b. Behavior section is non-empty
  BEHAVIOR_CONTENT=$(sed -n '/^## Behavior$/,/^## /p' "$DESIGN_FILE" | grep -v '^## ' | grep -v '^$' | head -1)
  if [ -z "$BEHAVIOR_CONTENT" ] || echo "$BEHAVIOR_CONTENT" | grep -q "What does the skill do"; then
    check_fail "DESIGN.md Behavior section is empty or template placeholder"
  else
    check_ok "DESIGN.md Behavior section has content"
  fi
else
  check_fail "DESIGN.md missing: skills/$SKILL_NAME/DESIGN.md"
fi

# 2. SKILL.md exists and has valid frontmatter
if [ -f "$SKILL_FILE" ]; then
  check_ok "SKILL.md exists"

  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE")

  if echo "$FRONTMATTER" | grep -q '^name:'; then
    check_ok "frontmatter has name field"
  else
    check_fail "SKILL.md missing 'name:' in frontmatter"
  fi

  if echo "$FRONTMATTER" | grep -q '^description:'; then
    check_ok "frontmatter has description field"
  else
    check_fail "SKILL.md missing 'description:' in frontmatter"
  fi

  if echo "$FRONTMATTER" | grep -q '^version:'; then
    check_ok "frontmatter has version field"

    # 2a. Version format is valid
    SKILL_VERSION=$(extract_frontmatter_version "$SKILL_FILE")
    if validate_version_string "$SKILL_VERSION" 2>/dev/null; then
      check_ok "version format valid: $SKILL_VERSION"

      # 2b. Version matches catalog
      CATALOG_VERSION=$(jq -r --arg name "$SKILL_NAME" '.[] | select(.name == $name) | .version' "$CATALOG")
      if [ "$SKILL_VERSION" = "$CATALOG_VERSION" ]; then
        check_ok "version matches catalog: $SKILL_VERSION"
      else
        check_fail "version mismatch: SKILL.md=$SKILL_VERSION, catalog=$CATALOG_VERSION"
      fi
    else
      check_fail "invalid version format: '$SKILL_VERSION' (expected X.Y.Z)"
    fi
  else
    check_fail "SKILL.md missing 'version:' in frontmatter"
  fi
else
  check_fail "SKILL.md missing: skills/$SKILL_NAME/SKILL.md"
fi

# 3. CHANGELOG.md exists and has entry for current version
if [ -f "$CHANGELOG_FILE" ]; then
  check_ok "CHANGELOG.md exists"

  if [ -n "${SKILL_VERSION:-}" ]; then
    if grep -qF "## [$SKILL_VERSION]" "$CHANGELOG_FILE"; then
      check_ok "CHANGELOG.md has entry for version $SKILL_VERSION"
    else
      check_fail "CHANGELOG.md missing entry for version $SKILL_VERSION (expected '## [$SKILL_VERSION]')"
    fi
  fi
else
  check_fail "CHANGELOG.md missing: skills/$SKILL_NAME/CHANGELOG.md"
fi

# 4. Skill exists in catalog
if jq -e --arg name "$SKILL_NAME" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
  check_ok "skill exists in catalog"
else
  check_fail "skill '$SKILL_NAME' not found in skills-catalog.json"
fi

# 5. Lint check (strict mode)
if [ -f "$SKILL_FILE" ]; then
  if "$REPO_ROOT/scripts/lint-skill.sh" --strict "$SKILL_NAME" >/dev/null 2>&1; then
    check_ok "lint check passes"
  else
    check_fail "lint check failed (run: ./scripts/lint-skill.sh $SKILL_NAME)"
  fi
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "=== FAILED: $ERRORS error(s) ==="
  exit 1
else
  echo "=== PASSED ==="
  exit 0
fi
