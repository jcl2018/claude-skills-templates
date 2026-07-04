# Test: `goal-task-eval` (`workflow` / `local-hook`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `goal-task-eval` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `agentic` |
| Command | `bash scripts/eval.sh CJ_goal_task` |
| Tier | `paid` |

## What it is

The /CJ_goal_task workflow eval — drives the task orchestrator through a real gstack-independent path (task -> halted_at_too_complex); agentic (spends model tokens), so it runs on-demand at the local-hook layer, never on a CI schedule or the free-tier default.

## How to run

```bash
bash scripts/eval.sh CJ_goal_task
```

Run via the category contract: `/CJ_test_run goal-task-eval` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer local-hook` (the whole layer).

## Explanation

This test proves the `/CJ_goal_task` orchestrator actually **runs** — a real
Claude-driven `claude --print` eval drives it through its preamble + isolation +
hard complexity gate and asserts it emits `halted_at_too_complex` with the
`/CJ_goal_feature` routing suggestion, without reaching any gstack skill. It is the
`workflow`-category proof that backs the `workflow-cj-goal-task-runs`
`level: workflow` behavior, which the Check 28 workflow-coverage gate binds to the
`CJ_goal_task` orchestrator. It is `agentic` (a headless model run spends tokens),
so it lives at the `local-hook` layer — run on-demand, never on a CI schedule or
the free-tier default. The eval case is `tests/eval/CJ_goal_task/halt-too-complex/`.

For the per-case breakdown of the behavioral eval harness, see the
[eval family doc](../../../eval.md).
