# Test: `goal-task-e2e-det` (`workflow` / `local-hook`)

> **Topic:** [goal-task](../../topics/goal-task/index.md) · **Goal:**
> [a small task becomes a reviewable PR](../../../goals/goal-task.md) ·
> **Layer view:** [local-hook](../../topics/goal-task/local-hook.md).
> This test is the deterministic half of the harness that runs a REAL
> `/CJ_goal_task` build.

| Field | Value |
|-------|-------|
| Name | `goal-task-e2e-det` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash tests/e2e-local.test.sh` |
| Tier | `free` |

## What it is

The DETERMINISTIC (no-Claude) half of the local happy-path E2E harness
(`scripts/e2e-local.sh`) — the harness whose real run drives a whole
`/CJ_goal_task` build in a throwaway sandbox: the SKIP gate (unset flag or a
missing prerequisite exits 0 without ever reaching a model), the sandbox
provision/teardown (a mktemp clone + the `.cj-e2e-sandbox` marker + a local
bare origin that defeats `gh pr create`), the materialized report generator
(evidence-derived rows; a missing-evidence row renders `unverified`, never a
false pass), the gitignore posture, and the auth gate against stubbed `claude`
binaries.

## How to run

```bash
bash tests/e2e-local.test.sh
# via the contract:
/CJ_test_run goal-task-e2e-det
/CJ_test_run --category workflow
/CJ_test_run --layer local-hook
```

## Explanation

This is the `goal-task` topic's **local-hook deterministic** point: a quick,
zero-model-spend proof that the machinery which CAN run the task verb end to
end (sandbox, safety seams, reporting, auth gating) stays correct — runnable on
demand before harness-adjacent changes leave the machine (it also runs per-PR
inside the full suite; a `local-hook` row's `layer` is descriptive placement).
It reuses the existing deterministic test of the E2E harness rather than adding
a new one — zero new maintenance, per the topic's deterministic-only enrollment
posture (see the [dream doc](../../../goals/goal-task.md)). The REAL
model-driven `/CJ_goal_task` build remains the separate on-demand `e2e-local`
run (`CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh`), required by nothing in this
contract. If the harness is ever retired, the documented fallback is
re-declaring [`goal-task-chain`](../CI-nightly/goal-task-chain.md) at this
layer.

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
