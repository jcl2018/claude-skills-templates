---
type: design
parent: F000008
title: "tracker-recut — Feature Design"
version: 1
status: Draft
date: 2026-05-05
author: chjiang
reviewers: []
---

<!-- Condensed distillation of the approved /office-hours design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260505-140754.md
     The full design (with reviewer concerns and migration inventory) lives there.
     This DESIGN.md captures problem, shape, big decisions, risks, definition of done, pointers. -->

## Problem

The personal-workflow skill's trackers and artifact set drifted away from the engineer's day-to-day workflow. Three concrete gaps:

1. `/office-hours` is listed as step 1 *inside* Phase 1 of feature/user-story trackers — implies the work-item exists before `/office-hours` runs, but `/office-hours` is the entry point that produces the design plan that the work-item is then scaffolded around.
2. Phase 3 collapses smoke (CI-resident automation, never re-edited) and E2E (manual pre-ship walkthrough) into one `[ ] TEST-SPEC verified` gate — losing the affordance the v1.4.0 TEST-SPEC restructure introduced.
3. Artifact redundancy: `feature-summary.md` overlaps `TRACKER.md` fields; `milestones.md` is often empty for small features; `PRD.md` + `ARCHITECTURE.md` are written and edited together as one logical "lock the spec" act but live in two separate files.

## Shape of the solution

New artifact set: feature 3, user-story 4, task 2, defect 3 (was 4/4/2/3). Each persistent doc maps 1:1 to a workflow step that produces it. `DESIGN.md` ← /office-hours; `SPEC.md` ← scaffold step (was PRD + ARCH); `TEST-SPEC.md` ← scaffold step (smoke + E2E sections); `ROADMAP.md` ← scaffold step (was feature-summary + milestones); `RCA.md` ← /investigate (defects); `test-plan.md` ← scaffold step (tasks/defects).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Templates + manifest + validator (introduces new shape) | S000014 | [S000014_TRACKER.md](S000014_templates_manifest_check_md/S000014_TRACKER.md) |
| Migrate 13 historical work items + F000008 itself to new shape | S000015 | [S000015_TRACKER.md](S000015_historical_migration/S000015_TRACKER.md) |
| Examples + fixtures + repo-level docs (CONTRIBUTING, PHILOSOPHY, registry, scripts) | S000016 | [S000016_TRACKER.md](S000016_examples_fixtures_repo/S000016_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Re-cut from scratch (not reflow-only or merge-only) | User picked C in /office-hours; "consolidate" implies artifact-level cleanup, not just text edits |
| 2 | Workflow-mirrored + strategic merges (not lean / TRACKER-heavy) | "the structure doc" (singular) phrasing carried the PRD+ARCH merge; lean would push too much into TRACKER and lose PR-diff hygiene |
| 3 | DESIGN.md inside work-item is condensed distillation (not verbatim copy or stub-only) | Preserves repo-grep value without bloating the repo with 300-line transcripts; full transcript stays in ~/.gstack/projects/ |
| 4 | /review bundled into /ship's internal review (not a separate Phase 3 gate) | User flipped on the merits when shown the tradeoff; Phase 3 stays at 4 gates |
| 5 | Single sweep PR (not two-phase, not legacy tolerance) | Matches v1.4.0 TEST-SPEC sweep pattern; no broken intermediate state; no permanent dual-shape complexity in check.md |
| 6 | SPEC.md preserves PRD's `### P0/P1/P2` priority sub-sections inside `## Requirements` | Keeps check.md Step 18 parser at filename-only change instead of full row-filter rewrite |
| 7 | F000008 self-migrates as part of S000015 sweep | F000008 scaffolds with current shape (since new templates don't exist yet during scaffolding); sweep migrates F000008 along with the 13 historical items in the same PR |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Step 18 parser regression — incidental `PRD`/`ARCHITECTURE` mentions at lines 84, 218, 220, 365 of check.md easy to miss | S000014 TEST-SPEC includes a grep-based smoke check covering all 4 lines |
| Sweep PR diff size (~60 distinct files, ~95 file ops) hard to review | S000016 commits in logical batches even within single PR (templates → migrations → repo-level surfaces) |
| `template-registry.json:9` `doc_types` mismatch silently breaking external consumers | S000016 must include the registry update; smoke test asserts the new array contents |
| `scripts/test-deploy.sh:414` path bug (`templates/` vs `templates/personal-workflow/`) | S000016 manual line-414 fix after sed; verify by running test-deploy.sh after change |
| F000008 self-migration order: must run AFTER S000014 lands manifest+templates, BEFORE S000015 finishes sweep | Sequence S000014 → S000015 (sweeps F000008 too) → S000016 |
| `/personal-workflow check` walk root verification — must not pick up `deprecated/work-items/F000003_*` | Confirm walk root is `work-items/` (not parent); spot-check check.md Step 14 directory walk after migration |

## Definition of done

- [ ] All 3 children shipped per their TRACKERs.
- [ ] `/personal-workflow check` on full `work-items/` tree returns zero findings (template, lifecycle, traceability all PASS).
- [ ] `./scripts/test.sh` passes (full suite).
- [ ] `./scripts/validate.sh` passes.
- [ ] VERSION bumped to v1.5.0; CHANGELOG entry written.
- [ ] Manual smoke: scaffold a hypothetical F999_smoke_test feature on a throwaway scratch dir with the new templates; verify check.md returns PASS; rollback throwaway.

## Not in scope

- company-workflow templates and `deprecated/work-items/F000003_*` — sealed history.
- `work-copilot/` byte-mirror — mirrors company-workflow only; unaffected.
- `test-plan.md` casing alignment — design Open Question 3 deferred.
- A `personal-copilot/` bundle mirroring the new shape for Copilot — would be a separate feature.
- Backward-compat / legacy-mode handling in `check.md` for old-shape work items.

## Pointers

- Parent tracker: [F000008_TRACKER.md](F000008_TRACKER.md)
- Roadmap: [F000008_ROADMAP.md](F000008_ROADMAP.md)
- Approved /office-hours design (full): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260505-140754.md`
- Predecessor: v1.4.0 TEST-SPEC restructure (commit abe411c, PR #57)
