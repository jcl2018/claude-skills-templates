# Test: `windows` (`CI-push` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `windows` |
| Category | `CI-push` |
| Command | `bash scripts/windows-smoke.sh` |
| Tier | `free` |

## Purpose

The Windows Git Bash portability smoke (copy-mode install, in-place stamp, _cj-shared update-check resolution) — the fast per-PR Windows signal.

## How to run

```bash
bash scripts/windows-smoke.sh
```

Run via the category contract: `/CJ_test_run windows` (single test) or
`/CJ_test_run --category CI-push` (the whole category).
