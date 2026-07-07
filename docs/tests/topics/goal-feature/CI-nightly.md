# goal-feature @ CI-nightly — the composed helper-chain proof

**Dream:** [a one-line topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The per-PR smoke proves each seam in isolation; this layer proves they
COMPOSE. The nightly point is
[`goal-feature-chain`](../../workflow/CI-nightly/goal-feature-chain.md)
(`bash tests/goal-feature-chain.test.sh`) — one hermetic temp sandbox, the
feature verb's helper chain in pipeline order:

1. **real worktree entry** (`--caller feature`, no dry-run) + the
   `--assert-isolated` verdict from inside it;
2. **sync opt-out** (`--phase sync --no-sync` → `PHASE_RESULT=skipped`,
   `SYNC_RAN=0` — no install attempted);
3. **pr-check** (read-only, offline-tolerant);
4. **design-gate seam** — `AUTO=inactive` bare, `AUTO=continue` under the
   double guard (env flag + sandbox marker);
5. **at-PR recap** (the AFTER header + all three labelled sections);
6. **janitor preview** (`--dry-run`; the worktree from step 1 must survive).

## Why nightly, not per-PR

A real `git worktree add` per run is heavier than the per-PR budget, so
`scripts/test.sh` registers the drill under the `TEST_FAST=1` guard: the per-PR
gate (`validate.yml`, `TEST_FAST=1`) SKIPs it, and the nightly full suite
(`.github/workflows/nightly.yml`, no flag) runs it every night — the same
re-layering pattern as the heavy `test-deploy` suite. A composition regression
surfaces within a day instead of slowing every PR.

## Run it

```bash
bash tests/goal-feature-chain.test.sh
/CJ_test_run goal-feature-chain
bash scripts/test.sh        # the nightly path (no TEST_FAST) also runs it
```
