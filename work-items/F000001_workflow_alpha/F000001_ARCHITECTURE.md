---
type: architecture
parent: ""
feature: F000001_workflow_alpha
title: "Workflow Alpha — Architecture"
version: 2
status: Done
date: 2026-04-11
updated: 2026-04-13
author: chjiang
prd: F000001_PRD.md
reviewers: []
---

## Overview

The workflow alpha feature establishes a doc-first development lifecycle through three interconnected systems: (1) tracker templates encoding a 4-phase lifecycle with type-specific gates, (2) a declarative artifact manifest system for scaffolding, and (3) structural completeness validation in /docs check. The lifecycle phases (Track, Implement, Review, Ship) are encoded in templates, not a dedicated skill. Review and ship delegate to gstack /review and /ship.

## Architecture

```
rules/work-items.md (CLAUDE.md rules)
    │
    ├── Branch naming -> work item type
    ├── ID generation (F/S/D/T + 6-digit)
    ├── Directory structure conventions
    └── Scaffolding instructions
            │
            ▼
artifact-manifests.json
    │
    ├── types.feature.required     -> [tracker]
    ├── types.user-story.required  -> [tracker, prd, architecture, test-spec, milestones]
    ├── types.defect.required      -> [tracker, rca, test-plan]
    ├── types.task.required         -> [tracker, test-plan]
    ├── hierarchy              -> {feature->user-story, user-story->task}
    └── placement              -> {feature:root, story:feature, task:story}
            │
            ▼
templates/tracker-{type}.md
    │
    ├── Phase 1: Track   (scaffold docs, define scope)
    ├── Phase 2: Implement (children drive work / direct implementation)
    ├── Phase 3: Review  (/docs check + test verification + /review)
    └── Phase 4: Ship    (/ship + /land-and-deploy)
            │
            ▼
skills/docs/check.md (Steps 15-17)
    │
    ├── Step 15: Structural completeness + orphan/misplaced detection
    ├── Step 16: Tree report (depth-first, 4 badges per node)
    ├── Step 17: Graph artifact (.docs/work-item-graph.json)
    └── Step 19: Human-readable report (.docs/work-item-report.md)
```

### Components

| Component | Path | Description |
|-----------|------|-------------|
| Work item rules | rules/work-items.md | Branch conventions, scaffolding instructions, ID generation |
| Artifact manifest | artifact-manifests.json | Type-to-artifact mapping, hierarchy rules, placement rules |
| Feature tracker | templates/tracker-feature.md | 4-phase lifecycle with feature-specific gates |
| User-story tracker | templates/tracker-user-story.md | 4-phase lifecycle, coordinates children |
| Task tracker | templates/tracker-task.md | 4-phase lifecycle, lightweight gates |
| Defect tracker | templates/tracker-defect.md | 4-phase lifecycle with /investigate + RCA |
| Structural check | skills/docs/check.md | Steps 15-17 for hierarchy validation |
| Tree subcommand | skills/docs/tree.md | Standalone tree rendering |
| Doc templates | templates/doc-*.md | Scaffolding templates (PRD, ARCHITECTURE, etc.) |

### Template Resolution

```
1. $REPO_ROOT/templates/        (repo-local, highest priority)
2. ~/.claude/spec/templates/    (user spec system)
3. ~/.claude/templates/         (skills-deploy fallback)
```

### Hierarchy Model

| Type | Required child | Min | Allowed placement |
|------|---------------|-----|-------------------|
| feature | user-story | 1 | root (direct child of work-items/) |
| user-story | task | 1 | inside a feature directory |
| task | — | — | inside a user-story directory |
| defect | — | — | root (direct child of work-items/) |

### Badge Taxonomy

| Badge category | Status values (severity order) |
|---------------|-------------------------------|
| template | PASS < WARN < DRIFT < INCOMPLETE |
| lifecycle | PASS < WARN < LIFECYCLE_INCONSISTENT |
| traceability | PASS < INFO < UNTESTED |
| structure | PASS < INCOMPLETE < MISPLACED |

### Graph Artifact Schema (v1.0.0)

Written to `.docs/work-item-graph.json` with fields: version, generated_at, generated_commit, nodes (id, slug, type, state, path, parent, children, badges, completeness), edges, structural_rules.

## Design Decisions

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| Lifecycle in templates, not a skill | Tracker templates encode phases | Dedicated /workflow skill | Skill was redundant with gstack /review + /ship; templates are simpler and portable |
| Manifest-driven scaffolding | artifact-manifests.json | Hardcoded per-type logic | Extensible: add types without code changes |
| Hierarchy rules in manifest | Required field, no fallback | Hard-coded rules | Per-project customization |
| Badge worst-severity aggregation | Single badge per category per node | All individual check results | Single-glance health without losing detail in flat output |

## Historical Note

An intermediate `/workflow` router skill (skills/workflow/) was built and then removed in v0.2.2. Its track phase was replaced by CLAUDE.md rules (rules/work-items.md). Its implement, review, and ship phases were redundant with gstack /office-hours, /review, and /ship. The 4-phase lifecycle pattern persists in the tracker templates.
