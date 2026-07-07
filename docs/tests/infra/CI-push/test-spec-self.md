# Test: `test-spec-self` (`infra` / `CI-push`)

| Field | Value |
|-------|-------|
| Name | `test-spec-self` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/test-spec.test.sh` |
| Tier | `free` |

## What it is

The self-test of the test-contract **parser** — `scripts/test-spec.sh`, the
two-tier registry engine that merges the portable `spec/test-spec.md` seed with
this repo's `spec/test-spec-custom.md` overlay. It exercises the parser
round-trip, the absent-vs-invalid split, the coverage cross-check, and the ≥20
reverse-token floor against **temp-dir fixture registries**. It is the
`categories:` promotion of the existing `test-test-spec` units-row
(`tests/test-spec.test.sh`).

## How to run

```bash
bash tests/test-spec.test.sh
# via the category contract:
/CJ_test_run test-spec-self
/CJ_test_run --category infra      # the whole category
/CJ_test_run --layer CI-push       # the whole layer
```

## Explanation

`test-spec.sh` is the foundation nearly every other test check stands on:
`validate.sh` Checks 24 / 26 / 28 / 30 / 31 / 32, `/CJ_test_audit` Stage 1, and
`/CJ_test_run`'s pre-step all call into it. A silent regression in the parser
would corrupt every one of those checks at once, so the engine itself earns a
standing per-PR guard. Running on hermetic fixture registries keeps the self-test
independent of the live overlay (it cannot be masked by a passing real tree) and
free of model spend. For the per-unit breakdown of what the `test` family
asserts, see the [test family doc](../../test.md) and the catalog at
[docs/test-catalog.md](../../../test-catalog.md).
