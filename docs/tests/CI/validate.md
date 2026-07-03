# Test: `validate` (`CI` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `validate` |
| Category | `CI` |
| Command | `bash scripts/validate.sh` |
| Tier | `free` |

## Purpose

The repo validator (the ci layer): all numbered + error + warning checks against the catalog, docs, and spec family.

## How to run

```bash
bash scripts/validate.sh
```

Run via the category contract: `/CJ_test_run validate` (single test) or
`/CJ_test_run --category CI` (the whole category).
