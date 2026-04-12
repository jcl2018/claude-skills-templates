---
type: test-spec
parent: S000003_template_registry
feature: F000003_company_spec_system
title: "Template Registry and Namespace Coexistence — Test Specification"
version: 2
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
architecture: S000003_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Registry file exists and parses | AC-1 | Repo root | Parse template-registry.json | Valid JSON with version and sets | P0 | Unit |
| 2 | core | Workbench set declared | AC-1 | Registry exists | Read workbench entry | path=templates/, types correct, contract=null | P0 | Unit |
| 3 | core | Company-workflow set declared | AC-2 | Registry exists | Read company-workflow entry | path=templates/company-workflow/, types correct, contract populated | P0 | Unit |
| 4 | resilience | Company subfolder has all 13 files | AC-3 | templates/company-workflow/ created | List directory | Exactly 13 files: 5 trackers + 8 docs | P0 | Unit |
| 5 | resilience | Root templates unchanged | AC-3 | Before/after state | git diff templates/*.md | Empty diff | P0 | Unit |
| 6 | core | Byte-identical to spec source | AC-4 | Files copied | diff each file against ~/Downloads/spec/templates/ | Zero differences per file | P0 | Unit |
| 7 | core | Tracker frontmatter complete | AC-5 | Templates present | Parse YAML frontmatter of each tracker | Field counts match spec (11-12 per tracker) | P0 | Unit |
| 8 | core | Section ordering preserved | AC-6 | Templates present | Extract ## headings from each tracker | Order matches contract.json expected_order | P0 | Unit |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Registry JSON validity | Parses without error | `python3 -c "import json; json.load(open('template-registry.json'))"` |
| S2 | core | Both sets declared | Two entries in sets | `python3 -c "import json; d=json.load(open('template-registry.json')); assert len(d['sets'])>=2"` |
| S3 | core | Company subfolder file count | Exactly 13 templates | `ls templates/company-workflow/*.md \| wc -l` equals 13 |
| S4 | core | All 5 trackers present | Named correctly | `ls templates/company-workflow/tracker-{feature,defect,task,user-story,review}.md` exits 0 |
| S5 | core | All 8 docs present | Named correctly | `ls templates/company-workflow/doc-{ARCHITECTURE,PRD,RCA,TEST-SPEC,milestones,review-notes,scrum,test-plan}.md` exits 0 |
| S6 | core | workflow_type in every tracker | Company-required field present | `grep -c 'workflow_type' templates/company-workflow/tracker-*.md` equals 5 |
| S7 | core | url in every tracker | Company-required field present | `grep -c 'url:' templates/company-workflow/tracker-*.md` equals 5 |
| S8 | resilience | Root templates untouched | No byte changes | `git diff --stat templates/*.md` empty |

### Tier 2: E2E Tests

Scaffolding E2E tests (E1-E8) moved to S000005_scaffold_work_items/S000005_TEST-SPEC.md.
Those tests require the `create` subcommand which is S000005 scope, not S000003.

S000003 Tier 2 tests are covered by T000002's test-plan (9 regression test cases, all Pass).

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Registry schema validation | No JSON Schema yet; hand-authored | Low: manual review catches errors in small file |
| Third template set addition | Not needed yet | Registry structure supports it; test when needed |
| skills-deploy subfolder support | Depends on current skills-deploy behavior | If deploy fails, T000003 patches it |
