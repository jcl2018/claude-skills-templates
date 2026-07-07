# Test: `goal-defect-smoke` (`workflow` / `CI-push`)

> **Topic:** [goal-defect](../../topics/goal-defect/index.md) · **Goal:**
> [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
> **Layer view:** [CI-push](../../topics/goal-defect/CI-push.md).
> This test is the defect verb's fast per-PR proof of its deterministic
> plumbing shape.

| Field | Value |
|-------|-------|
| Name | `goal-defect-smoke` |
| Category | `workflow` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/cj-goal-defect-smoke.test.sh` |
| Tier | `free` |

## What it is

The defect-path SHAPE smoke — the mirror of the feature-path smoke for
`/CJ_goal_defect`: worktree entry (`cj-worktree-init.sh --caller defect` → a
`cj-def-*` branch), the shared helper's `worktree` / `ship` / `telemetry`
phases under `--mode defect`, and the workbench-owned leaf-dispatch targets
(`CJ_qa-work-item`, `CJ_document-release`) on disk. The gstack tails
(`/investigate`, `/ship`, `/land-and-deploy`) are deliberately not asserted —
a bare CI checkout does not have them. Dry-run based and seconds-fast, so it
gates every PR.

## How to run

```bash
bash tests/cj-goal-defect-smoke.test.sh
# via the contract:
/CJ_test_run goal-defect-smoke
/CJ_test_run --category workflow
/CJ_test_run --layer CI-push
```

## Explanation

This is the `goal-defect` topic's **CI-push** point under the
deterministic-only topic contract — and the point that closed the defect verb's
biggest gap: before it, the defect path had NO per-PR deterministic proof at
all (feature and task each had one). A regression in the defect verb's worktree
entry, phase dispatch, or leaf wiring now turns the PR red immediately. It
never invokes the `/CJ_goal_defect` skill itself — the agent-executed pipeline
prose is out of deterministic reach (the helpers-only ceiling, named in the
[dream doc](../../../goals/goal-defect.md)); the heavier end-to-end sibling is
[`goal-defect-chain`](../CI-nightly/goal-defect-chain.md) at CI-nightly.

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
