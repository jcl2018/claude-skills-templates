---
type: roadmap
parent: F000001
title: "personal-workflow — Roadmap"
date: 2026-04-24
author: chjiang
status: Draft
---

<!-- Migrated from F000001_feature-summary.md + F000001_milestones.md during
     F000008 v1.5.0 sweep. Section content preserved verbatim from the
     two source files for historical fidelity. The new doc-ROADMAP.md
     template suggests Scope / Non-Goals / Success Criteria / Decomposition
     / Delivery Timeline (with Delivery History sub-section) / Dependency
     Graph / Open Questions; refine over time as needed. -->

<!-- ===== From F000001_feature-summary.md ===== -->

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

## Decomposition

- [S000001 — Workflow Implementation](S000001_workflow_implementation/S000001_TRACKER.md) — full implementation, shipped via PRs #22, #24
- [S000006 — Personal-Workflow Knowledge Port](S000006_personal_workflow_port/S000006_TRACKER.md) — DEFERRED 2026-04-20 (evidence-gated unblock; absorbed from former F000004 on 2026-04-24)

## Non-Goals

- Knowledge-loading parity with company-workflow — DEFERRED via S000006 after `/autoplan` dual-voice CEO review converged NO-GO. Reopen condition: a specific personal-repo task where missing knowledge-loading is an observed blocker.
- Company/formal work-item tracking — owned by `company-workflow` (F000003), not this skill. Templates and lifecycle deliberately diverge.
- A separate `/workflow` router skill — built then removed in v0.2.2; the routing is now CLAUDE.md rules + per-skill commands.

<!-- ===== From F000001_milestones.md ===== -->

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Workflow router skill (SKILL.md + 4 subcommands) | — | Done | chjiang | Branch detection, work item resolution, phase detection, status menu | — |
| 2 | Template consolidation (4 tracker templates) | — | Done | chjiang | Solo-dev gates, removed review type, removed scrum, structured IDs | — |
| 3 | Add hierarchy field to artifact-manifests.json | — | Done | chjiang | Schema: feature->user-story (min 1), user-story->task (min 1) | — |
| 4 | Separate claims.json gate in check.md | — | Done | chjiang | Steps 1-5 skip if missing, Steps 6+ run regardless | — |
| 5 | Implement Steps 15-17 in check.md | — | Done | chjiang | Structural check + orphan detection, tree report, graph artifact | #3, #4 |
| 6 | Add badge taxonomy mapping | — | Done | chjiang | Map all existing statuses to 4 badge categories with severity | #5 |
| 7 | Add lifecycle cross-reference | — | Done | chjiang | "Broken down" checked + 0 children = LIFECYCLE_INCONSISTENT | #5 |
| 8 | Create tree.md + SKILL.md routing | — | Done | chjiang | /docs tree standalone subcommand, structural badges only | #5 |
| 9 | Human-readable report (Step 19) | — | Done | chjiang | .docs/work-item-report.md with tree, badge summary, findings | #5 |
| 10 | Update catalog + validate | — | Done | chjiang | Version bumps, test suite passes | #8 |
| 11 | Remove GENERATION-GUIDE templates | — | Done | chjiang | Deleted template, cleaned references in catalog/CLAUDE.md/PHILOSOPHY.md | — |
| 12 | Update tracker template Phase 1 + Phase 2 | — | Done | chjiang | Required doc lists per type, /office-hours design doc reference | — |
| 13 | Make doc triplet self-contained | — | Done | chjiang | PRD/ARCHITECTURE/TEST-SPEC expanded to cover all 3 consolidated areas | — |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Migrated content has no recorded delivery history
     entries; left empty. -->

- _none recorded at migration time_

## Dependency Graph

```
#1 workflow router ──────────────────────────────────────────────► #10 catalog
#2 template consolidation ───────────────────────────────────────► #10
#3 hierarchy field ──┐
                     ├──► #5 Steps 15-17 ──┬──► #6 badge taxonomy
#4 claims gate ──────┘                     ├──► #7 lifecycle xref
                                           ├──► #8 tree.md ──────► #10
                                           └──► #9 report
#11 GENERATION-GUIDE cleanup (independent)
#12 tracker template updates (independent)
#13 doc triplet update (independent)
```

## Open Questions

<!-- Questions still being decided. Migrated content has no recorded open
     questions; left empty intentionally. -->

| Question | Next check |
|----------|-----------|
| _none recorded at migration time_ | _N/A_ |
