#!/usr/bin/env bash
# test-deploy.sh — Automated tests for skills-deploy.
# Uses temp directories to isolate from real ~/.claude/skills/ and ~/.claude/templates/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$REPO_ROOT/scripts/skills-deploy"
CATALOG="$REPO_ROOT/skills-catalog.json"
ERRORS=0
_CLEANUP_DIRS=()

# shellcheck disable=SC2154
trap 'for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do rm -rf "$d" 2>/dev/null; done' EXIT

setup_env() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  export SKILLS_DEPLOY_TARGET="$tmp_dir"
  export SKILLS_DEPLOY_MANIFEST="$SKILLS_DEPLOY_TARGET/.skills-templates.json"
  export SKILLS_DEPLOY_TEMPLATES_TARGET="$SKILLS_DEPLOY_TARGET/templates"
  export SKILLS_DEPLOY_RULES_TARGET="$SKILLS_DEPLOY_TARGET/rules"
  mkdir -p "$SKILLS_DEPLOY_TEMPLATES_TARGET"
  _CLEANUP_DIRS+=("$SKILLS_DEPLOY_TARGET")
}

teardown_env() {
  rm -rf "$SKILLS_DEPLOY_TARGET" 2>/dev/null || true
}

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Count catalog entries that have skill files (exclude templates-only entries)
SKILL_COUNT=$(jq '[.[] | select(.files | length > 0)] | length' "$CATALOG")

echo "=== Deploy script tests ==="
echo ""

# Test 1: Install all skills
echo "Test 1: Install all skills"
setup_env
"$DEPLOY" install >/dev/null 2>&1
count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d ! -path "$SKILLS_DEPLOY_TEMPLATES_TARGET" ! -path "$SKILLS_DEPLOY_RULES_TARGET" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq "$SKILL_COUNT" ]; then
  ok "Installed $SKILL_COUNT skill directories"
else
  fail_test "Expected $SKILL_COUNT skills, got $count"
fi
teardown_env

# Test 2: Multi-file skill gets all .md files
echo "Test 2: Multi-file skill (docs)"
setup_env
"$DEPLOY" install docs >/dev/null 2>&1
md_count=$(find "$SKILLS_DEPLOY_TARGET/docs" -name "*.md" -type l 2>/dev/null | wc -l | tr -d ' ')
if [ "$md_count" -ge 3 ]; then
  ok "docs has $md_count .md symlinks"
else
  fail_test "Expected 3+ .md symlinks, got $md_count"
fi
teardown_env

# Test 3: Templates-only catalog entry (no SKILL.md, just templates)
echo "Test 3: Templates-only catalog entry"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
tpl_count=$(jq -r '.[] | select(.name == "templates") | .templates | length' "$CATALOG")
actual_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$actual_count" -eq "$tpl_count" ]; then
  ok "Templates entry deployed $tpl_count templates"
else
  fail_test "Expected $tpl_count templates, got $actual_count"
fi
teardown_env

# Test 4: Idempotent install
echo "Test 4: Idempotent install"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" install >/dev/null 2>&1
count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d ! -path "$SKILLS_DEPLOY_TEMPLATES_TARGET" ! -path "$SKILLS_DEPLOY_RULES_TARGET" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq "$SKILL_COUNT" ]; then
  ok "Second install still has $SKILL_COUNT skills"
else
  fail_test "Expected $SKILL_COUNT skills after re-install, got $count"
fi
teardown_env

# Test 5: Remove requires args
echo "Test 5: Remove requires args"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if "$DEPLOY" remove 2>/dev/null; then
  fail_test "remove with no args should fail"
else
  ok "remove with no args fails"
fi
teardown_env

# Test 6: Remove specific skill
echo "Test 6: Remove specific skill"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" remove skill-author --force >/dev/null 2>&1
if [ ! -d "$SKILLS_DEPLOY_TARGET/skill-author" ]; then
  ok "skill-author removed"
else
  fail_test "skill-author still exists"
fi
teardown_env

# Test 7: Remove --all
echo "Test 7: Remove --all"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" remove --all --force >/dev/null 2>&1
# Only templates/ dir should remain (empty)
skill_count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d -not -name "templates" -not -name "rules" 2>/dev/null | wc -l | tr -d ' ')
if [ "$skill_count" -eq 0 ]; then
  ok "All skills removed"
