# Test: `goal-task-eval` (`workflow` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `goal-task-eval` |
| Category | `workflow` |
| Command | `bash scripts/eval.sh CJ_goal_task` |
| Tier | `paid` |

## What it is

The `/CJ_goal_task` workflow eval — a real Claude-driven run that drives the task
orchestrator end to end through a gstack-independent path (a deliberately
over-scoped topic the complexity gate must refuse, ending at
`halted_at_too_complex`) and validates the structured JSON outcome against the
case's schema.

## How to run

```bash
bash scripts/eval.sh CJ_goal_task
```

Run via the category contract: `/CJ_test_run goal-task-eval` (single test) or
`/CJ_test_run --category workflow` (every workflow test). This is a **paid** tier
test — it spends real model budget, so `/CJ_test_run` runs it only behind
`--evals` / `--all`, never on a default run. In CI it runs on the nightly eval
schedule (`.github/workflows/eval-nightly.yml`).

## Explanation

A `CJ_goal_*` orchestrator can be fully documented and still not actually run;
this eval is the honest `level: workflow` proof that the task pipeline really
executes its preamble, isolation, and complexity-gate decision — not just that its
docs exist. It targets a gstack-independent halt path so the case is deterministic
without a full happy-path-to-PR run (that remains deferred on the gstack-in-CI
blocker). The eval harness itself is described in `scripts/eval.sh`; for the
per-unit breakdown of the eval-suite family, see the units-detail page
[docs/tests/eval.md](../eval.md).
