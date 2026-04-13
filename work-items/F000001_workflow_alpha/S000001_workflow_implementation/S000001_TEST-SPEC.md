---
type: test-spec
parent: S000001_workflow_implementation
feature: F000001_workflow_alpha
title: "Workflow Alpha Implementation — Test Specification"
version: 3
status: Done
date: 2026-04-11
updated: 2026-04-13
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

### Template Consolidation

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 1 | core | No multi-person fields | AC-1 | No "reviewer noted", "Linux branch", JIRA, workflow_type | P0 | Unit |
| 2 | core | Task lighter than feature | AC-3 | Task gate count < feature gate count | P0 | Unit |
| 3 | core | Review type removed | AC-6 | tracker-review.md does not exist | P0 | Unit |
| 4 | core | Structured IDs in templates | AC-5 | F/S/D/T prefix with 6-digit number | P0 | Unit |
| 5 | core | Valid frontmatter in all templates | — | All templates parseable | P0 | Unit |

### Structural Completeness

| # | Tag | Test Case | AC | Expected Result | Priority | Type |
|---|-----|-----------|-----|-----------------|----------|------|
| 6 | core | Feature with 0 stories flagged | AC-9 | F000002 flagged INCOMPLETE | P0 | Integration |
| 7 | core | Feature with stories passes | AC-10 | F000001 shows PASS | P0 | Integration |
| 8 | core | Story with 0 tasks flagged | AC-11 | INCOMPLETE flagged | P0 | Integration |
| 9 | core | Tree renders depth-first sorted | AC-12 | F000001 before F000002 | P0 | Integration |
| 10 | core | Tree shows 4 badges per node | AC-13 | template, lifecycle, traceability, structure | P0 | Integration |
| 11 | core | Badge shows worst severity | AC-14 | DRIFT + PASS -> DRIFT | P0 | Integration |
| 12 | core | Graph artifact emitted | AC-15 | .docs/work-item-graph.json created | P0 | Integration |
| 13 | core | Graph node has all fields | AC-16 | id, slug, type, state, path, parent, children, badges, completeness | P0 | Integration |
| 14 | core | Hierarchy from manifest | AC-17 | Rules read from artifact-manifests.json | P0 | Integration |
| 15 | resilience | Missing hierarchy warns | AC-18 | Warning, structural checks skipped | P0 | Integration |
| 16 | resilience | No claims.json still runs | AC-23 | Steps 1-5 skipped, Steps 6+ run | P0 | Integration |
| 17 | usability | /docs tree renders | AC-19 | Structural badges shown, others show "-" | P1 | Integration |
| 18 | core | Misplaced item detected | AC-20 | Task under feature flagged MISPLACED | P1 | Integration |
| 19 | observability | Lifecycle cross-reference | AC-22 | "Broken down" + 0 children = LIFECYCLE_INCONSISTENT | P1 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, in test.sh)

| # | Check | What It Validates |
|---|-------|-------------------|
| S1 | Hierarchy field in manifest | Structural rules declared |
| S2 | tree.md exists | /docs tree subcommand present |
| S3 | SKILL.md routes tree | Subcommand routing includes tree |
| S4 | No multi-person fields | Templates are solo-dev clean |
| S5 | No review type | tracker-review.md removed |
| S6 | Valid frontmatter | All SKILL.md files parseable |
| S7 | Catalog valid JSON | skills-catalog.json parseable |

### Tier 2: E2E Tests (require Claude execution)

| # | Scenario | Steps | Expected Outcome |
|---|----------|-------|-----------------|
| E1 | Full /docs check with structural | Run /docs check on repo | F000002 INCOMPLETE, tree rendered, graph emitted |
| E2 | /docs check without claims.json | Delete .docs/claims.json, run /docs check | Staleness skipped, work item checks run |
| E3 | /docs tree standalone | Run /docs tree | Tree with structural badges only |
| E4 | Full test suite | Run ./scripts/test.sh | 0 failures, RESULT: PASS |

## Coverage Notes

- Template consolidation tests (S4-S5, #1-5) are fully automated in test.sh
- Structural completeness tests (#6-19) require /docs check execution
- Creating F000001 itself served as the E2E test of the work item lifecycle
