# Test: `test-deploy` (`infra` / `CI-nightly`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `test-deploy` |
| Category | `infra` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## What it is

The skills-deploy end-to-end suite in isolated temp dirs (install / remove /
relink / doctor / drift) — the POSIX-host run. Re-layered from `CI-push` to
`CI-nightly` (a CI-hygiene follow-up): it is the heaviest deterministic sub-suite
(many throwaway temp-dir installs), so the per-PR gate skips it and the nightly
full suite runs it.

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run test-deploy` (single test),
`/CJ_test_run --category infra` (the whole category), or
`/CJ_test_run --layer CI-nightly` (the whole layer).

Cadence: per-PR, `.github/workflows/validate.yml` runs `TEST_FAST=1
./scripts/test.sh`, which SKIPS this suite; the full `.github/workflows/nightly.yml`
run (`./scripts/test.sh`, no flag) executes it every night.

## Explanation

`skills-deploy` is the deployment harness — install / remove / relink / doctor in
`~/.claude/`, template ownership + checksum drift, copy-mode fallback on Git Bash,
and shared-script orphan pruning. A regression there silently breaks every
consumer's install, so this suite drives the whole lifecycle end to end in
throwaway temp homes (never the real `~/.claude/`). It is deterministic but slow
because each assertion provisions a fresh isolated home; that cost is why it runs
on the `CI-nightly` cadence rather than on every PR (the per-PR gate keeps the fast
structural + unit coverage). See the units-detail page
[docs/tests/test-deploy.md](../../../test-deploy.md) for the per-assertion
breakdown behind this front door.
