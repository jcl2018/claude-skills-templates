# Test: `suite` (`CI-push` category)

<!-- The authoritative per-test front door (What it is / How to run / Explanation).
     Seeded by /CJ_test_audit from the spec/test-spec-custom.md categories: axis;
     filled by hand. The audit seeds this only when absent (idempotent; present =>
     skip), so edits are safe. -->

| Field | Value |
|-------|-------|
| Name | `suite` |
| Category | `CI-push` |
| Command | `bash scripts/test.sh` |
| Tier | `free` |

## What it is

The full behavioral test suite. It runs `validate.sh` first, then every
registered `tests/*.test.sh` sub-suite, then the `skills-deploy` end-to-end suite
(`test-deploy.sh`) and the Windows Git Bash portability smoke
(`windows-smoke.sh`) — the superset of `validate` that must be green before a push
lands.

## How to run

```bash
bash scripts/test.sh
```

Run via the category contract: `/CJ_test_run suite` (single test) or
`/CJ_test_run --category CI-push` (every push-cadence test).

## Explanation

Where `validate` is the fast static gate, `suite` is the behavioral proof: it
exercises the shell tooling and every unit sub-suite end to end, so a change that
passes `validate` but breaks actual behavior is still caught. It is the
authoritative pre-push run (the ubuntu CI job runs the same script). For the
per-unit breakdown of the sub-suites it drives, see the units-detail page
[docs/tests/test.md](../test.md).
