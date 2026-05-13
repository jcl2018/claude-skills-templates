---
type: design
parent: "S000036"
feature: "F000016"
title: "Add --work-item-dir flag to CJ_personal-pipeline — Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

<!-- Story-scope design doc. See parent F000016_DESIGN.md for feature context.
     Captures the problem this story solves, the architectural shape, key decisions,
     and risks. SPEC.md owns the requirements and AC. -->

## Problem

`CJ_personal-pipeline` today requires a design-doc path (`~/.gstack/projects/...design-*.md`).
Child user-stories scaffolded by a feature scaffold have no design doc — only TRACKER.md,
SPEC.md, and TEST-SPEC.md in the child dir. The pipeline cannot run impl+qa on these child
dirs without this flag. `run.md` Branch (b) multi-story loop (S000037) depends on
this flag to dispatch per-child pipeline runs.

This story adds `--work-item-dir <path>` as a first-class input mode to `pipeline.md` and
`SKILL.md`, making the pipeline reusable by any caller that has a pre-scaffolded work item
dir — not just the ship-feature wrapper.

## Shape of the solution

Two file changes:
1. `pipeline.md` Step 1: extend arg parser; gate existing DESIGN_DOC validation on override
   being absent; add `--work-item-dir` validation block when override is set; set `WORK_ITEM_DIR`
   from override and `DESIGN_DOC=""`.
2. `pipeline.md` Step 2: add Branch (e) at top — when `WORK_ITEM_DIR_OVERRIDE` is set, skip
   footer search and Phase 1 entirely; journal-write `[orchestrator] --work-item-dir mode`;
   continue to Step 4. Step 4 sub-step 1 (footer check) is explicitly skipped in this mode.
3. `pipeline.md` Step 9.1 + 9.3: handle empty DESIGN_DOC (telemetry field + summary line).
4. `SKILL.md`: update Usage section; bump version to 0.2.0.
5. `skills-catalog.json`: bump version entry.

The carve-out logic for Step 4 sub-step 1 is prose-level — the model carries the skip
as prose state (same pattern used elsewhere in pipeline.md for flag-state persistence
across Bash calls).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Skip Step 4 sub-step 1 (footer check) only; run sub-steps 2–4 normally | Footer check reads DESIGN_DOC file for `SCAFFOLDED →` line. DESIGN_DOC="" in this mode; check would fail or no-op. Sub-steps 2–4 (boundary check, multi-story guard, shape confirm) are still meaningful and run. |
| 2 | Preserve `~/.gstack/projects/` path guard inside `else` branch of WORK_ITEM_DIR_OVERRIDE check | Without this guard, `--work-item-dir` immediately errors with "design doc must be under ~/.gstack/projects/...". The guard must only apply when no override is set. |
| 3 | Telemetry: add `work_item_dir_mode: true` field | Lets future sunset analysis separate wrapper-invoked runs (via --work-item-dir) from standalone design-doc runs without ambiguity. |
| 4 | Summary line `Design: (work-item-dir mode — no design doc)` | Avoids blank output in Step 9.3; makes the mode explicit for operators reading logs. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `--suppress-final-gate` + `--work-item-dir` combination: both flags must coexist cleanly in Step 1 arg parser | Verify during impl: both flags independently set their respective variables; no ordering dependency |
| Tracker filename lookup for WORK_ITEM_DIR_OVERRIDE: Step 1 validation uses `find ... -name "*_TRACKER.md" -o -name "TRACKER.md"` — must match actual personal-artifact-manifests.json filename convention | Verify `S000036_TRACKER.md` pattern is found by `*_TRACKER.md` glob |

## Definition of done

- [ ] `CJ_personal-pipeline --work-item-dir <dir>` runs without error and skips scaffold
- [ ] `--suppress-final-gate` works in combination with `--work-item-dir`
- [ ] `./scripts/validate.sh` passes
- [ ] SKILL.md version bumped to 0.2.0; skills-catalog.json updated

## Not in scope

- `--work-item-dir` for defect/task work items (only user-story dirs used by S000037, but the flag is type-agnostic by design — no restriction needed)
- Validate.sh new test case for `--work-item-dir` mode (healthy, not blocking for v1 per design doc)

## Pointers

- Parent feature: [F000016_TRACKER.md](../F000016_TRACKER.md)
- Feature design: [F000016_DESIGN.md](../F000016_DESIGN.md)
- Sibling story: [S000037_ship_feature_multi_story_loop/S000037_TRACKER.md](../S000037_ship_feature_multi_story_loop/S000037_TRACKER.md)
- pipeline.md implementation sketch: F000016 design doc §"Change 1: pipeline.md — --work-item-dir flag"
