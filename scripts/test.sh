#!/usr/bin/env bash
# Smoke tests for the skill workbench. Superset of validate.sh.
# Exit 0 = all tests pass. Exit 1 = one or more failures.

. "$(dirname "$0")/lib.sh"
init

ERRORS=0

ok() { echo "  OK: $1"; }
fail_test() { echo "  FAIL: $1" >&2; ERRORS=$((ERRORS + 1)); }

# Catalog-driven SKILL.md path lookup (F000006). Mirrors the helper in
# scripts/skills-deploy and scripts/validate.sh: skill source root is the
# dirname of catalog files[0], so a skill can live anywhere the catalog
# points (skills/, deprecated/, etc.).
skill_md_path() {
  jq -r --arg n "$1" '.[] | select(.name == $n) | (.files // []) | .[0] // ""' "$CATALOG" 2>/dev/null || true
}
skill_md_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    echo "$REPO_ROOT/$f0"
  fi
}
skill_source_dir_abs() {
  local f0
  f0=$(skill_md_path "$1")
  if [ -n "$f0" ]; then
    echo "$REPO_ROOT/$(dirname "$f0")"
  fi
}

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
  skill_file=$(skill_md_abs "$name")
  if [ -z "$skill_file" ] || [ ! -f "$skill_file" ]; then
    continue
  fi
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
    ts_missing=""
    for sec in "## Smoke Tests" "## E2E Tests"; do
      grep -q "$sec" "$doc_dir/TEST-SPEC.md" 2>/dev/null || ts_missing="$ts_missing $sec"
    done
    if [ -z "$ts_missing" ]; then
      ok "$name TEST-SPEC.md has ## Smoke Tests and ## E2E Tests"
    else
      fail_test "$name TEST-SPEC.md missing required section(s):$ts_missing"
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
  if echo "$deps_output" | grep -q "CJ_personal-workflow\|CJ_system-health"; then
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
[ -f "$REPO_ROOT/doc/SKILL-CATALOG.md" ] && cp "$REPO_ROOT/doc/SKILL-CATALOG.md" "/tmp/skill-catalog-backup-$$"
trap 'cp "/tmp/catalog-backup-$$" "$CATALOG"; cp "/tmp/readme-backup-$$" "$REPO_ROOT/README.md"; [ -f "/tmp/version-backup-$$" ] && cp "/tmp/version-backup-$$" "$REPO_ROOT/VERSION"; [ -f "/tmp/changelog-backup-$$" ] && cp "/tmp/changelog-backup-$$" "$REPO_ROOT/CHANGELOG.md"; [ -f "/tmp/skill-catalog-backup-$$" ] && cp "/tmp/skill-catalog-backup-$$" "$REPO_ROOT/doc/SKILL-CATALOG.md"; rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold" "/tmp/catalog-backup-$$" "/tmp/readme-backup-$$" "/tmp/version-backup-$$" "/tmp/changelog-backup-$$" "/tmp/skill-catalog-backup-$$"' EXIT

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

# Step 1b (F000032): scaffold USAGE.md alongside SKILL.md to satisfy Check 13
cat > "$SKILLS_DIR/zzz-test-scaffold/USAGE.md" << 'USAGEEOF'
---
skill-name: "zzz-test-scaffold"
version: 0.1.0
status: experimental
---

# Skill Usage: zzz-test-scaffold

## When to use

Test fixture only. Created by `scripts/test.sh` integration test.

## When NOT to use

Anywhere. This is a synthesized test skill that is cleaned up after the run.

## Mental model

Fixture for the manual-skill-creation integration test.

## Common pitfalls

None — fixture is removed by EXIT trap + inline cleanup.

## Related skills

None.
USAGEEOF

# Step 1c (F000034): append a stub section to doc/SKILL-CATALOG.md so Check 15
# finds zzz-test-scaffold listed (the catalog entry below makes it routable; the
# `status != "deprecated"` + non-empty `files` predicate matches; Check 15 then
# expects a `### zzz-test-scaffold` section with chart-or-tag). Tag-only stub
# uses the closed-enum `(single-step utility)` value. EXIT trap + Step 5 inline
# cleanup restore the catalog from /tmp/skill-catalog-backup-$$.
if [ -f "$REPO_ROOT/doc/SKILL-CATALOG.md" ]; then
  cat >> "$REPO_ROOT/doc/SKILL-CATALOG.md" << 'CATALOGEOF'

### zzz-test-scaffold

**Status:** experimental (integration-test fixture; cleaned up after the test runs)
**Source:** `skills/zzz-test-scaffold/SKILL.md` · `skills/zzz-test-scaffold/USAGE.md`

**Invoke when:** Never. This is a synthesized test skill — the manual-skill-creation integration test creates it, validates the workbench accepts it, then tears it down.

`(single-step utility)` — Fixture for the manual-skill-creation integration test; removed by EXIT trap + Step 5 inline cleanup.
CATALOGEOF
fi

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

# Step 5 (S000052): inline cleanup of the scaffold-test fixture before any
# downstream test (e.g. test-deploy.sh) runs. EXIT trap also cleans this up,
# but that fires after the script finishes — too late for downstream tests
# that read $CATALOG or scan $SKILLS_DIR. Without inline cleanup, the
# zzz-test-scaffold catalog entry persists into test-deploy.sh's `install`
# call, doctor then resolves its source to $main_toplevel (per T000025) which
# differs from the worktree path where the dir lives, and Test 8 ("Doctor on
# healthy install") fails with `WARN: zzz-test-scaffold — source directory
# missing in repo`. Cleaning up inline keeps the EXIT trap as a defense-in-depth
# fallback for unexpected exits.
cp "/tmp/catalog-backup-$$" "$CATALOG"
[ -f "/tmp/skill-catalog-backup-$$" ] && cp "/tmp/skill-catalog-backup-$$" "$REPO_ROOT/doc/SKILL-CATALOG.md"
rm -rf "$SKILLS_DIR/zzz-test-scaffold" "$DOCS_DIR/zzz-test-scaffold"

# Template content smoke tests (S000002 TEST-SPEC)
echo ""
echo "Checking tracker template content..."

# S1: No "reviewer noted" in any tracker
if grep -rl "reviewer noted" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'reviewer noted' still present in personal tracker templates"
else
  ok "No 'reviewer noted' in personal tracker templates"
fi

# S2: No "Linux branch" in any personal tracker
if grep -rl "Linux branch" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise gate 'Linux branch' still present in personal tracker templates"
else
  ok "No 'Linux branch' in personal tracker templates"
fi

# S3: No JIRA/TFS in any personal tracker
if grep -rl "JIRA\|TFS" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Enterprise references (JIRA/TFS) still present in personal tracker templates"
else
  ok "No JIRA/TFS references in personal tracker templates"
fi

# S4: No workflow_type in any personal tracker
if grep -rl "workflow_type" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Redundant field 'workflow_type' still present in personal tracker templates"
else
  ok "No workflow_type in personal tracker templates"
fi

# S6: Task total gate count <= feature total gate count (lighter lifecycle)
task_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/CJ_personal-workflow/tracker-task.md" || true)
feat_total=$(grep -c '^\- \[ \]' "$REPO_ROOT/templates/CJ_personal-workflow/tracker-feature.md" || true)
if [ "$task_total" -le "$feat_total" ] 2>/dev/null; then
  ok "Task total gates ($task_total) <= feature total gates ($feat_total)"
