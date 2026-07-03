# Test: `test-deploy` (`CI` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `test-deploy` |
| Category | `CI` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## Purpose

The skills-deploy end-to-end suite in isolated temp dirs (install / remove / relink / doctor / drift).

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run test-deploy` (single test) or
`/CJ_test_run --category CI` (the whole category).
