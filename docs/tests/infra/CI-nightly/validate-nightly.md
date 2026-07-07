# Test: `validate-nightly` (`infra` / `CI-nightly`)

> **Topic:** [validator](../../topics/validator/index.md) · **Goal:**
> [no structural break ever lands](../../../goals/validator.md) ·
> **Layer view:** [CI-nightly](../../topics/validator/CI-nightly.md).
> This is the validator's **CI-nightly** level: the same checks re-run every
> night inside the full suite, on a clean runner, off the per-PR path.

| Field | Value |
|-------|-------|
| Name | `validate-nightly` |
| Category | `infra` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash scripts/validate.sh` |
| Tier | `free` |

## What it is

The repo validator as executed inside the **nightly full-suite run**:
`.github/workflows/nightly.yml` runs the full (non-`TEST_FAST`) `scripts/test.sh`
every night, and `test.sh`'s first step is `scripts/validate.sh` — so every
validator check re-fires nightly on a clean `ubuntu-latest` runner regardless of
PR traffic. Same command as the per-PR [`validate`](../CI-push/validate.md) test —
a distinct cadence and context (the heavy suite, nightly).

## How to run

```bash
bash scripts/validate.sh        # the command nightly.yml reaches via test.sh
```

Run via the category contract: `/CJ_test_run validate-nightly` (single test),
`/CJ_test_run --category infra` (the whole category),
`/CJ_test_run --layer CI-nightly` (the whole layer), or
`/CJ_test_run --topic validator` (the whole topic).

The real nightly trigger is the workflow cron (`.github/workflows/nightly.yml`);
a manual CI run is `gh workflow run nightly.yml`.

## Explanation

The per-PR [`validate`](../CI-push/validate.md) run only fires when someone
pushes; the nightly re-run proves the tree stays structurally sound on a clean
runner even between PRs (catching environment drift, a runner-image change, or a
merge-ordering artifact that per-PR runs missed). It is the validator topic's
CI-nightly coverage point in the three-layer topic contract.

For the per-check breakdown of everything the validator asserts, see the
[validate family doc](../../validate.md); for the layer-level "how", see
[validator @ CI-nightly](../../topics/validator/CI-nightly.md).
