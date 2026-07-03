# Test: `windows` (`CI-push` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `windows` |
| Category | `CI-push` |
| Command | `bash scripts/windows-smoke.sh` |
| Tier | `free` |

## What it is

The Windows Git Bash portability smoke. It asserts the copy-mode install (real
files + checksum-tracked drift, since Git Bash has no real symlinks), the
`install_mode: in-place` stamp, and the `_cj-shared` update-check resolution under
`FORCE_COPY` — the fast per-PR signal that the workbench still works on Windows.

## How to run

```bash
bash scripts/windows-smoke.sh
```

Run via the category contract: `/CJ_test_run windows` (single test) or
`/CJ_test_run --category CI-push` (every push-cadence test). The same checks gate
every PR via the `windows-latest` Git Bash CI job.

## Explanation

The workbench is POSIX-shell software that must also run under Git Bash on
Windows, where symlinks are unavailable and `skills-deploy install` falls back to
copy-mode. This smoke is the cheap, per-push proof that the copy-mode path and the
in-place install model still hold on Windows, so a POSIX-only regression is caught
before it ships. For the per-unit breakdown of the Windows checks, see the
units-detail page [docs/tests/windows-smoke.md](../windows-smoke.md).
