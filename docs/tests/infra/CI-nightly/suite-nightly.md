# Test: `suite-nightly` (`infra` / `CI-nightly`)

> **Topic:** [full-suite](../../topics/full-suite/index.md) · **Goal:**
> [the whole verification surface stays green](../../../goals/full-suite.md) ·
> **Layer view:** [CI-nightly](../../topics/full-suite/CI-nightly.md).
> This is the full suite's **CI-nightly** level: the complete, unabridged
> `test.sh` run — nothing skipped — every night.

| Field | Value |
|-------|-------|
| Name | `suite-nightly` |
| Category | `infra` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash scripts/test.sh` |
| Tier | `free` |

## What it is

The full behavioral test suite as **`.github/workflows/nightly.yml`'s full
non-`TEST_FAST` run**: the validator, every registered `tests/*.test.sh`
sub-suite, the inline integration families, `windows-smoke.sh`, AND the heavy
`test-deploy.sh` fixture suite — which the per-PR [`suite`](../CI-push/suite.md)
run skips under `TEST_FAST=1`. This nightly run is where the deploy harness
actually gates. Same command as the per-PR suite row — a distinct cadence and
scope (full, nightly, off the PR path).

## How to run

```bash
bash scripts/test.sh            # the full run — no TEST_FAST, nothing skipped
```

Run via the category contract: `/CJ_test_run suite-nightly` (single test),
`/CJ_test_run --category infra` (the whole category),
`/CJ_test_run --layer CI-nightly` (the whole layer), or
`/CJ_test_run --topic full-suite` (the whole topic).

The real nightly trigger is the workflow cron (`.github/workflows/nightly.yml`);
a manual CI run is `gh workflow run nightly.yml`.

## Explanation

The per-PR gate stays fast by deliberately skipping the heaviest work
(`TEST_FAST=1` skips `test-deploy.sh`); this nightly run is the compensating
proof that the WHOLE suite — heavy parts included — still passes end to end.
Without it, a test-deploy regression could sit unnoticed until the next manual
full run. It is the full-suite topic's CI-nightly coverage point in the
three-layer topic contract.

For what the suite is made of, see the [test-catalog index](../../../test-catalog.md)
and the [test family doc](../../test.md); for the layer-level "how", see
[full-suite @ CI-nightly](../../topics/full-suite/CI-nightly.md).
