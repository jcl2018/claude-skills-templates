# Test: `suite-local` (`infra` / `local-hook`)

> **Topic:** [full-suite](../../topics/full-suite/index.md) · **Goal:**
> [the whole verification surface stays green](../../../goals/full-suite.md) ·
> **Layer view:** [local-hook](../../topics/full-suite/local-hook.md).
> This is the full suite's **local-hook** level: the documented
> run-locally-before-push harness.

| Field | Value |
|-------|-------|
| Name | `suite-local` |
| Category | `infra` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash scripts/test.sh` |
| Tier | `free` |

## What it is

The full behavioral test suite run **locally, before pushing** — the workbench's
standing convention (the per-PR CI gate fails on ANY finding, so the full
`test.sh` + shellcheck are run on the developer's machine first). It executes
the validator, every registered `tests/*.test.sh` sub-suite, the inline
integration families, `test-deploy.sh`, and `windows-smoke.sh` in one pass. Same
command as the per-PR [`suite`](../CI-push/suite.md) row — a distinct execution
context (your machine, at your cadence, before the push).

## How to run

```bash
bash scripts/test.sh            # run locally before pushing
```

Run via the category contract: `/CJ_test_run suite-local` (single test),
`/CJ_test_run --category infra` (the whole category),
`/CJ_test_run --layer local-hook` (the whole layer), or
`/CJ_test_run --topic full-suite` (the whole topic).

## Explanation

Per-PR CI proves the suite green — but only after a push, and a red CI run costs
a full round trip. The local-before-push run is where suite regressions are
SUPPOSED to be caught first: same command, same assertions, on the machine that
made the change. It is the full-suite topic's local-hook deterministic coverage
point in the three-layer topic contract. (The pre-commit hook runs only the
faster `validate.sh` — see [`validate-hook`](validate-hook.md); this row is the
heavier, manual before-push discipline.)

For what the suite is made of, see the [test-catalog index](../../../test-catalog.md)
and the [test family doc](../../test.md); for the layer-level "how", see
[full-suite @ local-hook](../../topics/full-suite/local-hook.md).
