# Test: `portability-deploy` (`workflow` / `CI-nightly`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `portability-deploy` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## What it is

The skills-deploy end-to-end workflow on windows-latest, run nightly (windows-nightly.yml) — proves the full install/remove/relink/doctor workflow holds Windows-native; same script as the push-cadence test-deploy, a distinct CI context (platform + cadence).

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run portability-deploy` (single test),
`/CJ_test_run --category workflow` (the whole category), or
`/CJ_test_run --layer CI-nightly` (the whole layer).

## Explanation

This test proves the **full skills-deploy workflow** (install / remove / relink /
doctor / drift) holds on a Windows-native runner. It is the heavier `CI-nightly`
sibling of `portability-smoke`: same `workflow` category (it exercises the
install/sync workflow end to end), but the full `test-deploy.sh` suite runs on
`windows-latest` on a nightly schedule (`.github/workflows/windows-nightly.yml`)
rather than gating every PR, because it is too slow for the push cadence. Locally
the same `test-deploy.sh` runs on the host platform.

For the per-unit breakdown of what the suite asserts, see the
[test-deploy family doc](../../../test-deploy.md).
