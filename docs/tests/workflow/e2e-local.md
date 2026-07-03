# Test: `e2e-local` (`workflow` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `e2e-local` |
| Category | `workflow` |
| Command | `CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh` |
| Tier | `local-only` |

## Purpose

The local happy-path E2E harness — a real /CJ_goal_task build in a throwaway sandbox, driven through the build gates to the /ship boundary.

## How to run

```bash
CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh
```

Run via the category contract: `/CJ_test_run e2e-local` (single test) or
`/CJ_test_run --category workflow` (the whole category).
