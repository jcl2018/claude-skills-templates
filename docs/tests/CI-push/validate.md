# Test: `validate` (`CI-push` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `validate` |
| Category | `CI-push` |
| Command | `bash scripts/validate.sh` |
| Tier | `free` |

## What it is

The repo validator — the `ci`-layer static check. It runs every numbered check
plus the error and warning checks against the skills catalog, the docs, and the
`spec/` contract family (doc-spec, test-spec, workflow-spec), asserting the repo
is internally consistent before anything ships.

## How to run

```bash
bash scripts/validate.sh
```

Run via the category contract: `/CJ_test_run validate` (single test) or
`/CJ_test_run --category CI-push` (every push-cadence test). `validate.sh` also
runs automatically as the pre-commit hook and as the first step of the full
suite (`scripts/test.sh`).

## Explanation

`validate.sh` is the fast, deterministic gate that keeps the catalog, the
generated docs, and the two-tier contracts from drifting apart — it is what a PR
must pass on every push. For the per-check breakdown (what each numbered / error
/ warning check asserts, its anchor, and its owner), see the units-detail page
[docs/tests/validate.md](../validate.md).
