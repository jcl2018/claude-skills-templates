---
type: test-spec
parent: S000003_company_workflow_implementation
feature: F000003_company_spec_system
title: "Company Workflow Implementation — Test Specification"
version: 2
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
architecture: S000003_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

### Validate (shipped)

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 1 | validate | Valid tracker passes | Exit 0 | P0 | Pass |
| 2 | validate | Missing workflow_type caught | VIOLATION on stderr, exit 1 | P0 | Pass |
| 3 | validate | Missing section caught | VIOLATION naming section | P0 | Pass |
| 4 | validate | Section order violation caught | VIOLATION on stderr | P0 | Pass |
| 5 | validate | Lifecycle phase missing caught | VIOLATION naming phase | P0 | Pass |
| 6 | validate | Too few checkboxes caught | VIOLATION with count | P0 | Pass |
| 7 | validate | Invalid fixture fails | Exit 1, violations listed | P0 | Pass |
| 8 | validate | Root templates unchanged | git diff templates/*.md empty | P0 | Pass |

### Directory Mode Validate

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 9 | dir-validate | Manifest has 5 types | Valid JSON, 5 entries | P0 | Pending |
| 10 | dir-validate | Feature missing PRD (fixture) | [MISSING] PRD.md | P0 | Pending |
| 11 | dir-validate | Frontmatter drift | [DRIFT] missing required field | P0 | Pending |
| 12 | dir-validate | Complete feature passes (fixture) | 5x [PASS] | P0 | Pending |
| 13 | dir-validate | Type normalization | userstory and user-story both accepted | P0 | Pending |
| 14 | dir-validate | Unknown type | [WARN] type not recognized | P0 | Pending |
| 15 | dir-validate | No TRACKER.md in dir | Error message | P0 | Pending |
| 16 | dir-validate | Unresolved placeholder | [DRIFT] {PLACEHOLDER} detected | P0 | Pending |
| 17 | dir-validate | ID prefix stripping | S000003_PRD.md matches PRD.md | P0 | Pending |
| 18 | dir-validate | /docs check unaffected | Identical output before/after | P0 | Pending |

### Examples

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 19 | examples | 13 example files exist | ls examples/ = 13 files | P0 | Pending |
| 20 | examples | Each example has valid frontmatter | Parse YAML, required fields present | P0 | Pending |
| 21 | examples | No unresolved placeholders | grep {PLACEHOLDER} = 0 matches | P0 | Pending |
| 22 | examples | Example per tracker template | 5 tracker examples match 5 tracker templates | P0 | Pending |
| 23 | examples | Example per doc template | 8 doc examples match 8 doc templates | P0 | Pending |

### skills-deploy Subdirectory Fix

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 24 | deploy-fix | Subdirs symlinked after install | `ls -la ~/.claude/skills/company-workflow/` shows examples/, reference/, philosophy/, fixtures/ as symlinks | P0 | Pending |
| 25 | deploy-fix | Symlink targets correct | Each subdir symlink points to repo source (`skills/company-workflow/{dir}`) | P0 | Pending |
| 26 | deploy-fix | Top-level files still work | SKILL.md, WORKFLOW.md, contract.json, company-artifact-manifests.json all symlinked | P0 | Pending |
| 27 | deploy-fix | Other skills unaffected | Skills without subdirs deploy identically to before | P0 | Pending |
| 28 | deploy-fix | Overwrite mode works | `skills-deploy install --overwrite` replaces existing subdir symlinks | P0 | Pending |

### Delivery

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 29 | deliver | skills-deploy installs skill dir | ~/.claude/skills/company-workflow/ exists | P0 | Pending |
| 30 | deliver | skills-deploy installs templates | ~/.claude/templates/company-workflow/ has 13 files | P0 | Pending |
| 31 | deliver | Examples deployed | ~/.claude/skills/company-workflow/examples/ has 13 files | P0 | Pending |
| 32 | deliver | Reference guides deployed | ~/.claude/skills/company-workflow/reference/ has 7 files | P0 | Pending |
| 33 | deliver | Philosophy docs deployed | ~/.claude/skills/company-workflow/philosophy/ has 3 files | P0 | Pending |
| 34 | deliver | WORKFLOW.md deployed | ~/.claude/skills/company-workflow/WORKFLOW.md exists | P0 | Pending |
| 35 | deliver | Validate works after deploy | Run validate from deployed path, exit 0 | P0 | Pending |

### Portability

| # | Tag | Test Case | Expected Result | Priority | Status |
|---|-----|-----------|-----------------|----------|--------|
| 36 | deploy | Skill works without gstack | cp to temp repo, validate runs | P0 | Pending |

## Test Tiers

### Tier 1: Smoke Tests

| # | Check | What It Validates |
|---|-------|-------------------|
| S1 | Registry JSON valid | `python3 -c "import json; json.load(open('template-registry.json'))"` |
| S2 | Both sets declared | 2+ entries in registry |
| S3 | 13 company templates present | `ls templates/company-workflow/*.md \| wc -l` |
| S4 | All 5 trackers present | tracker-{feature,defect,task,user-story,review}.md |
| S5 | All 8 docs present | doc-{ARCHITECTURE,PRD,RCA,TEST-SPEC,milestones,review-notes,scrum,test-plan}.md |
| S6 | workflow_type in every tracker | `grep -c workflow_type` = 5 |
| S7 | Root templates untouched | `git diff --stat templates/*.md` empty |
| S8 | Manifest has 5 types | Parse company-artifact-manifests.json |
| S9 | SKILL.md has no gstack refs | `grep -c gstack skills/company-workflow/SKILL.md` = 0 |
| S10 | 13 examples present | `ls skills/company-workflow/examples/*.md \| wc -l` = 13 |
| S11 | No placeholders in examples | `grep -r '{PLACEHOLDER}' examples/` = 0 |
| S12 | WORKFLOW.md present | `[ -f skills/company-workflow/WORKFLOW.md ]` |
| S13 | Subdirs deployed as symlinks | `[ -L ~/.claude/skills/company-workflow/examples ]` after install |

### Tier 2: E2E Tests

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| E1 | Validate complete feature dir | Run validate on valid-feature-dir/ fixture | 5x [PASS] |
| E2 | Validate incomplete feature dir | Run validate on invalid-missing-artifact-dir/ fixture | [MISSING] PRD + others |
| E3 | Validate file mode | Run validate on valid-feature-dir/TRACKER.md | exit 0 |
| E4 | Validate invalid file | Run validate on invalid-bad-frontmatter.md | exit 1, violations |
| E5 | Portability | cp skill to temp repo, run validate | exit 0 |
| E6 | Deploy subdirs | Run skills-deploy install, check examples/ reference/ philosophy/ are symlinks | All 4 subdirs symlinked |
| E7 | Delivery | Run skills-deploy install, verify all files at ~/.claude/ | All files + examples + WORKFLOW.md present |
| E8 | Deployed validate | After deploy, run validate on a fixture from ~/.claude/ path | exit 0 |
| E9 | Examples complete | Verify 1:1 mapping between templates and examples | 13 pairs |
| E10 | No regression on other skills | Run skills-deploy install, verify system-health skill unchanged | Identical to before |

## Coverage Gaps

| Gap | Why | Risk |
|-----|-----|------|
| Concurrent scaffolding | Single-user repo | Low |
| Enforcement depth 3+ | Only tested 1-2 | Low |
| Cross-machine deploy | Only tested local install | Med |
