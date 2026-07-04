# Test: `goal-feature-eval` (`workflow` / `CI-nightly`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `goal-feature-eval` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `agentic` |
| Command | `bash scripts/eval.sh CJ_goal_feature` |
| Tier | `paid` |

## What it is

The /CJ_goal_feature workflow eval — drives the feature orchestrator through its dry-run chain-plan preview on the gstack-independent path (end_state dry_run_preview); backs the workflow-cj-goal-feature-runs level:workflow behavior; agentic, nightly cadence.

## How to run

```bash
bash scripts/eval.sh CJ_goal_feature
```

Run via the category contract: `/CJ_test_run goal-feature-eval` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer CI-nightly` (the whole layer).

## Explanation

This test proves the `/CJ_goal_feature` orchestrator actually **runs** — a real
Claude-driven `claude --print` eval drives it through its preamble + `--dry-run`
chain-plan preview and asserts `end_state: dry_run_preview` without reaching any
gstack skill. It is the `workflow`-category proof that backs the
`workflow-cj-goal-feature-runs` `level: workflow` behavior, which the Check 28
workflow-coverage gate binds to the `CJ_goal_feature` orchestrator. It is `agentic`
(a headless model run spends tokens), so it lives at the `CI-nightly` layer and
never runs on the free-tier default. The eval case is
`tests/eval/CJ_goal_feature/dry-run-plan/`.

For the per-case breakdown of the behavioral eval harness, see the
[eval family doc](../../../eval.md).
