---
type: architecture
parent: S000001_workflow_implementation
feature: F000001_workflow_alpha
title: "Workflow Alpha Implementation — Architecture"
version: 3
status: Done
date: 2026-04-11
updated: 2026-04-13
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Three interconnected changes to the skill development workbench:

1. **Template consolidation**: All 4 tracker templates rewritten for solo-dev workflow. Removed review work item type, scrum, multi-person ceremony. Added structured IDs. Phase 1 lists required artifacts per type. Phase 2 for features/stories coordinates children; tasks/defects do direct implementation.
2. **Structural completeness** in /docs check: Three new steps (15-17) validate hierarchy, render a tree report, and emit a graph artifact. Plus /docs tree as a standalone subcommand.
3. **Human-readable report**: Step 19 writes .docs/work-item-report.md after all checks complete.

## Architecture

```
artifact-manifests.json
    │
    ├── types     -> per-type required artifacts + templates
    ├── hierarchy -> {feature->user-story (min 1), user-story->task (min 1)}
    └── placement -> {feature:root, defect:root, story:feature, task:story}
            │
            ▼
skills/docs/check.md
    │
    ├── Steps 1-5:  Staleness checks (skip if no claims.json)
    ├── Steps 6-14: Template, lifecycle, traceability checks
    ├── Step 15:    Structural completeness + orphan/misplaced detection
    ├── Step 16:    Tree report (depth-first, 4 badges per node)
    ├── Step 17:    Graph artifact (.docs/work-item-graph.json)
    └── Step 19:    Human-readable report (.docs/work-item-report.md)
            │
            ▼
skills/docs/tree.md -> Step 15 + Step 16 (structural badges only, others show "-")
```

### Components

| Component | Change Type | Description |
|-----------|------------|-------------|
| skills/docs/check.md | Modified | Add Steps 15-17, Step 19, separate claims.json gate, badge taxonomy |
| skills/docs/tree.md | New | Standalone tree subcommand |
| skills/docs/SKILL.md | Modified | Add /docs tree routing |
| artifact-manifests.json | Modified | Add hierarchy and placement fields |
| skills-catalog.json | Modified | Version bumps, add tree.md |
| templates/tracker-feature.md | Modified | Solo-dev gates, required doc lists, coordination Phase 2 |
| templates/tracker-user-story.md | Modified | Solo-dev gates, required doc lists, coordination Phase 2 |
| templates/tracker-task.md | Modified | Solo-dev gates, required doc lists, implementation Phase 2 |
| templates/tracker-defect.md | Modified | Solo-dev gates, required doc lists, /investigate + RCA |

### Removed

| File | Reason |
|------|--------|
| templates/tracker-review.md | Review work item type eliminated |
| templates/contract-PRD.md | Unused enforcement templates |
| templates/contract-ARCHITECTURE.md | Unused enforcement templates |
| templates/contract-TEST-SPEC.md | Unused enforcement templates |
| templates/GENERATION-GUIDE.md | Dead template, replaced by artifact-manifests.json |
| templates/*-GENERATION-GUIDE.md (3) | Dead templates |

### Data Flow

1. check.md reads artifact-manifests.json for hierarchy rules
2. Step 10 walks work-items/ recursively, builds Actual Model (type, parent, children, state per item)
3. Steps 11-14 run checks 1-3, accumulating badges per node
4. Step 15 reads hierarchy rules, counts children per type, flags INCOMPLETE/MISPLACED, checks placement rules
5. Step 16 calculates completeness counts, renders depth-first tree with all 4 badges per node
6. Step 17 serializes graph to .docs/work-item-graph.json
7. Step 19 writes human-readable report to .docs/work-item-report.md

### Badge Taxonomy

| Badge category | Status values (severity order) |
|---------------|-------------------------------|
| template | PASS < WARN (EXTRA) < DRIFT (missing field/section) < INCOMPLETE (MISSING artifact) |
| lifecycle | PASS < WARN < LIFECYCLE_INCONSISTENT |
| traceability | PASS < INFO (P1/P2 untested) < UNTESTED (P0 untested) |
| structure | PASS < INCOMPLETE < MISPLACED |

### Graph Artifact Schema (v1.0.0)

```json
{
  "version": "1.0.0",
  "generated_at": "ISO-8601",
  "generated_commit": "short-SHA",
  "nodes": [{
    "id": "F000001", "slug": "...", "type": "feature", "state": "Open",
    "path": "...", "parent": null, "children": [...],
    "badges": {"template": "PASS", "lifecycle": "PASS", "traceability": "PASS", "structure": "PASS"},
    "completeness": {"count": 1, "min": 1, "required_child": "user-story"}
  }],
  "edges": [],
  "structural_rules": {"feature": {"required_child": "user-story", "min": 1}, "user-story": {"required_child": "task", "min": 1}}
}
```

### Template Consolidation

| Change | Before | After |
|--------|--------|-------|
| Ship phase gates | "Reviewer noted findings", "Linux branch build passed" | /docs check + TEST-SPEC/test-plan verification + /ship (includes pre-landing review) + /land-and-deploy |
| ID format | Free-text | F/S/D/T + 6-digit + keywords |
| Phase 1 docs | Generic "produce docs" | Type-specific required doc list per artifact-manifests.json |
| Phase 2 (feature/story) | Direct implementation | Coordinates children |
| Phase 2 (task/defect) | Generic | Direct implementation with design doc reference |
| Multi-person fields | JIRA URL, workflow_type, reviewers | Removed |

## Error Handling

| Error condition | Response |
|----------------|----------|
| hierarchy field missing from manifest | Warn, skip structural checks |
| No work-items/ directory | Skip all work item checks |
| No claims.json | Skip Steps 1-5, continue to Step 6 |
| "Broken down" checked + 0 children | Flag LIFECYCLE_INCONSISTENT |

## Design Decisions

1. **Hierarchy rules in manifest, not hard-coded**: Enables per-project customization. Required field forces repos to be explicit.
2. **Badge taxonomy with severity ordering**: Worst-severity aggregation gives single-glance health.
3. **Separate /docs tree**: Quick structural view without running all check steps.
4. **Solo-dev gates over multi-person ceremony**: Gates like "reviewer noted findings" are meaningless for a solo developer.
5. **Feature/story Phase 2 coordinates children**: Implementation happens in tasks and defects (leaf nodes), not in features or stories.

## Historical Note

An intermediate /workflow router skill was built during development and removed in v0.2.2. Its track phase was replaced by CLAUDE.md rules (rules/work-items.md). Its implement, review, and ship phases were redundant with gstack /office-hours, /review, and /ship.
