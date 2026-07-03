# Test: `windows-deploy` (`CI-nightly` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `windows-deploy` |
| Category | `CI-nightly` |
| Command | `bash scripts/test-deploy.sh` |
| Tier | `free` |

## What it is

The `skills-deploy` end-to-end suite run on `windows-latest`, nightly. It runs the
same `test-deploy.sh` script as the push-cadence `test-deploy` test, but in a
distinct CI context — the Windows platform, on the nightly cadence — to catch
Windows-specific deploy regressions that the POSIX push run cannot see.

## How to run

```bash
bash scripts/test-deploy.sh
```

Run via the category contract: `/CJ_test_run windows-deploy` (single test) or
`/CJ_test_run --category CI-nightly` (every nightly-cadence test). In CI it runs
nightly on `windows-latest` via `.github/workflows/windows-nightly.yml`; locally
it runs on the host platform (there is no `platform:` field yet, so a local run
is not Windows-gated).

## Explanation

The Windows copy-mode deploy path is the most platform-divergent surface in the
workbench, but running the full `test-deploy` suite on `windows-latest` on every
push would slow the PR path, so it is deferred to a nightly schedule. Same script,
different context — the cadence and platform are the reason it is a separate
category test from `test-deploy`
([docs/tests/CI-push/test-deploy.md](../CI-push/test-deploy.md)). For the per-unit
breakdown of the deploy suite it drives, see the units-detail page
[docs/tests/test-deploy.md](../test-deploy.md).