else
  fail_test "Task total gates ($task_total) > feature total gates ($feat_total)"
fi

# No review tracker template should exist in CJ_personal-workflow templates
# (CJ_company-workflow/tracker-review.md is valid — it's a separate template set)
if [ -f "$REPO_ROOT/templates/CJ_personal-workflow/tracker-review.md" ]; then
  fail_test "tracker-review.md should not exist in CJ_personal-workflow (review type is company-only)"
else
  ok "No tracker-review.md in CJ_personal-workflow (review type correctly absent)"
fi

# Personal-workflow template directory exists with expected count
pw_count=$(find "$REPO_ROOT/templates/CJ_personal-workflow" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$pw_count" -eq 10 ]; then
  ok "templates/CJ_personal-workflow/ contains $pw_count templates (expected 10)"
else
  fail_test "templates/CJ_personal-workflow/ contains $pw_count templates (expected 10)"
fi

# Personal-workflow catalog entry exists
if jq -e '.[] | select(.name == "CJ_personal-workflow")' "$CATALOG" >/dev/null 2>&1; then
  ok "CJ_personal-workflow catalog entry exists"
else
  fail_test "CJ_personal-workflow catalog entry missing from skills-catalog.json"
fi

# No stale /docs references in personal tracker templates
if grep -rl "/docs check\|/docs tree" "$REPO_ROOT/templates/CJ_personal-workflow/tracker-"*.md 2>/dev/null | grep -q .; then
  fail_test "Stale /docs references in personal tracker templates (should be /CJ_personal-workflow)"
else
  ok "No stale /docs references in personal tracker templates"
fi

# Portability test: CJ_personal-workflow skill has zero gstack dependencies
echo ""
echo "Portability test: CJ_personal-workflow standalone..."

if grep -q "gstack" "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "CJ_personal-workflow SKILL.md contains gstack references (should be standalone)"
else
  ok "CJ_personal-workflow SKILL.md has zero gstack references"
fi

# shellcheck disable=SC2088
if grep -q "~/.gstack" "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" 2>/dev/null; then
  fail_test "CJ_personal-workflow SKILL.md references ~/.gstack/ (should be standalone)"
else
  ok "CJ_personal-workflow SKILL.md has no ~/.gstack/ paths"
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
echo "Regression test (D000006): test-doc scope contracts..."

# Scope comments in test-doc templates (CJ_personal-workflow only after
# CJ_company-workflow retirement in F000023/S000053).
_tp_path="$REPO_ROOT/templates/CJ_personal-workflow/doc-test-plan.md"
_tp_disp="CJ_personal-workflow doc-test-plan.md"
if grep -q "ONE fix (defect) or ONE task" "$_tp_path"; then
  ok "$_tp_disp has the test-plan scope comment"
else
  fail_test "$_tp_disp is missing the test-plan scope comment"
fi

_ts_path="$REPO_ROOT/templates/CJ_personal-workflow/doc-TEST-SPEC.md"
_ts_disp="CJ_personal-workflow doc-TEST-SPEC.md"
if grep -q "ENTIRE user story" "$_ts_path"; then
  ok "$_ts_disp has the TEST-SPEC scope comment"
else
  fail_test "$_ts_disp is missing the TEST-SPEC scope comment"
fi

echo ""
echo "Regression test (D000007): contract.json eliminated; templates are the single source of truth..."

# contract.json must NOT exist for the personal-workflow skill (templates are the spec)
if [ -f "$REPO_ROOT/skills/CJ_personal-workflow/contract.json" ]; then
  fail_test "skills/CJ_personal-workflow/contract.json still exists; D000007 deleted it (templates are now the spec)"
else
  ok "skills/CJ_personal-workflow/contract.json correctly absent"
fi

# Validator files must not reference the deleted contract.json as a runtime dependency
# (intentional documentation mentions like "there is no separate contract.json" are
# fine — we grep for read/cat/load patterns that would indicate runtime use)
for vf in \
    "$REPO_ROOT/skills/CJ_personal-workflow/SKILL.md" \
    "$REPO_ROOT/skills/CJ_personal-workflow/check.md"; do
  vf_rel="${vf#"$REPO_ROOT"/}"
  if grep -qE '(cat|jq|Read|read).*contract\.json' "$vf"; then
    fail_test "$vf_rel still has a runtime read of contract.json (line should be removed)"
  else
    ok "$vf_rel does not load contract.json at runtime"
  fi
done

# Catalog must not list contract.json under either skill (would cause validate.sh
# orphan-file warnings after the delete)
if jq -r '.[] | select(.name=="CJ_company-workflow" or .name=="CJ_personal-workflow") | .files[]' "$REPO_ROOT/skills-catalog.json" 2>/dev/null | grep -q "contract\.json"; then
  fail_test "skills-catalog.json still lists contract.json under CJ_company-workflow or CJ_personal-workflow"
else
  ok "skills-catalog.json no longer references contract.json for either workflow skill"
fi

echo ""
echo "Regression test (D000008): CLAUDE.md merge convention guard..."

# CLAUDE.md must keep the merge-convention section so future /ship runs in this
# repo use the right gh pr merge invocation. The convention evolved in v2.0.6:
# - Original: prescribe --auto --squash --delete-branch (guarded against
#   regressing to --auto --delete-branch which silently fails without --squash).
# - v2.0.6+: --auto removed entirely. This repo's auto-merge is disabled, so
#   `gh pr merge --auto` exits 0 even when the actual merge fails (error to
#   stderr). Skipping --auto sidesteps the silent-fail; the new "Verify before
#   cleanup" guard tells agents to confirm state=MERGED after merge.
# This guard now checks for the new convention: --squash --delete-branch
# without --auto, plus the verify-before-cleanup paragraph.
if grep -q "^## CI/CD merge convention" "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md has the CI/CD merge convention section"
else
  fail_test "CLAUDE.md is missing the '## CI/CD merge convention' section (D000008 guard)"
fi

# shellcheck disable=SC2016  # backticks are intentional regex content, not command substitution
if grep -qE 'gh pr merge[^`]*--squash[^`]*--delete-branch' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md prescribes the --squash --delete-branch invocation"
else
  fail_test "CLAUDE.md is missing the --squash --delete-branch gh pr merge invocation (D000008 guard)"
fi

# v2.0.6+ guard: must explicitly tell agents NOT to add --auto.
if grep -qE '(Do NOT add|do NOT use).{0,30}--auto' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md warns against the --auto flag (auto-merge disabled in repo)"
else
  fail_test "CLAUDE.md is missing the 'do not add --auto' warning (v2.0.6 D000008 guard)"
fi

# v2.0.6+ guard: must tell agents to verify state=MERGED before cleanup.
if grep -qE '(must print|state.{0,5}=|state.{0,5}is).{0,40}MERGED|MERGED.{0,40}(before|cleanup)' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md prescribes the verify-state=MERGED check before cleanup"
else
  fail_test "CLAUDE.md is missing the verify-state=MERGED guidance (v2.0.6 D000008 guard)"
fi

if grep -qE 'gh api .*-X DELETE.*git/refs/heads' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md documents the worktree-aware remote-branch cleanup workaround"
else
  fail_test "CLAUDE.md is missing the 'gh api -X DELETE' worktree cleanup workaround (D000008 guard)"
fi

# v2.0.6+ guard: must point to the workbench-side check-version-queue.sh preflight.
if grep -q "check-version-queue.sh" "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md points to scripts/check-version-queue.sh queue-collision preflight"
else
  fail_test "CLAUDE.md is missing the check-version-queue.sh queue-collision preflight pointer (v2.0.6 D000008 guard)"
fi

echo ""
echo "Regression test (D000009): feature type requires DESIGN.md artifact..."

# Both manifests must declare a design artifact under types.feature.required,
# and matching doc-DESIGN.md templates must exist. Prevents a future refactor
# from silently dropping the DESIGN requirement back to where it was before.
if jq -e '.types.feature.required[] | select(.filename == "DESIGN.md" and .template == "doc-DESIGN.md")' \
     "$REPO_ROOT/skills/CJ_personal-workflow/personal-artifact-manifests.json" > /dev/null; then
  ok "personal-artifact-manifests.json feature.required includes DESIGN.md"
else
  fail_test "personal-artifact-manifests.json feature.required missing DESIGN.md entry (D000009 guard)"
fi

if [ -f "$REPO_ROOT/templates/CJ_personal-workflow/doc-DESIGN.md" ]; then
  ok "templates/CJ_personal-workflow/doc-DESIGN.md present"
else
  fail_test "templates/CJ_personal-workflow/doc-DESIGN.md missing (D000009 guard)"
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

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  case "$_wf" in
    CJ_personal-workflow) _tmpls="doc-DESIGN.md doc-SPEC.md doc-ROADMAP.md" ;;
  esac
  for _tmpl in $_tmpls; do
    if jq -e --arg p "$_wf/$_tmpl" --arg n "$_wf" \
         '.[] | select(.name == $n) | .templates | index($p)' \
         "$CATALOG" > /dev/null 2>&1; then
      ok "skills-catalog.json $_wf.templates includes $_tmpl"
    else
      fail_test "skills-catalog.json $_wf.templates missing $_tmpl (D000012 guard)"
    fi
  done
