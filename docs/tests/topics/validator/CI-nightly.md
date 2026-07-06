# validator @ CI-nightly — the clean-runner re-proof

Realizes the [validator dream](../../../goals/validator.md)'s **every-boundary
firing** property at the nightly cadence: the tree is re-proven structurally
sound every night, independent of PR traffic.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`validate-nightly`](../../infra/CI-nightly/validate-nightly.md) | deterministic | **Whole-contract coverage, nightly** | `.github/workflows/nightly.yml` runs the full `scripts/test.sh`, whose first step is `scripts/validate.sh` — every check re-fires on a clean `ubuntu-latest` runner. |

## How this layer achieves the dream

Per-PR runs fire only when someone pushes. The nightly re-run covers the gaps
between pushes: a runner-image change, a dependency drift, or an artifact of
merge ordering that individual PR runs never saw. Because it rides inside the
full suite, a nightly validator failure surfaces alongside the behavioral suite
results in the same run log.

## How to run

```bash
bash scripts/validate.sh              # the command the nightly reaches via test.sh
gh workflow run nightly.yml           # trigger the real nightly manually
/CJ_test_run validate-nightly
/CJ_test_run --topic validator
```

For the per-check breakdown, see the [validate family doc](../../validate.md).
