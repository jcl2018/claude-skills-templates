# Test: `e2e-local` (`workflow` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `e2e-local` |
| Category | `workflow` |
| Command | `CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh` |
| Tier | `local-only` |

## What it is

The local happy-path E2E harness. It runs a REAL `/CJ_goal_task` build end to end
in a throwaway sandbox (a `mktemp` clone with a local bare origin that accepts
push but defeats `gh pr create`), driven unattended through the build gates to the
`/ship` boundary, and writes a materialized report whose outcome is derived from
real post-run evidence (a new work-item dir, a non-empty diff, the run's
`end_state`).

## How to run

```bash
CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh
```

Run via the category contract: `/CJ_test_run e2e-local` (single test) or
`/CJ_test_run --category workflow` (every workflow test). This is a
**local-only** tier test: it requires gstack, a usable `claude` login, and `gh`,
and it spends model budget, so it is gated on `CJ_E2E_LOCAL=1` and runs only
behind `--e2e` / `--all`. With the flag unset or any prerequisite missing it SKIPs
cleanly, so CI and a normal `test.sh` never touch a model.

## Explanation

This is the fullest proof the workbench has that a whole cj_goal build works — a
real orchestrator run, not a deterministic stub or a single-skill eval. It is
local-only by necessity (it needs a live model and a real `gh`), which is exactly
why it is NOT a `units:` family with a generated `docs/tests/<family>.md` page:
there is no atomic-unit table behind it, just the one end-to-end harness. Its
deterministic half (the SKIP path + the sandbox/report libraries) is unit-tested
without Claude. For where this harness sits among the workbench's test layers —
shell skeleton, contract gates, behavioral eval cases, full E2E — see the test
hierarchy explainer [docs/tests/test-hierarchy.md](../test-hierarchy.md).
