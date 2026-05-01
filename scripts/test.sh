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
if [ "$pw_count" -eq 12 ]; then
  ok "templates/personal-workflow/ contains $pw_count templates (expected 12)"
else
  fail_test "templates/personal-workflow/ contains $pw_count templates (expected 12)"
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

echo ""
echo "Regression test (D000008): CLAUDE.md merge convention guard..."

# CLAUDE.md must keep the merge-convention section so future /ship runs in this
# repo use the right gh pr merge invocation (--auto --squash, not --auto alone)
# and know to use gh api for the worktree-aware remote-branch cleanup
if grep -q "^## CI/CD merge convention" "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md has the CI/CD merge convention section"
else
  fail_test "CLAUDE.md is missing the '## CI/CD merge convention' section (D000008 guard)"
fi

if grep -qE 'gh pr merge.*--auto.*--squash' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md prescribes the --auto --squash combined invocation"
else
  fail_test "CLAUDE.md is missing the explicit --auto --squash gh pr merge invocation (D000008 guard)"
fi

if grep -qE 'gh api .*-X DELETE.*git/refs/heads' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md documents the worktree-aware remote-branch cleanup workaround"
else
  fail_test "CLAUDE.md is missing the 'gh api -X DELETE' worktree cleanup workaround (D000008 guard)"
fi

echo ""
echo "Regression test (D000009): feature type requires DESIGN.md artifact..."

# Both manifests must declare a design artifact under types.feature.required,
# and matching doc-DESIGN.md templates must exist. Prevents a future refactor
# from silently dropping the DESIGN requirement back to where it was before.
if jq -e '.types.feature.required[] | select(.filename == "DESIGN.md" and .template == "doc-DESIGN.md")' \
     "$REPO_ROOT/skills/personal-workflow/personal-artifact-manifests.json" > /dev/null; then
  ok "personal-artifact-manifests.json feature.required includes DESIGN.md"
else
  fail_test "personal-artifact-manifests.json feature.required missing DESIGN.md entry (D000009 guard)"
fi

if jq -e '.types.feature.required[] | select(.filename == "DESIGN.md" and .template == "doc-DESIGN.md")' \
     "$REPO_ROOT/skills/company-workflow/company-artifact-manifests.json" > /dev/null; then
  ok "company-artifact-manifests.json feature.required includes DESIGN.md"
else
  fail_test "company-artifact-manifests.json feature.required missing DESIGN.md entry (D000009 guard)"
fi

if [ -f "$REPO_ROOT/templates/personal-workflow/doc-DESIGN.md" ]; then
  ok "templates/personal-workflow/doc-DESIGN.md present"
else
  fail_test "templates/personal-workflow/doc-DESIGN.md missing (D000009 guard)"
fi

if [ -f "$REPO_ROOT/templates/company-workflow/doc-DESIGN.md" ]; then
  ok "templates/company-workflow/doc-DESIGN.md present"
else
  fail_test "templates/company-workflow/doc-DESIGN.md missing (D000009 guard)"
fi

echo ""
echo "Regression test (D000012): deployed workflow templates stay in sync with workbench..."

# Background: D000009 added doc-DESIGN.md and v0.14.2 added doc-feature-summary.md
# to the workbench manifests + templates dir, but ~/.claude/templates/ was never
# refreshed via skills-deploy install --overwrite. Downstream repos (e.g. portfolio)
# that resolve templates from ~/.claude/ saw the new manifest requirement without
# the corresponding template files. This block:
#   (a) verifies skills-catalog.json declares both new templates so skills-deploy
#       install has the metadata to copy them
#   (b) when ~/.claude/templates/{personal,company}-workflow/ exists on this host,
#       asserts every workbench template is present and byte-identical in the
#       deployed copy. Skipped on hosts where skills-deploy hasn't run (e.g. CI).

for _wf in personal-workflow company-workflow; do
  for _tmpl in doc-DESIGN.md doc-feature-summary.md; do
    if jq -e --arg p "$_wf/$_tmpl" --arg n "$_wf" \
         '.[] | select(.name == $n) | .templates | index($p)' \
         "$CATALOG" > /dev/null 2>&1; then
      ok "skills-catalog.json $_wf.templates includes $_tmpl"
    else
      fail_test "skills-catalog.json $_wf.templates missing $_tmpl (D000012 guard)"
    fi
  done
done

