---
type: design
parent: "S000037"
feature: "F000016"
title: "Rewrite ship-feature.md Branch (b) multi-story loop — Design"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
reviewers: []
---

<!-- Story-scope design doc. See parent F000016_DESIGN.md for feature context. -->

## Problem

`run.md` Branch (b) today halts with manual instructions:
```
Multi-story feature scaffolded. Per-child invocation needed:
  /CJ_ship-feature <design-doc-for-child-1>
  /CJ_ship-feature <design-doc-for-child-2>
```
The hint is not executable — child user-stories have no design docs. The user must
manually drive impl+qa+ship+land for each child, defeating the orchestrator's purpose.

This story replaces that halt with an auto-iterate loop: enumerate child user-story dirs
(`S[0-9]*`), for each create a branch off main, copy scaffold files from the feature
branch, run `CJ_personal-pipeline --work-item-dir --suppress-final-gate` to do impl+qa,
invoke /ship for the PR, invoke /land-and-deploy to merge. Sequential. Depends on S000036
shipping first.

## Shape of the solution

One file: `skills/CJ_run/run.md`, Branch (b) section, plus small
extensions to `write_state()`, Step 6.1 telemetry, Step 6.2 summary, and the Decision
Gates section.

Key git-ops sequence per child:
1. `git fetch origin main` (ensure latest after prior child's merge)
2. `git checkout -b ${FEATURE_NAME}--${CHILD_NAME}-$(date +%Y%m%d-%H%M%S) origin/main`
3. `git checkout $FEATURE_BRANCH -- $CHILD_REL` (copy scaffold files from feature branch)
4. `git commit -m "scaffold: ${CHILD_NAME} (from ${FEATURE_NAME} feature scaffold)"`
5. Dispatch pipeline subagent (`--work-item-dir $CHILD_DIR --suppress-final-gate`)
6. On green: invoke /ship (GATE: diff-review AUQ fires here per child)
7. Invoke /land-and-deploy (merges + verifies)
8. `git checkout $FEATURE_BRANCH` (restore for next iteration)

Resume guard: check for already-merged branch matching `${FEATURE_NAME}--${CHILD_NAME}*`
before each child. Skip already-merged children on re-run.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Sequential child processing (not parallel) | Parallel adds race conditions on main: child N+1's branch creation could land ahead of child N's merge, causing conflicts. Sequential is safe and the diff-per-PR is clean. |
| 2 | Resume guard via `gh pr list --state merged` | Idempotency on re-run: a partially-completed multi-story run should not re-ship already-merged children. The timestamp suffix in CHILD_BRANCH prevents false-positive matches; the `startswith` check covers re-runs. |
| 3 | `git checkout $FEATURE_BRANCH -- $CHILD_REL` (not cherry-pick) | Sparse checkout of just the child's subdirectory. Cherry-pick requires a commit SHA and would include all changes in that commit (including sibling children). Sparse checkout is surgical. |
| 4 | v1: inline /ship + /land-and-deploy (Skill tool), not Agent subagent | For N ≤ 3 children (~4K tokens × N = ~12K tokens). Exceeding this causes context compaction mid-loop. v1 limits to N ≤ 3 with an AUQ for larger features. v2 dispatches as Agent subagents automatically. |
| 5 | Rename `multi_story_scaffold_only` → `multi_story_mode` in telemetry | `multi_story_scaffold_only: true` is misleading for a fully-green multi-story run. `multi_story_mode: true` is accurate for all multi-story invocations. The brittleness-trip-wire filter is updated to exclude `multi_story_mode: true` rows. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Child dir naming convention: `S[0-9]*` filter — does it match all user-story child dirs and exclude fixtures, docs? | Verify against personal-artifact-manifests.json and WORKFLOW.md before shipping |
| Context size for N > 3: inline /ship + /land-and-deploy overflow | v1: surface AUQ at loop start if CHILDREN_TOTAL > 3. v2: auto-dispatch as Agent subagents. Implement v1 guard during impl. |
| git state on child failure: is `git checkout $FEATURE_BRANCH` sufficient to restore? | Test with a deliberate pipeline failure on child 2. Verify repo is on feature branch and no partial files are staged. |

## Definition of done

- [ ] ship-feature.md Branch (b) auto-iterates over children without halting
- [ ] Resume guard works: re-run skips already-merged children
- [ ] Child pipeline failure halts loop and leaves repo on feature branch
- [ ] `./scripts/validate.sh` passes
- [ ] SKILL.md version bumped to 0.2.0; skills-catalog.json updated

## Not in scope

- Parent TRACKER copy per child PR (deferred to follow-up)
- Parallel child execution (v2)
- N > 3 auto-dispatch as Agent subagents (v2; v1 surfaces AUQ)

## Pointers

- Parent feature: [F000016_TRACKER.md](../F000016_TRACKER.md)
- Feature design: [F000016_DESIGN.md](../F000016_DESIGN.md)
- Depends on: [S000036_pipeline_work_item_dir_flag/S000036_TRACKER.md](../S000036_pipeline_work_item_dir_flag/S000036_TRACKER.md)
- ship-feature.md implementation sketch: F000016 design doc §"Change 3: ship-feature.md — Branch (b) rewrite"
