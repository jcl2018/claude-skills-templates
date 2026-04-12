---
type: test-spec
parent: ""
feature: F000003_company_spec_system
title: "Company-Spec Work Item System — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: F000003_PRD.md
architecture: F000003_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Company tracker has required frontmatter | AC-1 | templates/company-workflow/ exists | Read tracker-feature.md frontmatter | Has name, type, workflow_type, status, created, updated, url | P0 | Unit |
| 2 | core | Company tracker has required sections | AC-1 | templates/company-workflow/ exists | Read tracker-feature.md sections | Lifecycle, Todos, Log, PRs, Files, Journal in expected order | P0 | Unit |
| 3 | core | Registry declares both sets | AC-2 | template-registry.json exists | Parse JSON | existing and company-workflow sets present | P0 | Unit |
| 4 | core | Validation passes for valid item | AC-3 | Valid work item created | Run company-workflow validate | Exit code 0 | P0 | Integration |
| 5 | core | Validation fails for invalid item | AC-3 | Invalid fixture exists | Run company-workflow validate on fixture | Exit code 1, stderr lists violations | P0 | Integration |
| 6 | resilience | Personal-dev templates unchanged | AC-4 | git clean state recorded | Compare templates/*.md before/after | Byte-identical | P0 | Unit |
| 7 | resilience | validate.sh passes | AC-4 | Company skill added | Run ./scripts/validate.sh | Exit code 0 | P0 | Integration |
| 8 | resilience | test.sh passes | AC-4 | Company skill added | Run ./scripts/test.sh | Exit code 0 | P0 | Integration |
| 9 | integration | Catalog entry valid | AC-5 | skills-catalog.json updated | Run validate.sh | company-workflow entry passes | P1 | Unit |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Company template frontmatter | All trackers have required YAML fields | `grep -c 'workflow_type' templates/company-workflow/tracker-*.md` |
| S2 | core | Company template sections | Sections match contract.json expected_order | `grep '## ' templates/company-workflow/tracker-feature.md` |
| S3 | core | Registry JSON validity | File parses without error | `python3 -c "import json; json.load(open('template-registry.json'))"` |
| S4 | resilience | Personal-dev untouched | No byte changes | `git diff --stat templates/*.md` returns empty |
| S5 | resilience | validate.sh passes | Catalog consistent | `./scripts/validate.sh` |
| S6 | core | Skill directory structure | All expected files present | `ls skills/company-workflow/` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Scaffold company work item | Create work item → validate against contract.json | Passes all contract rules | Pass: exit 0. Fail: any missing field |
| E2 | core | Validate invalid fixture | Run validate on fixtures/invalid-bad-frontmatter.md | Catches violation | Pass: exit 1, stderr names issue |
| E3 | integration | Deploy to test machine | Run skills-deploy install → check ~/.claude/templates/company-workflow/ | Templates deployed | Pass: 13 company templates present |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| skills-deploy subfolder support | Depends on current behavior; T000003 if needed | Low: manual workaround exists |
| Upstream spec sync | One-time import; no sync mechanism | Low: manual diff-and-copy |
| review type scaffolding | Company skill handles internally | Low: not needed from existing path |
