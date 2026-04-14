---
type: test-spec
parent: S000003_company_workflow_implementation
feature: F000003_company_spec_system
title: "Company Workflow Implementation — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000003_PRD.md
architecture: S000003_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

### Template Registry

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 1 | core | Registry file exists and parses | AC-1 | Valid JSON with version and sets | P0 | Unit |
| 2 | core | Workbench set declared | AC-1 | path=templates/, types correct | P0 | Unit |
| 3 | core | Company-workflow set declared | AC-2 | path=templates/company-workflow/, contract populated | P0 | Unit |
| 4 | resilience | Company subfolder has all 13 files | AC-3 | Exactly 13 files: 5 trackers + 8 docs | P0 | Unit |
| 5 | resilience | Root templates unchanged | AC-6 | git diff templates/*.md empty | P0 | Unit |
| 6 | core | Byte-identical to spec source | AC-4 | Zero differences per file | P0 | Unit |
| 7 | core | Tracker frontmatter complete | AC-5 | Field counts match spec (11-12 per tracker) | P0 | Unit |
| 8 | core | Section ordering preserved | AC-5 | Order matches contract.json | P0 | Unit |

### Artifact Enforcement

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 9 | core | Manifest exists and parses | AC-7 | Valid JSON with 5 type entries | P0 | Unit |
| 10 | core | Feature missing PRD detected | AC-7 | [MISSING] PRD.md | P0 | E2E |
| 11 | core | Defect missing RCA detected | AC-7 | [MISSING] RCA.md | P0 | E2E |
| 12 | core | Task missing test-plan detected | AC-7 | [MISSING] test-plan.md | P0 | E2E |
| 13 | core | Review missing review-notes detected | AC-7 | [MISSING] review-notes.md | P0 | E2E |
| 14 | core | Frontmatter drift detected | AC-8 | [DRIFT] missing "workflow_type" | P0 | E2E |
| 15 | core | Section drift detected | AC-9 | [DRIFT] missing "Journal" | P0 | E2E |
| 16 | core | Complete feature passes | AC-10 | [PASS] for all 5 artifacts | P0 | E2E |
| 17 | core | Complete defect passes | AC-10 | [PASS] for all 3 | P0 | E2E |
| 18 | core | Complete review passes | AC-10 | [PASS] for all 2 | P0 | E2E |
| 19 | resilience | /docs check unaffected | AC-15 | Does not read company manifest | P0 | Integration |

### Scaffolding

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 20 | core | Scaffold feature creates 5 artifacts | AC-11 | tracker + PRD + ARCH + TEST-SPEC + milestones | P0 | E2E |
| 21 | core | Scaffold defect creates 3 artifacts | AC-11 | tracker + RCA + test-plan | P0 | E2E |
| 22 | core | Scaffold task creates 2 artifacts | AC-11 | tracker + test-plan, parent in frontmatter | P0 | E2E |
| 23 | core | Scaffold userstory creates 5 artifacts | AC-11 | tracker + PRD + ARCH + TEST-SPEC + milestones, type=userstory | P0 | E2E |
| 24 | core | Scaffold review creates 2 artifacts | AC-11 | tracker + review-notes, deadline field present | P0 | E2E |
| 25 | core | Placeholders filled correctly | AC-12 | name, id, date, branch, repo all populated | P0 | E2E |
| 26 | resilience | Scaffolded tracker passes validation | AC-16 | Exit 0 | P0 | E2E |
| 27 | resilience | Existing templates untouched after scaffold | AC-6 | SHA256 checksums identical | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Registry JSON validity | Parses without error | `python3 -c "import json; json.load(open('template-registry.json'))"` |
| S2 | core | Both sets declared | Two entries in sets | `python3 -c "import json; d=json.load(open('template-registry.json')); assert len(d['sets'])>=2"` |
| S3 | core | Company subfolder file count | Exactly 13 templates | `ls templates/company-workflow/*.md \| wc -l` equals 13 |
| S4 | core | All 5 trackers present | Named correctly | `ls templates/company-workflow/tracker-{feature,defect,task,user-story,review}.md` |
| S5 | core | All 8 docs present | Named correctly | `ls templates/company-workflow/doc-{ARCHITECTURE,PRD,RCA,TEST-SPEC,milestones,review-notes,scrum,test-plan}.md` |
| S6 | core | workflow_type in every tracker | Company-required field | `grep -c 'workflow_type' templates/company-workflow/tracker-*.md` equals 5 |
| S7 | core | url in every tracker | Company-required field | `grep -c 'url:' templates/company-workflow/tracker-*.md` equals 5 |
| S8 | resilience | Root templates untouched | No byte changes | `git diff --stat templates/*.md` empty |
| S9 | core | Manifest has 5 types | All types declared | Parse company-artifact-manifests.json, assert 5 types |
| S10 | core | Feature requires 5 artifacts | Correct count | Parse manifest, assert feature.required length = 5 |
| S11 | core | SKILL.md has create subcommand | Documented | `grep -q 'create' skills/company-workflow/SKILL.md` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps | Expected Outcome |
|---|-----|----------|-------|-----------------|
| E1 | core | Scaffold feature "google-search-clone" | create --type feature --name google-search-clone | 5 artifacts, validate exit 0, workflow_type present |
| E2 | core | Scaffold defect "login-500-expired-token" | create --type defect --name login-500-expired-token | 3 artifacts, RCA has Symptom section |
| E3 | core | Scaffold task "migrate-user-table" | create --type task --name migrate-user-table --parent S000003 | 2 artifacts, parent in frontmatter |
| E4 | core | Scaffold userstory "seller-product-listing" | create --type userstory --name seller-product-listing | 5 artifacts, type=userstory (no hyphen) |
| E5 | core | Scaffold review "q2-security-audit" | create --type review --name q2-security-audit | 2 artifacts, deadline field, Meetings/Handoff sections |
| E6 | resilience | Scaffold then verify no existing files touched | Record SHA256 before, scaffold, compare after | Checksums identical |
| E7 | core | Validate deliberately invalid work item | Create tracker missing workflow_type + url | Exit 1, violations listed |
| E8 | core | Scaffold all 5 types in sequence | Scaffold one of each, validate all | 5x exit 0, correct artifact counts |
| E9 | core | Enforcement on complete feature | Scaffold all 5 artifacts, run check | 5x [PASS] |
| E10 | core | Enforcement on incomplete feature | Scaffold, delete ARCHITECTURE.md, run check | [MISSING] ARCHITECTURE.md, 4x [PASS] |
| E11 | core | Enforcement frontmatter drift | Remove workflow_type from tracker, run check | [DRIFT] |
| E12 | core | Enforcement section drift | Delete Journal section, run check | [DRIFT] |
| E13 | resilience | /docs check independence | Run /docs check before and after | Identical output |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| skills-deploy subfolder support | Depends on current behavior; follow-up if needed | Low: manual workaround exists |
| Upstream spec sync | One-time import; no sync mechanism | Low: manual diff-and-copy |
| Concurrent scaffolding | Single-user repo | Low: no shared state |
| Enforcement on deeply nested items | Only tested depth 1-2 | Low: depth 3 rare |
| Registry schema validation | No JSON Schema yet | Low: manual review for small file |