done

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  _D12_DEPLOYED="${HOME}/.claude/templates/$_wf"
  # Catalog-driven workbench source dir (F000006). Honors the catalog
  # templates_source override; falls back to templates/{wf} for active skills.
  _D12_SRC_REL=$(jq -r --arg n "$_wf" '.[] | select(.name == $n) | .templates_source // ""' "$CATALOG" 2>/dev/null || echo "")
  if [ -n "$_D12_SRC_REL" ]; then
    _D12_SRC="$REPO_ROOT/$_D12_SRC_REL"
  else
    _D12_SRC="$REPO_ROOT/templates/$_wf"
  fi
  if [ -d "$_D12_DEPLOYED" ]; then
    _D12_DRIFT=0
    # Forward direction: every workbench template must exist + byte-match in deployed (D000012)
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
    # Reverse direction: every deployed template must exist in workbench (D000014)
    # Catches stale templates left in ~/.claude/ after a workbench removal — skills-deploy
    # install --overwrite adds files but does not remove them, so without this check
    # extras accumulate undetected (made more relevant by D000013's auto-sync hook).
    for _dst in "$_D12_DEPLOYED"/*.md; do
      [ -f "$_dst" ] || continue
      _name=$(basename "$_dst")
      _src="$_D12_SRC/$_name"
      if [ ! -f "$_src" ]; then
        fail_test "deployed template not in workbench: $_wf/$_name (manually rm — workbench removed this template; D000014 guard)"
        _D12_DRIFT=$((_D12_DRIFT + 1))
      fi
    done
    if [ "$_D12_DRIFT" -eq 0 ]; then
      ok "deployed templates/$_wf/ matches workbench source (both directions)"
    fi
  else
    echo "  SKIP: ~/.claude/templates/$_wf/ not present — skills-deploy hasn't run on this host"
  fi
done

echo ""
echo "Regression test (D000014): WORKFLOW.md type-to-artifact counts match manifest..."

# Background: D000009 (DESIGN), v0.14.2 (feature-summary), and earlier CJ_company-workflow
# changes (PR-DESCRIPTION) added required artifacts to the manifest but didn't update
# the type-to-artifact tables and prose in skills/{personal,company}-workflow/WORKFLOW.md.
# Scaffolding AIs read WORKFLOW.md, see the wrong count, and produce incomplete work
# items that fail downstream validation. This block forces the markdown table count
# to match the manifest's required-array length — manifest is authoritative.

# shellcheck disable=SC2043  # single-element loop preserved for CJ_personal-workflow scope after CJ_company-workflow retirement (F000023/S000053)
for _wf in CJ_personal-workflow; do
  # Strip the CJ_ prefix from the skill name to recover the manifest filename
  # base (manifests retain their original "personal-artifact-manifests.json"
  # filename; only the directory was renamed under T000018).
  _NAKED="${_wf#CJ_}"
  _PREFIX="${_NAKED%-workflow}"
  # Catalog-driven source dir (F000006): manifest + WORKFLOW.md live in the
  # same directory as the skill's SKILL.md, wherever the catalog points.
  _SOURCE_DIR=$(skill_source_dir_abs "$_wf")
  _MANIFEST="$_SOURCE_DIR/${_PREFIX}-artifact-manifests.json"
  _WORKFLOW_MD="$_SOURCE_DIR/WORKFLOW.md"
  if [ ! -f "$_MANIFEST" ] || [ ! -f "$_WORKFLOW_MD" ]; then
    fail_test "$_wf manifest or WORKFLOW.md missing (D000014 guard)"
    continue
  fi
  while IFS=$'\t' read -r _type _expected; do
    _md_count=$(grep -E "^\| $_type \|" "$_WORKFLOW_MD" | head -1 | awk -F'|' '{print $4}' | tr -d ' ')
    if [ -z "$_md_count" ]; then
      fail_test "$_wf WORKFLOW.md missing table row for type \"$_type\" (D000014 guard)"
    elif [ "$_md_count" = "$_expected" ]; then
      ok "$_wf WORKFLOW.md $_type count ($_expected) matches manifest"
    else
      fail_test "$_wf WORKFLOW.md $_type count drift: WORKFLOW.md=$_md_count, manifest=$_expected (D000014 guard)"
    fi
  done < <(jq -r '.types | to_entries[] | .key + "\t" + (.value.required | length | tostring)' "$_MANIFEST")
done

echo ""
echo "Regression test (D000013): setup-hooks.sh installs post-merge auto-sync hook..."

# Background: D000012 added a regression check that catches deploy drift but doesn't
# prevent it. D000013 closes Option C2 from D000012's RCA: setup-hooks.sh now writes
# a post-merge hook so workbench pulls auto-run skills-deploy install --overwrite
# whenever templates/skills/catalog/rules change. This block verifies the source
# script still emits the right hook content; it does not fire the hook itself
# (avoids touching .git/hooks/ in CI).

# D000022 re-anchored this guard from the literal 'cat > "$HOOK_DIR/post-merge"'
# to the install_hook shape: setup-hooks.sh now installs hooks via the
# clobber-safe install_hook helper, not a bare cat-redirect. Same D000013
# regression intent (setup-hooks.sh still writes a post-merge hook); new
# structural token. No SC2016 disable needed — the pattern has no literal $.
if grep -qE 'install_hook[[:space:]]+post-merge' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh writes a post-merge hook"
else
  fail_test "setup-hooks.sh missing post-merge hook block (D000013 guard)"
fi

if grep -qE 'skills-deploy.*install.*--overwrite' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "post-merge hook invokes skills-deploy install --overwrite"
else
  fail_test "post-merge hook missing skills-deploy install --overwrite call (D000013 guard)"
fi

if grep -qF 'templates/|skills/|skills-catalog\.json|rules/' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "post-merge hook filters on deploy-relevant paths (templates, skills, catalog, rules)"
else
  fail_test "post-merge hook missing path filter for templates/skills/catalog/rules (D000013 guard)"
fi

# D000021: setup.sh bootstrap must wire setup-hooks.sh, else a fresh clone never
# installs the post-merge auto-sync hook above and the repo's update model
# silently degrades to manual behavior. Source-level static check only — never
# runs the network-dependent setup.sh (same CI-safety rationale as this block).
# Anchor on the executable invocation (quoted $CLONE_DIR prefix), NOT a bare
# 'setup-hooks.sh' substring — the explanatory comments in setup.sh also
# contain that string, so a loose grep stays green even if the invocation
# line is deleted (matches the structural-token style of the D000013 guards
# above, e.g. 'install_hook post-merge').
# shellcheck disable=SC2016 # literal $CLONE_DIR is intentional — grepping for the exact source string in setup.sh
if grep -qE '"\$CLONE_DIR/scripts/setup-hooks\.sh"' "$REPO_ROOT/scripts/setup.sh"; then
  ok "setup.sh bootstrap invokes setup-hooks.sh (post-merge hook auto-installed on fresh clone)"
else
  fail_test "setup.sh does not invoke setup-hooks.sh — fresh-clone bootstrap leaves auto-sync hook uninstalled (D000013 bootstrap-wiring guard)"
fi

# D000022: setup-hooks.sh must not blind-clobber operator/tooling-owned git
# hooks. Since D000021 wired setup-hooks.sh into setup.sh's always-on update
# path, an unconditional `cat > "$HOOK_DIR/<hook>"` would silently destroy a
# customized pre-commit/post-merge (Husky, lefthook, local) with no backup, and
# a partial write would leave a truncated hook present. The fix installs via a
# sentinel-aware, atomic install_hook helper. Source-level static checks only —
# never fires a hook (same CI-safety rationale as the D000013 block above).
# shellcheck disable=SC2016 # literal $SENTINEL is intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF '! grep -qF "$SENTINEL"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh checks the workbench sentinel before overwriting an existing hook (D000022 guard)"
else
  fail_test "setup-hooks.sh missing sentinel ownership check — operator/tooling hooks can be blind-clobbered (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $HOOK_DIR/$tmp/$hook_path are intentional — grepping for the exact source strings in setup-hooks.sh
if grep -qF 'mktemp "$HOOK_DIR/.${hook_name}.XXXXXX"' "$REPO_ROOT/scripts/setup-hooks.sh" \
   && grep -qF 'mv "$tmp" "$hook_path"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh stages hooks via mktemp and installs with an atomic mv (D000022 guard)"
else
  fail_test "setup-hooks.sh missing atomic mktemp-stage + mv install — a partial write can leave a truncated hook (D000022 guard)"
fi

# shellcheck disable=SC2016 # literal $hook_path/$backup are intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF 'cp -p "$hook_path" "$backup"' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh backs up a non-workbench hook to <hook>.bak before clobbering (D000022 guard)"
else
  fail_test "setup-hooks.sh missing .bak backup of non-workbench hooks — custom hooks lost unrecoverably (D000022 guard)"
fi

# D000022 (pre-landing-review hardening): the two failure-mode invariants below
# have no other static anchor, so a regression that drops them would stay green
# while re-opening exactly the bug classes D000022 exists to kill.
#   (a) exit $rc — setup-hooks.sh must propagate a non-zero exit so setup.sh's
#       `|| echo WARN >&2` guard fires; dropping it re-introduces the masked
#       partial-failure class (the original D000022 / PR #150 finding).
#   (b) backup-fail abort — if the .bak copy fails, install_hook must refuse to
#       overwrite (the design's "one unacceptable outcome": losing an un-backed
#       custom hook). The ERROR string is emitted only on that abort path,
#       immediately before its `return 1`, so its presence proves the branch.
# shellcheck disable=SC2016 # literal $rc is intentional — grepping for the exact source string in setup-hooks.sh
if grep -qF 'exit $rc' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh propagates a non-zero exit on hook-install failure (D000022 guard)"
else
  fail_test "setup-hooks.sh missing 'exit \$rc' — a failed hook install is masked from setup.sh's WARN guard (D000022 guard)"
fi

if grep -qF 'could not be backed up — refusing to overwrite' "$REPO_ROOT/scripts/setup-hooks.sh"; then
  ok "setup-hooks.sh aborts without clobbering when the .bak backup fails (D000022 guard)"
else
  fail_test "setup-hooks.sh missing backup-fail abort — an un-backed custom hook can be destroyed (D000022 guard)"
fi

echo ""
echo "Regression test (D000015): skills-deploy install overwrites drifted templates by default..."

# Background: pre-D000015, `skills-deploy install` defaulted to `overwrite=false`
# and skipped drifted templates with a WARN line. Users had to remember
# `--overwrite` for every routine deploy. D000015 flips the default: deploy
# overwrites by default; `--no-overwrite` is the new opt-out. `--overwrite` is
# kept as a tolerated no-op so D000013's post-merge hook (which still passes it)
# continues to work without modification.

# Check 1: default is overwrite=true
if grep -qE 'local skills=\(\) overwrite=true' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy default is overwrite=true (D000015)"
else
  fail_test "scripts/skills-deploy default is not overwrite=true — D000015 regressed"
fi

# Check 2: --no-overwrite flag is wired
if grep -qE -- '--no-overwrite\) overwrite=false' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy supports --no-overwrite opt-out (D000015)"
else
  fail_test "scripts/skills-deploy missing --no-overwrite flag handler (D000015 guard)"
fi

# Check 3: --overwrite is still tolerated (backwards compat with D000013's hook)
if grep -qE -- '--overwrite\) overwrite=true' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy still tolerates --overwrite as a no-op (backwards compat with D000013)"
else
  fail_test "scripts/skills-deploy dropped --overwrite handler — D000013 post-merge hook will break (D000015 guard)"
fi

# Check 4: WARN-and-skip language is gone (PRESERVE replaces it under --no-overwrite)
if ! grep -qF 'use --overwrite to replace' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy no longer emits 'use --overwrite to replace' (D000015)"
else
  fail_test "scripts/skills-deploy still references 'use --overwrite to replace' — D000015 regressed"
fi

# Check 5: help text documents --no-overwrite
if grep -qE 'install \[skill\.\.\.\] \[--no-overwrite\]' "$REPO_ROOT/scripts/skills-deploy"; then
  ok "scripts/skills-deploy help text documents --no-overwrite (D000015)"
else
  fail_test "scripts/skills-deploy help text not updated for D000015"
fi

# Check 6: CLAUDE.md reflects the new default
if grep -qF 'overwritten by default' "$REPO_ROOT/CLAUDE.md"; then
  ok "CLAUDE.md documents new default install behavior (D000015)"
else
  fail_test "CLAUDE.md still documents --overwrite as opt-in — D000015 docs not synced"
fi


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

# ---------- CJ_improve-queue: append path keeps TODOS.md POSIX-clean ----------
# Regression guard: build_row()'s output is captured via $(...), which strips
# the trailing newline; atomic_append must re-add exactly one so TODOS.md ends
# with a single \n after every append. All three modes (audit/evaluate/research)
# funnel through cmd_apply -> atomic_append, so this one path covers them all.
# A prior fix (commit 8c2ee8f) only patched the artifact, not the source — this
# test fails if the EOF newline regresses (dropped) or doubles (trailing blank
# line), on the FIRST append and on a SECOND consecutive append.
echo ""
echo "Checking CJ_improve-queue append path keeps TODOS.md POSIX-clean..."
_IQ_SCRIPT="$REPO_ROOT/skills/CJ_improve-queue/scripts/improve_queue.sh"
_IQ_FIX="$REPO_ROOT/tests/fixtures/CJ_improve-queue"
if [ -x "$_IQ_SCRIPT" ] && [ -f "$_IQ_FIX/sample-verdict-novel.json" ] && [ -f "$_IQ_FIX/sample-verdict-conflict.json" ]; then
  _IQ_TMP=$(mktemp -d -t improve-queue-eof.XXXXXX)
  (
    cd "$_IQ_TMP"
    git init -q
    git config user.email test@test.local
    git config user.name test
    printf '# TODOS\n\n- existing row\n' > TODOS.md
    git add TODOS.md && git commit -qm init
  ) >/dev/null 2>&1

  # assert TODOS.md ends with exactly one LF: last 2 bytes hex = "XX0a", XX != 0a.
  _iq_assert_single_lf() {  # $1=file  $2=label
    local l2
    l2=$(tail -c 2 "$1" | xxd -p | tr -d '\n')
    case "$l2" in
      0a0a) fail_test "$2: TODOS.md EOF has a trailing blank line (double \\n, last2=[$l2])" ;;
      *0a)  ok "$2: TODOS.md ends with exactly one trailing newline" ;;
      *)    fail_test "$2: TODOS.md missing trailing newline (last2=[$l2])" ;;
    esac
  }

  # 1st append (novel verdict).
  ( cd "$_IQ_TMP" && bash "$_IQ_SCRIPT" apply < "$_IQ_FIX/sample-verdict-novel.json" ) >/dev/null 2>&1
  _iq_assert_single_lf "$_IQ_TMP/TODOS.md" "CJ_improve-queue 1st append"

  # Commit row1, then 2nd append (conflict verdict — distinct signature, so it
  # appends rather than NO-OPs). Proves the fix recurs cleanly across appends.
  ( cd "$_IQ_TMP" && git add -A && git commit -qm row1 ) >/dev/null 2>&1
  ( cd "$_IQ_TMP" && bash "$_IQ_SCRIPT" apply < "$_IQ_FIX/sample-verdict-conflict.json" ) >/dev/null 2>&1
  _iq_assert_single_lf "$_IQ_TMP/TODOS.md" "CJ_improve-queue 2nd append"

  unset -f _iq_assert_single_lf
  rm -rf "$_IQ_TMP" /tmp/cj-improve-queue-lock
else
  echo "  SKIP: CJ_improve-queue script or fixtures missing, skipping EOF regression test"
fi

# T000011 MIRROR_SPECS sync-check block deleted in S000052 (F000023).
# The validate.sh Error check 10 MIRROR_SPECS machinery this block tested
# (drift detection, orphan FAIL-vs-WARN policy, manifest schema parity) was
# removed when work-copilot/ became canonical. No mirror = no drift = no
# corresponding test surface. The existence-check that replaces it is
# directly exercised by ./scripts/validate.sh on every CI run.

# Restore errexit after the S000010 test block.
set -e

# Integration: test-deploy.sh end-to-end (D000016)
# The wrapper-grep check at line ~388 confirms test-deploy.sh defines the jq()
# CRLF-stripping wrapper structurally. This phase actually RUNS test-deploy.sh
# end-to-end so template-ownership regressions in skills-deploy fail in CI loudly
# instead of rotting silently — closes the meta-bug behind D000016.
echo ""
echo "Running scripts/test-deploy.sh end-to-end..."
if "$REPO_ROOT/scripts/test-deploy.sh" >/dev/null 2>&1; then
  ok "scripts/test-deploy.sh passed end-to-end (skills-deploy template-ownership tests)"
else
  _td_rc=$?
  fail_test "scripts/test-deploy.sh failed end-to-end (rc=$_td_rc) — run \`./scripts/test-deploy.sh\` directly to see failures"
fi

# Smoke-test scripts/check-version-queue.sh
echo ""
echo "Smoke-testing scripts/check-version-queue.sh..."
if "$REPO_ROOT/scripts/check-version-queue.sh" >/dev/null 2>&1; then
  ok "scripts/check-version-queue.sh exits 0 on default (human-readable) invocation"
else
  _cvq_rc=$?
  fail_test "scripts/check-version-queue.sh failed on default invocation (rc=$_cvq_rc) — run \`./scripts/check-version-queue.sh\` directly to see"
fi
# Verify --json mode produces valid JSON (only when gh is online + authed; skip otherwise)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  _cvq_json=$("$REPO_ROOT/scripts/check-version-queue.sh" --json 2>/dev/null || true)
  if [ -n "$_cvq_json" ] && echo "$_cvq_json" | jq -e '.next' >/dev/null 2>&1; then
    ok "scripts/check-version-queue.sh --json emits valid JSON with .next field"
  else
    fail_test "scripts/check-version-queue.sh --json output is not valid JSON or missing .next field"
  fi
fi

# Regression test (F000025/S000054): /CJ_goal_todo_fix SKILL.md preamble sources
# scripts/cj-worktree-init.sh BEFORE Path Resolution / Routing.
# Mirrors the D000013 setup-hooks idiom — single grep per target SKILL.md.
# Without these, an upstream refactor could silently drop the auto-worktree
# wiring and the feature would regress to "polluting main checkout"
# behavior with no test signal.
# (F000035 v6.0.0 sunset: dropped the /CJ_goal_run + /CJ_goal_investigate shim
# assertions — both skills retired, files deleted.)
echo ""
echo "Regression test (F000025): /CJ_goal_todo_fix SKILL.md wires cj-worktree-init.sh..."

if grep -qE 'cj-worktree-init\.sh.*--caller todo' "$REPO_ROOT/skills/CJ_goal_todo_fix/SKILL.md"; then
  ok "skills/CJ_goal_todo_fix/SKILL.md sources cj-worktree-init.sh (--caller todo)"
else
  fail_test "skills/CJ_goal_todo_fix/SKILL.md missing cj-worktree-init.sh wiring (F000025 regression guard)"
fi

if grep -q 'cj-worktree-init\.sh' "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh" \
   && grep -qE '\-\-caller todo.*--force-create' "$REPO_ROOT/skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh"; then
  ok "skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh calls cj-worktree-init.sh with --caller todo --force-create"
else
  fail_test "drain-one-todo.sh missing per-iteration cj-worktree-init.sh --force-create call (F000025 regression guard)"
fi

# Helper test: 13-case behavior coverage (F000025 5 mutating-mode cases +
# T000033 8 --assert-isolated verdict cases + pipeline.md static-grep guard).
echo ""
echo "Running tests/cj-worktree-init.test.sh (13-case helper test)..."
if bash "$REPO_ROOT/tests/cj-worktree-init.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-worktree-init.test.sh: all 13 cases pass"
else
  _cwit_rc=$?
  fail_test "tests/cj-worktree-init.test.sh failed (rc=$_cwit_rc) — run \`bash tests/cj-worktree-init.test.sh\` directly to see"
fi

# Regression test (drain-one-todo worktree-init path resolution defect):
# drain-one-todo.sh must resolve scripts/cj-worktree-init.sh via the
# workbench-source path in ~/.claude/.skills-templates.json (.source) — the
# same convention todo_fix.sh / the single-TODO SKILL.md preamble / the
# F000009 update-check preamble use. The original BASH_SOURCE-relative
# `../../..` resolution silently broke from the deployed ~/.claude/ location
# (skills-deploy never deploys repo-root scripts/ there), so drain ran every
# TODO in-place and lost per-iteration worktree isolation (the F000025/S000054
# collision-avoidance the feature exists to provide).
echo ""
echo "Running tests/drain-one-todo-worktree-resolve.test.sh (deployed-path resolution)..."
if bash "$REPO_ROOT/tests/drain-one-todo-worktree-resolve.test.sh" >/dev/null 2>&1; then
  ok "tests/drain-one-todo-worktree-resolve.test.sh: deployed drain resolves cj-worktree-init.sh via manifest .source"
else
  _dwr_rc=$?
  fail_test "tests/drain-one-todo-worktree-resolve.test.sh failed (rc=$_dwr_rc) — run \`bash tests/drain-one-todo-worktree-resolve.test.sh\` directly to see"
fi

# Regression test (drain-one-todo silent in-place scaffold when worktree
# helper unavailable — distinct from D000021): when cj-worktree-init.sh is
# genuinely unreachable in drain dispatch context ($_WT_HELPER empty: manifest
# .source missing/empty/non-exec AND the BASH_SOURCE in-repo fallback also not
# executable), drain-one-todo.sh must FAIL LOUD (release lock; RESULT:
# STATUS=halted; REASON=worktree-helper-unavailable; exit 2) instead of
# silently delegating to todo_fix.sh and scaffolding the drained TODO into the
# current (possibly dirty / unrelated) branch. D000021 fixed only the path
# resolution; its RCA Insights explicitly scoped this silent-fallthrough out.
echo ""
echo "Running tests/drain-one-todo-helper-unavailable.test.sh (unreachable-helper fail-loud)..."
if bash "$REPO_ROOT/tests/drain-one-todo-helper-unavailable.test.sh" >/dev/null 2>&1; then
  ok "tests/drain-one-todo-helper-unavailable.test.sh: drain halts loud when cj-worktree-init.sh unreachable (no in-place scaffold)"
else
  _dhu_rc=$?
  fail_test "tests/drain-one-todo-helper-unavailable.test.sh failed (rc=$_dhu_rc) — run \`bash tests/drain-one-todo-helper-unavailable.test.sh\` directly to see"
fi

# (F000035 v6.0.0 sunset: removed the `tests/cj-goal-investigate-did-allocator.test.sh`
# runner block — the test exercised the /CJ_goal_investigate pipeline's D-ID
# allocator, which retired with the skill itself. The depth-3 nested-domain
# bug it guarded against is now CJ_goal_defect-territory; if that path
# regresses, a fresh test in the defect skill's TEST-SPEC owns the guard.)

# ─────────────────────────────────────────────────────────────────────────────
# D000NNN regression — cj_goal preamble doc-sync AUQ recommendation polarity.
# The 3 cj_goal SKILL.md preambles labelled A as "recommended on main", but
# upstream /document-release Step 1 hard-aborts on the base branch — so A
# always aborts on main; B (snooze) is the only path that works. The test
# asserts the literal AUQ-template wording matches the corrected polarity:
# B is recommended on main, A is recommended on a feature branch (and flagged
# as "WILL ABORT on main"). Also checks the CLAUDE.md mechanism note.
echo ""
echo "Running tests/cj-goal-doc-sync-auq-recommendation.test.sh (preamble AUQ polarity)..."
if bash "$REPO_ROOT/tests/cj-goal-doc-sync-auq-recommendation.test.sh" >/dev/null 2>&1; then
  ok "tests/cj-goal-doc-sync-auq-recommendation.test.sh: 2 live SKILL.md preambles (feature + defect) + CLAUDE.md match corrected polarity"
else
  _cgdsar_rc=$?
  fail_test "tests/cj-goal-doc-sync-auq-recommendation.test.sh failed (rc=$_cgdsar_rc) — run \`bash tests/cj-goal-doc-sync-auq-recommendation.test.sh\` directly to see"
fi

# (F000035 v6.0.0 sunset: removed the `tests/cj-goal-investigate-shim.test.sh`
# runner block — the test exercised the T000035 deprecation-shim contract for
# /CJ_goal_investigate, which has now been fully retired and deleted from disk.)

# ─────────────────────────────────────────────────────────────────────────────
# F000026 / S000056 — scripts/cj-handoff-gate.sh test rows
# Tests 1-11 of the TEST-SPEC, executed against the deterministic gate helper.
# Each test crafts a minimal git-diff fixture (raw + numstat) and feeds it to
# scripts/cj-handoff-gate.sh via --diff-from-file / --numstat-from-file +
# --base, then asserts exit code / stdout markers / stderr halt markers.
# ─────────────────────────────────────────────────────────────────────────────

GATE_HELPER="$REPO_ROOT/scripts/cj-handoff-gate.sh"
CJGA_FIX_DIR=$(mktemp -d -t cjga-fix-XXXXX)
# Defect 3 fix: compose with the existing suite-level EXIT trap (line 177)
# instead of clobbering it. Without composition, the suite-level trap that
# restores README.md / skills-catalog.json / VERSION / CHANGELOG.md and cleans
# up zzz-test-scaffold is silently overwritten — the checkout is left dirty
# after the run. The trap-union pattern below preserves both behaviors.
_OLD_EXIT_TRAP=$(trap -p EXIT | sed -E "s/^trap -- '(.*)' EXIT$/\\1/")
if [ -n "$_OLD_EXIT_TRAP" ]; then
  # Single-quote the cleanup portion so $CJGA_FIX_DIR expands at signal time,
  # not at trap-definition time (shellcheck SC2064). The previous-trap text is
  # already a literal command string from `trap -p`, so it composes safely.
  trap "${_OLD_EXIT_TRAP}; "'rm -rf "$CJGA_FIX_DIR"' EXIT
else
  trap 'rm -rf "$CJGA_FIX_DIR"' EXIT
fi

_write_markers_green() {
  local f="$1"
  cat > "$f" <<EOF
PIPELINE_END_STATE=green
SMOKE=pass
E2E=pass
PHASE2_GATES=checked
EOF
}

_write_markers_red() {
  local f="$1" key="$2" val="$3"
  cat > "$f" <<EOF
PIPELINE_END_STATE=green
SMOKE=pass
E2E=pass
PHASE2_GATES=checked
EOF
  # Patch the specific marker
  if command -v gsed >/dev/null 2>&1; then
    gsed -i "s/^$key=.*/$key=$val/" "$f"
  else
    sed -i.bak "s/^$key=.*/$key=$val/" "$f" && rm -f "$f.bak"
  fi
}

