# full-suite @ CI-nightly — the full, untrimmed run

Realizes the [full-suite dream](../../../goals/full-suite.md)'s **nothing
silently skipped** property: the work the per-PR gate trims for speed is re-run
in full every night, so every declared test still runs *somewhere* on a regular
cadence.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`suite-nightly`](../../infra/CI-nightly/suite-nightly.md) | deterministic | **Superset execution, untrimmed** | `.github/workflows/nightly.yml` runs the full `./scripts/test.sh` (no `TEST_FAST`) — validator, every sub-suite, windows-smoke AND the heavy `test-deploy.sh` fixture harness. |

## How this layer achieves the dream

This run is where the per-PR trim is paid back: `test-deploy.sh` (the
skills-deploy install/remove/relink/doctor fixture suite) gates HERE, not per-PR.
Dropping this nightly while keeping the per-PR trim would leave the deploy
harness running nowhere — the exact silent-skip failure mode the dream forbids.
The nightly also re-proves the rest of the suite on a clean runner, independent
of PR traffic.

## How to run

```bash
bash scripts/test.sh                  # the full, untrimmed run
gh workflow run nightly.yml           # trigger the real nightly manually
/CJ_test_run suite-nightly
/CJ_test_run --topic full-suite
```

For what the suite is made of, see the [test-catalog index](../../../test-catalog.md)
and the [test family doc](../../test.md).
