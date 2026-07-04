# Test: `portability-smoke` (`infra` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `portability-smoke` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash scripts/windows-smoke.sh` |
| Tier | `free` |

## What it is

The Windows Git Bash portability smoke of the deploy/install harness (copy-mode install, in-place stamp, _cj-shared update-check resolution) — standing verification infra, not a user-facing workflow; the fast per-PR Windows signal.

## How to run

```bash
bash scripts/windows-smoke.sh
```

Run via the category contract: `/CJ_test_run portability-smoke` (single test),
`/CJ_test_run --category infra` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This test proves the **deploy/install harness** a maintainer runs on Windows holds
under Git Bash — that a `skills-deploy install` falls back to copy-mode when real
symlinks are unavailable, stamps `install_mode: in-place`, and that the
`_cj-shared` update-check still resolves. It is an `infra` test (standing
verification of the deploy/install harness, not a user-facing workflow) at the
`CI-push` layer (cheap enough — a few seconds — to gate every PR). The heavier full
Windows-native `skills-deploy` suite is the companion `portability-deploy` test at
the `CI-nightly` layer; the declared-vs-actual portability lint is the
`portability-check18-lint` test at `CI-push`; and the version-notification is the
`portability-version-check` test at `local-hook`.

For the per-unit breakdown of what the smoke actually asserts, see the
[windows-smoke family doc](../../../windows-smoke.md).
