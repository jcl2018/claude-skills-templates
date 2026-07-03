# Test: `suite` (`CI-push` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `suite` |
| Category | `CI-push` |
| Command | `bash scripts/test.sh` |
| Tier | `free` |

## Purpose

The full behavioral test suite — runs validate.sh, every registered tests/*.test.sh sub-suite, test-deploy.sh, and windows-smoke.sh.

## How to run

```bash
bash scripts/test.sh
```

Run via the category contract: `/CJ_test_run suite` (single test) or
`/CJ_test_run --category CI-push` (the whole category).
