# goal-defect @ CI-nightly — the composed chain proof, through the land tail

**Dream:** [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
**Topic overview:** [index](index.md).

## How the dream is achieved at this layer

The per-PR smoke proves each seam in isolation; this layer proves the defect
verb's steps COMPOSE — including the LAND tail only the landing verbs have.
The nightly point is
[`goal-defect-chain`](../../workflow/CI-nightly/goal-defect-chain.md)
(`bash tests/goal-defect-chain.test.sh`) — one hermetic temp sandbox, the
helper chain in pipeline order:

1. **real worktree entry** (`--caller defect`, no dry-run) → a `cj-def-*`
   branch + a live worktree dir;
2. **D-ID claim preview** — `cj-id-claim.sh --prefix D --floor <N> --dry-run`
   from inside the worktree previews a `D[0-9]{6}` mint and creates NO claim
   dir (the atomic ID source the defect promotion step uses);
3. **pr-check** (read-only, offline-tolerant);
4. **the recap PAIR** — `--when before` (`=== About to land ===`) then
   `--when after` (`=== Landed / PR opened ===`), the bracket the landing verbs
   emit around `/land-and-deploy`;
5. **land-sync preview** — `POST_LAND_SYNC_MANIFEST=<temp fixture>
   post-land-sync.sh --dry-run` resolves a throwaway fixture `.source`, prints
   the would-run pull + install, and mutates nothing (the real `~/.claude` is
   never touched);
6. **janitor preview** (`--dry-run`; the worktree from step 1 must survive).

## Why nightly, not per-PR

A real `git worktree add` + fixture repos per run is heavier than the per-PR
budget, so `scripts/test.sh` registers the drill under the `TEST_FAST=1`
guard: the per-PR gate SKIPs it, the nightly full suite
(`.github/workflows/nightly.yml`, no flag) runs it every night — the
`test-deploy` re-layering pattern. The gstack `/investigate` / `/ship` /
`/land-and-deploy` tails stay out of reach (upstream skills — the drill stops
at this repo's deterministic seams).

## Run it

```bash
bash tests/goal-defect-chain.test.sh
/CJ_test_run goal-defect-chain
bash scripts/test.sh        # the nightly path (no TEST_FAST) also runs it
```
