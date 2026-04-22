---
type: design
parent: F000004_knowledge_integration
title: "knowledge-integration — Feature Design"
version: 1
status: Backfill
date: 2026-04-22
author: chjiang
reviewers: []
---

<!-- Retroactive backfill: F000004 shipped before DESIGN.md was a required
     feature artifact (added in D000009, 2026-04-22). The original design
     decisions for this feature live in F000004_TRACKER.md (Journal +
     Insights) and in the nested user-story ARCHITECTURE.md files. This
     file exists for manifest compliance and as a thin index for future
     readers. -->

## Problem

See [F000004_TRACKER.md](F000004_TRACKER.md) Log/Insights. knowledge-integration added external-knowledge support to company-workflow: always-on loading, per-repo opt-in gate, and on-demand matching via the `AI_KNOWLEDGE_DIR` env var.

## Shape of the solution

Three user-stories (S000005 + knowledge helpers) delivered the feature across v0.12.0 (always-on loading + opt-in gate) and v0.13.0 (on-demand matching). Cross-story detail lives in the nested user-stories.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (see nested stories) | S-ids in this dir | (per-story TRACKER/PRD/ARCHITECTURE) |

## Big decisions

See `F000004_TRACKER.md` Journal and nested ARCHITECTURE docs for the design trail. Key themes: strict yml parsing, safe env var display, deterministic sort under `LC_ALL=C`, warning-on-stderr with zero-exit-code.

| # | Decision | Why |
|---|----------|-----|
| — | (captured in TRACKER Journal and nested ARCHITECTURE docs) | — |

## Risks & open questions

Feature shipped. Follow-ups tracked in `work-items/defects/` if any surface.

| Risk / Question | Next check |
|-----------------|-----------|
| — | — |

## Definition of done

Feature shipped across v0.12.0 and v0.13.0 (see CHANGELOG). Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

See `F000004_TRACKER.md`.

- (see TRACKER)

## Pointers

- Parent tracker: [F000004_TRACKER.md](F000004_TRACKER.md)
- Milestones: [F000004_milestones.md](F000004_milestones.md)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