# Helper to build a single-entry raw-mode diff. Format per `git diff --raw -z`:
#   :100644 100644 <sha_a> <sha_b> <STATUS>\t<PATH>\0
# Multiple entries are NUL-separated. We build a single line then convert
# the trailing tab+path to NUL when writing the fixture.
_raw_entry() {
  local mode_a="$1" mode_b="$2" status="$3" path="$4"
  # Use printf %b so the trailing \0 is written literally.
  printf ':%s %s 1111111 2222222 %s\t%s\0' "$mode_a" "$mode_b" "$status" "$path"
}

echo ""
echo "=== F000026: scripts/cj-handoff-gate.sh deterministic tests ==="

if [ ! -x "$GATE_HELPER" ]; then
  fail_test "scripts/cj-handoff-gate.sh missing or not executable"
else
  ok "scripts/cj-handoff-gate.sh present + executable"
fi

# Test 1 (S1): denylisted-path change → exit non-zero
echo ""
echo "Test 1 (S1): denylist hit on skills/CJ_personal-workflow/SKILL.md"
_RAW="$CJGA_FIX_DIR/t1.raw"
_NUM="$CJGA_FIX_DIR/t1.numstat"
_MKR="$CJGA_FIX_DIR/t1.markers"
_raw_entry 100644 100644 M "skills/CJ_personal-workflow/SKILL.md" > "$_RAW"
printf '3\t0\tskills/CJ_personal-workflow/SKILL.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t1.err"; then
  fail_test "Test 1: gate should have halted on denylist hit, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t1.err"; then
    ok "Test 1: gate halted with [gate2-denylist] (correct)"
  else
    fail_test "Test 1: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 2a (S2): >120 added lines → exit non-zero
