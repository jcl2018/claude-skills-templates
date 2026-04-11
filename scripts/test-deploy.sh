#!/usr/bin/env bash
# test-deploy.sh — Automated tests for skills-deploy.
# Uses temp directories to isolate from real ~/.claude/skills/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY="$REPO_ROOT/scripts/skills-deploy"
ERRORS=0
_CLEANUP_DIRS=()

trap 'for d in "${_CLEANUP_DIRS[@]+"${_CLEANUP_DIRS[@]}"}"; do rm -rf "$d" 2>/dev/null; done' EXIT

setup_env() {
  export SKILLS_DEPLOY_TARGET=$(mktemp -d)
  export SKILLS_DEPLOY_MANIFEST="$SKILLS_DEPLOY_TARGET/.skills-templates.json"
  _CLEANUP_DIRS+=("$SKILLS_DEPLOY_TARGET")
}

teardown_env() {
  rm -rf "$SKILLS_DEPLOY_TARGET" 2>/dev/null || true
}

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

echo "=== Deploy script tests ==="
echo ""

# Test 1: Install all skills
echo "Test 1: Install all skills"
setup_env
"$DEPLOY" install >/dev/null 2>&1
count=$(ls -d "$SKILLS_DEPLOY_TARGET"/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq 9 ]; then
  ok "Installed 9 skill directories"
else
  fail_test "Expected 9 skills, got $count"
fi
teardown_env

# Test 2: Multi-file skill gets all .md files
echo "Test 2: Multi-file skill (align-feature-contract)"
setup_env
"$DEPLOY" install align-feature-contract >/dev/null 2>&1
md_count=$(find "$SKILLS_DEPLOY_TARGET/align-feature-contract" -name "*.md" -type l 2>/dev/null | wc -l | tr -d ' ')
if [ "$md_count" -ge 5 ]; then
  ok "align-feature-contract has $md_count .md symlinks"
else
  fail_test "Expected 5+ .md symlinks, got $md_count"
fi
teardown_env

# Test 3: Dependency resolution (work -> 4 deps)
echo "Test 3: Dependency resolution"
setup_env
"$DEPLOY" install work >/dev/null 2>&1
for dep in work-track work-implement work-review work-ship; do
  if [ -d "$SKILLS_DEPLOY_TARGET/$dep" ]; then
    ok "Dependency $dep installed"
  else
    fail_test "Dependency $dep missing"
  fi
done
teardown_env

# Test 4: Idempotent install
echo "Test 4: Idempotent install"
setup_env
"$DEPLOY" install >/dev/null 2>&1
"$DEPLOY" install >/dev/null 2>&1
count=$(ls -d "$SKILLS_DEPLOY_TARGET"/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq 9 ]; then
  ok "Second install still has 9 skills"
else
  fail_test "Expected 9 skills after re-install, got $count"
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
count=$(find "$SKILLS_DEPLOY_TARGET" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -eq 0 ]; then
  ok "All skills removed"
else
  fail_test "Expected 0 skills, got $count"
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
  fail_test "Doctor did not report healthy"
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

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$ERRORS test(s) failed." >&2
  exit 1
fi
