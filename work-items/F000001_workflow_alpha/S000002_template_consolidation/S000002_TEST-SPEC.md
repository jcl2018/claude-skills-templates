---
type: test-spec
parent: S000002_template_consolidation
feature: F000001_workflow_alpha
title: "Work Item Template Consolidation — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: S000002_PRD.md
architecture: S000002_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | No enterprise gates in feature tracker | AC-1,2 | Updated tracker-feature.md | grep for "reviewer noted", "Linux branch" | Zero matches | P0 | Smoke |
| 2 | core | No enterprise gates in defect tracker | AC-1,2 | Updated tracker-defect.md | grep for "reviewer noted", "Linux branch" | Zero matches | P0 | Smoke |
| 3 | core | No enterprise gates in task tracker | AC-1,2 | Updated tracker-task.md | grep for "reviewer noted", "Linux branch" | Zero matches | P0 | Smoke |
| 4 | core | No enterprise gates in user-story tracker | AC-1,2 | Updated tracker-user-story.md | grep for "reviewer noted", "Linux branch" | Zero matches | P0 | Smoke |
| 5 | core | No enterprise gates in review tracker | AC-1,2 | Updated tracker-review.md | grep for "reviewer noted", "Linux branch" | Zero matches | P0 | Smoke |
| 6 | core | Clean frontmatter across all templates | AC-4 | All 5 templates updated | grep for "JIRA", "TFS", "workflow_type" | Zero matches | P0 | Smoke |
| 7 | core | Task tracker is lighter | AC-3 | Updated tracker-task.md | Count Phase 3+4 checkboxes vs tracker-feature.md | Task has fewer or equal gates | P0 | Smoke |
| 8 | resilience | Phase detection works with new gates | AC-6 | Work item using new template | Run `/workflow` | Correct phase displayed | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | No "reviewer noted" in any tracker | Enterprise review gates removed | `grep -rl "reviewer noted" templates/tracker-*.md` returns empty |
| S2 | core | No "Linux branch" in any tracker | Platform-specific gates removed | `grep -rl "Linux branch" templates/tracker-*.md` returns empty |
| S3 | core | No JIRA/TFS in any tracker | Enterprise URL fields removed | `grep -rl "JIRA\|TFS" templates/tracker-*.md` returns empty |
| S4 | core | No workflow_type in any tracker | Redundant field removed | `grep -rl "workflow_type" templates/tracker-*.md` returns empty |
| S5 | core | Review tracker has sub-gates | Consistent style | `grep -c "^- \[ \]" templates/tracker-review.md` returns > 4 |
| S6 | core | Task Phase 3 gate count | Lighter lifecycle | `sed -n '/Phase 3/,/Phase 4/p' templates/tracker-task.md \| grep -c "^- \[ \]"` ≤ feature count |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | resilience | Scaffold + phase detection | 1. `git checkout -b feat/test-consolidation` 2. `/workflow track create --type feature` 3. `/workflow` | Status menu shows Phase 1, 4 phases listed, gates use new language | All gates are solo-dev appropriate, phase count correct |
| E2 | core | Task scaffold | 1. `git checkout -b task/test-task` 2. `/workflow track create --type task` | Lighter tracker created | Fewer Phase 3+4 gates than feature |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Existing work items with old gate text | Phase detection counts checkboxes, not text | Old items still work, just have stale wording |
| skills-deploy template sync | Requires installed skills at ~/.claude/ | Manual test: `skills-deploy install --overwrite` |
