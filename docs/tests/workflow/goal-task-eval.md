# Test: `goal-task-eval` (`workflow` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `goal-task-eval` |
| Category | `workflow` |
| Command | `bash scripts/eval.sh CJ_goal_task` |
| Tier | `paid` |

## Purpose

The /CJ_goal_task workflow eval — drives the task orchestrator through a real gstack-independent path (task -> halted_at_too_complex).

## How to run

```bash
bash scripts/eval.sh CJ_goal_task
```

Run via the category contract: `/CJ_test_run goal-task-eval` (single test) or
`/CJ_test_run --category workflow` (the whole category).
