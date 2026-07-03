# Test: `windows-deploy` (`CI-nightly` category)

<!-- SEEDED STUB — one doc per category test.
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis.
     Safe to edit: the audit seeds this only when absent (idempotent; present => skip). -->

| Field | Value |
|-------|-------|
| Name | `windows-deploy` |
| Category | `CI-nightly` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## Purpose

The skills-deploy end-to-end suite on windows-latest, run nightly (windows-nightly.yml) — same script as the push-cadence test-deploy, but a distinct CI context (platform + cadence); locally it runs on the host platform (no platform: field yet).

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run windows-deploy` (single test) or
`/CJ_test_run --category CI-nightly` (the whole category).
