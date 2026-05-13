---
type: roadmap
parent: "F000016"
title: "/CJ_ship-feature multi-story auto-iterate — Roadmap"
date: 2026-05-13
author: chjiang
status: Draft
---

## Scope

This feature makes `/CJ_ship-feature` drive multi-story features end-to-end without
manual intervention. After scaffolding a feature with N child user-stories, the wrapper
now auto-iterates: for each child it creates a branch off main, copies scaffold files,
runs `CJ_personal-pipeline --work-item-dir --suppress-final-gate`, ships a PR, and lands
it. Sequential delivery — each child merges to main before the next child starts.
Prerequisite: `CJ_personal-pipeline` gains a `--work-item-dir` flag (S000036) so it can
operate on pre-scaffolded dirs without a design doc. The multi-story loop itself lives in
`run.md` (S000037).

## Non-Goals

- Parallel child execution — sequential delivery only in v1; parallel adds race conditions on main
- Parent TRACKER copy per child PR — deferred; not required for impl+qa to function
- Auto-detection of N > 3 child threshold — v1 surfaces AUQ; v2 auto-dispatch as subagent
- Synthetic design docs per child — rejected approach (Approach C); not in scope
- Updating /autoplan or /plan-eng-review for multi-story awareness — separate feature if needed

## Success Criteria

- [ ] `/CJ_ship-feature <multi-story-feature-design-doc>` runs end-to-end without manual intervention for a 2-child feature on the happy path
- [ ] Each child PR diff = that child's scaffold + impl+qa changes only (no sibling contamination)
- [ ] No AUQs fire between /autoplan completion and each child's /ship diff-review
- [ ] `CJ_personal-pipeline --work-item-dir <dir>` works in standalone mode too
- [ ] `./scripts/validate.sh` passes; both skills version-bumped (0.1.0 → 0.2.0)

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000036](S000036_pipeline_work_item_dir_flag/S000036_TRACKER.md) | Add `--work-item-dir` flag to `CJ_personal-pipeline` | Open |
| [S000037](S000037_ship_feature_multi_story_loop/S000037_TRACKER.md) | Rewrite run.md Branch (b) multi-story loop | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000036: `--work-item-dir` flag in pipeline.md + SKILL.md | — | Not Started | chjiang | Standalone test: pick existing user-story dir, verify impl reaches Step 5 | — |
| 2 | S000037: Branch (b) rewrite in run.md | — | Not Started | chjiang | Start with 2-child scaffold fixture to validate git-ops loop | 1 |
| 3 | End-to-end test: minimal 2-story feature design doc → 2 separate PRs | — | Not Started | chjiang | Validate full happy path | 2 |
| 4 | Version bumps + skills-deploy install | — | Not Started | chjiang | `skills-catalog.json` both entries, SKILL.md files, deploy | 2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

## Dependency Graph

```
#1 --work-item-dir flag (S000036) --> #2 Branch (b) rewrite (S000037)
                                          |
                                          v
                                      #3 End-to-end test
                                          |
                                          v
                                      #4 Version bumps + deploy
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Child dir detection naming: is `S[0-9]*` the only convention? | Verify in personal-artifact-manifests.json / WORKFLOW.md before shipping S000037 |
| Context size limit for N > 3 children: inline Skills vs Agent subagents? | Decide during S000037 impl; v1 limit N ≤ 3 with AUQ for larger features |
