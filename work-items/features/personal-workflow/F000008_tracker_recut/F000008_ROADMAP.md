---
type: roadmap
parent: F000008
title: "tracker-recut — Roadmap"
date: 2026-05-05
author: chjiang
status: Draft
---

<!-- Migrated from F000008_feature-summary.md + F000008_milestones.md during
     F000008 v1.5.0 sweep. Section content preserved verbatim from the
     two source files for historical fidelity. The new doc-ROADMAP.md
     template suggests Scope / Non-Goals / Success Criteria / Decomposition
     / Delivery Timeline (with Delivery History sub-section) / Dependency
     Graph / Open Questions; refine over time as needed. -->

<!-- ===== From F000008_feature-summary.md ===== -->

## Scope

Re-cut the personal-workflow skill's tracker templates and artifact set so that every persistent doc maps 1:1 to a step in the engineer's actual workflow (`/office-hours` → `/personal-workflow templates` → implement → smoke + E2E → `/ship` → `/land-and-deploy`). Replaces the current 4/4/2/3 artifact mix (feature/user-story/task/defect) with 3/4/2/3 by merging redundant docs (PRD + ARCHITECTURE → SPEC, feature-summary + milestones → ROADMAP) and adding DESIGN.md to the user-story artifact set so the `/office-hours` distillation has a home there too.

## Success Criteria

- [ ] Tracker templates' Phase 3 gates surface smoke and E2E as separate, named checkpoints — not collapsed into "TEST-SPEC verified".
- [ ] No work-item artifact overlaps content with another (no feature-summary-vs-TRACKER duplication; no PRD-vs-ARCHITECTURE split-write).
- [ ] All 13 historical work items match the new shape after migration; `/personal-workflow check` passes with zero findings.
- [ ] `template-registry.json`, `personal-artifact-manifests.json`, `WORKFLOW.md`, `CONTRIBUTING.md`, `PHILOSOPHY.md` all reference the new artifact names; no stale PRD/ARCHITECTURE/feature-summary/milestones references in active surfaces.
- [ ] `./scripts/test.sh` and `./scripts/validate.sh` pass on the new shape.
- [ ] VERSION bumped to v1.5.0; CHANGELOG entry written.

## Decomposition

- [S000014 — Templates + manifest + check.md](S000014_templates_manifest_check_md/S000014_TRACKER.md)
- [S000015 — Historical migration](S000015_historical_migration/S000015_TRACKER.md)
- [S000016 — Examples + fixtures + repo-level surfaces](S000016_examples_fixtures_repo/S000016_TRACKER.md)

## Non-Goals

- company-workflow templates and `deprecated/work-items/F000003_*` — sealed by F000007; left as-is. The walk root for `/personal-workflow check` is `work-items/` not `deprecated/work-items/`, so they don't surface in reports either.
- `work-copilot/` byte-mirror — mirrors company-workflow only; unaffected.
- `test-plan.md` casing alignment for tasks/defects — kept lowercase per design Open Question 3.
- A future `personal-copilot/` bundle that mirrors personal-workflow into a Copilot-friendly format — would be a separate feature.
- Backward-compat / legacy-mode handling in `check.md` for old-shape work items — explicitly rejected per design (matches v1.4.0 TEST-SPEC sweep pattern).

<!-- ===== From F000008_milestones.md ===== -->

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000014: new templates + manifest + check.md updates land on branch | 2026-05-06 | Not Started | chjiang | doc-SPEC.md + doc-ROADMAP.md created; 4 old doc templates deleted; manifest v3.0.0; check.md Step 18 (5 line edits) + 4 incidentals; WORKFLOW.md 7 lines | — |
| 2 | S000015: 13 historical work items + F000008 itself swept to new shape | 2026-05-07 | Not Started | chjiang | 5 features → ROADMAP merge; 8 user-stories → SPEC merge + DESIGN stubs; F000008's feature-summary+milestones → ROADMAP; F000008's children's PRD+ARCH → SPEC | #1 |
| 3 | S000016: examples + fixtures + repo-level surfaces updated | 2026-05-07 | Not Started | chjiang | example-doc-{SPEC,ROADMAP}.md created, 4 example docs deleted, 2 example trackers rewritten; PHILOSOPHY/CONTRIBUTING/template-registry/scripts updated | #1 |
| 4 | `/personal-workflow check` + `./scripts/test.sh` + `./scripts/validate.sh` all pass | 2026-05-08 | Not Started | chjiang | Acceptance gate before /ship | #2, #3 |
| 5 | VERSION bump v1.5.0 + CHANGELOG entry | 2026-05-08 | Not Started | chjiang | Done as part of /ship workflow | #4 |
| 6 | /ship + /land-and-deploy | 2026-05-08 | Not Started | chjiang | Single sweep PR; auto-merge after CI; remote branch cleanup per CLAUDE.md note | #5 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Migrated content has no recorded delivery history
     entries; left empty. -->

- _none recorded at migration time_

## Dependency Graph

```
#1 (S000014: templates + manifest + check.md)
   ├──> #2 (S000015: historical migration including F000008 self-migration)
   └──> #3 (S000016: examples + fixtures + repo-level surfaces)
              ↓ (both required)
              #4 (validation + check pass)
                 ↓
                 #5 (version + changelog)
                    ↓
                    #6 (ship + deploy)
```

## Open Questions

<!-- Questions still being decided. Migrated content has no recorded open
     questions; left empty intentionally. -->

| Question | Next check |
|----------|-----------|
| _none recorded at migration time_ | _N/A_ |
