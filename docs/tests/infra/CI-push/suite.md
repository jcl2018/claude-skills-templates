# Test: `suite` (`infra` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `suite` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash scripts/test.sh` |
| Tier | `free` |

## What it is

The full behavioral test suite — runs validate.sh, every registered tests/*.test.sh sub-suite, test-deploy.sh, and windows-smoke.sh.

## How to run

```bash
bash scripts/test.sh
```

Run via the category contract: `/CJ_test_run suite` (single test),
`/CJ_test_run --category infra` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

_(why this test exists / what it proves. Cross-link the relevant
`docs/tests/<family>.md` units-detail page(s) — see the catalog at
[docs/test-catalog.md](../../../test-catalog.md) — for the per-unit breakdown
behind this front door.)_