for _wf in personal-workflow company-workflow; do
  _D12_DEPLOYED="${HOME}/.claude/templates/$_wf"
  _D12_SRC="$REPO_ROOT/templates/$_wf"
  if [ -d "$_D12_DEPLOYED" ]; then
    _D12_DRIFT=0
    for _src in "$_D12_SRC"/*.md; do
      [ -f "$_src" ] || continue
      _name=$(basename "$_src")
      _dst="$_D12_DEPLOYED/$_name"
      if [ ! -f "$_dst" ]; then
        fail_test "deployed template missing: $_wf/$_name (run scripts/skills-deploy install --overwrite; D000012 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      elif ! cmp -s "$_src" "$_dst"; then
        fail_test "deployed template differs from workbench: $_wf/$_name (run scripts/skills-deploy install --overwrite; D000012 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      fi
    done
    if [ "$_D12_DRIFT" -eq 0 ]; then
      ok "deployed templates/$_wf/ matches workbench source"
    fi
  else
    echo "  SKIP: ~/.claude/templates/$_wf/ not present — skills-deploy hasn't run on this host"
  fi
done

echo ""
echo "Regression test (T000004): AI_KNOWLEDGE_DIR resolution block (S000004)..."
# Background: /company-workflow validate is an LLM-driven SKILL.md, not an
# executable, so bash CI cannot invoke it end-to-end. These tests extract the
# Knowledge Resolution bash block from SKILL.md and exec it in isolation
# against mocked env states. That block IS the implementation for S000004;
# testing it this way gives genuine coverage. See D000004_RCA.md for why.

# Use a single tmpdir for all T000004 artifacts; portable across GNU + BSD mktemp.
_T4_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 't000004' 2>/dev/null)
_T4_KR="$_T4_TMPDIR/kr.sh"
_T4_VALID="$_T4_TMPDIR/valid-dir"
_T4_FILE="$_T4_TMPDIR/not-a-dir"
mkdir -p "$_T4_VALID"
touch "$_T4_FILE"

# Extract the Knowledge Resolution bash block from SKILL.md once.
# End-bound updated to ## Knowledge Helpers (introduced in S000005 c1) so the
# extraction stays scoped to the Resolution block even as new Knowledge-* sections
# get added between Resolution and Template Registry.
awk '/^## Knowledge Resolution/,/^## Knowledge Helpers/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T4_KR"

if [ ! -s "$_T4_KR" ]; then
  fail_test "T000004: could not extract Knowledge Resolution bash block from SKILL.md"
else
  # --- Tier 1 structural greps ---
  if grep -q "^## Knowledge Resolution" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
    ok "T000004 case 1: SKILL.md has ## Knowledge Resolution section"
  else
    fail_test "T000004 case 1: SKILL.md missing ## Knowledge Resolution section"
  fi

  if grep -q "AI_KNOWLEDGE_DIR" "$REPO_ROOT/skills/company-workflow/SKILL.md" \
     && grep -q "_KNOWLEDGE_DIR=" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
    ok "T000004 case 2: SKILL.md references AI_KNOWLEDGE_DIR and exposes _KNOWLEDGE_DIR"
  else
    fail_test "T000004 case 2: SKILL.md missing AI_KNOWLEDGE_DIR or _KNOWLEDGE_DIR"
  fi

  if grep -q "AI_KNOWLEDGE_DIR" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
    ok "T000004 case 3: WORKFLOW.md documents AI_KNOWLEDGE_DIR"
  else
    fail_test "T000004 case 3: WORKFLOW.md missing AI_KNOWLEDGE_DIR documentation"
  fi
  # Case 4 (validate.sh passes): already asserted at top of test.sh.

  # Case 11 (S6): resolution block emits nothing to stdout
  _t4_stdout=$(env -u AI_KNOWLEDGE_DIR bash "$_T4_KR" 2>/dev/null) || true
  if [ -z "$_t4_stdout" ]; then
    ok "T000004 case 11: block emits nothing to stdout when env unset"
  else
    fail_test "T000004 case 11: block leaked to stdout: '$_t4_stdout'"
  fi

  # --- Tier 2 extract-and-exec ---

  # Case 5 (E1): env unset → 1 warning line on stderr, exit 0
  if _t4_out=$(env -u AI_KNOWLEDGE_DIR bash "$_T4_KR" 2>&1 1>/dev/null); then
    _t4_lines=$(printf '%s\n' "$_t4_out" | grep -c "^Warning:" || true)
    if [ "$_t4_lines" = "1" ] && printf '%s' "$_t4_out" | grep -q "not set"; then
      ok "T000004 case 5 (E1): env unset → 1 'not set' warning, exit 0"
    else
      fail_test "T000004 case 5 (E1): expected 1 'not set' warning, got lines=$_t4_lines output='$_t4_out'"
    fi
  else
    fail_test "T000004 case 5 (E1): exit != 0 when env unset"
  fi

  # Case 6 (E2): valid dir → silent, exit 0
  if _t4_out=$(AI_KNOWLEDGE_DIR="$_T4_VALID" bash "$_T4_KR" 2>&1); then
    if [ -z "$_t4_out" ]; then
      ok "T000004 case 6 (E2): valid dir → silent, exit 0"
    else
      fail_test "T000004 case 6 (E2): expected silent, got: '$_t4_out'"
    fi
  else
    fail_test "T000004 case 6 (E2): exit != 0 on valid dir"
  fi

  # Case 7 (E3): nonexistent path → warning names path + 'not found'
  _t4_bad=/does/not/exist/xyz-t000004
  if _t4_out=$(AI_KNOWLEDGE_DIR="$_t4_bad" bash "$_T4_KR" 2>&1 1>/dev/null); then
    if printf '%s' "$_t4_out" | grep -q "not found" \
       && printf '%s' "$_t4_out" | grep -qF "$_t4_bad"; then
      ok "T000004 case 7 (E3): nonexistent path → warning names path + 'not found'"
    else
      fail_test "T000004 case 7 (E3): wrong warning for bad path. output='$_t4_out'"
    fi
  else
    fail_test "T000004 case 7 (E3): exit != 0 on bad path"
  fi

  # Case 8 (E4): path is a file → 'not a directory'
  if _t4_out=$(AI_KNOWLEDGE_DIR="$_T4_FILE" bash "$_T4_KR" 2>&1 1>/dev/null); then
    if printf '%s' "$_t4_out" | grep -q "not a directory" \
       && printf '%s' "$_t4_out" | grep -qF "$_T4_FILE"; then
      ok "T000004 case 8 (E4): file-not-dir → warning + path + 'not a directory'"
    else
      fail_test "T000004 case 8 (E4): wrong warning for file path. output='$_t4_out'"
    fi
  else
    fail_test "T000004 case 8 (E4): exit != 0 on file path"
  fi

  # Case 9 (regression diff): MANUAL ONLY per test-plan.md scope note.
  # /company-workflow validate is LLM-driven; bash CI cannot invoke it end-to-end.

  # Case 10 (E1b): empty-string env → 'not set' (parity with unset)
  if _t4_out=$(AI_KNOWLEDGE_DIR="" bash "$_T4_KR" 2>&1 1>/dev/null); then
    if printf '%s' "$_t4_out" | grep -q "not set"; then
      ok "T000004 case 10 (E1b): empty-string env → 'not set' (parity with unset)"
    else
      fail_test "T000004 case 10 (E1b): wrong warning for empty-string. output='$_t4_out'"
    fi
  else
    fail_test "T000004 case 10 (E1b): exit != 0 on empty-string"
  fi

  # Case 12 (E5): set -e safety across unset / bad / valid sub-cases
  _t4_se_ok=1
  if ! env -u AI_KNOWLEDGE_DIR bash -c "set -e; source '$_T4_KR'" >/dev/null 2>&1; then _t4_se_ok=0; fi
  if ! AI_KNOWLEDGE_DIR=/no/such/path bash -c "set -e; source '$_T4_KR'" >/dev/null 2>&1; then _t4_se_ok=0; fi
  if ! AI_KNOWLEDGE_DIR="$_T4_VALID" bash -c "set -e; source '$_T4_KR'" >/dev/null 2>&1; then _t4_se_ok=0; fi
  if [ "$_t4_se_ok" = "1" ]; then
    ok "T000004 case 12 (E5): block survives parent 'set -e' across unset/bad/valid"
  else
    fail_test "T000004 case 12 (E5): set -e propagated internal test failure"
  fi

  # Case 13 (E6): hostile newline input → single-line warning (sanitization pin)
  if _t4_out=$(AI_KNOWLEDGE_DIR=$'/tmp/evil\npath-t000004' bash "$_T4_KR" 2>&1 1>/dev/null); then
    _t4_lines=$(printf '%s' "$_t4_out" | grep -c "^Warning:" || true)
    if [ "$_t4_lines" = "1" ]; then
      ok "T000004 case 13 (E6): hostile newline input → 1 warning line (sanitized)"
    else
      fail_test "T000004 case 13 (E6): expected 1 warning line, got $_t4_lines. output='$_t4_out'"
    fi
  else
    fail_test "T000004 case 13 (E6): exit != 0 on hostile input"
  fi
fi

rm -rf "$_T4_TMPDIR"

echo ""
echo "Regression test (T000006 c1): Knowledge Helpers (S000005)..."
# Background: c1 adds a ## Knowledge Helpers section that documents four bash
# helpers (parse_knowledge_yml, parse_knowledge_triggers, list_categories,
# list_md_files). Canonical implementations live in
# skills/company-workflow/bin/knowledge-helpers.sh; SKILL.md blocks source
# that file rather than inlining definitions. Tests source the canonical
# file directly and exercise each function against fixtures built by
# scripts/test-helpers/knowledge.sh.

_T6H_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 't000006h' 2>/dev/null)
_T6H_CANONICAL="$REPO_ROOT/skills/company-workflow/bin/knowledge-helpers.sh"

# --- Tier 1 structural greps ---

if grep -q "^## Knowledge Helpers" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c1 case 1: SKILL.md has ## Knowledge Helpers section"
else
  fail_test "T000006 c1 case 1: SKILL.md missing ## Knowledge Helpers section"
fi

if [ -f "$REPO_ROOT/scripts/test-helpers/knowledge.sh" ]; then
  ok "T000006 c1 case 2: scripts/test-helpers/knowledge.sh exists"
else
  fail_test "T000006 c1 case 2: scripts/test-helpers/knowledge.sh missing"
fi

if [ -f "$_T6H_CANONICAL" ]; then
  ok "T000006 c1 case 3: bin/knowledge-helpers.sh exists (canonical helpers)"
else
  fail_test "T000006 c1 case 3: bin/knowledge-helpers.sh missing at $_T6H_CANONICAL"
fi

# Canonical helpers must define every public function the contract documents.
for _fn in parse_knowledge_yml parse_knowledge_triggers list_categories list_md_files; do
  if grep -q "^${_fn}()" "$_T6H_CANONICAL"; then
    ok "T000006 c1 case 4.${_fn}: bin/knowledge-helpers.sh defines ${_fn}()"
  else
    fail_test "T000006 c1 case 4.${_fn}: bin/knowledge-helpers.sh missing ${_fn}() definition"
  fi
done

if grep -q '^build_knowledge_fixture()' "$REPO_ROOT/scripts/test-helpers/knowledge.sh"; then
  ok "T000006 c1 case 5: test-helpers/knowledge.sh defines build_knowledge_fixture()"
else
  fail_test "T000006 c1 case 5: test-helpers/knowledge.sh missing build_knowledge_fixture()"
fi

# Every Knowledge ... block in SKILL.md must source bin/knowledge-helpers.sh
# (catches the case where someone copy-pastes a block and forgets the source).
_T6H_SOURCE_COUNT=$(grep -c 'bin/knowledge-helpers\.sh' "$REPO_ROOT/skills/company-workflow/SKILL.md" || true)
if [ "$_T6H_SOURCE_COUNT" -ge 4 ]; then
  ok "T000006 c1 case 5b: SKILL.md references bin/knowledge-helpers.sh from $_T6H_SOURCE_COUNT places (≥4 expected: Helpers + Loading + On-Demand + Diagnostic)"
else
  fail_test "T000006 c1 case 5b: SKILL.md references bin/knowledge-helpers.sh from only $_T6H_SOURCE_COUNT places (≥4 expected)"
fi

# --- Tier 2 helper behavior (source + exercise) ---

if [ -f "$_T6H_CANONICAL" ]; then
  # Build a fixture covering every mode the helpers care about
  source "$REPO_ROOT/scripts/test-helpers/knowledge.sh"
  _T6H_FIX=$(build_knowledge_fixture "$_T6H_TMPDIR/fixture" \
    "coding:always" \
    "runbooks:on-demand" \
    "domain:on-demand:pricing" \
    "broken:malformed" \
    "notes")

  # Source the canonical helpers directly (cleaner than extracting from SKILL.md)
  # shellcheck disable=SC1090
  source "$_T6H_CANONICAL"

  # Case 6: parse_knowledge_yml on surface: always
  _r=$(parse_knowledge_yml "$_T6H_FIX/coding/.knowledge.yml")
  if [ "$_r" = "always" ]; then
    ok "T000006 c1 case 6: parse_knowledge_yml(coding) → always"
  else
    fail_test "T000006 c1 case 6: parse_knowledge_yml(coding) got '$_r', expected 'always'"
  fi

  # Case 7: parse_knowledge_yml on surface: on-demand
  _r=$(parse_knowledge_yml "$_T6H_FIX/runbooks/.knowledge.yml")
  if [ "$_r" = "on-demand" ]; then
    ok "T000006 c1 case 7: parse_knowledge_yml(runbooks) → on-demand"
  else
    fail_test "T000006 c1 case 7: parse_knowledge_yml(runbooks) got '$_r', expected 'on-demand'"
  fi

  # Case 8: forward-compat — on-demand + triggers parses clean
  _r=$(parse_knowledge_yml "$_T6H_FIX/domain/.knowledge.yml")
  if [ "$_r" = "on-demand" ]; then
    ok "T000006 c1 case 8: parse_knowledge_yml(domain w/triggers) → on-demand (triggers ignored in v1, forward-compat)"
  else
    fail_test "T000006 c1 case 8: parse_knowledge_yml(domain) got '$_r', expected 'on-demand'"
  fi

  # Case 9: malformed → empty
  _r=$(parse_knowledge_yml "$_T6H_FIX/broken/.knowledge.yml")
  if [ -z "$_r" ]; then
    ok "T000006 c1 case 9: parse_knowledge_yml(broken) → empty (malformed detected)"
  else
    fail_test "T000006 c1 case 9: parse_knowledge_yml(broken) got '$_r', expected empty"
  fi

  # Case 10: missing yml → empty
  _r=$(parse_knowledge_yml "$_T6H_FIX/notes/.knowledge.yml")
  if [ -z "$_r" ]; then
    ok "T000006 c1 case 10: parse_knowledge_yml(missing) → empty"
  else
    fail_test "T000006 c1 case 10: parse_knowledge_yml(missing) got '$_r', expected empty"
  fi

  # Case 11: yml edge cases — quoted, comment, CRLF, BOM
  _T6H_EDGE="$_T6H_TMPDIR/edge"
  mkdir -p "$_T6H_EDGE"
  printf 'surface: "always"\n' > "$_T6H_EDGE/q.yml"
  printf 'surface: always # house style\n' > "$_T6H_EDGE/c.yml"
  printf 'surface: always\r\n' > "$_T6H_EDGE/crlf.yml"
  printf '\xef\xbb\xbfsurface: always\n' > "$_T6H_EDGE/bom.yml"
  printf "surface: 'always'\n" > "$_T6H_EDGE/sq.yml"
  _edge_ok=1
  [ "$(parse_knowledge_yml "$_T6H_EDGE/q.yml")"    = "always" ] || _edge_ok=0
  [ "$(parse_knowledge_yml "$_T6H_EDGE/c.yml")"    = "always" ] || _edge_ok=0
  [ "$(parse_knowledge_yml "$_T6H_EDGE/crlf.yml")" = "always" ] || _edge_ok=0
  [ "$(parse_knowledge_yml "$_T6H_EDGE/bom.yml")"  = "always" ] || _edge_ok=0
  [ -z "$(parse_knowledge_yml "$_T6H_EDGE/sq.yml")" ] || _edge_ok=0   # single-quote NOT supported
  if [ "$_edge_ok" = "1" ]; then
    ok "T000006 c1 case 11: parser handles quoted/comment/CRLF/BOM, rejects single-quote"
  else
    fail_test "T000006 c1 case 11: yml edge-case handling incorrect"
  fi

  # Case 12: list_categories lex-sorted, skips hidden
  mkdir -p "$_T6H_FIX/.hidden"
  _cats=$(list_categories "$_T6H_FIX" | LC_ALL=C sort | tr '\n' ',')
  # Expected (lex-sorted): broken, coding, domain, notes, runbooks
  _exp_cats="$_T6H_FIX/broken,$_T6H_FIX/coding,$_T6H_FIX/domain,$_T6H_FIX/notes,$_T6H_FIX/runbooks,"
  if [ "$_cats" = "$_exp_cats" ]; then
    ok "T000006 c1 case 12: list_categories returns lex-sorted + skips hidden dirs"
  else
    fail_test "T000006 c1 case 12: list_categories output mismatch. got='$_cats' expected='$_exp_cats'"
  fi

  # Case 13: list_md_files recursive + lex-sorted
  _mdfs=$(list_md_files "$_T6H_FIX/coding" | tr '\n' ',')
  # Expected: a.md then sub/b.md (lex-sorted by path)
  _exp_mdfs="$_T6H_FIX/coding/a.md,$_T6H_FIX/coding/sub/b.md,"
  if [ "$_mdfs" = "$_exp_mdfs" ]; then
    ok "T000006 c1 case 13: list_md_files returns recursive *.md lex-sorted"
  else
    fail_test "T000006 c1 case 13: list_md_files output mismatch. got='$_mdfs' expected='$_exp_mdfs'"
  fi

  # Case 14: list_categories on non-existent dir → empty
  _r=$(list_categories /nonexistent-t6h-$$)
  if [ -z "$_r" ]; then
    ok "T000006 c1 case 14: list_categories(nonexistent) → empty"
  else
    fail_test "T000006 c1 case 14: list_categories(nonexistent) got '$_r', expected empty"
  fi

  # Case 15: list_md_files on non-existent dir → empty
  _r=$(list_md_files /nonexistent-t6h-$$)
  if [ -z "$_r" ]; then
    ok "T000006 c1 case 15: list_md_files(nonexistent) → empty"
  else
    fail_test "T000006 c1 case 15: list_md_files(nonexistent) got '$_r', expected empty"
  fi
fi

rm -rf "$_T6H_TMPDIR"

echo ""
echo "Regression test (T000006 c2): Knowledge Loading + knowledge-doctor (S000005)..."
# Background: c2 ships always-on loading. Tests extract the Knowledge Loading
# bash block and exec it against fixture repos built via build_knowledge_fixture.
# Separate tests exercise the knowledge-doctor diagnostic block.

_T6L_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 't000006l' 2>/dev/null)
_T6L_LOADING="$_T6L_TMPDIR/loading.sh"
_T6L_DOCTOR="$_T6L_TMPDIR/doctor.sh"

awk '/^## Knowledge Loading/,/^## On-Demand Matching/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T6L_LOADING"

awk '/^## Diagnostic: knowledge-doctor/,/^## Template Registry/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T6L_DOCTOR"

# --- Tier 1 structural greps ---

if grep -q "^## Knowledge Loading" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c2 case 1 (S1): SKILL.md has ## Knowledge Loading section"
else
  fail_test "T000006 c2 case 1: SKILL.md missing ## Knowledge Loading section"
fi

if grep -q "## Always-On Knowledge" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c2 case 2 (S2): SKILL.md emits ## Always-On Knowledge section name"
else
  fail_test "T000006 c2 case 2: SKILL.md missing ## Always-On Knowledge emission"
fi

if grep -qi "read.*always-on knowledge\|read every path\|read each" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c2 case 3 (S3): SKILL.md instructs Claude to Read the listed paths"
else
  fail_test "T000006 c2 case 3: SKILL.md missing Claude-facing Read instruction"
fi

if ! grep -q "knowledge-enabled" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c2 case 4: SKILL.md does NOT reference legacy .claude/knowledge-enabled marker (removed in v1.0.0)"
else
  fail_test "T000006 c2 case 4: SKILL.md still references the removed knowledge-enabled marker"
fi

if grep -q "^## Diagnostic: knowledge-doctor" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c2 case 5: SKILL.md has knowledge-doctor diagnostic section"
else
  fail_test "T000006 c2 case 5: SKILL.md missing knowledge-doctor section"
fi

# Knowledge Loading block must source bin/knowledge-helpers.sh (replaces the
# pre-extraction byte-identity drift tripwire — there's now only one canonical
# definition, so drift is impossible by construction). This case verifies the
# block correctly references the canonical helpers.
if grep -q 'bin/knowledge-helpers\.sh' "$_T6L_LOADING"; then
  ok "T000006 c2 case 6: Knowledge Loading block sources bin/knowledge-helpers.sh"
else
  fail_test "T000006 c2 case 6: Knowledge Loading block missing reference to bin/knowledge-helpers.sh"
fi

# WORKFLOW.md docs (S14, S16)
if grep -qE "surface.*always" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
  ok "T000006 c2 case 7 (S14): WORKFLOW.md documents .knowledge.yml schema"
else
  fail_test "T000006 c2 case 7: WORKFLOW.md missing .knowledge.yml schema"
fi

if ! grep -q "knowledge-enabled" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
  ok "T000006 c2 case 8: WORKFLOW.md does NOT reference legacy .claude/knowledge-enabled marker (removed in v1.0.0)"
else
  fail_test "T000006 c2 case 8: WORKFLOW.md still references the removed knowledge-enabled marker"
fi

if grep -qi "trust boundary\|prompt injection\|Read into Claude" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
  ok "T000006 c2 case 9 (S15): WORKFLOW.md includes security callout"
else
  fail_test "T000006 c2 case 9: WORKFLOW.md missing security callout about Read trust boundary"
fi

# Loading block extracts non-empty
if [ -s "$_T6L_LOADING" ]; then
  ok "T000006 c2 case 10: Knowledge Loading bash block extracts non-empty"
else
  fail_test "T000006 c2 case 10: Knowledge Loading bash block extraction empty"
fi

# Doctor block extracts non-empty
if [ -s "$_T6L_DOCTOR" ]; then
  ok "T000006 c2 case 11: knowledge-doctor bash block extracts non-empty"
else
  fail_test "T000006 c2 case 11: knowledge-doctor bash block extraction empty"
fi

# --- Tier 2 behavioral tests ---

# Helper: build a fixture repo with knowledge dir and run loading
_t6l_run_loading() {
  # $1 = AI_KNOWLEDGE_DIR, $2 = repo root
  # Additional env vars passed through (AI_KNOWLEDGE_DISABLE, etc.)
  local kdir="$1" repo="$2"
  ( cd "$repo" && AI_KNOWLEDGE_DIR="$kdir" bash "$_T6L_LOADING" )
}

# Fixture repo factory. Provisions the canonical helpers via symlink so the
# Loading + Doctor blocks find them through the workbench-relative fallback
# (same shape as a real workbench checkout).
_t6l_make_repo() {
  local repo
  repo=$(mktemp -d 2>/dev/null || mktemp -d -t 't6l-repo' 2>/dev/null)
  ( cd "$repo" && git init -q )
  mkdir -p "$repo/skills/company-workflow"
  ln -snf "$REPO_ROOT/skills/company-workflow/bin" "$repo/skills/company-workflow/bin"
  printf '%s' "$repo"
}

source "$REPO_ROOT/scripts/test-helpers/knowledge.sh"

# ---------- A1/E1: always-on category → emits paths ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "coding:always")
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
if printf '%s' "$_t6l_out" | grep -q "^## Always-On Knowledge" \
   && printf '%s' "$_t6l_out" | grep -q "coding/a.md" \
   && printf '%s' "$_t6l_out" | grep -q "coding/sub/b.md"; then
  ok "T000006 c2 case 12 (A1): always-on category emits nested + flat *.md absolute paths"
else
  fail_test "T000006 c2 case 12 (A1): always-on emission incorrect. output=[$_t6l_out]"
fi

# Lex-sorted verification (A5)
_t6l_paths=$(printf '%s' "$_t6l_out" | grep "^- " | sort -C && echo "sorted" || echo "unsorted")
if [ "$_t6l_paths" = "sorted" ]; then
  ok "T000006 c2 case 13 (A5): emitted paths are lex-sorted"
else
  fail_test "T000006 c2 case 13 (A5): paths not lex-sorted"
fi
rm -rf "$_t6l_repo"

# ---------- A2: on-demand category NOT in always-on ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "runbooks:on-demand:pricing")
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
if ! printf '%s' "$_t6l_out" | grep -q "runbooks"; then
  ok "T000006 c2 case 14 (A2): on-demand category NOT emitted under Always-On Knowledge"
else
  fail_test "T000006 c2 case 14 (A2): on-demand category leaked into Always-On output"
fi
rm -rf "$_t6l_repo"

# ---------- A3: missing yml = silent skip, no warning ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "notes")
_t6l_out_all=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>&1)
if [ -z "$_t6l_out_all" ] || ! printf '%s' "$_t6l_out_all" | grep -qi "warning\|malformed"; then
  ok "T000006 c2 case 15 (A3): missing yml → silent skip, no warning"
else
  fail_test "T000006 c2 case 15 (A3): missing yml emitted unexpected output: [$_t6l_out_all]"
fi
rm -rf "$_t6l_repo"

# ---------- A4/E3: malformed yml warns, sibling still loads ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "coding:always" "broken:malformed")
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
_t6l_err=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>&1 1>/dev/null)
if printf '%s' "$_t6l_out" | grep -q "coding/a.md" \
   && printf '%s' "$_t6l_err" | grep -q "malformed" \
   && printf '%s' "$_t6l_err" | grep -q "broken"; then
  ok "T000006 c2 case 16 (A4/E3): malformed yml → warning names file, sibling category still loads"
else
  fail_test "T000006 c2 case 16 (A4/E3): malformed yml resilience incorrect. stdout=[$_t6l_out] stderr=[$_t6l_err]"
fi
rm -rf "$_t6l_repo"

# ---------- A6/E4: unset env → no loading sections ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_out=$( cd "$_t6l_repo" && env -u AI_KNOWLEDGE_DIR bash "$_T6L_LOADING" 2>&1 )
if [ -z "$_t6l_out" ] || ! printf '%s' "$_t6l_out" | grep -q "^## Always-On Knowledge"; then
  ok "T000006 c2 case 17 (A6/E4): env unset → no Always-On Knowledge section"
else
  fail_test "T000006 c2 case 17: env unset emitted loading output: [$_t6l_out]"
fi
rm -rf "$_t6l_repo"

# ---------- G3-always-on: env var set + always-on category → loads ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "coding:always")
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
if printf '%s' "$_t6l_out" | grep -q "^## Always-On Knowledge"; then
  ok "T000006 c2 case 20: env var set + always-on category → Always-On section emitted"
else
  fail_test "T000006 c2 case 20: always-on category failed to activate loading: [$_t6l_out]"
fi
rm -rf "$_t6l_repo"

# ---------- Forward-compat: surface: on-demand + triggers: [x] parses clean, emits nothing, no warning ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "domain:on-demand:pricing")
_t6l_all=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>&1)
if ! printf '%s' "$_t6l_all" | grep -q "^## Always-On Knowledge" \
   && ! printf '%s' "$_t6l_all" | grep -qi "malformed\|warning"; then
  ok "T000006 c2 case 21 (forward-compat): surface: on-demand + triggers parses clean, emits nothing, no warning"
else
  fail_test "T000006 c2 case 21: forward-compat on-demand emitted unexpected output: [$_t6l_all]"
fi
rm -rf "$_t6l_repo"

# ---------- AI_KNOWLEDGE_DISABLE escape hatch ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "coding:always")
_t6l_out=$( cd "$_t6l_repo" && AI_KNOWLEDGE_DIR="$_t6l_kdir" AI_KNOWLEDGE_DISABLE=1 bash "$_T6L_LOADING" 2>&1 )
if [ -z "$_t6l_out" ]; then
  ok "T000006 c2 case 25: AI_KNOWLEDGE_DISABLE=1 → one-shot disable, empty output"
else
  fail_test "T000006 c2 case 25: AI_KNOWLEDGE_DISABLE=1 emitted output: [$_t6l_out]"
fi
rm -rf "$_t6l_repo"

# ---------- Path cap: 500+1 paths → hard fail ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "bulk:always")
# Fixture adds a.md + sub/b.md. Add 500 more to exceed cap.
for i in $(seq 1 501); do
  echo "pad$i" > "$_t6l_kdir/bulk/pad_$i.md"
done
_t6l_all=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>&1)
if printf '%s' "$_t6l_all" | grep -q "loading aborted" \
   && printf '%s' "$_t6l_all" | grep -q "exceeds cap" \
   && ! printf '%s' "$_t6l_all" | grep -q "^## Always-On Knowledge"; then
  ok "T000006 c2 case 26 (scale): 500+1 paths → hard-fail warning, no loading"
else
  fail_test "T000006 c2 case 26: cap gate wrong behavior. output=[$_t6l_all]"
fi
rm -rf "$_t6l_repo"

# ---------- yml edge cases: trailing ws, quoted, comment, CRLF, BOM ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir="$_t6l_repo/k"
mkdir -p "$_t6l_kdir"
for _variant in ws quot cmt crlf bom; do
  mkdir -p "$_t6l_kdir/$_variant/sub"
  printf '# content\nCANARY_%s\n' "$_variant" > "$_t6l_kdir/$_variant/a.md"
  printf 'CANARY_%s_NESTED\n' "$_variant" > "$_t6l_kdir/$_variant/sub/b.md"
done
printf 'surface: always   \n' > "$_t6l_kdir/ws/.knowledge.yml"
printf 'surface: "always"\n' > "$_t6l_kdir/quot/.knowledge.yml"
printf 'surface: always # house style\n' > "$_t6l_kdir/cmt/.knowledge.yml"
printf 'surface: always\r\n' > "$_t6l_kdir/crlf/.knowledge.yml"
printf '\xef\xbb\xbfsurface: always\n' > "$_t6l_kdir/bom/.knowledge.yml"
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
_t6l_missing=""
for _variant in ws quot cmt crlf bom; do
  if ! printf '%s' "$_t6l_out" | grep -q "$_variant/a.md"; then
    _t6l_missing="$_t6l_missing $_variant"
  fi
done
if [ -z "$_t6l_missing" ]; then
  ok "T000006 c2 case 27 (yml edge cases): trailing-ws/quoted/comment/CRLF/BOM all parse as always"
else
  fail_test "T000006 c2 case 27: yml variants failed to load: $_t6l_missing. stdout=[$_t6l_out]"
fi
rm -rf "$_t6l_repo"

# ---------- Absolute path with spaces ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir="$_t6l_repo/k with spaces"
_t6l_kdir=$(build_knowledge_fixture "$_t6l_kdir" "coding:always")
_t6l_out=$(_t6l_run_loading "$_t6l_kdir" "$_t6l_repo" 2>/dev/null)
if printf '%s' "$_t6l_out" | grep -q "k with spaces/coding/a.md"; then
  ok "T000006 c2 case 28: paths with spaces survive emission"
else
  fail_test "T000006 c2 case 28: space-in-path handling broken. output=[$_t6l_out]"
fi
rm -rf "$_t6l_repo"

# ---------- Invalid-env passthrough: AI_KNOWLEDGE_DIR pointing at a regular file ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_file="$_t6l_repo/notdir"
touch "$_t6l_file"
_t6l_all=$( cd "$_t6l_repo" && AI_KNOWLEDGE_DIR="$_t6l_file" bash "$_T6L_LOADING" 2>&1 )
if [ -z "$_t6l_all" ]; then
  ok "T000006 c2 case 29: AI_KNOWLEDGE_DIR=<regular file> → silent pass-through (S000004 owns warnings)"
else
  fail_test "T000006 c2 case 29: invalid env emitted unexpected output: [$_t6l_all]"
fi
rm -rf "$_t6l_repo"

# ---------- knowledge-doctor: all preconditions pass ----------
_t6l_repo=$(_t6l_make_repo)
_t6l_kdir=$(build_knowledge_fixture "$_t6l_repo/k" "coding:always" "runbooks:on-demand:pricing" "notes" "broken:malformed")
_t6l_out=$( cd "$_t6l_repo" && AI_KNOWLEDGE_DIR="$_t6l_kdir" bash "$_T6L_DOCTOR" 2>&1 )
if printf '%s' "$_t6l_out" | grep -q "coding.*surface=always.*loads=yes" \
   && printf '%s' "$_t6l_out" | grep -q "runbooks.*surface=on-demand.*loads=on-match" \
   && printf '%s' "$_t6l_out" | grep -q "notes.*missing yml" \
   && printf '%s' "$_t6l_out" | grep -q "broken.*malformed yml" \
   && printf '%s' "$_t6l_out" | grep -q "result: loading enabled" \
   && ! printf '%s' "$_t6l_out" | grep -q "^marker:"; then
  ok "T000006 c2 case 30: knowledge-doctor surfaces state of every category + preconditions (and emits no marker line)"
else
  fail_test "T000006 c2 case 30: doctor output wrong shape. output=[$_t6l_out]"
fi
rm -rf "$_t6l_repo"

rm -rf "$_T6L_TMPDIR"

echo ""
echo "Regression test (T000006 c3): On-Demand Matching (S000005)..."
# Background: c3 adds `## On-Demand Matching` section to SKILL.md that emits
# `## On-Demand Knowledge Candidates` block for on-demand categories with
# non-empty triggers. Tests extract the block, execute against fixtures, and
# verify the structure + trigger parsing + preconditions.

_T6M_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 't000006m' 2>/dev/null)
_T6M_OM="$_T6M_TMPDIR/on-demand.sh"
_T6M_HELPERS="$_T6M_TMPDIR/helpers.sh"

awk '/^## On-Demand Matching/,/^## Diagnostic: knowledge-doctor/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T6M_OM"

awk '/^## Knowledge Helpers/,/^## Knowledge Loading/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T6M_HELPERS"

# --- Tier 1 structural greps ---

if grep -q "^## On-Demand Matching" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 1 (S4): SKILL.md has ## On-Demand Matching section"
else
  fail_test "T000006 c3 case 1: SKILL.md missing ## On-Demand Matching section"
fi

if grep -q "## On-Demand Knowledge Candidates" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 2 (S5): SKILL.md emits ## On-Demand Knowledge Candidates name"
else
  fail_test "T000006 c3 case 2: SKILL.md missing ## On-Demand Knowledge Candidates emission"
fi

if grep -qi "tokenize" "$REPO_ROOT/skills/company-workflow/SKILL.md" \
   && grep -qi "whole-word\|whole word" "$REPO_ROOT/skills/company-workflow/SKILL.md" \
   && grep -qi "token boundaries" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 3 (S6/S7): SKILL.md specifies tokenization + whole-word + phrase at token boundaries"
else
  fail_test "T000006 c3 case 3: SKILL.md missing matching semantics (tokenize / whole-word / phrase)"
fi

if grep -qi "case-insensitive" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 4 (S7): SKILL.md specifies case-insensitive matching"
else
  fail_test "T000006 c3 case 4: SKILL.md missing case-insensitive spec"
fi

if grep -q "\[knowledge\] matched:" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 5 (S8): SKILL.md specifies match log format [knowledge] matched: ..."
else
  fail_test "T000006 c3 case 5: SKILL.md missing match log format"
fi

if grep -qi "latest user message\|most recent message\|latest message" "$REPO_ROOT/skills/company-workflow/SKILL.md"; then
  ok "T000006 c3 case 6 (S9): SKILL.md pins matching scope to latest user message only"
else
  fail_test "T000006 c3 case 6: SKILL.md missing 'latest message only' scope"
fi

if grep -q "^parse_knowledge_triggers" "$REPO_ROOT/skills/company-workflow/bin/knowledge-helpers.sh"; then
  ok "T000006 c3 case 7: bin/knowledge-helpers.sh defines parse_knowledge_triggers"
else
  fail_test "T000006 c3 case 7: bin/knowledge-helpers.sh missing parse_knowledge_triggers"
fi

# Replaces the pre-extraction drift tripwire: with one canonical definition
# in bin/knowledge-helpers.sh, drift is impossible. Verify the On-Demand block
# correctly sources the canonical helpers.
if grep -q 'bin/knowledge-helpers\.sh' "$_T6M_OM"; then
  ok "T000006 c3 case 8: On-Demand Matching block sources bin/knowledge-helpers.sh"
else
  fail_test "T000006 c3 case 8: On-Demand Matching block missing reference to bin/knowledge-helpers.sh"
fi

if grep -qi "triggers" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md" \
   && grep -qi "pricing engine\|multi-word phrase" "$REPO_ROOT/skills/company-workflow/WORKFLOW.md"; then
  ok "T000006 c3 case 9 (S13/S15): WORKFLOW.md documents triggers + multi-word phrase example"
else
  fail_test "T000006 c3 case 9: WORKFLOW.md missing trigger-authoring guidance"
fi

# --- Tier 2 behavioral tests ---

source "$REPO_ROOT/scripts/test-helpers/knowledge.sh"
# Source canonical helpers directly — see ## Knowledge Helpers in SKILL.md
# shellcheck disable=SC1090
source "$REPO_ROOT/skills/company-workflow/bin/knowledge-helpers.sh"

_t6m_run_om() {
  # $1 = AI_KNOWLEDGE_DIR, $2 = repo root
  local kdir="$1" repo="$2"
  ( cd "$repo" && AI_KNOWLEDGE_DIR="$kdir" bash "$_T6M_OM" )
}

# Fixture repo factory. Provisions canonical helpers via symlink so the
# On-Demand block finds them via the workbench-relative fallback.
_t6m_make_repo() {
  local repo
  repo=$(mktemp -d 2>/dev/null || mktemp -d -t 't6m-repo' 2>/dev/null)
  ( cd "$repo" && git init -q )
  mkdir -p "$repo/skills/company-workflow"
  ln -snf "$REPO_ROOT/skills/company-workflow/bin" "$repo/skills/company-workflow/bin"
  printf '%s' "$repo"
}

# ---------- parse_knowledge_triggers: inline form ----------
_t6m_dir=$(mktemp -d)
printf 'surface: on-demand\ntriggers: [pricing, "pricing engine", PE]\n' > "$_t6m_dir/inline.yml"
_got=$(parse_knowledge_triggers "$_t6m_dir/inline.yml" | tr '\n' '|')
if [ "$_got" = "pricing|pricing engine|PE|" ]; then
  ok "T000006 c3 case 10: parse_knowledge_triggers handles inline flow form with quoted phrase"
else
  fail_test "T000006 c3 case 10: inline parse incorrect. got=[$_got]"
fi

# ---------- parse_knowledge_triggers: block form ----------
printf 'surface: on-demand\ntriggers:\n  - pricing\n  - "pricing engine"\n  - PE\n' > "$_t6m_dir/block.yml"
_got=$(parse_knowledge_triggers "$_t6m_dir/block.yml" | tr '\n' '|')
if [ "$_got" = "pricing|pricing engine|PE|" ]; then
  ok "T000006 c3 case 11: parse_knowledge_triggers handles block form with quoted phrase"
else
  fail_test "T000006 c3 case 11: block parse incorrect. got=[$_got]"
fi

# ---------- parse_knowledge_triggers: empty list ----------
printf 'surface: on-demand\ntriggers: []\n' > "$_t6m_dir/empty.yml"
_got=$(parse_knowledge_triggers "$_t6m_dir/empty.yml")
if [ -z "$_got" ]; then
  ok "T000006 c3 case 12: parse_knowledge_triggers returns empty for empty list"
else
  fail_test "T000006 c3 case 12: empty list should return empty. got=[$_got]"
fi

# ---------- parse_knowledge_triggers: missing key (surface: always only) ----------
printf 'surface: always\n' > "$_t6m_dir/nokey.yml"
_got=$(parse_knowledge_triggers "$_t6m_dir/nokey.yml")
if [ -z "$_got" ]; then
  ok "T000006 c3 case 13: parse_knowledge_triggers returns empty when triggers key absent"
else
  fail_test "T000006 c3 case 13: missing key should return empty. got=[$_got]"
fi

# ---------- parse_knowledge_triggers: single-quoted values ----------
printf "surface: on-demand\ntriggers: ['a', \"b\", 'c c']\n" > "$_t6m_dir/sq.yml"
_got=$(parse_knowledge_triggers "$_t6m_dir/sq.yml" | tr '\n' '|')
if [ "$_got" = "a|b|c c|" ]; then
  ok "T000006 c3 case 14: parse_knowledge_triggers strips single and double quotes"
else
  fail_test "T000006 c3 case 14: quote stripping wrong. got=[$_got]"
fi

rm -rf "$_t6m_dir"

# ---------- On-Demand Matching: always-on categories NOT emitted ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "coding:always")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if ! printf '%s' "$_t6m_out" | grep -q "^## On-Demand Knowledge Candidates"; then
  ok "T000006 c3 case 15 (O8): always-on-only fixture → no On-Demand block"
else
  fail_test "T000006 c3 case 15: always-on category leaked into On-Demand block"
fi
rm -rf "$_t6m_repo"

# ---------- On-Demand: missing-yml categories not emitted ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "notes")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if ! printf '%s' "$_t6m_out" | grep -q "^## On-Demand Knowledge Candidates"; then
  ok "T000006 c3 case 16: missing yml → no On-Demand block"
else
  fail_test "T000006 c3 case 16: missing-yml category emitted unexpectedly"
fi
rm -rf "$_t6m_repo"

# ---------- On-Demand: empty-triggers categories not emitted (O7 equivalent) ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "staging:on-demand")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if ! printf '%s' "$_t6m_out" | grep -q "^## On-Demand Knowledge Candidates"; then
  ok "T000006 c3 case 17 (O7): empty triggers → category NOT emitted as candidate"
else
  fail_test "T000006 c3 case 17: empty-triggers category leaked. output=[$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- On-Demand: single-trigger category emits correctly (O1) ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "runbooks:on-demand:pricing")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if printf '%s' "$_t6m_out" | grep -q "^## On-Demand Knowledge Candidates" \
   && printf '%s' "$_t6m_out" | grep -q "^category: .*runbooks$" \
   && printf '%s' "$_t6m_out" | grep -q "^triggers: pricing$" \
   && printf '%s' "$_t6m_out" | grep -q "runbooks/a.md" \
   && printf '%s' "$_t6m_out" | grep -q "runbooks/sub/b.md"; then
  ok "T000006 c3 case 18 (O1): single-trigger category emits category + triggers + file list"
else
  fail_test "T000006 c3 case 18: single-trigger emission wrong. output=[$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- On-Demand: phrase-trigger quoted in emission (O2/O6) ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" 'domain:on-demand:pricing engine')
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if printf '%s' "$_t6m_out" | grep -q 'triggers: "pricing engine"'; then
  ok "T000006 c3 case 19 (O2): phrase trigger emitted quoted"
else
  fail_test "T000006 c3 case 19: phrase trigger not quoted. output=[$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- On-Demand: multi-category + mixed modes (O5/O8) ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" \
  "coding:always" \
  "runbooks:on-demand:pricing" \
  "security:on-demand:auth" \
  "staging:on-demand" \
  "notes" \
  "broken:malformed")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
_expected_cats=$(printf '%s' "$_t6m_out" | grep -c "^category: ")
# Expected: 2 (runbooks + security). coding excluded (always), staging excluded (empty triggers),
# notes excluded (no yml), broken excluded (malformed)
if [ "$_expected_cats" = "2" ] \
   && printf '%s' "$_t6m_out" | grep -q "runbooks" \
   && printf '%s' "$_t6m_out" | grep -q "security" \
   && ! printf '%s' "$_t6m_out" | grep -q "coding" \
   && ! printf '%s' "$_t6m_out" | grep -q "staging" \
   && ! printf '%s' "$_t6m_out" | grep -q "notes"; then
  ok "T000006 c3 case 20 (O5/O8): multi-category fixture emits exactly the 2 loadable on-demand cats"
else
  fail_test "T000006 c3 case 20: multi-cat emission wrong. got $_expected_cats category lines. output=[$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- Gate: env unset → no block ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_out=$( cd "$_t6m_repo" && env -u AI_KNOWLEDGE_DIR bash "$_T6M_OM" 2>&1 )
if [ -z "$_t6m_out" ]; then
  ok "T000006 c3 case 22: env unset → silent, no block"
else
  fail_test "T000006 c3 case 22: env unset leaked output. [$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- Gate: AI_KNOWLEDGE_DISABLE → no block ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "runbooks:on-demand:pricing")
_t6m_out=$( cd "$_t6m_repo" && AI_KNOWLEDGE_DIR="$_t6m_kdir" AI_KNOWLEDGE_DISABLE=1 bash "$_T6M_OM" 2>&1 )
if [ -z "$_t6m_out" ]; then
  ok "T000006 c3 case 23: AI_KNOWLEDGE_DISABLE=1 → one-shot skip"
else
  fail_test "T000006 c3 case 23: disable leaked output. [$_t6m_out]"
fi
rm -rf "$_t6m_repo"

# ---------- Claude-facing instruction presence (S6/S7/S8/S9 consolidated) ----------
_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" "runbooks:on-demand:pricing")
_t6m_out=$(_t6m_run_om "$_t6m_kdir" "$_t6m_repo" 2>/dev/null)
if printf '%s' "$_t6m_out" | grep -qi "tokenize" \
   && printf '%s' "$_t6m_out" | grep -qi "case-insensitive" \
   && printf '%s' "$_t6m_out" | grep -q "\[knowledge\] matched:"; then
  ok "T000006 c3 case 24: emitted block includes Claude-facing instructions (tokenize + case-insensitive + match log format)"
else
  fail_test "T000006 c3 case 24: emitted block missing required Claude instructions"
fi
rm -rf "$_t6m_repo"

# ---------- Doctor: on-demand with triggers shows 'on-match' ----------
_T6M_DOCTOR="$_T6M_TMPDIR/doctor.sh"
awk '/^## Diagnostic: knowledge-doctor/,/^## Template Registry/' \
  "$REPO_ROOT/skills/company-workflow/SKILL.md" \
  | awk '/^```bash/,/^```$/' | sed '/^```/d' > "$_T6M_DOCTOR"

_t6m_repo=$(_t6m_make_repo)
_t6m_kdir=$(build_knowledge_fixture "$_t6m_repo/k" \
  "runbooks:on-demand:pricing" \
  "staging:on-demand")
_t6m_out=$( cd "$_t6m_repo" && AI_KNOWLEDGE_DIR="$_t6m_kdir" bash "$_T6M_DOCTOR" 2>&1 )
if printf '%s' "$_t6m_out" | grep -q "runbooks.*loads=on-match" \
   && printf '%s' "$_t6m_out" | grep -q "staging.*loads=no (empty triggers)"; then
  ok "T000006 c3 case 25: knowledge-doctor shows 'loads=on-match (triggers: ...)' for loadable and 'empty triggers' for inert"
else
  fail_test "T000006 c3 case 25: doctor on-demand rendering wrong. output=[$_t6m_out]"
fi
rm -rf "$_t6m_repo"

rm -rf "$_T6M_TMPDIR"

# ---------- copilot-deploy.py: install → doctor → remove round-trip ----------
# Guards against regressions in the 264-LoC Python installer. Tier 1 smoke:
# install the bundle into a tmp target, run doctor (expect all PASS), then
# remove and verify cleanup. This is the only automated coverage for
# scripts/copilot-deploy.py.
if command -v python3 >/dev/null 2>&1; then
  _CD_TMP=$(mktemp -d -t copilot-deploy-test.XXXXXX)
  mkdir -p "$_CD_TMP/target"
  _CD_PY="$REPO_ROOT/scripts/copilot-deploy.py"

  # install
  _cd_install_out=$(python3 "$_CD_PY" install "$_CD_TMP/target" 2>&1)
  _cd_install_rc=$?
  if [ "$_cd_install_rc" -eq 0 ] && echo "$_cd_install_out" | grep -q "SUMMARY: installed=" \
     && [ -f "$_CD_TMP/target/.github/copilot-instructions.md" ] \
     && [ -f "$_CD_TMP/target/.github/work-copilot/copilot-artifact-manifests.json" ] \
     && [ -f "$_CD_TMP/target/.github/work-copilot/install-manifest.json" ]; then
    ok "copilot-deploy install lands bundle files into target .github/"
  else
    fail_test "copilot-deploy install failed or missing expected files. rc=$_cd_install_rc output=[$_cd_install_out]"
  fi

  # doctor (expect all PASS, exit 0)
  _cd_doctor_out=$(python3 "$_CD_PY" doctor "$_CD_TMP/target" 2>&1)
  _cd_doctor_rc=$?
  if [ "$_cd_doctor_rc" -eq 0 ] \
     && ! echo "$_cd_doctor_out" | grep -qE "\[MISSING\]|\[DRIFT\]|\[ORPHAN\]"; then
    ok "copilot-deploy doctor reports clean install (no MISSING/DRIFT/ORPHAN)"
  else
    fail_test "copilot-deploy doctor found issues. rc=$_cd_doctor_rc output=[$_cd_doctor_out]"
  fi

  # CRLF normalization: mutate a .md file to add CRLF line endings, doctor
  # should still PASS (hash is computed on normalized LF content).
  _cd_test_file="$_CD_TMP/target/.github/copilot-instructions.md"
  python3 -c "
import sys
from pathlib import Path
p = Path(sys.argv[1])
data = p.read_bytes().replace(b'\n', b'\r\n')
p.write_bytes(data)
" "$_cd_test_file"
  _cd_doctor_crlf_out=$(python3 "$_CD_PY" doctor "$_CD_TMP/target" 2>&1)
  _cd_doctor_crlf_rc=$?
  if [ "$_cd_doctor_crlf_rc" -eq 0 ] \
     && ! echo "$_cd_doctor_crlf_out" | grep -qE "\[DRIFT\]"; then
    ok "copilot-deploy doctor treats CRLF and LF as equivalent for text files"
  else
    fail_test "copilot-deploy doctor flagged CRLF as drift (Windows autocrlf regression). rc=$_cd_doctor_crlf_rc output=[$_cd_doctor_crlf_out]"
  fi

  # remove
  _cd_remove_out=$(python3 "$_CD_PY" remove "$_CD_TMP/target" 2>&1)
  _cd_remove_rc=$?
  if [ "$_cd_remove_rc" -eq 0 ] && echo "$_cd_remove_out" | grep -q "SUMMARY: removed=" \
     && [ ! -f "$_CD_TMP/target/.github/copilot-instructions.md" ] \
     && [ ! -f "$_CD_TMP/target/.github/work-copilot/install-manifest.json" ]; then
    ok "copilot-deploy remove deletes installed files"
  else
    fail_test "copilot-deploy remove failed. rc=$_cd_remove_rc output=[$_cd_remove_out]"
  fi

  rm -rf "$_CD_TMP"
else
  echo "  SKIP: python3 not available, skipping copilot-deploy smoke test"
fi

# ---------- S000010: bundle artifact completeness coverage ----------
# Tests the v2 mirror artifacts beyond the v1 templates check.
# (S000010_TEST-SPEC.md tests 8, 9, 10, 12 — install-side coverage.)
#
# These tests deliberately invoke commands that exit non-zero (validate.sh
# failing on drift, doctor refusing path-traversal). Disable errexit for
# this block; restore at the end. Test failures still report via fail_test.

set +e

echo ""
echo "Checking S000010 bundle-artifact-completeness coverage..."

# Test 8 (S000010): copilot-instructions.md ≤ 8192 bytes
_ci_size=$(wc -c < "$REPO_ROOT/work-copilot/instructions/copilot-instructions.md" | tr -d ' ')
if [ "$_ci_size" -le 8192 ]; then
  ok "S000010 test 8: copilot-instructions.md is $_ci_size bytes (≤8192 budget)"
else
  fail_test "S000010 test 8: copilot-instructions.md is $_ci_size bytes (over 8192 budget)"
fi

# Test 9 (S000010): bundle-layout pointers present (grep -F per path)
_ci_file="$REPO_ROOT/work-copilot/instructions/copilot-instructions.md"
_ci_missing=""
for _path in "work-copilot/WORKFLOW.md" "work-copilot/reference/" "work-copilot/philosophy/" "work-copilot/examples/" "work-copilot/fixtures/"; do
  if ! grep -qF "$_path" "$_ci_file"; then
    _ci_missing="$_ci_missing $_path"
  fi
done
if [ -z "$_ci_missing" ]; then
  ok "S000010 test 9: copilot-instructions.md references all 5 new bundle dirs"
else
  fail_test "S000010 test 9: copilot-instructions.md missing path strings:$_ci_missing"
fi

# Test 10 (S000010): install spot-checks for each new bundle dir + DRIFT case
if command -v python3 >/dev/null 2>&1; then
  _S010_TMP=$(mktemp -d -t s010-test.XXXXXX)
  mkdir -p "$_S010_TMP/target"
  python3 "$REPO_ROOT/scripts/copilot-deploy.py" install "$_S010_TMP/target" >/dev/null 2>&1
  _spot_missing=""
  for _spot in \
    ".github/work-copilot/WORKFLOW.md" \
    ".github/work-copilot/reference/guide-general.md" \
    ".github/work-copilot/philosophy/rationale-PRD.md" \
    ".github/work-copilot/examples/example-doc-ARCHITECTURE.md" \
    ".github/work-copilot/fixtures/invalid-bad-frontmatter.md"; do
    [ -f "$_S010_TMP/target/$_spot" ] || _spot_missing="$_spot_missing $_spot"
  done
  if [ -z "$_spot_missing" ]; then
    ok "S000010 test 10: install lays down 5/5 new mirror artifacts (1 per new bundle dir)"
  else
    fail_test "S000010 test 10: install missing artifacts:$_spot_missing"
  fi

  # Test 12 (S000010): doctor reports DRIFT on a NESTED fixture (G9 — the file
  # that historically drifted, not just top-level WORKFLOW.md)
  _nested="$_S010_TMP/target/.github/work-copilot/fixtures/valid-feature-dir/TRACKER.md"
  if [ -f "$_nested" ]; then
    echo "extra mutation" >> "$_nested"
    _drift_out=$(python3 "$REPO_ROOT/scripts/copilot-deploy.py" doctor "$_S010_TMP/target" 2>&1)
    _drift_rc=$?
    if [ "$_drift_rc" -ne 0 ] && echo "$_drift_out" | grep -qF "[DRIFT]" && echo "$_drift_out" | grep -qF "valid-feature-dir/TRACKER.md"; then
      ok "S000010 test 12 (G9): doctor reports DRIFT on nested fixture mutation"
    else
      fail_test "S000010 test 12 (G9): doctor missed DRIFT on nested fixture. rc=$_drift_rc output=[$_drift_out]"
    fi
  else
    fail_test "S000010 test 12 (G9): nested fixture not installed; cannot test DRIFT detection"
  fi

  # Test 13 (autoplan G3): path-traversal defense in doctor
  python3 -c "
import json, sys
mp = sys.argv[1]
with open(mp) as f: m = json.load(f)
m['files'].append({'src':'fake', 'dest':'../../../etc/passwd', 'sha256':'fake'})
with open(mp, 'w') as f: json.dump(m, f, indent=2)
" "$_S010_TMP/target/.github/work-copilot/install-manifest.json"
  _trav_out=$(python3 "$REPO_ROOT/scripts/copilot-deploy.py" doctor "$_S010_TMP/target" 2>&1)
  _trav_rc=$?
  if [ "$_trav_rc" -eq 2 ] && echo "$_trav_out" | grep -qF "escapes target directory"; then
    ok "autoplan G3: doctor refuses path-traversal in install-manifest"
  else
    fail_test "autoplan G3: doctor accepted path-traversal entry. rc=$_trav_rc output=[$_trav_out]"
  fi

  # Test 14 (DX3): --dry-run leaves filesystem untouched
  _DRY_TMP=$(mktemp -d -t s010-dry.XXXXXX)
  mkdir -p "$_DRY_TMP/target"
  python3 "$REPO_ROOT/scripts/copilot-deploy.py" install --dry-run "$_DRY_TMP/target" >/dev/null 2>&1
  if [ ! -d "$_DRY_TMP/target/.github" ]; then
    ok "DX3: install --dry-run does not write to filesystem"
  else
    fail_test "DX3: install --dry-run created $_DRY_TMP/target/.github (should not write)"
  fi
  rm -rf "$_DRY_TMP"

  rm -rf "$_S010_TMP"
else
  echo "  SKIP: python3 not available, skipping S000010 install tests"
fi

# ---------- T000011: MIRROR_SPECS sync-check synthetic cases ----------
# Validates the v2 sync-check behaviors directly: drift detection + orphan
# FAIL-vs-WARN policy split + manifest schema parity.

echo ""
echo "Checking T000011 MIRROR_SPECS sync-check behaviors..."

# Helper: run validate.sh, return exit code; capture output. Block sits inside
# set +e so non-zero exits (drift / orphan-FAIL cases) are captured, not fatal.
_run_validate() {
  ( cd "$REPO_ROOT" && bash scripts/validate.sh 2>&1 )
}

# Smoke 1 (T000011 case 1, single-file shape, drift): mutate WORKFLOW.md
# and assert validate.sh exits non-zero with [FAIL] naming the file.
_t11_orig=$(mktemp -t t11.XXXXXX)
cp "$REPO_ROOT/work-copilot/WORKFLOW.md" "$_t11_orig"
echo "drift" >> "$REPO_ROOT/work-copilot/WORKFLOW.md"
_t11_out=$(_run_validate)
_t11_rc=$?
cp "$_t11_orig" "$REPO_ROOT/work-copilot/WORKFLOW.md"
rm -f "$_t11_orig"
if [ "$_t11_rc" -ne 0 ] && echo "$_t11_out" | grep -qF "work-copilot/WORKFLOW.md differs from"; then
  ok "T000011 case 1 (single-file drift): validate.sh fails, names diverged file"
else
  fail_test "T000011 case 1: drift on WORKFLOW.md not detected. rc=$_t11_rc"
fi

# Smoke 2 (T000011 case 4, flat-glob shape, drift on a guide)
_t11_orig=$(mktemp -t t11.XXXXXX)
cp "$REPO_ROOT/work-copilot/reference/guide-task.md" "$_t11_orig"
echo "drift" >> "$REPO_ROOT/work-copilot/reference/guide-task.md"
_t11_out=$(_run_validate)
_t11_rc=$?
cp "$_t11_orig" "$REPO_ROOT/work-copilot/reference/guide-task.md"
rm -f "$_t11_orig"
if [ "$_t11_rc" -ne 0 ] && echo "$_t11_out" | grep -qF "guide-task.md differs"; then
  ok "T000011 case 4 (flat-glob drift): validate.sh fails on reference/ drift"
else
  fail_test "T000011 case 4: drift on reference/guide-task.md not detected. rc=$_t11_rc"
fi

# Smoke 3 (T000011 case 7, recursive-glob shape, drift on a nested fixture)
_t11_orig=$(mktemp -t t11.XXXXXX)
cp "$REPO_ROOT/work-copilot/fixtures/valid-feature-dir/TRACKER.md" "$_t11_orig"
echo "drift" >> "$REPO_ROOT/work-copilot/fixtures/valid-feature-dir/TRACKER.md"
_t11_out=$(_run_validate)
_t11_rc=$?
cp "$_t11_orig" "$REPO_ROOT/work-copilot/fixtures/valid-feature-dir/TRACKER.md"
rm -f "$_t11_orig"
if [ "$_t11_rc" -ne 0 ] && echo "$_t11_out" | grep -qF "valid-feature-dir/TRACKER.md differs"; then
  ok "T000011 case 7 (recursive-glob drift): validate.sh fails on nested fixture drift"
else
  fail_test "T000011 case 7: drift on nested fixture not detected. rc=$_t11_rc"
fi

# Smoke 4 (T000011 case 6 + autoplan D3): orphan in templates/ → WARN only
echo "stale" > "$REPO_ROOT/work-copilot/templates/legacy-tracker.md"
_t11_out=$(_run_validate)
_t11_rc=$?
rm -f "$REPO_ROOT/work-copilot/templates/legacy-tracker.md"
if [ "$_t11_rc" -eq 0 ] && echo "$_t11_out" | grep -qF "legacy-tracker.md has no counterpart"; then
  ok "T000011 case 6 (autoplan D3): orphan in templates/ warns only (v1 backward compat)"
else
  fail_test "T000011 case 6: templates/ orphan policy regressed (should WARN, not FAIL)"
fi

# Smoke 5 (T000011 case 9 + autoplan D3): orphan in reference/ → FAIL
echo "stale" > "$REPO_ROOT/work-copilot/reference/guide-stale.md"
_t11_out=$(_run_validate)
_t11_rc=$?
rm -f "$REPO_ROOT/work-copilot/reference/guide-stale.md"
if [ "$_t11_rc" -ne 0 ] && echo "$_t11_out" | grep -qF "guide-stale.md has no counterpart"; then
  ok "T000011 case 9 (autoplan D3): orphan in reference/ FAILS (new-mirror policy)"
else
  fail_test "T000011 case 9: orphan in reference/ should FAIL (autoplan D3 broken). rc=$_t11_rc"
fi

# Smoke 6 (autoplan D5): manifest schema parity — schema change FAILS
if command -v jq >/dev/null 2>&1; then
  _t11_orig=$(mktemp -t t11.XXXXXX)
  cp "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json" "$_t11_orig"
  python3 -c "
import json, sys
p = sys.argv[1]
with open(p) as f: m = json.load(f)
m['types']['feature']['required'].append({'artifact':'extra','template':'doc-extra.md','filename':'extra.md'})
with open(p, 'w') as f: json.dump(m, f, indent=2)
" "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json"
  _t11_out=$(_run_validate)
  _t11_rc=$?
  cp "$_t11_orig" "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json"
  rm -f "$_t11_orig"
  if [ "$_t11_rc" -ne 0 ] && echo "$_t11_out" | grep -qF "schema differs"; then
    ok "autoplan D5: manifest schema-parity rejects schema change"
  else
    fail_test "autoplan D5: manifest schema change not detected. rc=$_t11_rc"
  fi

  # Smoke 7 (autoplan D5): description-only change passes
  _t11_orig=$(mktemp -t t11.XXXXXX)
  cp "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json" "$_t11_orig"
  python3 -c "
import json, sys
p = sys.argv[1]
with open(p) as f: m = json.load(f)
m['description'] = 'Different prose, same schema'
with open(p, 'w') as f: json.dump(m, f, indent=2)
" "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json"
  _t11_out=$(_run_validate)
  _t11_rc=$?
  cp "$_t11_orig" "$REPO_ROOT/work-copilot/copilot-artifact-manifests.json"
  rm -f "$_t11_orig"
  if [ "$_t11_rc" -eq 0 ] && echo "$_t11_out" | grep -qF "schema-parity"; then
    ok "autoplan D5: description-only divergence passes (field exempt from sync)"
  else
    fail_test "autoplan D5: description-only change incorrectly failed. rc=$_t11_rc"
  fi
else
  echo "  SKIP: jq not available, skipping manifest schema-parity tests"
fi

# Restore errexit after the S000010 + T000011 test block.
set -e

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
