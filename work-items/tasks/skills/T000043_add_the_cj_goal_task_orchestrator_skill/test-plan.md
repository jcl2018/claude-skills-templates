---
type: test-plan
parent: T000043
title: "add the CJ_goal_task orchestrator skill (the small-task verb) — Test Plan"
date: 2026-06-07
author: Charlie
status: Passed
---

## Scope

Adds the `/CJ_goal_task` orchestrator (the `task` verb of the cj_goal family):
`skills/CJ_goal_task/{SKILL.md,pipeline.md,USAGE.md,scripts/cj-task-scaffold.sh}`
plus family wiring (`scripts/cj-goal-common.sh` `--mode task`,
`scripts/cj-worktree-init.sh` `--caller task`→`cj-task`,
`scripts/cj-worktree-cleanup.sh` `cj-task-*` scope), catalog/routing/docs, and
tests. The verb takes a free-text small task, runs a HARD complexity gate, scaffolds
a `type: task` work-item, builds it silently (implement → QA), and STOPs at a PR.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Complexity gate refuses design topics | `cj-task-scaffold.sh --topic "redesign X"` | `CJ_TASK_RESULT=too-complex`, `SUGGEST=/CJ_goal_feature`, exit 2 | Pass |
| 2 | Complexity gate refuses bug topics | `cj-task-scaffold.sh --topic "investigate Y"` | `too-complex`, `SUGGEST=/CJ_goal_defect`, exit 2 | Pass |
| 3 | Complexity gate refuses large-scope topics | `cj-task-scaffold.sh --topic "epic overhaul"` | `too-complex`, `SUGGEST=/CJ_goal_feature`, exit 2 | Pass |
| 4 | "design doc" wording NOT a false-positive | `--topic "refine the design doc"` `--dry-run` | gate PASS (`CJ_TASK_RESULT=dry-run`) | Pass |
| 5 | Small task scaffolds a compliant `type: task` dir | live `cj-task-scaffold.sh` in a sandbox | TRACKER + test-plan written, topic injected, footer present | Pass |
| 6 | Idempotent re-scaffold | re-run same topic | `IDEMPOTENT_SKIP=1`, same dir, no second T-ID | Pass |
| 7 | `--mode task` accepted by cj-goal-common | `cj-goal-common.sh --phase portability-audit --mode task --dry-run` | `MODE=task`, `PHASE_RESULT=ok` | Pass |
| 8 | `--caller task` → `cj-task-*` worktree prefix | `cj-worktree-init.sh --caller task --dry-run` | `state=created`, `cj-task-*` branch | Pass |
| 9 | `cj-task-*` worktrees in the cleanup sweep | MERGED `cj-task-*` fixture | REMOVED by `cj-worktree-cleanup.sh` | Pass |
| 10 | `docs/workflow.md` Touches block (Check 15b) | `validate.sh` + `test.sh` T000040 check | CJ_goal_task section has all 4 anchored bullets | Pass |
| 11 | Portability honest (`local-only`) | `cj-portability-audit.sh --skill CJ_goal_task` | `FINDINGS=0`, verdict `portable` | Pass |

## Verification Steps

- [x] `scripts/validate.sh` passes (0 errors, 0 warnings) — Check 15b sees the
  CJ_goal_task orchestrator section; Check 18 portability clean; Check 21 sees 4
  orchestrators reference the permission policy
- [x] `scripts/test.sh` passes (0 failures) — incl. `cj-task-scaffold.test.sh`
  (8 cases), the extended `cj-worktree-init`/`cj-worktree-cleanup` tests, and the
  3 F000054 `--mode task` integration assertions
- [x] `cj-task-scaffold.test.sh` passes standalone (gate refusals + dry-run + live
  scaffold + idempotency)
- [x] Self-test: this very work-item (T000043) was scaffolded by the new
  `cj-task-scaffold.sh` (dogfood)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | feat/cj-goal-task | Pass |
