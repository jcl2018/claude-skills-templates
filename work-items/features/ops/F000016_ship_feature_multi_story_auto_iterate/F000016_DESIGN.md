---
type: design
parent: "F000016"
title: "/CJ_ship-feature multi-story auto-iterate — Feature Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_ship-feature` currently halts after scaffolding a multi-story feature (Branch (b)
of Step 3 in `run.md`) and prints manual instructions like
`/CJ_ship-feature <design-doc-for-child-1>`. Two problems:

1. Each child user-story has no design doc — the scaffold creates TRACKER.md + SPEC.md +
   TEST-SPEC.md in the child dir, but no `/office-hours` design doc exists per child. The
   "per-child invocation" hint is not executable as-is.
2. The user has to manually drive impl+qa+ship+land for every child — defeating the point
   of the orchestrator.

The fix: after scaffold detects N children, auto-iterate. For each child story, create a
per-child branch off main, copy that child's scaffold files, run impl+qa (AUQs suppressed),
ship as a separate PR, and land it. Sequential. Each child merges to main independently.

## Shape of the solution

Two coordinated changes (Approach B from /office-hours):

1. `CJ_personal-pipeline`: add `--work-item-dir <path>` flag so the pipeline can operate
   on a pre-scaffolded work item dir (no design doc required). This makes the pipeline
   a first-class interface beyond design-doc mode.
2. `run.md`: rewrite Branch (b) to enumerate child dirs, loop per child:
   branch off main → copy scaffold → run pipeline with `--work-item-dir` + `--suppress-final-gate`
   → /ship → /land-and-deploy.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Add `--work-item-dir` flag to pipeline | S000036 | [S000036_pipeline_work_item_dir_flag/S000036_TRACKER.md](S000036_pipeline_work_item_dir_flag/S000036_TRACKER.md) |
| Rewrite run.md Branch (b) multi-story loop | S000037 | [S000037_ship_feature_multi_story_loop/S000037_TRACKER.md](S000037_ship_feature_multi_story_loop/S000037_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Extend `pipeline.md` with `--work-item-dir`, not just patch run.md | Makes `--work-item-dir` a reusable first-class input mode for any caller, not a call-site hack. Satisfies P2 (user-corrected premise). |
| 2 | Per-child branches + per-child PRs (not combined PR) | Each PR diff = one story's scaffold + impl + tests. No mega-PR with N stories to review at once. Satisfies P3. |
| 3 | Suppress AUQs between /autoplan and per-child /ship | AUQs in subagent context are unreachable (S000026). Two wrapper gates remain: /autoplan final + /ship diff-review per child. Satisfies P4. |
| 4 | Approach B over Approach A (run.md only) | Approach A violates P3 (combined PR) and P4 (inline AUQs). Rejected. |
| 5 | Approach B over Approach C (synthetic design docs + recursive /CJ_ship-feature) | Approach C reruns /autoplan per child (~3-10 min × N children) on already-reviewed stories. Expensive, fragile. Rejected. |
| 6 | Step 4 sub-step 1 (footer check) skipped in --work-item-dir mode | DESIGN_DOC="" in this mode; footer check reads the design doc file. Carve-out: skip sub-step 1 only; sub-steps 2–4 run normally. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Child dir detection naming filter: uses `S[0-9]*` convention — misses non-S prefixes | Verify in personal-artifact-manifests.json / WORKFLOW.md before shipping S000037 |
| Context size with N > 3 children: inline /ship + /land-and-deploy adds ~4K tokens per child | v1 may limit to N ≤ 3; surface AUQ for larger features. Revisit in v2. |
| git state restoration if child fails mid-loop | S000037 implementation must restore repo to feature branch on failure (recoverable state) |
| Child branch naming collisions on re-run | Timestamp suffix in CHILD_BRANCH prevents collisions; resume guard checks for already-merged branches |

## Definition of done

- [ ] `/CJ_ship-feature <multi-story-feature-design-doc>` runs end-to-end without manual intervention for a 2-child feature on the happy path
- [ ] Each child story gets its own branch off main and its own PR
- [ ] Each child PR diff contains only that child's scaffold + impl+qa changes
- [ ] No AUQs fire between /autoplan completion and each child's /ship diff-review
- [ ] If child N fails, wrapper halts, reports failure, leaves repo on feature branch
- [ ] `CJ_personal-pipeline --work-item-dir <dir>` works standalone (not just from ship-feature)
- [ ] `./scripts/validate.sh` passes after all changes
- [ ] Both skills version bumped (0.1.0 → 0.2.0) in SKILL.md and skills-catalog.json

## Not in scope

- Parent TRACKER copy per child PR (reviewer convenience) — deferred to follow-up; not required for impl+qa to function
- Parallel child execution — sequential delivery is safe, parallel adds race conditions on main
- Auto-detection of N > 3 child threshold for subagent dispatch — v1 surface AUQ; v2 auto-detect
- Synthetic design docs per child — rejected approach (Approach C)
- Updating /autoplan or /plan-eng-review for multi-story awareness — out of scope for this feature

## Pointers

- Parent tracker: [F000016_TRACKER.md](F000016_TRACKER.md)
- Roadmap: [F000016_ROADMAP.md](F000016_ROADMAP.md)
- Design doc source: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-142519.md`
- Spike S000026 (AUQ unreachability in subagents): informs AUQ suppression design
