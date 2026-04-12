---
type: test-spec
parent: S000003_structural_completeness
feature: F000001_workflow_alpha
title: "Structural Completeness + Tree Report — Test Specification"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Feature with 0 stories flagged | AC-1 | F000002 exists with 0 children | Run `/docs check` | `[INCOMPLETE] F000002_system_health_v1 — feature has 0 user-story children` | P0 | Integration |
| 2 | core | Feature with stories passes | AC-2 | F000001 has S000001, S000002, S000003 | Run `/docs check` | `[PASS] F000001_workflow_alpha — 3 user-story children` | P0 | Integration |
| 3 | core | Story with 0 tasks flagged | AC-3 | S000002 exists with 0 children | Run `/docs check` | `[INCOMPLETE] S000002_template_consolidation — user-story has 0 task children` | P0 | Integration |
| 4 | core | Story with tasks passes | AC-4 | S000001 has T000001 | Run `/docs check` | `[PASS] S000001_four_phase — 1 task child` | P0 | Integration |
| 5 | core | Tree renders depth-first sorted | AC-5 | F000001 + F000002 exist | Run `/docs check` | Tree shows F000001 before F000002, S000001 before S000002 | P0 | Integration |
| 6 | core | Tree shows 4 badges per node | AC-6 | Full work items exist | Run `/docs check` | Each node line shows template, lifecycle, traceability, structure | P0 | Integration |
| 7 | core | Badge shows worst severity | AC-7 | Item has DRIFT + PASS in template checks | Run `/docs check` | Template badge shows DRIFT | P0 | Integration |
| 8 | core | Graph artifact emitted | AC-8 | work-items/ exists | Run `/docs check` | `.docs/work-item-graph.json` created with version, nodes, edges, structural_rules | P0 | Integration |
| 9 | core | Graph node has all fields | AC-9 | F000001 exists | Run `/docs check` | Node has id, slug, type, state, path, parent, children, badges, completeness | P0 | Integration |
| 10 | core | Hierarchy from manifest | AC-10 | `hierarchy` field in artifact-manifests.json | Run `/docs check` | Rules read from manifest, not hard-coded | P0 | Integration |
| 11 | resilience | Missing hierarchy warns | AC-11 | Remove `hierarchy` field | Run `/docs check` | Warning about missing hierarchy, structural checks skipped | P0 | Integration |
| 12 | resilience | No claims.json still runs work items | AC-12 | Delete `.docs/claims.json` | Run `/docs check` | Steps 1-5 skipped with note, Steps 6+ run | P0 | Integration |
| 13 | usability | /docs tree renders | AC-13 | work-items/ exists | Run `/docs tree` | Tree rendered, structure badge shown, others show "—" | P1 | Integration |
| 14 | core | Task under feature = MISPLACED | AC-14 | T000002 directly under F000002 | Run `/docs check` | `[MISPLACED] T000002 — task not allowed as direct child of feature` | P1 | Integration |
| 15 | core | Placement rules enforced | AC-15 | Various items at various levels | Run `/docs check` | Root-level items: feature/defect only. Story inside feature. Task inside story. | P1 | Integration |
| 16 | observability | Lifecycle cross-reference | AC-16 | F000002 has "broken down" checked, 0 children | Run `/docs check` | LIFECYCLE_INCONSISTENT flagged | P1 | Integration |
| 17 | usability | Completeness counts shown | AC-17 | F000001 has 3 stories | Run `/docs check` | Tree shows "3 user-story children" | P2 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | hierarchy field exists in manifest | artifact-manifests.json has hierarchy key | `jq '.hierarchy' artifact-manifests.json` |
| S2 | core | tree.md exists | /docs tree subcommand file created | `test -f skills/docs/tree.md` |
| S3 | core | SKILL.md routes tree | Subcommand routing includes tree | `grep -q 'tree' skills/docs/SKILL.md` |
| S4 | core | Graph schema version | work-item-graph.json has version field | `jq '.version' .docs/work-item-graph.json` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | Full /docs check with structural | Run `/docs check` on repo with F000001 (complete) + F000002 (incomplete) | F000002 flagged INCOMPLETE, tree rendered, graph emitted | Binary: all 3 outputs correct |
| E2 | resilience | /docs check without claims.json | Delete .docs/claims.json, run `/docs check` | Staleness skipped, work item checks run, structural checks run | Binary: no crash, work item output present |
| E3 | usability | /docs tree standalone | Run `/docs tree` | Tree rendered with structural badges, no staleness output | Binary: tree output present, no staleness section |
