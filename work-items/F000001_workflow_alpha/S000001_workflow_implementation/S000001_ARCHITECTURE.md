---
type: architecture
parent: S000001_workflow_implementation
feature: F000001_workflow_alpha
title: "Workflow Alpha Implementation — Architecture"
version: 1
status: Draft
date: 2026-04-11
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Extends `/docs check` with three new steps (15-17) that validate structural completeness of work items, render a tree report with per-node badges, and emit a machine-readable graph artifact. Also adds `/docs tree` as a standalone subcommand for quick hierarchy views, and separates the claims.json gate so work item checks run independently of narrative doc staleness.

## Architecture

```
artifact-manifests.json ──► hierarchy rules
         │                        │
         ▼                        ▼
check.md Step 10 ──────► Step 15 ──────► Step 16 ──────► Step 17
(Actual Model:            (structural     (tree report:    (graph artifact:
 walk work-items/,         check +         depth-first      JSON to .docs/
 parse TRACKERs)           orphan detect)  w/ 4 badges)     work-item-graph.json)
         │
         ▼
tree.md ────────► Step 15 + Step 16 (structural badges only, others show "—")
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/docs/check.md | claude-skills-templates | Modified | Add Steps 15-17, separate claims.json gate, add badge taxonomy mapping |
| skills/docs/tree.md | claude-skills-templates | New | Standalone tree subcommand (walk + render, no checks 1-3) |
| skills/docs/SKILL.md | claude-skills-templates | Modified | Add `/docs tree` routing |
| artifact-manifests.json | claude-skills-templates | Modified | Add `hierarchy` field |
| skills-catalog.json | claude-skills-templates | Modified | Version bump, add tree.md |

### Data Flow

1. check.md reads `artifact-manifests.json` for hierarchy rules
2. Step 10 walks `work-items/` recursively, builds Actual Model (type, parent, children, state per item)
3. Steps 11-14 run checks 1-3, accumulating badges per node
4. Step 15 reads hierarchy rules, counts children per type, flags INCOMPLETE/MISPLACED, checks placement rules
5. Step 16 calculates completeness counts, renders depth-first tree with all 4 badges per node
6. Step 17 serializes graph to `.docs/work-item-graph.json`

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `/docs tree` | `/docs tree` | Renders tree report with structural badges only |

### Modified APIs

| API | Change | Description |
|-----|--------|-------------|
| `/docs check` | Extended | New Steps 15-17, separated claims.json gate |

## Schema Changes

### artifact-manifests.json — new `hierarchy` field

```json
"hierarchy": {
  "feature": {"required_child": "user-story", "min": 1},
  "user-story": {"required_child": "task", "min": 1}
}
```

Required field. Missing = warn + skip structural checks. Malformed = warn + skip.

### Placement rules

| Type | Allowed placement |
|------|------------------|
| feature | root-level (direct child of work-items/) |
| defect | root-level (direct child of work-items/) |
| user-story | inside a feature directory |
| task | inside a user-story directory |

### Badge taxonomy mapping

| Badge category | Status values (severity order) |
|---------------|-------------------------------|
| template | PASS < WARN (EXTRA) < DRIFT (missing field/section) < INCOMPLETE (MISSING artifact) |
| lifecycle | PASS < WARN < LIFECYCLE_INCONSISTENT |
| traceability | PASS < INFO (P1/P2 untested) < UNTESTED (P0 untested) |
| structure | PASS < INCOMPLETE < MISPLACED |

### work-item-graph.json schema (v1.0.0)

```json
{
  "version": "1.0.0",
  "generated_at": "ISO-8601",
  "generated_commit": "short-SHA",
  "nodes": [{
    "id": "F000001",
    "slug": "F000001_workflow_alpha",
    "type": "feature",
    "state": "Open",
    "path": "work-items/F000001_workflow_alpha",
    "parent": null,
    "children": ["S000001", "S000002"],
    "badges": {
      "template": "PASS",
      "lifecycle": "PASS",
      "traceability": "PASS",
      "structure": "PASS"
    },
    "completeness": {"count": 2, "min": 1, "required_child": "user-story"}
  }],
  "edges": [],
  "structural_rules": {
    "feature": {"required_child": "user-story", "min": 1},
    "user-story": {"required_child": "task", "min": 1}
  }
}
```

### Claims.json gate change

Before: check.md stops at Step 2 if claims.json missing.
After: Steps 1-5 (staleness) skip with note if claims.json missing. Steps 6+ (work items) run regardless.

## Error Handling

| Error condition | Response |
|----------------|----------|
| `hierarchy` field missing from manifest | Warn, skip structural checks |
| `hierarchy` field malformed | Warn, skip structural checks |
| No work-items/ directory | Skip all work item checks (existing behavior) |
| No claims.json | Skip Steps 1-5, continue to Step 6 (new behavior) |
| "Broken down" checked + 0 children | Flag LIFECYCLE_INCONSISTENT in Check 2 output |

## Dependencies

- Step 10 Actual Model (existing, no changes needed)
- artifact-manifests.json (add hierarchy field)
- Normalization rules from Step 8 (existing, reused)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Hierarchy field missing in foreign repos | Medium | Low | Warn and skip structural checks gracefully |
| Badge taxonomy incomplete for future check statuses | Low | Low | New statuses added to mapping table when introduced |
| Graph artifact schema changes breaking consumers | Low | Medium | Version field enables forward compatibility |

## Design Decisions

1. **Hierarchy rules in manifest, not hard-coded:** Enables per-project customization. Required field (no fallback) forces repos to be explicit about their hierarchy expectations.
2. **Badge taxonomy with severity ordering:** Worst-severity aggregation gives a single-glance health indicator per node without losing detail in the flat check output.
3. **Separate /docs tree subcommand:** Quick structural view without running all 14+ check steps. Structural badges only, others show "—".
