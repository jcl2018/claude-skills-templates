---
type: design
parent: F000002_system_health
title: "system-health — Feature Design"
version: 1
status: Backfill
date: 2026-04-22
author: chjiang
reviewers: []
---

<!-- Retroactive backfill: F000002 shipped before DESIGN.md was a required
     feature artifact (added in D000009, 2026-04-22). The original design
     decisions for this feature live in F000002_TRACKER.md (Journal +
     Insights) and in the nested user-story ARCHITECTURE.md files. This
     file exists for manifest compliance and as a thin index for future
     readers. -->

## Problem

See [F000002_TRACKER.md](F000002_TRACKER.md) Log/Insights. system-health (originally scaffolded as `system_health_v1`) delivered the `~/.claude/` health dashboard skill — dependency graph, filesystem health checks, usage analytics, and a composite health score. Renamed 2026-04-24 so the feature represents the skill, not just its v1 cut.

## Shape of the solution

A standalone `system-health` skill shipped via the workbench. Cross-story detail lives in the nested user-stories under this directory.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (see nested stories) | S-ids in this dir | (per-story TRACKER/PRD/ARCHITECTURE) |

## Big decisions

See `F000002_TRACKER.md` Journal and the nested user-stories' ARCHITECTURE.md files for the design trail.

| # | Decision | Why |
|---|----------|-----|
| — | (captured in TRACKER Journal and nested ARCHITECTURE docs) | — |

## Risks & open questions

Feature shipped. Follow-ups tracked in `work-items/defects/`.

| Risk / Question | Next check |
|-----------------|-----------|
| — | — |

## Definition of done

Feature shipped. Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

See `F000002_TRACKER.md`.

- (see TRACKER)

## Pointers

- Parent tracker: [F000002_TRACKER.md](F000002_TRACKER.md)
- Roadmap: [F000002_ROADMAP.md](F000002_ROADMAP.md)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
