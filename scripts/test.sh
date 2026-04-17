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

  if [ -f "$doc_dir/feature-summary.md" ]; then
    fs_missing=""
    for sec in "## Scope" "## Success Criteria" "## Constituent User-Stories" "## Out-of-Scope"; do
      grep -q "$sec" "$doc_dir/feature-summary.md" 2>/dev/null || fs_missing="$fs_missing $sec"
    done
    if [ -z "$fs_missing" ]; then
      ok "$name feature-summary.md has all required sections (Scope, Success Criteria, Constituent User-Stories, Out-of-Scope)"
    else
      fail_test "$name feature-summary.md missing sections:$fs_missing"
    fi
  fi
done

# Smoke test for company-workflow's example-doc-feature-summary.md
EX_FS="$REPO_ROOT/skills/company-workflow/examples/example-doc-feature-summary.md"
if [ -f "$EX_FS" ]; then
  fs_missing=""
  for sec in "## Scope" "## Success Criteria" "## Constituent User-Stories" "## Out-of-Scope"; do
    grep -q "$sec" "$EX_FS" 2>/dev/null || fs_missing="$fs_missing $sec"
  done
  if [ -z "$fs_missing" ]; then
    ok "company-workflow example-doc-feature-summary.md has all required sections"
  else
    fail_test "company-workflow example-doc-feature-summary.md missing sections:$fs_missing"
  fi
fi

# Smoke test for fixtures/valid-feature-dir/feature-summary.md
FX_FS="$REPO_ROOT/skills/company-workflow/fixtures/valid-feature-dir/feature-summary.md"
if [ -f "$FX_FS" ]; then
  fs_missing=""
  for sec in "## Scope" "## Success Criteria" "## Constituent User-Stories" "## Out-of-Scope"; do
    grep -q "$sec" "$FX_FS" 2>/dev/null || fs_missing="$fs_missing $sec"
  done
  if [ -z "$fs_missing" ]; then
    ok "company-workflow valid-feature-dir/feature-summary.md has all required sections"
  else
    fail_test "company-workflow valid-feature-dir/feature-summary.md missing sections:$fs_missing"
  fi
fi

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
  if echo "$deps_output" | grep -q "personal-workflow\|system-health"; then
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
if grep -rl "reviewer noted" "$REPO_ROOT/templates/personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'reviewer noted' still present in personal tracker templates"
else
  ok "No 'reviewer noted' in personal tracker templates"
fi

# S2: No "Linux branch" in any personal tracker
if grep -rl "Linux branch" "$REPO_ROOT/templates/personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'Linux branch' still present in personal tracker templates"
else
  ok "No 'Linux branch' in personal tracker templates"
fi

# S3: No JIRA/TFS in any personal tracker
if grep -rl "JIRA\|TFS" "$REPO_ROOT/templates/personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise references (JIRA/TFS) still present in personal tracker templates"
else
  ok "No JIRA/TFS references in personal tracker templates"
fi

# S4: No workflow_type in any personal tracker
if grep -rl "workflow_type" "$REPO_ROOT/templates/personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Redundant field 'workflow_type' still present in personal tracker templates"
else
  ok "No workflow_type in personal tracker templates"
fi

# S6: Task total gate count <= feature total gate count (lighter lifecycle)
task_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/personal-workflow/tracker-task.md" || true)
feat_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/personal-workflow/tracker-feature.md" || true)
if [ "$task_total" -le "$feat_total" ] 2>/dev/null; then
  ok "Task total gates ($task_total) <= feature total gates ($feat_total)"
else
  fail_test "Task total gates ($task_total) > feature total gates ($feat_total)"
fi

# No review tracker template should exist in personal-workflow templates
# (company-workflow/tracker-review.md is valid — it's a separate template set)
if [ -f "$REPO_ROOT/templates/personal-workflow/tracker-review.md" ]; then
  fail_test "tracker-review.md should not exist in personal-workflow (review type is company-only)"
else
  ok "No tracker-review.md in personal-workflow (review type correctly absent)"
fi