echo ""
echo "Test 2a (S2): size cap — 121 added lines"
_RAW="$CJGA_FIX_DIR/t2a.raw"
_NUM="$CJGA_FIX_DIR/t2a.numstat"
_MKR="$CJGA_FIX_DIR/t2a.markers"
_raw_entry 100644 100644 M "docs/notes.md" > "$_RAW"
printf '121\t0\tdocs/notes.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t2a.err"; then
  fail_test "Test 2a: gate should have halted on 121-line size cap, but exited 0"
else
  if grep -q '\[gate2-size-cap\]' "$CJGA_FIX_DIR/t2a.err"; then
    ok "Test 2a: gate halted with [gate2-size-cap] (correct)"
  else
    fail_test "Test 2a: gate halted but missing [gate2-size-cap] marker"
  fi
fi

# Test 2b (S2): >5 files → exit non-zero
echo ""
echo "Test 2b (S2): size cap — 6 files"
_RAW="$CJGA_FIX_DIR/t2b.raw"
_NUM="$CJGA_FIX_DIR/t2b.numstat"
_MKR="$CJGA_FIX_DIR/t2b.markers"
{
  _raw_entry 100644 100644 M "docs/a.md"
  _raw_entry 100644 100644 M "docs/b.md"
  _raw_entry 100644 100644 M "docs/c.md"
  _raw_entry 100644 100644 M "docs/d.md"
  _raw_entry 100644 100644 M "docs/e.md"
  _raw_entry 100644 100644 M "docs/f.md"
} > "$_RAW"
{
  printf '2\t0\tdocs/a.md\n'
  printf '2\t0\tdocs/b.md\n'
  printf '2\t0\tdocs/c.md\n'
  printf '2\t0\tdocs/d.md\n'
  printf '2\t0\tdocs/e.md\n'
  printf '2\t0\tdocs/f.md\n'
} > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t2b.err"; then
  fail_test "Test 2b: gate should have halted on 6-file size cap, but exited 0"
