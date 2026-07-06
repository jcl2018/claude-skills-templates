# full-suite @ CI-push — the fast per-PR gate

Realizes the [full-suite dream](../../../goals/full-suite.md)'s **green before it
ships** property at the push/PR boundary: no PR merges while the (trimmed) suite
is red.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`suite`](../../infra/CI-push/suite.md) | deterministic | **Superset execution, per PR** | `.github/workflows/validate.yml` runs `TEST_FAST=1 ./scripts/test.sh` — the validator + every registered sub-suite + the inline families + windows-smoke, with only the heavy deploy harness trimmed. |

## How this layer achieves the dream

The per-PR run is the merge gate: the whole behavioral surface except the
heaviest fixture harness runs on every push, so a behavioral regression cannot
land quietly. The `TEST_FAST=1` trim exists to keep the gate fast; it is honest
only because [CI-nightly](CI-nightly.md) runs the untrimmed suite every night —
the trim + the compensating nightly are two halves of one design.

## How to run

```bash
TEST_FAST=1 bash scripts/test.sh    # the exact per-PR CI command
/CJ_test_run suite
/CJ_test_run --topic full-suite
```

For what the suite is made of, see the [test-catalog index](../../../test-catalog.md)
and the [test family doc](../../test.md).
