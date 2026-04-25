---
type: design
parent: F000001_personal_workflow
title: "personal-workflow — Feature Design"
version: 1
status: Backfill
date: 2026-04-22
author: chjiang
reviewers: []
---

<!-- Retroactive backfill: F000001 shipped before DESIGN.md was a required
     feature artifact (added in D000009, 2026-04-22). The original design
     decisions for this feature live in F000001_TRACKER.md (Journal +
     Insights) and in the nested user-story ARCHITECTURE.md files. This
     file exists for manifest compliance and as a thin index for future
     readers. -->

## Problem

See [F000001_TRACKER.md](F000001_TRACKER.md) Log/Insights. personal-workflow (originally scaffolded as `workflow_alpha`) was the founding feature of this workbench: it established the personal-dev work item standard, the 3-phase lifecycle, and the scaffolding conventions now used across every feature. Renamed and consolidated 2026-04-24 so each skill maps to exactly one feature; the deferred S000006 knowledge port from former F000004 is now a child here.

## Shape of the solution

A personal-dev work item skill (`personal-workflow`) with a template library, an artifact manifest, and a `check` command. Cross-story detail lives in the nested user-stories under this directory.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (see nested stories) | S000001+ | (per-story TRACKER/PRD/ARCHITECTURE) |

## Big decisions

See `F000001_TRACKER.md` Journal and the nested user-stories' ARCHITECTURE.md files for the real design trail. A faithful backfill would duplicate that content; pointers are preferred.

| # | Decision | Why |
|---|----------|-----|
| — | (captured in TRACKER Journal and nested ARCHITECTURE docs) | — |

## Risks & open questions

Feature shipped. Residual risks are tracked as follow-up defects (see `work-items/defects/` for D000001–D000008 which all trace back to edges of this original design).

| Risk / Question | Next check |
|-----------------|-----------|
| — | — |

## Definition of done

Feature shipped on {historical date}. Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

See `F000001_TRACKER.md`.

- (see TRACKER)

## Pointers

- Parent tracker: [F000001_TRACKER.md](F000001_TRACKER.md)
- Milestones: [F000001_milestones.md](F000001_milestones.md)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