else
  if grep -q '\[gate2-size-cap\]' "$CJGA_FIX_DIR/t2b.err"; then
    ok "Test 2b: gate halted with [gate2-size-cap] (correct)"
  else
    fail_test "Test 2b: gate halted but missing [gate2-size-cap] marker"
  fi
fi

# Test 3 (S3): rename of denylisted file → exit non-zero (via --no-renames decomposition)
echo ""
echo "Test 3 (S3): rename of denylisted file (--no-renames surfaces as add+delete)"
_RAW="$CJGA_FIX_DIR/t3.raw"
_NUM="$CJGA_FIX_DIR/t3.numstat"
_MKR="$CJGA_FIX_DIR/t3.markers"
{
  _raw_entry 100644 000000 D "skills/CJ_personal-workflow/SKILL.md"
  _raw_entry 000000 100644 A "skills/foo.md"
} > "$_RAW"
{
  printf '0\t10\tskills/CJ_personal-workflow/SKILL.md\n'
  printf '10\t0\tskills/foo.md\n'
} > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t3.err"; then
  fail_test "Test 3: gate should have halted on rename-of-denylisted-file, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t3.err"; then
    ok "Test 3: rename surfaced as denylist hit via --no-renames decomposition (correct)"
  else
    fail_test "Test 3: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 4 (S4): new symlink → exit non-zero
