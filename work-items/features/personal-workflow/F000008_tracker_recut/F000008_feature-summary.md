---
type: feature-summary
parent: F000008
title: "tracker-recut — Feature Summary"
date: 2026-05-05
author: chjiang
status: Draft
---

## Scope

Re-cut the personal-workflow skill's tracker templates and artifact set so that every persistent doc maps 1:1 to a step in the engineer's actual workflow (`/office-hours` → `/personal-workflow templates` → implement → smoke + E2E → `/ship` → `/land-and-deploy`). Replaces the current 4/4/2/3 artifact mix (feature/user-story/task/defect) with 3/4/2/3 by merging redundant docs (PRD + ARCHITECTURE → SPEC, feature-summary + milestones → ROADMAP) and adding DESIGN.md to the user-story artifact set so the `/office-hours` distillation has a home there too.

## Success Criteria

- [ ] Tracker templates' Phase 3 gates surface smoke and E2E as separate, named checkpoints — not collapsed into "TEST-SPEC verified".
- [ ] No work-item artifact overlaps content with another (no feature-summary-vs-TRACKER duplication; no PRD-vs-ARCHITECTURE split-write).
- [ ] All 13 historical work items match the new shape after migration; `/personal-workflow check` passes with zero findings.
- [ ] `template-registry.json`, `personal-artifact-manifests.json`, `WORKFLOW.md`, `CONTRIBUTING.md`, `PHILOSOPHY.md` all reference the new artifact names; no stale PRD/ARCHITECTURE/feature-summary/milestones references in active surfaces.
- [ ] `./scripts/test.sh` and `./scripts/validate.sh` pass on the new shape.
- [ ] VERSION bumped to v1.5.0; CHANGELOG entry written.

## Constituent User-Stories

- [S000014 — Templates + manifest + check.md](S000014_templates_manifest_check_md/S000014_TRACKER.md)
- [S000015 — Historical migration](S000015_historical_migration/S000015_TRACKER.md)
- [S000016 — Examples + fixtures + repo-level surfaces](S000016_examples_fixtures_repo/S000016_TRACKER.md)

## Out-of-Scope

- company-workflow templates and `deprecated/work-items/F000003_*` — sealed by F000007; left as-is. The walk root for `/personal-workflow check` is `work-items/` not `deprecated/work-items/`, so they don't surface in reports either.
- `work-copilot/` byte-mirror — mirrors company-workflow only; unaffected.
- `test-plan.md` casing alignment for tasks/defects — kept lowercase per design Open Question 3.
- A future `personal-copilot/` bundle that mirrors personal-workflow into a Copilot-friendly format — would be a separate feature.
- Backward-compat / legacy-mode handling in `check.md` for old-shape work items — explicitly rejected per design (matches v1.4.0 TEST-SPEC sweep pattern).