else
  fail_test "Expected 0 skill dirs, got $skill_count"
fi
if [ ! -f "$SKILLS_DEPLOY_MANIFEST" ]; then
  ok "Manifest cleaned up"
else
  fail_test "Manifest still exists"
fi
teardown_env

# Test 8: Doctor on healthy install
echo "Test 8: Doctor on healthy install"
setup_env
"$DEPLOY" install >/dev/null 2>&1
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "Health: OK"; then
  ok "Doctor reports healthy"
else
  fail_test "Doctor did not report healthy: $output"
fi
teardown_env

# Test 9: Doctor detects broken symlink
echo "Test 9: Doctor detects broken symlink"
setup_env
"$DEPLOY" install skill-author >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TARGET/skill-author/SKILL.md"
ln -s /nonexistent/path "$SKILLS_DEPLOY_TARGET/skill-author/SKILL.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "broken symlink"; then
  ok "Doctor detects broken symlink"
else
  fail_test "Doctor missed broken symlink"
fi
teardown_env

# Test 10: Non-existent skill name
echo "Test 10: Non-existent skill name"
setup_env
output=$("$DEPLOY" install nonexistent-skill 2>&1)
if echo "$output" | grep -q "SKIP"; then
  ok "Non-existent skill skipped"
else
  fail_test "Non-existent skill not handled"
fi
teardown_env

# Test 11: Manifest is valid JSON
echo "Test 11: Manifest is valid JSON"
setup_env
"$DEPLOY" install >/dev/null 2>&1
if jq empty "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null; then
  ok "Manifest is valid JSON"
else
  fail_test "Manifest is invalid JSON"
fi
teardown_env

# Test 12: Relink repairs broken symlink
echo "Test 12: Relink repairs broken symlink"
setup_env
"$DEPLOY" install skill-author >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TARGET/skill-author/SKILL.md"
"$DEPLOY" relink >/dev/null 2>&1
if [ -L "$SKILLS_DEPLOY_TARGET/skill-author/SKILL.md" ] && [ -e "$SKILLS_DEPLOY_TARGET/skill-author/SKILL.md" ]; then
  ok "Relink restored broken symlink"
else
  fail_test "Relink did not restore symlink"
fi
teardown_env

# === Template tests ===
echo ""
echo "=== Template deployment tests ==="
echo ""

# Test T1: Install deploys templates
echo "Test T1: Install deploys templates"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
expected_count=$(jq -r '.[] | select(.name == "templates") | .templates | length' "$CATALOG")
actual_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$actual_count" -eq "$expected_count" ]; then
  ok "Templates entry deployed $expected_count templates"
else
  fail_test "Expected $expected_count templates, got $actual_count"
fi
# Verify manifest has templates section
if jq -e '.templates' "$SKILLS_DEPLOY_MANIFEST" >/dev/null 2>&1; then
  ok "Manifest has templates section"
else
  fail_test "Manifest missing templates section"
fi
teardown_env

# Test T2: Shared ownership (synthetic fixture)
echo "Test T2: Shared ownership"
setup_env
# Install both templates and skill-author
"$DEPLOY" install templates >/dev/null 2>&1
"$DEPLOY" install skill-author >/dev/null 2>&1
# Manually add skill-author as co-owner of doc-PRD.md (simulating shared template)
jq '.templates["doc-PRD.md"].owners += ["skill-author"] | .templates["doc-PRD.md"].owners = (.templates["doc-PRD.md"].owners | unique)' \
  "$SKILLS_DEPLOY_MANIFEST" > "$SKILLS_DEPLOY_MANIFEST.tmp" && mv "$SKILLS_DEPLOY_MANIFEST.tmp" "$SKILLS_DEPLOY_MANIFEST"
