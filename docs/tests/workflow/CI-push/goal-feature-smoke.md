# Test: `goal-feature-smoke` (`workflow` / `CI-push`)

> **Topic:** [goal-feature](../../topics/goal-feature/index.md) · **Goal:**
> [a topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
> **Layer view:** [CI-push](../../topics/goal-feature/CI-push.md).
> This test is the feature verb's fast per-PR proof of its deterministic
> plumbing shape.

| Field | Value |
|-------|-------|
| Name | `goal-feature-smoke` |
| Category | `workflow` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/cj-goal-feature-smoke.test.sh` |
| Tier | `free` |

## What it is

The feature-path SHAPE smoke: it probes each deterministic seam of the
`/CJ_goal_feature` pipeline in isolation — worktree entry
(`cj-worktree-init.sh --caller feature` → a `cj-feat-*` branch), the shared
helper's `worktree` / `ship` / `telemetry` phases under `--mode feature`, and
the workbench-owned leaf-dispatch targets (scaffold / impl / qa `SKILL.md`s) on
disk. Dry-run based and seconds-fast, so it gates every PR.

## How to run

```bash
bash tests/cj-goal-feature-smoke.test.sh
# via the contract:
/CJ_test_run goal-feature-smoke
/CJ_test_run --category workflow
/CJ_test_run --layer CI-push
```

## Explanation

This is the `goal-feature` topic's **CI-push** point under the deterministic-only
topic contract: a regression in the feature verb's worktree entry, phase
dispatch, or leaf wiring turns the PR red immediately, instead of surfacing at
the nightly cadence or in an operator run. It deliberately never invokes the
`/CJ_goal_feature` skill itself — the agent-executed pipeline prose is out of
deterministic reach (the helpers-only ceiling, named in the
[dream doc](../../../goals/goal-feature.md)); the helper scripts are the
testable surface. The heavier end-to-end sibling is
[`goal-feature-chain`](../CI-nightly/goal-feature-chain.md) at CI-nightly.

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
