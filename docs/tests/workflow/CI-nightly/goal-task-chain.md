# Test: `goal-task-chain` (`workflow` / `CI-nightly`)

> **Topic:** [goal-task](../../topics/goal-task/index.md) · **Goal:**
> [a small task becomes a reviewable PR](../../../goals/goal-task.md) ·
> **Layer view:** [CI-nightly](../../topics/goal-task/CI-nightly.md).
> This test drives the task verb's whole deterministic helper chain end to end,
> nightly.

| Field | Value |
|-------|-------|
| Name | `goal-task-chain` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash tests/goal-task-chain.test.sh` |
| Tier | `free` |

## What it is

The task verb's CHAIN drill: one hermetic temp sandbox (staging the real task
templates), the helper chain in pipeline order — a **real** worktree is created
(`--caller task` → `cj-task-*`), the **real** bash scaffolder mints a T-ID
work-item inside it (`CJ_TASK_RESULT=ok`, a `T[0-9]{6}` id, the work-item dir
with a `type: task` TRACKER + `test-plan.md`), the at-PR 3-part recap renders,
and the worktree janitor previews with `--dry-run` (worktree + scaffolded
work-item both untouched).

## How to run

```bash
bash tests/goal-task-chain.test.sh
# via the contract:
/CJ_test_run goal-task-chain
/CJ_test_run --category workflow
/CJ_test_run --layer CI-nightly
```

## Explanation

This is the `goal-task` topic's **CI-nightly** point: heavier than the per-PR
budget (a real `git worktree add` + a real scaffold per run), so
`scripts/test.sh` registers it under the `TEST_FAST=1` guard — the per-PR gate
SKIPs it, the nightly full suite (`.github/workflows/nightly.yml`) runs it
every night (the `test-deploy` re-layering pattern). Where the
[CI-push scaffolder suite](../CI-push/goal-task-scaffold.md) probes the
scaffolder's cases in isolation, this drill proves the task verb's steps
compose: worktree entry → scaffold-inside-the-worktree → recap → cleanup, each
phase's documented contract fields asserted in one flow. It reaches helper
SCRIPTS only — the agent-executed pipeline prose is deliberately out of scope
(see the [dream doc](../../../goals/goal-task.md)'s posture section).

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
