# goal-task @ CI-nightly — the composed helper-chain proof

**Dream:** [a small ad-hoc task becomes a reviewable PR](../../../goals/goal-task.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The per-PR suite proves the scaffolder in isolation; this layer proves the task
verb's steps COMPOSE. The nightly point is
[`goal-task-chain`](../../workflow/CI-nightly/goal-task-chain.md)
(`bash tests/goal-task-chain.test.sh`) — one hermetic temp sandbox (staging the
real task templates), the helper chain in pipeline order:

1. **real worktree entry** (`--caller task`, no dry-run) → a `cj-task-*`
   branch + a live worktree dir;
2. **real scaffold inside the worktree** — `cj-task-scaffold.sh --topic ...
   --repo <worktree>` mints a `T[0-9]{6}` work-item with the `type: task`
   TRACKER + `test-plan.md` (the no-design scaffold that replaces
   `/office-hours` on the task path, running where the pipeline actually runs
   it: inside the isolated checkout);
3. **at-PR recap** (`--mode task --when after` — the AFTER header + all three
   labelled sections);
4. **janitor preview** (`--dry-run`; the worktree AND the scaffolded work-item
   must survive).

## Why nightly, not per-PR

A real `git worktree add` + a real scaffold per run is heavier than the per-PR
budget, so `scripts/test.sh` registers the drill under the `TEST_FAST=1`
guard: the per-PR gate SKIPs it, the nightly full suite
(`.github/workflows/nightly.yml`, no flag) runs it every night — the
`test-deploy` re-layering pattern.

## Run it

```bash
bash tests/goal-task-chain.test.sh
/CJ_test_run goal-task-chain
bash scripts/test.sh        # the nightly path (no TEST_FAST) also runs it
```