echo ""
echo "Test 4 (S4): new symlink (mode 120000)"
_RAW="$CJGA_FIX_DIR/t4.raw"
_NUM="$CJGA_FIX_DIR/t4.numstat"
_MKR="$CJGA_FIX_DIR/t4.markers"
_raw_entry 000000 120000 A "docs/link.md" > "$_RAW"
printf '1\t0\tdocs/link.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t4.err"; then
  fail_test "Test 4: gate should have halted on new symlink, but exited 0"
else
  if grep -q '\[gate2-symlink\]' "$CJGA_FIX_DIR/t4.err"; then
    ok "Test 4: gate halted with [gate2-symlink] (correct)"
  else
    fail_test "Test 4: gate halted but missing [gate2-symlink] marker"
  fi
fi

# Test 5 (S5): test-surface change → exit non-zero
echo ""
echo "Test 5 (S5): test-surface weakening (tests/ change)"
_RAW="$CJGA_FIX_DIR/t5.raw"
_NUM="$CJGA_FIX_DIR/t5.numstat"
_MKR="$CJGA_FIX_DIR/t5.markers"
_raw_entry 100644 100644 M "tests/foo.test.sh" > "$_RAW"
printf '5\t2\ttests/foo.test.sh\n' > "$_NUM"
_write_markers_green "$_MKR"
if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t5.err"; then
  fail_test "Test 5: gate should have halted on tests/ touch, but exited 0"
else
  if grep -q '\[gate2-denylist\]' "$CJGA_FIX_DIR/t5.err"; then
    ok "Test 5: tests/ touch surfaced as denylist hit (correct)"
  else
    fail_test "Test 5: gate halted but missing [gate2-denylist] marker"
  fi
fi

