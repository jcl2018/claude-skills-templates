---
type: test-spec
parent: S000004_artifact_enforcement
feature: F000003_company_spec_system
title: "Artifact Enforcement — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000004_PRD.md
architecture: S000004_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Manifest exists and parses | — | Skill created | Parse company-artifact-manifests.json | Valid JSON with 5 type entries | P0 | Unit |
| 2 | core | Feature missing PRD detected | AC-1 | Feature with tracker only | Run check | [MISSING] PRD.md | P0 | E2E |
| 3 | core | Defect missing RCA detected | AC-1 | Defect with tracker only | Run check | [MISSING] RCA.md | P0 | E2E |
| 4 | core | Task missing test-plan detected | AC-1 | Task with tracker only | Run check | [MISSING] test-plan.md | P0 | E2E |
| 5 | core | Review missing review-notes detected | AC-1 | Review with tracker only | Run check | [MISSING] review-notes.md | P0 | E2E |
| 6 | core | Frontmatter drift detected | AC-2 | Tracker missing workflow_type | Run check | [DRIFT] missing "workflow_type" | P0 | E2E |
| 7 | core | Section drift detected | AC-3 | Tracker missing Journal section | Run check | [DRIFT] missing "Journal" | P0 | E2E |
| 8 | core | Complete feature passes | AC-4 | Feature with all 5 artifacts | Run check | [PASS] for all 5 | P0 | E2E |
| 9 | core | Complete defect passes | AC-4 | Defect with all 3 artifacts | Run check | [PASS] for all 3 | P0 | E2E |
| 10 | core | Complete review passes | AC-4 | Review with all 2 artifacts | Run check | [PASS] for all 2 | P0 | E2E |
| 11 | resilience | /docs check unaffected | AC-5 | Both systems exist | Run /docs check | Does not read company manifest | P0 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | Manifest has 5 types | All work item types declared | `python3 -c "import json; d=json.load(open('skills/company-workflow/company-artifact-manifests.json')); assert len(d['types'])==5"` |
| S2 | core | Feature requires 5 artifacts | Correct count | `python3 -c "import json; d=json.load(open('skills/company-workflow/company-artifact-manifests.json')); assert len(d['types']['feature']['required'])==5"` |
| S3 | core | Defect requires 3 artifacts | Correct count | same pattern, assert 3 |
| S4 | core | Task requires 2 artifacts | Correct count | same pattern, assert 2 |
| S5 | core | Userstory requires 5 artifacts | Correct count | same pattern, assert 5 |
| S6 | core | Review requires 2 artifacts | Correct count | same pattern, assert 2 |

### Tier 2: E2E Tests (real end-to-end execution)

Each test scaffolds a work item with realistic input, then deliberately removes or
corrupts artifacts to test enforcement.

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Feature "Design a Twitter clone" — complete | Scaffold all 5 artifacts. Run `company-workflow check`. | [PASS] for tracker, PRD, ARCHITECTURE, TEST-SPEC, milestones. | Pass: 5x [PASS]. Fail: any [MISSING] or [DRIFT]. |
| E2 | core | Feature "Design a Twitter clone" — missing ARCHITECTURE | Scaffold all 5, delete ARCHITECTURE.md. Run check. | [MISSING] ARCHITECTURE.md. Other 4 show [PASS]. | Pass: exactly 1 [MISSING], 4 [PASS]. Fail: wrong count. |
| E3 | core | Defect "Payment double-charge on timeout" — complete | Scaffold tracker + RCA + test-plan. Run check. | [PASS] for all 3. | Pass: 3x [PASS]. |
| E4 | core | Defect — missing RCA | Scaffold tracker + test-plan only. Run check. | [MISSING] RCA.md. | Pass: [MISSING] names RCA. |
| E5 | core | Task "Add rate limiting to API" — complete | Scaffold tracker + test-plan. Run check. | [PASS] for both. | Pass: 2x [PASS]. |
| E6 | core | Userstory "As a buyer, I want to save payment methods" — complete | Scaffold all 5 artifacts. Run check. | [PASS] for all 5. Tracker has `type: userstory`. | Pass: 5x [PASS], type is `userstory` not `user-story`. |
| E7 | core | Review "Q3 security audit" — complete | Scaffold tracker + review-notes. Run check. | [PASS] for both. Tracker has `deadline` field, review-notes has `verdict` field. | Pass: 2x [PASS]. |
| E8 | core | Feature — tracker missing workflow_type | Scaffold complete feature, remove `workflow_type` line from tracker. Run check. | [DRIFT] TRACKER.md — missing required field "workflow_type". PRD/ARCH/TEST-SPEC/milestones still [PASS]. | Pass: 1 [DRIFT] + 4 [PASS]. |
| E9 | core | Feature — tracker missing Journal section | Scaffold complete feature, delete `## Journal` section from tracker. Run check. | [DRIFT] TRACKER.md — missing section "Journal". | Pass: [DRIFT] names Journal. |
| E10 | resilience | /docs check independence | Run `/docs check` before and after adding company enforcement. | Output identical both times. /docs check does not reference company manifest. | Pass: identical output. Fail: any new lines mentioning company. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Lifecycle consistency (parent/child state) | Deferred to future story | Low: enforcement covers artifact presence and structure |
| PRD→TEST-SPEC traceability | Deferred to future story | Med: traceability matters but is not a company spec requirement today |
| Enforcement on deeply nested items (depth 3) | Only tested at depth 1-2 | Low: depth 3 is rare |
