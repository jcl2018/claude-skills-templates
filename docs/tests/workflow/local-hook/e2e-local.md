# Test: `e2e-local` (`workflow` / `local-hook`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `e2e-local` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `agentic` |
| Command | `CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh` |
| Tier | `local-only` |

## What it is

The local happy-path E2E harness — a real /CJ_goal_task build in a throwaway sandbox, driven through the build gates to the /ship boundary; agentic + local-only (runs on your machine, never in CI).

## How to run

```bash
CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh
```

Run via the category contract: `/CJ_test_run e2e-local` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer local-hook` (the whole layer).

## Explanation

_(why this test exists / what it proves. Cross-link the relevant
`docs/tests/<family>.md` units-detail page(s) — see the catalog at
[docs/test-catalog.md](../../../test-catalog.md) — for the per-unit breakdown
behind this front door.)_
