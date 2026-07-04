# Test: `goal-task-eval` (`workflow` / `CI-nightly`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `goal-task-eval` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `agentic` |
| Command | `bash scripts/eval.sh CJ_goal_task` |
| Tier | `paid` |

## What it is

The /CJ_goal_task workflow eval — drives the task orchestrator through a real gstack-independent path (task -> halted_at_too_complex); agentic (spends model tokens), so it runs nightly, never on the free-tier default.

## How to run

```bash
bash scripts/eval.sh CJ_goal_task
```

Run via the category contract: `/CJ_test_run goal-task-eval` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer CI-nightly` (the whole layer).

## Explanation

_(why this test exists / what it proves. Cross-link the relevant
`docs/tests/<family>.md` units-detail page(s) — see the catalog at
[docs/test-catalog.md](../../../test-catalog.md) — for the per-unit breakdown
behind this front door.)_
