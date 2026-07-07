# Test: `test-run-self` (`infra` / `CI-push`)

| Field | Value |
|-------|-------|
| Name | `test-run-self` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/test-run.test.sh` |
| Tier | `free` |

## What it is

The self-test of the test-contract **executor** — `scripts/test-run.sh` and the
`runners:` / `categories:` axes it reads. It drives the runner engine against
**temp-dir fixture registries** (never the real `test.sh` — that would be a
recursion trap), so "the tooling tests itself" is a first-class verification
surface rather than an implicit assumption. It is the `categories:` promotion of
the existing `test-test-run` units-row (`tests/test-run.test.sh`).

## How to run

```bash
bash tests/test-run.test.sh
# via the category contract:
/CJ_test_run test-run-self
/CJ_test_run --category infra      # the whole category
/CJ_test_run --layer CI-push       # the whole layer
```

## Explanation

The executor is the piece that turns the static test contract into a real
pass/fail run: it parses the `runners:` axis, plans the tier-gated selection
(free default; `--evals` / `--e2e` / `--all` widen), maps each runner's exit code
to an aggregate `{pass, fail, all-skipped}`, and writes the `.md` report + `.json`
ledger. If that engine silently regressed, every downstream "do the tests pass?"
answer would be untrustworthy — so it earns a standing per-PR guard. The suite
runs entirely on fixture registries under `mktemp`, so it never invokes the real
suite and never spends a model. For the per-unit breakdown of what the `test`
family asserts, see the [test family doc](../../test.md) and the catalog at
[docs/test-catalog.md](../../../test-catalog.md).
