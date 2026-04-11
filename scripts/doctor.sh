#!/usr/bin/env bash
# Skill health diagnostics. Advisory tool — always exits 0.
# Checks for quality issues that validate.sh intentionally skips.

. "$(dirname "$0")/lib.sh"
init

ISSUES=0

issue() {
  local severity="$1"
  shift
  echo "  [$severity] $*"
  ISSUES=$((ISSUES + 1))
}

info() { echo "  OK: $1"; }

echo "=== Skill Health Check ==="

# Check 1: SKILL.md description length (should be one line for /help rendering)
echo ""
echo "Checking description lengths..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  [ -f "$skill_file" ] || continue
  desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | sed 's/^description: *//' | sed 's/^"//;s/"$//')
  if [ ${#desc} -gt 120 ]; then
    issue "WARNING" "$name: description is ${#desc} chars (>120), may not render well in /help"
  else
    info "$name description length OK (${#desc} chars)"
  fi
done

# Check 2: Missing allowed-tools frontmatter (security risk)
echo ""
echo "Checking allowed-tools frontmatter..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  [ -f "$skill_file" ] || continue
  if sed -n '/^---$/,/^---$/p' "$skill_file" | grep -q 'allowed-tools:'; then
    info "$name has allowed-tools defined"
  else
    issue "WARNING" "$name: no allowed-tools frontmatter (skill has unrestricted tool access)"
  fi
done

# Check 3: Template references to nonexistent files
echo ""
echo "Checking template file references..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  for f in $(jq -r --arg name "$name" '.[] | select(.name == $name) | .files[]' "$CATALOG"); do
    if [ -f "$REPO_ROOT/$f" ]; then
      info "$name file $f exists"
    else
      issue "ERROR" "$name: listed file $f does not exist on disk"
    fi
  done
done

# Check 4: Version staleness (SKILL.md modified since catalog version set)
echo ""
echo "Checking version staleness..."
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for name in $(jq -r '.[].name' "$CATALOG"); do
    skill_file="skills/$name/SKILL.md"
    [ -f "$REPO_ROOT/$skill_file" ] || continue
    version=$(jq -r --arg name "$name" '.[] | select(.name == $name) | .version' "$CATALOG")
    if [ "$version" = "0.1.0" ]; then
      # Check if file has been modified (any commits touching it)
      commits=$(git log --oneline -- "$skill_file" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$commits" -gt 1 ]; then
        issue "WARNING" "$name: version is still 0.1.0 but SKILL.md has $commits commits"
      else
        info "$name version OK"
      fi
    else
      info "$name version $version"
    fi
  done
else
  echo "  Skipping version staleness check (not in a git repo)"
fi

# Summary
echo ""
echo "=== Health Check Summary ==="
echo "  Issues found: $ISSUES"
echo "  (This is advisory — all issues are suggestions, not failures)"
exit 0
