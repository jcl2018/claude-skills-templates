---
type: feature-summary
parent: F000001_personal_workflow
title: "personal-workflow — Feature Summary"
date: 2026-04-24
author: chjiang
status: Backfill
---

<!-- Retroactive backfill: F000001 shipped before feature-summary.md was a
     required feature artifact for personal-workflow (added in this PR's
     manifest update). The original roll-up identity for this feature lives
     in F000001_TRACKER.md (Acceptance Criteria, Insights, Journal). This
     file exists for manifest compliance. -->

## Scope

`personal-workflow` is the solo-developer work-item validation skill in this
repo. It encodes a 4-phase lifecycle (Track → Implement → Review → Ship) into
tracker templates per work-item type (feature, user-story, task, defect),
backed by `personal-artifact-manifests.json` for type-specific artifact sets
and a `check`/`tree` command surface for structural validation. No multi-person
ceremony — solo-dev gates only.

## Success Criteria

- [x] 4-phase lifecycle encoded in tracker templates (Track → Implement → Review → Ship)
- [x] Type-specific artifact sets via `personal-artifact-manifests.json`
- [x] Solo-dev tracker templates (no multi-person ceremony)
- [x] Structural completeness validation in `/personal-workflow check`
- [x] Tree report and graph artifact (`/personal-workflow tree`, `work-item-graph.json`)
- [x] Final E2E validation: the work item that built the workflow was itself created using the workflow (S000001)

## Constituent User-Stories

- [S000001 — Workflow Implementation](S000001_workflow_implementation/S000001_TRACKER.md) — full implementation, shipped via PRs #22, #24
- [S000006 — Personal-Workflow Knowledge Port](S000006_personal_workflow_port/S000006_TRACKER.md) — DEFERRED 2026-04-20 (evidence-gated unblock; absorbed from former F000004 on 2026-04-24)

## Out-of-Scope

- Knowledge-loading parity with company-workflow — DEFERRED via S000006 after `/autoplan` dual-voice CEO review converged NO-GO. Reopen condition: a specific personal-repo task where missing knowledge-loading is an observed blocker.
- Company/formal work-item tracking — owned by `company-workflow` (F000003), not this skill. Templates and lifecycle deliberately diverge.
- A separate `/workflow` router skill — built then removed in v0.2.2; the routing is now CLAUDE.md rules + per-skill commands.
