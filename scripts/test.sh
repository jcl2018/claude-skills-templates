#!/usr/bin/env bash
# Smoke tests for the skill workbench. Superset of validate.sh.
# Exit 0 = all tests pass. Exit 1 = one or more failures.

. "$(dirname "$0")/lib.sh"
init

ERRORS=0

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Ensure git user config exists (required for commit in CI environments)
if ! git config user.name >/dev/null 2>&1; then
  git config user.name "test"
  git config user.email "test@test.local"
fi

echo "=== Running validate.sh ==="
if "$REPO_ROOT/scripts/validate.sh"; then
  ok "validate.sh passed"
else
  fail_test "validate.sh failed"
fi

echo ""
echo "=== Additional smoke tests ==="

# Test: No duplicate skill names in catalog
echo ""
echo "Checking for duplicate skill names..."
dupes=$(jq -r '.[].name' "$CATALOG" | sort | uniq -d)
if [ -z "$dupes" ]; then
  ok "No duplicate skill names"
else
  fail_test "Duplicate skill names found: $dupes"
fi

# Test: All SKILL.md files have parseable frontmatter
echo ""
echo "Checking SKILL.md frontmatter parseability..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  skill_file="$SKILLS_DIR/$name/SKILL.md"
  [ -f "$skill_file" ] || continue
  # Check frontmatter exists between --- markers
  fm=$(sed -n '/^---$/,/^---$/p' "$skill_file")
  if echo "$fm" | grep -q 'name:' && echo "$fm" | grep -q 'description:'; then
    ok "$name frontmatter is parseable"
  else
    fail_test "$name SKILL.md frontmatter is not parseable"
  fi
done

# Test: Doc triplets have required sections
echo ""
echo "Checking doc triplet required sections..."
for name in $(jq -r '.[].name' "$CATALOG"); do
  doc_dir="$DOCS_DIR/$name"
  [ -d "$doc_dir" ] || continue

  if [ -f "$doc_dir/PRD.md" ]; then
    if grep -q '## Problem Statement' "$doc_dir/PRD.md" 2>/dev/null; then
      ok "$name PRD.md has ## Problem Statement"
    else
      fail_test "$name PRD.md missing ## Problem Statement section"
    fi
  fi

  if [ -f "$doc_dir/ARCHITECTURE.md" ]; then
    if grep -qE '## (Overview|Architecture)' "$doc_dir/ARCHITECTURE.md" 2>/dev/null; then
      ok "$name ARCHITECTURE.md has ## Overview or ## Architecture"
    else
      fail_test "$name ARCHITECTURE.md missing ## Overview or ## Architecture section"
    fi
  fi

  if [ -f "$doc_dir/TEST-SPEC.md" ]; then
    if grep -q '## Test Matrix' "$doc_dir/TEST-SPEC.md" 2>/dev/null; then
      ok "$name TEST-SPEC.md has ## Test Matrix"
    else
      fail_test "$name TEST-SPEC.md missing ## Test Matrix section"
    fi
  fi
done

# Test: Advisory scripts run without crashing
echo ""
echo "Smoke-testing advisory scripts..."

if "$REPO_ROOT/scripts/doctor.sh" >/dev/null 2>&1; then
  ok "doctor.sh runs without crash"
else
  fail_test "doctor.sh crashed"
fi

# lint-skill.sh exits non-zero on warnings (expected behavior, not a crash)
lint_output=$("$REPO_ROOT/scripts/lint-skill.sh" 2>&1) || true
if echo "$lint_output" | grep -q "Skill Content Lint"; then
  ok "lint-skill.sh runs without crash"
else
  fail_test "lint-skill.sh crashed (no output)"
fi

if deps_output=$("$REPO_ROOT/scripts/deps.sh" 2>&1); then
  if echo "$deps_output" | grep -q "docs\|system-health"; then
    ok "deps.sh runs and output contains known skills"
  else
    fail_test "deps.sh runs but output missing expected skill names"
  fi
else
  fail_test "deps.sh crashed"
fi

if "$REPO_ROOT/scripts/generate-readme.sh" >/dev/null 2>&1; then
  ok "generate-readme.sh runs without crash"
  # Idempotency check
  first=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  second=$("$REPO_ROOT/scripts/generate-readme.sh" 2>/dev/null)
  if [ "$first" = "$second" ]; then
    ok "generate-readme.sh is idempotent"
  else
    fail_test "generate-readme.sh produces different output on repeated runs"
  fi
else
  fail_test "generate-readme.sh crashed"
fi

# Integration test: catalog consistency after manual skill creation
echo ""
echo "Integration test: manual skill creation cycle..."