# Personal-workflow template directory exists with expected count
pw_count=$(find "$REPO_ROOT/templates/personal-workflow" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$pw_count" -eq 10 ]; then
  ok "templates/personal-workflow/ contains $pw_count templates (expected 10)"
else
  fail_test "templates/personal-workflow/ contains $pw_count templates (expected 10)"
fi

# Personal-workflow catalog entry exists
if jq -e '.[] | select(.name == "personal-workflow")' "$CATALOG" >/dev/null 2>&1; then
  ok "personal-workflow catalog entry exists"
else
  fail_test "personal-workflow catalog entry missing from skills-catalog.json"
fi

# No stale /docs references in personal tracker templates
if grep -rl "/docs check\|/docs tree" "$REPO_ROOT/templates/personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Stale /docs references in personal tracker templates (should be /personal-workflow)"
else
  ok "No stale /docs references in personal tracker templates"
fi

# Portability test: personal-workflow skill has zero gstack dependencies
echo ""
echo "Portability test: personal-workflow standalone..."

if grep -q "gstack" "$REPO_ROOT/skills/personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "personal-workflow SKILL.md contains gstack references (should be standalone)"
else
  ok "personal-workflow SKILL.md has zero gstack references"
fi

# shellcheck disable=SC2088
if grep -q "~/.gstack" "$REPO_ROOT/skills/personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "personal-workflow SKILL.md references ~/.gstack/ (should be standalone)"
else
  ok "personal-workflow SKILL.md has no ~/.gstack/ paths"
fi

# Portability test: company-workflow skill has zero gstack dependencies
echo ""
echo "Portability test: company-workflow standalone..."

if grep -q "gstack" "$REPO_ROOT/skills/company-workflow/SKILL.md" 2>/dev/null; then
  fail_test "company-workflow SKILL.md contains gstack references (should be standalone)"
else
  ok "company-workflow SKILL.md has zero gstack references"
fi

# shellcheck disable=SC2088
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

# Regression test: Windows jq CRLF wrapper (D000005)
# Background: jq.exe on Windows writes output with CRLF line endings, which
# breaks template-name regexes and integer comparisons in bash. Each script
# that calls jq must either source lib.sh (which defines the wrapper) or
# define its own inline wrapper. This test guards against that wrapper
# silently disappearing in a future refactor.
echo ""
echo "Regression test (D000005): Windows jq CRLF wrapper present..."

# 1. lib.sh defines the wrapper
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/lib.sh"; then
  ok "scripts/lib.sh defines the jq() wrapper"
else
  fail_test "scripts/lib.sh is missing the jq() CRLF-stripping wrapper"
fi

# 2. skills-deploy defines its own wrapper (it does not source lib.sh)
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy defines the jq() wrapper"
else
  fail_test "scripts/skills-deploy is missing the jq() CRLF-stripping wrapper"
fi

# 3. test-deploy.sh defines its own wrapper (it does not source lib.sh)
if grep -qE '^jq\(\) \{ command jq "\$@" \| tr -d .{1,3}r.{1,3}; \}' "$REPO_ROOT/scripts/test-deploy.sh"; then
  ok "scripts/test-deploy.sh defines the jq() wrapper"
else
  fail_test "scripts/test-deploy.sh is missing the jq() CRLF-stripping wrapper"
fi

# 4. Behavior test: the wrapper strips CR when invoked from a script context
#    with `set -o pipefail`. Simulate by sourcing lib.sh then feeding jq input
#    whose output we then stringify and check for CR bytes.
crlf_probe=$(bash -c "set -euo pipefail; . '$REPO_ROOT/scripts/lib.sh'; printf '{\"n\":3}' | jq -r '.n'" 2>/dev/null | od -c | head -1)
if echo "$crlf_probe" | grep -q '\\r'; then
  fail_test "lib.sh jq wrapper did NOT strip CR (output contained \\r bytes)"
else
  ok "lib.sh jq wrapper output is CR-free"
fi

# 5. Pipefail-propagation test: jq -e must still return non-zero when the
#    expression is false, even through the tr pipe. Without `pipefail` active
#    (or with a naive wrapper), `if jq -e ... ` would always take the true
#    branch.
if bash -c "set -euo pipefail; . '$REPO_ROOT/scripts/lib.sh'; echo '{\"a\":1}' | jq -e '.b' >/dev/null 2>&1"; then
  fail_test "jq -e wrapper leaks true exit when expression is null (pipefail not respected)"
else
  ok "jq -e wrapper correctly propagates false exit through pipe"
fi

echo ""
echo "Regression test (D000006): company-workflow Phase 2 test-verification gates + scope contracts..."

# Phase 2 test-verification gates in all 4 company-workflow trackers
# Anchored on '^- [ ]' checkbox prefix + key tokens to survive minor reword but
# fail loudly on full removal of the gate line.
if grep -qE '^- \[ \].*test-plan\.md.*Pass' "$REPO_ROOT/templates/company-workflow/tracker-defect.md"; then
  ok "tracker-defect Phase 2 references test-plan verification"
else
  fail_test "tracker-defect.md is missing the test-plan.md Pass-verification Phase 2 gate"
fi

if grep -qE '^- \[ \].*test-plan\.md.*Pass' "$REPO_ROOT/templates/company-workflow/tracker-task.md"; then
  ok "tracker-task Phase 2 references test-plan verification"
else
  fail_test "tracker-task.md is missing the test-plan.md Pass-verification Phase 2 gate"
fi

if grep -qE '^- \[ \].*TEST-SPEC\.md.*Pass' "$REPO_ROOT/templates/company-workflow/tracker-user-story.md"; then
  ok "tracker-user-story Phase 2 references TEST-SPEC verification"
else
  fail_test "tracker-user-story.md is missing the TEST-SPEC.md Pass-verification Phase 2 gate"
fi

if grep -qE '^- \[ \].*child user-story.*TEST-SPEC.*Pass' "$REPO_ROOT/templates/company-workflow/tracker-feature.md"; then
  ok "tracker-feature Phase 2 has TEST-SPEC roll-up gate"
else
  fail_test "tracker-feature.md is missing the child user-story TEST-SPEC roll-up gate"
fi

# Scope comments in test-doc templates (both skills)
for tmpl in templates/company-workflow/doc-test-plan.md templates/personal-workflow/doc-test-plan.md; do
  if grep -q "ONE fix (defect) or ONE task" "$REPO_ROOT/$tmpl"; then
    ok "$tmpl has the test-plan scope comment"
  else
    fail_test "$tmpl is missing the test-plan scope comment"
  fi
done

for tmpl in templates/company-workflow/doc-TEST-SPEC.md templates/personal-workflow/doc-TEST-SPEC.md; do
  if grep -q "ENTIRE user story" "$REPO_ROOT/$tmpl"; then
    ok "$tmpl has the TEST-SPEC scope comment"
  else
    fail_test "$tmpl is missing the TEST-SPEC scope comment"
  fi
done

# Title generalization in company doc-test-plan
if grep -q "{Defect Name} — Regression Test Plan" "$REPO_ROOT/templates/company-workflow/doc-test-plan.md"; then
  fail_test "company doc-test-plan.md still uses defect-only title placeholder; expected '{Item Name} — Test Plan'"
else
  ok "company doc-test-plan.md title is generalized"
fi

# WORKFLOW.md has the new subsection
if grep -q "### test-plan vs TEST-SPEC" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
  ok "company-workflow WORKFLOW.md has the test-plan vs TEST-SPEC subsection"
else
  fail_test "company-workflow WORKFLOW.md is missing the '### test-plan vs TEST-SPEC' subsection"
fi

echo ""
echo "Regression test (D000007): contract.json eliminated; templates are the single source of truth..."

# contract.json must NOT exist for either skill (templates are now the source of truth)
if [ -f "$REPO_ROOT/skills/company-workflow/contract.json" ]; then
  fail_test "skills/company-workflow/contract.json still exists; D000007 deleted it (templates are now the spec)"
else
  ok "skills/company-workflow/contract.json correctly absent"
fi

if [ -f "$REPO_ROOT/skills/personal-workflow/contract.json" ]; then
  fail_test "skills/personal-workflow/contract.json still exists; D000007 deleted it (templates are now the spec)"
else
  ok "skills/personal-workflow/contract.json correctly absent"
fi

# Validator files must not reference the deleted contract.json as a runtime dependency
# (intentional documentation mentions like "there is no separate contract.json" are
# fine — we grep for read/cat/load patterns that would indicate runtime use)
for vf in skills/company-workflow/SKILL.md skills/personal-workflow/SKILL.md skills/personal-workflow/check.md; do
  if grep -qE '(cat|jq|Read|read).*contract\.json' "$REPO_ROOT/$vf"; then
    fail_test "$vf still has a runtime read of contract.json (line should be removed)"
  else
    ok "$vf does not load contract.json at runtime"
  fi
done

# Catalog must not list contract.json under either skill (would cause validate.sh
# orphan-file warnings after the delete)
if jq -r '.[] | select(.name=="company-workflow" or .name=="personal-workflow") | .files[]' "$REPO_ROOT/skills-catalog.json" 2>/dev/null | grep -q "contract\.json"; then
  fail_test "skills-catalog.json still lists contract.json under company-workflow or personal-workflow"
else
  ok "skills-catalog.json no longer references contract.json for either workflow skill"
fi

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
