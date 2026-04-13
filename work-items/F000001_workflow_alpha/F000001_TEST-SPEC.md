---
type: test-spec
parent: ""
feature: F000001_workflow_alpha
title: "Workflow Alpha — Test Specification"
version: 2
status: Done
date: 2026-04-11
updated: 2026-04-13
author: chjiang
prd: F000001_PRD.md
architecture: F000001_ARCHITECTURE.md
reviewers: []
---

## Test Matrix

### Template System

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 1 | core | No multi-person fields in templates | AC-6 | No "reviewer noted", "Linux branch", JIRA, workflow_type | P0 | Unit |
| 2 | core | Task lighter than feature | AC-8 | Task gate count < feature gate count | P0 | Unit |
| 3 | core | Review type removed | AC-9 | tracker-review.md does not exist | P0 | Unit |
| 4 | core | Tracker templates have valid frontmatter | — | All templates parseable | P0 | Unit |

### Structural Completeness

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 5 | core | Feature with 0 stories flagged | AC-11 | F000002 flagged INCOMPLETE | P0 | Integration |
| 6 | core | Feature with stories passes | AC-11 | F000001 shows PASS | P0 | Integration |
| 7 | core | Tree shows 4 badges per node | AC-12 | Each node has template, lifecycle, traceability, structure | P0 | Integration |
| 8 | core | Graph artifact emitted | AC-13 | .docs/work-item-graph.json created | P0 | Integration |
| 9 | core | Hierarchy from manifest | AC-14 | Rules read from artifact-manifests.json | P0 | Integration |
| 10 | core | Misplaced item detected | AC-15 | Wrong parent type flagged MISPLACED | P1 | Integration |
| 11 | resilience | No claims.json still runs | AC-16 | Steps 1-5 skipped, Steps 6+ run | P0 | Integration |
| 12 | usability | /docs tree renders | AC-17 | Structural badges shown, others show "-" | P1 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, in test.sh)

| # | Check | What It Validates | Script/Command |
|---|-------|-------------------|---------------|
| S1 | Tracker templates exist per manifest | All 4 types have templates | `for t in feature defect task user-story; do test -f templates/tracker-$t.md; done` |
| S2 | Doc templates exist | PRD, ARCHITECTURE, TEST-SPEC, RCA, test-plan, milestones | `for t in PRD ARCHITECTURE TEST-SPEC RCA test-plan milestones; do test -f templates/doc-$t.md; done` |
| S3 | No multi-person fields | Solo-dev clean | `! grep -l 'reviewer noted\|Linux branch\|JIRA\|workflow_type' templates/tracker-*.md` |
| S4 | Hierarchy field in manifest | Structural rules declared | `jq '.hierarchy' artifact-manifests.json` |
| S5 | tree.md exists | /docs tree subcommand present | `test -f skills/docs/tree.md` |
| S6 | Catalog valid JSON | skills-catalog.json parseable | `jq . skills-catalog.json` |

### Tier 2: E2E Tests (require Claude execution)

| # | Scenario | Steps | Expected Outcome |
|---|----------|-------|-----------------|
| E1 | Full /docs check with structural | Run /docs check on repo | F000002 INCOMPLETE, tree rendered, graph emitted |
| E2 | /docs check without claims.json | Delete .docs/claims.json, run /docs check | Staleness skipped, work item checks run |
| E3 | /docs tree standalone | Run /docs tree | Tree with structural badges only |
| E4 | Full test suite | Run ./scripts/test.sh | 0 failures, RESULT: PASS |

## Coverage Notes

- Template system tests (S1-S3, #1-4) are fully automated in test.sh
- Structural completeness tests (#5-12) require /docs check execution
- Creating F000001 itself served as the E2E test of the work item lifecycle
