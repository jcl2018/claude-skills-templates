---
type: test-spec
parent: ""
feature: F000001_workflow_alpha
title: "workflow-alpha — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: F000001_PRD.md
architecture: F000001_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Feature work item scaffold | AC-1 | On feat/* branch, templates available | `/workflow track create --type feature` | work-items/{slug}/ with 5 artifacts | P0 | E2E |
| 2 | core | Defect work item scaffold | AC-5 | On fix/* branch | `/workflow track create --type defect` | TRACKER + RCA + test-plan (no PRD) | P0 | E2E |
| 3 | core | Status menu display | AC-2 | Active work item | `/workflow` | Name, type, branch, phase 1-4 progress | P0 | E2E |
| 4 | core | Branch auto-detection | AC-6 | On feat/workflow-alpha | `/workflow` | Resolves type=feature, slug=workflow-alpha | P0 | E2E |
| 5 | core | Contract gate at review | AC-4 | Work item with doc triplet | `/workflow review` | /contracts check invoked | P0 | E2E |
| 6 | core | Contract gate at ship | AC-4 | Work item with doc triplet | `/workflow ship` | /contracts check+test invoked | P0 | E2E |
| 7 | core | Evidence synthesis | AC-7 | Work item on branch with commits | `/workflow track` | Journal entries proposed from git log | P1 | E2E |
| 8 | core | Debug-backward mode | AC-8 | Defect work item | `/workflow implement` | 3-hypothesis testing, not build-forward | P1 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md has frontmatter | name + description present | `head -5 skills/workflow/SKILL.md \| grep -c '^---'` |
| S2 | core | All subcommand files exist | track.md, implement.md, review.md, ship.md | `ls skills/workflow/{track,implement,review,ship}.md` |
| S3 | core | Tracker templates exist per manifest type | feature, defect, task, user-story | `for t in feature defect task user-story; do [ -f templates/tracker-$t.md ]; done` |
| S4 | core | Doc templates exist | PRD, ARCHITECTURE, TEST-SPEC, RCA, test-plan, milestones | `for t in PRD ARCHITECTURE TEST-SPEC RCA test-plan milestones; do [ -f templates/doc-$t.md ]; done` |
| S5 | core | Catalog entry exists | docs in skills-catalog.json | `jq '.[] \| select(.name=="docs")' skills-catalog.json` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Create feature work item | 1. `git checkout -b feat/test-feature` 2. `/workflow track create` | work-items/test-feature/ with TRACKER + PRD + ARCHITECTURE + TEST-SPEC + milestones | All 5 files exist, placeholders replaced |
| E2 | core | View status | 1. With active work item 2. `/workflow` | Status menu with phase checklist | Phase progress matches TRACKER.md checkboxes |
| E3 | core | Task type scaffold | 1. `git checkout -b task/cleanup` 2. `/workflow track create --type task` | TRACKER + test-plan only | No PRD/ARCHITECTURE/TEST-SPEC |
| E4 | core | Evidence synthesis | 1. Make commits on branch 2. `/workflow track` | Proposed journal entries with commit SHAs | Entries grouped by type (fix → finding, etc.) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| gstack /review and /ship delegation | External dependency | If gstack skills change, delegation may break |
| Child items at depth 3 | Complex setup, P2 feature | Max depth enforced by code, not tested E2E |
| Scrum note generation | Output format varies | Manual inspection sufficient |