# Backup catalog for safe restore
cp "$CATALOG" "/tmp/catalog-backup-$$"
cp "$REPO_ROOT/README.md" "/tmp/readme-backup-$$"
[ -f "$REPO_ROOT/VERSION" ] && cp "$REPO_ROOT/VERSION" "/tmp/version-backup-$$"
[ -f "$REPO_ROOT/CHANGELOG.md" ] && cp "$REPO_ROOT/CHANGELOG.md" "/tmp/changelog-backup-$$"
trap 'cp "/tmp/catalog-backup-$$" "$CATALOG"; cp "/tmp/readme-backup-$$" "$REPO_ROOT/README.md"; [ -f "/tmp/version-backup-$$" ] && cp "/tmp/version-backup-$$" "$REPO_ROOT/VERSION"; [ -f "/tmp/changelog-backup-$$" ] && cp "/tmp/changelog-backup-$$" "$REPO_ROOT/CHANGELOG.md"; rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold" "/tmp/catalog-backup-$$" "/tmp/readme-backup-$$" "/tmp/version-backup-$$" "/tmp/changelog-backup-$$"' EXIT

# Step 1: manually create a skill directory + SKILL.md (the CLAUDE.md-guided way)
mkdir -p "$SKILLS_DIR/zzz-test-scaffold"
cat > "$SKILLS_DIR/zzz-test-scaffold/SKILL.md" << 'SKILLEOF'
---
name: zzz-test-scaffold
description: "Test skill for integration testing."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
---

# Test Skill

This is a test skill created by the integration test suite.
SKILLEOF

# Step 2: add catalog entry
jq '. + [{"name":"zzz-test-scaffold","version":"0.1.0","description":"Test skill for integration testing.","source":"local","depends":{"skills":[],"tools":[]},"portability":"standalone","files":["skills/zzz-test-scaffold/SKILL.md"],"templates":[],"status":"experimental"}]' "$CATALOG" > "/tmp/catalog-new-$$" && mv "/tmp/catalog-new-$$" "$CATALOG"

# Step 3: validate passes with the new skill
if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
  ok "validate.sh passes with manually created skill"
else
  fail_test "validate.sh fails after manual skill creation"
fi

# Step 4: frontmatter is parseable
fm=$(sed -n '/^---$/,/^---$/p' "$SKILLS_DIR/zzz-test-scaffold/SKILL.md")
if echo "$fm" | grep -q 'name:' && echo "$fm" | grep -q 'description:'; then
  ok "manually created skill has valid frontmatter"
else
  fail_test "manually created skill has invalid frontmatter"
fi

# Template content smoke tests (S000002 TEST-SPEC)
echo ""
echo "Checking tracker template content..."

# S1: No "reviewer noted" in any tracker
if grep -rl "reviewer noted" "$REPO_ROOT/templates/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'reviewer noted' still present in tracker templates"
else
  ok "No 'reviewer noted' in tracker templates"
fi

# S2: No "Linux branch" in any tracker
if grep -rl "Linux branch" "$REPO_ROOT/templates/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'Linux branch' still present in tracker templates"
else
  ok "No 'Linux branch' in tracker templates"
fi

# S3: No JIRA/TFS in any tracker
if grep -rl "JIRA\|TFS" "$REPO_ROOT/templates/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise references (JIRA/TFS) still present in tracker templates"
else
  ok "No JIRA/TFS references in tracker templates"
fi

# S4: No workflow_type in any tracker
if grep -rl "workflow_type" "$REPO_ROOT/templates/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Redundant field 'workflow_type' still present in tracker templates"
else
  ok "No workflow_type in tracker templates"
fi

# S6: Task total gate count <= feature total gate count (lighter lifecycle)
task_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/tracker-task.md" || true)
feat_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/tracker-feature.md" || true)
if [ "$task_total" -le "$feat_total" ] 2>/dev/null; then
  ok "Task total gates ($task_total) <= feature total gates ($feat_total)"
else
  fail_test "Task total gates ($task_total) > feature total gates ($feat_total)"
fi

# No review tracker template should exist in workbench templates
# (company-workflow/tracker-review.md is valid — it's a separate template set)
if [ -f "$REPO_ROOT/templates/tracker-review.md" ]; then
  fail_test "tracker-review.md should not exist (review type removed)"
else
  ok "No tracker-review.md (review type correctly removed)"
fi

# Portability test: company-workflow skill has zero gstack dependencies
echo ""
echo "Portability test: company-workflow standalone..."

if grep -q "gstack" "$REPO_ROOT/skills/company-workflow/SKILL.md" 2>/dev/null; then
  fail_test "company-workflow SKILL.md contains gstack references (should be standalone)"
else
  ok "company-workflow SKILL.md has zero gstack references"
fi

if grep -q "~/.gstack" "$REPO_ROOT/skills/company-workflow/SKILL.md" 2>/dev/null; then
  fail_test "company-workflow SKILL.md references ~/.gstack/ (should be standalone)"
else
  ok "company-workflow SKILL.md has no ~/.gstack/ paths"
fi

# Negative test: create orphan directory, verify validate catches it
echo ""
echo "Negative test: orphan directory detection..."
mkdir -p "$SKILLS_DIR/zzz-test-orphan"
if "$REPO_ROOT/scripts/validate.sh" >/dev/null 2>&1; then
  fail_test "validate.sh should have detected orphan zzz-test-orphan but passed"
else
  ok "validate.sh correctly detected orphan directory"
fi
rmdir "$SKILLS_DIR/zzz-test-orphan"

# Summary
echo ""
echo "=== Test Summary ==="
echo "  Failures: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi
