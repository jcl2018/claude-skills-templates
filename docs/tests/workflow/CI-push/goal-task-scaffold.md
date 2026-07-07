# Test: `goal-task-scaffold` (`workflow` / `CI-push`)

> **Topic:** [goal-task](../../topics/goal-task/index.md) · **Goal:**
> [a small task becomes a reviewable PR](../../../goals/goal-task.md) ·
> **Layer view:** [CI-push](../../topics/goal-task/CI-push.md).
> This test is the task verb's fast per-PR proof of its scaffolder + complexity
> gate.

| Field | Value |
|-------|-------|
| Name | `goal-task-scaffold` |
| Category | `workflow` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/cj-task-scaffold.test.sh` |
| Tier | `free` |

## What it is

The task verb's scaffolder suite: the HARD complexity gate's refusals (a
design-rework topic routes to `/CJ_goal_feature`, a bug/investigation topic to
`/CJ_goal_defect`, an explicit-large-scope topic halts), the allowed-topic
pass-through, `--dry-run` planning a T-ID with zero writes, the live scaffold
(a `type: task` work-item with TRACKER + test-plan + the topic footer), and
idempotent re-runs reusing the same dir. Sandbox-isolated and seconds-fast, so
it gates every PR.

## How to run

```bash
bash tests/cj-task-scaffold.test.sh
# via the contract:
/CJ_test_run goal-task-scaffold
/CJ_test_run --category workflow
/CJ_test_run --layer CI-push
```

## Explanation

This is the `goal-task` topic's **CI-push** point under the deterministic-only
topic contract. The scaffolder
(`skills/CJ_goal_task/scripts/cj-task-scaffold.sh`) IS the task verb's
distinctive step — the no-design, no-TODOS-row bash scaffold that replaces
`/office-hours` on the task path — so its gate + mint + shape regressing is the
most task-specific failure the verb has, and it turns the PR red immediately.
The composed-chain sibling is [`goal-task-chain`](../CI-nightly/goal-task-chain.md)
at CI-nightly; the agent-executed pipeline prose stays out of deterministic
reach (see the [dream doc](../../../goals/goal-task.md)'s posture section).

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