# Test 6 (S6): frozen-base behavior — re-run with same fixture must yield identical
# stdout regardless of git-state. We exercise --base override + fixture path twice;
# the helper's counts depend solely on the fixture, so they MUST match.
echo ""
echo "Test 6 (S6): frozen-base regression — identical fixture, identical counts"
_RAW="$CJGA_FIX_DIR/t6.raw"
_NUM="$CJGA_FIX_DIR/t6.numstat"
_MKR="$CJGA_FIX_DIR/t6.markers"
_raw_entry 100644 100644 M "docs/notes.md" > "$_RAW"
printf '3\t0\tdocs/notes.md\n' > "$_NUM"
_write_markers_green "$_MKR"
_OUT_A=$("$GATE_HELPER" --base sha-A --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1)
_RC_A=$?
_OUT_B=$("$GATE_HELPER" --base sha-B --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1)
_RC_B=$?
# Counts must match (ignore the BASE= line which differs)
_COUNTS_A=$(echo "$_OUT_A" | grep -E '^(FILES|LINES|DENYLIST|PIPELINE_END_STATE|SMOKE|E2E|PHASE2_GATES|GATE_RESULT)=')
_COUNTS_B=$(echo "$_OUT_B" | grep -E '^(FILES|LINES|DENYLIST|PIPELINE_END_STATE|SMOKE|E2E|PHASE2_GATES|GATE_RESULT)=')
if [ "$_COUNTS_A" = "$_COUNTS_B" ] && [ "$_RC_A" = "$_RC_B" ]; then
  ok "Test 6: identical fixture yields identical gate decision (counts + exit code stable across --base override)"
else
  fail_test "Test 6: gate decision diverged across --base override (counts or rc differ)"
fi

# Test 7 (S7): QA predicate — fail each marker individually
echo ""
echo "Test 7 (S7): QA predicate (Phase-2 markers)"
_RAW="$CJGA_FIX_DIR/t7.raw"
_NUM="$CJGA_FIX_DIR/t7.numstat"
_raw_entry 100644 100644 M "docs/ok.md" > "$_RAW"
printf '3\t0\tdocs/ok.md\n' > "$_NUM"

for _key in PIPELINE_END_STATE SMOKE E2E PHASE2_GATES; do
  _MKR="$CJGA_FIX_DIR/t7.${_key}.markers"
  _write_markers_red "$_MKR" "$_key" "fail"
  if "$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" >/dev/null 2>"$CJGA_FIX_DIR/t7.${_key}.err"; then
    fail_test "Test 7 ($_key=fail): gate should have halted, but exited 0"
  else
    if grep -q '\[gate2-qa-marker\]' "$CJGA_FIX_DIR/t7.${_key}.err"; then
      ok "Test 7 ($_key=fail): gate halted with [gate2-qa-marker] (correct)"
    else
      fail_test "Test 7 ($_key=fail): gate halted but missing [gate2-qa-marker] marker"
    fi
  fi
done


# Test 12: green-path positive — denylist clean, ≤5 files, ≤120 lines, markers green → exit 0
echo ""
echo "Test 12: green-path positive (gate exits 0 when all conditions hold)"
_RAW="$CJGA_FIX_DIR/t12.raw"
_NUM="$CJGA_FIX_DIR/t12.numstat"
_MKR="$CJGA_FIX_DIR/t12.markers"
_raw_entry 100644 100644 M "docs/small.md" > "$_RAW"
printf '5\t1\tdocs/small.md\n' > "$_NUM"
_write_markers_green "$_MKR"
if _OUT=$("$GATE_HELPER" --base abc123 --diff-from-file "$_RAW" --numstat-from-file "$_NUM" --markers-file "$_MKR" 2>&1); then
  if echo "$_OUT" | grep -q '^GATE_RESULT=auto-approved$'; then
    ok "Test 12: gate exited 0 with GATE_RESULT=auto-approved (green path works)"
  else
    fail_test "Test 12: gate exited 0 but GATE_RESULT missing/incorrect; got: $(echo "$_OUT" | grep '^GATE_RESULT=')"
  fi
else
  fail_test "Test 12: gate should have exited 0 on green-path fixture, but halted; output: $_OUT"
fi

# Test 13: Check 14 USAGE.md drift fires and is overridable
# F000033/S000066: prove that validate.sh Check 14 detects SKILL.md > USAGE.md
# drift (ERRORs with the documented override command), and that bumping the
# last-updated frontmatter field silences it. Cleanup via PRIOR_SHA reset.
#
# Clean-tree gate (F000033 QA-reverify): the test creates temp commits via
# `git commit -am` and resets with `git reset --hard`. On an uncommitted tree
# the `-am` would sweep unrelated work into the temp commit, and the reset
# would then discard it. Skip in that context with a code-presence check so
# Check 14's source still gets verified. The full test runs in CI and in any
# post-/ship invocation (clean tree).
echo ""
echo "Test 13: Check 14 USAGE.md drift fires and is overridable"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  if grep -q '^echo "=== Check 14:' scripts/validate.sh \
     && grep -q 'is stale' scripts/validate.sh \
     && grep -q 'last-updated' scripts/validate.sh; then
    ok "Test 13: SKIP (uncommitted working tree); Check 14 source present (=== Check 14:, is stale, last-updated)"
  else
    fail_test "Test 13: SKIP requested (uncommitted working tree) but Check 14 source missing one of: '=== Check 14:', 'is stale', 'last-updated'"
  fi
else
  PRIOR_SHA=$(git rev-parse HEAD)
  trap 'git reset --hard "$PRIOR_SHA" >/dev/null 2>&1 || true; rm -f skills/CJ_system-health/USAGE.md.bak skills/CJ_system-health/SKILL.md.bak' EXIT
  # (a) Advance CJ_system-health/SKILL.md's %ct via trailing newline + commit
  echo "" >> skills/CJ_system-health/SKILL.md
  git commit -am "TEST: temp SKILL.md edit" >/dev/null 2>&1
  # (b) Re-run validate.sh; assert non-zero exit AND drift ERROR in output
  if _T13_OUT=$(./scripts/validate.sh 2>&1); then
    fail_test "Test 13: validate.sh should have exited non-zero after SKILL.md drift, but exited 0"
  else
    if echo "$_T13_OUT" | grep -qF "ERROR: skills/CJ_system-health/USAGE.md is stale"; then
      ok "Test 13a: validate.sh exited non-zero with stale-USAGE.md ERROR (drift detected)"
    else
      fail_test "Test 13a: validate.sh exited non-zero but missing 'ERROR: skills/CJ_system-health/USAGE.md is stale' substring; output: $_T13_OUT"
    fi
  fi
  # (c) Apply the documented override — ISO-8601 second-resolution timestamp.
  # Date-only would be a no-op when USAGE.md already shows today's date (common
  # case immediately after a freshly-created USAGE.md gets a sibling SKILL.md
  # edit). The pre-commit hook accepts the override commit because Check 14 is
  # staged-aware: USAGE.md appears in `git diff --cached --name-only` and is
  # treated as current.
  sed -i.bak 's/^last-updated:.*/last-updated: "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"/' skills/CJ_system-health/USAGE.md && rm skills/CJ_system-health/USAGE.md.bak
  git commit -am "TEST: apply override" >/dev/null 2>&1
  # (d) Re-run validate.sh; assert exit 0 AND PASS line in output
  if _T13_OUT2=$(./scripts/validate.sh 2>&1); then
    if echo "$_T13_OUT2" | grep -qF "PASS: skills/CJ_system-health/USAGE.md is current"; then
      ok "Test 13b: validate.sh exited 0 with USAGE.md current PASS (override silences drift)"
    else
      fail_test "Test 13b: validate.sh exited 0 but missing 'PASS: skills/CJ_system-health/USAGE.md is current' substring"
    fi
  else
    fail_test "Test 13b: validate.sh should have exited 0 after override, but exited non-zero; output: $_T13_OUT2"
  fi
  # (e) Cleanup — restore worktree via PRIOR_SHA reset (trap handles this on EXIT too)
  git reset --hard "$PRIOR_SHA" >/dev/null 2>&1
  trap - EXIT
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
