---
type: design
parent: F000003_company_spec_system
title: "company-spec-work-item-system — Feature Design"
version: 1
status: Backfill
date: 2026-04-22
author: chjiang
reviewers: []
---

<!-- Retroactive backfill: F000003 shipped before DESIGN.md was a required
     feature artifact (added in D000009, 2026-04-22). The original design
     decisions for this feature live in F000003_TRACKER.md (Journal +
     Insights) and in the nested user-story ARCHITECTURE.md files. This
     file exists for manifest compliance and as a thin index for future
     readers. -->

## Problem

See [F000003_TRACKER.md](F000003_TRACKER.md) Log/Insights. company-spec-work-item-system established the `company-workflow` skill — a parallel track to personal-workflow with its own templates, artifact manifest, validation logic, and 4-phase lifecycle.

## Shape of the solution

A second work item skill targeting the company/formal workflow. Cross-story detail lives in the nested user-stories.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (see nested stories) | S-ids in this dir | (per-story TRACKER/PRD/ARCHITECTURE) |

## Big decisions

See `F000003_TRACKER.md` Journal, nested ARCHITECTURE docs, and the company-workflow philosophy notes at `skills/company-workflow/philosophy/`.

| # | Decision | Why |
|---|----------|-----|
| — | (captured in TRACKER Journal, nested ARCHITECTURE docs, and philosophy notes) | — |

## Risks & open questions

Feature shipped. Edge-case defects tracked in `work-items/defects/` (D000003 onward all trace to this feature's original design).

| Risk / Question | Next check |
|-----------------|-----------|
| — | — |

## Definition of done

Feature shipped. Backfill status only.

- [x] Feature shipped (status: closed in TRACKER)

## Not in scope

See `F000003_TRACKER.md`.

- (see TRACKER)

## Pointers

- Parent tracker: [F000003_TRACKER.md](F000003_TRACKER.md)
- Milestones: [F000003_milestones.md](F000003_milestones.md)
- Philosophy notes: [skills/company-workflow/philosophy/](../../../skills/company-workflow/philosophy/)
- Defect that required this file: [D000009](../../defects/D000009_personal_workflow_feature_missing_design_doc/D000009_TRACKER.md)
