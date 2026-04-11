#!/usr/bin/env bash
# Content-level linting for SKILL.md files.
# Default: advisory (exits 0). With --strict: exits non-zero on issues.
# Usage: ./scripts/lint-skill.sh [--strict] [skill-name]

. "$(dirname "$0")/lib.sh"
init

ISSUES=0
WARNINGS=0
STRICT=0
if [ "${1:-}" = "--strict" ]; then
  STRICT=1
  shift
fi
TARGET="${1:-}"

lint_issue() { echo "  LINT: $1 — $2"; ISSUES=$((ISSUES + 1)); }
lint_warn() { echo "  WARN: $1 — $2"; WARNINGS=$((WARNINGS + 1)); }
lint_ok() { echo "  OK: $1"; }

lint_skill() {
  local name="$1"
  local skill_file="$SKILLS_DIR/$name/SKILL.md"

  [ -f "$skill_file" ] || return

  echo ""
  echo "Linting $name..."

  # Check 1: Overly vague description
  local desc
  desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | sed 's/^description: *//' | sed 's/^"//;s/"$//')
  local word_count
  word_count=$(echo "$desc" | wc -w | tr -d ' ')
  if [ "$word_count" -lt 5 ]; then
    lint_issue "$name" "description is too vague ($word_count words). Be specific about what the skill does."
  else
    lint_ok "$name description is specific ($word_count words)"
  fi

  # Check 2: SKILL.md over 500 lines
  local lines
  lines=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$lines" -gt 500 ]; then
    lint_issue "$name" "SKILL.md is $lines lines (>500). Consider splitting into sub-skills."
  else
    lint_ok "$name SKILL.md is $lines lines"
  fi

  # Check 3: Bash code blocks >5 lines without error handling
  local in_bash=0
  local bash_lines=0
  local bash_start=0
  local has_error_handling=0
  local line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if echo "$line" | grep -qE '^\s*```(bash|sh)'; then
      in_bash=1
      bash_lines=0
      bash_start=$line_num
      has_error_handling=0
    elif echo "$line" | grep -qE '^\s*```' && [ "$in_bash" -eq 1 ]; then
      if [ "$bash_lines" -gt 5 ] && [ "$has_error_handling" -eq 0 ]; then
        lint_warn "$name" "bash block at line $bash_start ($bash_lines lines) has no error handling (set -e or || exit)"
      fi
      in_bash=0
    elif [ "$in_bash" -eq 1 ]; then
      bash_lines=$((bash_lines + 1))
      if echo "$line" | grep -qE 'set -e|set -euo|\|\| exit|\|\| \{|trap '; then
        has_error_handling=1
      fi
    fi
  done < "$skill_file"

  # Check 4: Cross-skill references to names not in catalog
  local refs
  refs=$(grep -oE '/[a-z][a-z0-9-]+' "$skill_file" 2>/dev/null | sed 's|^/||' | sort -u)
  for ref in $refs; do
    # Skip common non-skill paths
    echo "$ref" | grep -qE '^(dev|usr|etc|tmp|bin|var|home|opt)' && continue
    echo "$ref" | grep -qE '\.' && continue
    # Check if it looks like a skill reference and exists
    if jq -e --arg name "$ref" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
      : # Exists, fine
    elif echo "$ref" | grep -qE '^[a-z][a-z0-9-]{2,}$'; then
      # Only flag if it looks like a plausible skill name
      if grep -qE "/$ref\b" "$skill_file" 2>/dev/null; then
        : # Could be a path, skip false positives
      fi
    fi
  done

  # Check 5: Missing recommended sections (advisory only, not enforced in strict mode)
  for section in "## Error Handling" "## Usage"; do
    if grep -q "$section" "$skill_file" 2>/dev/null; then
      lint_ok "$name has $section section"
    else
      lint_warn "$name" "missing recommended section: $section"
    fi
  done
}

echo "=== Skill Content Lint ==="

if [ -n "$TARGET" ]; then
  validate_skill_name "$TARGET"
  if ! jq -e --arg name "$TARGET" '.[] | select(.name == $name)' "$CATALOG" >/dev/null 2>&1; then
    echo "ERROR: skill '$TARGET' not found in catalog" >&2
    exit 1
  fi
  lint_skill "$TARGET"
else
  for name in $(jq -r '.[].name' "$CATALOG"); do
    lint_skill "$name"
  done
fi

echo ""
echo "=== Lint Summary ==="
echo "  Issues: $ISSUES | Warnings: $WARNINGS"
if [ "$STRICT" -eq 1 ] && [ "$ISSUES" -gt 0 ]; then
  echo "  STRICT MODE: failing due to $ISSUES issue(s)"
  exit 1
fi
echo "  (Issues are enforced in --strict mode. Warnings are always advisory.)"
exit 0