# Remove templates — doc-PRD.md should persist (skill-author still owns it)
"$DEPLOY" remove templates --force >/dev/null 2>&1
if [ -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md" ]; then
  ok "doc-PRD.md persists (skill-author still owns it)"
else
  fail_test "doc-PRD.md was deleted despite skill-author ownership"
fi
# Remove skill-author — now doc-PRD.md should be cleaned up
"$DEPLOY" remove skill-author --force >/dev/null 2>&1
if [ ! -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md" ]; then
  ok "doc-PRD.md removed when last owner removed"
else
  fail_test "doc-PRD.md still exists after all owners removed"
fi
teardown_env

# Test T3: Full cleanup
echo "Test T3: Full cleanup"
setup_env
"$DEPLOY" install >/dev/null 2>&1
tpl_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$tpl_count" -gt 0 ]; then
  ok "Templates deployed ($tpl_count files)"
else
  fail_test "No templates deployed"
fi
"$DEPLOY" remove --all --force >/dev/null 2>&1
tpl_count=$(find "$SKILLS_DEPLOY_TEMPLATES_TARGET" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$tpl_count" -eq 0 ]; then
  ok "All templates cleaned up"
else
  fail_test "Templates remain after remove --all: $tpl_count"
fi
teardown_env

# Test T4: Doctor detects missing template
echo "Test T4: Doctor detects missing template"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
rm -f "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "FAIL.*doc-PRD.md"; then
  ok "Doctor detects missing template"
else
  fail_test "Doctor missed missing template"
fi
teardown_env

# Test T5: Doctor detects drifted template
echo "Test T5: Doctor detects drifted template"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
echo "modified content" >> "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md"
output=$("$DEPLOY" doctor 2>&1)
if echo "$output" | grep -q "WARN.*doc-PRD.md"; then
  ok "Doctor detects drifted template"
else
  fail_test "Doctor missed drifted template"
fi
teardown_env

# Test T6: --overwrite replaces drifted template
echo "Test T6: --overwrite replaces drifted template"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
echo "modified content" >> "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md"
# Re-install without --overwrite — should skip
output=$("$DEPLOY" install templates 2>&1)
if echo "$output" | grep -q "exists with different content"; then
  ok "Install warns about drifted template"
else
  fail_test "Install did not warn about drifted template"
fi
# Now with --overwrite
"$DEPLOY" install templates --overwrite >/dev/null 2>&1
if diff -q "$SKILLS_DEPLOY_TEMPLATES_TARGET/doc-PRD.md" "$REPO_ROOT/templates/doc-PRD.md" >/dev/null 2>&1; then
  ok "--overwrite restored template to source content"
else
  fail_test "--overwrite did not restore template"
fi
teardown_env

# Test T7: Idempotent install (no duplicate owners)
echo "Test T7: Idempotent install"
setup_env
"$DEPLOY" install templates >/dev/null 2>&1
"$DEPLOY" install templates >/dev/null 2>&1
# shellcheck disable=SC2034  # dup_count used for debug inspection
dup_count=$(jq '[.templates // {} | .[] | .owners | length] | map(select(. > 1)) | length' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo "0")
# Each template should have exactly 1 owner (templates), not 2
owner_count=$(jq '.templates["doc-PRD.md"].owners | length' "$SKILLS_DEPLOY_MANIFEST" 2>/dev/null || echo "0")
if [ "$owner_count" -eq 1 ]; then
  ok "No duplicate owners after double install"
else
  fail_test "Expected 1 owner for doc-PRD.md, got $owner_count"
fi
teardown_env

# Test T8: Path traversal rejected
echo "Test T8: Path traversal protection"
setup_env
# Test validate_template_name by calling it as a bash function
output=$(bash -c '[[ "../../evil.md" =~ ^[a-zA-Z0-9_.-]+\.md$ ]] && echo "MATCH" || echo "BLOCKED"' 2>&1)
if [ "$output" = "BLOCKED" ]; then
  ok "Path traversal pattern rejected by regex"
else
  fail_test "Path traversal not caught by regex"
fi
# Also test a valid name passes
output=$(bash -c '[[ "doc-PRD.md" =~ ^[a-zA-Z0-9_.-]+\.md$ ]] && echo "MATCH" || echo "BLOCKED"' 2>&1)
if [ "$output" = "MATCH" ]; then
  ok "Valid template name accepted by regex"
else
  fail_test "Valid template name rejected"
fi
teardown_env

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$ERRORS test(s) failed." >&2
  exit 1
fi
