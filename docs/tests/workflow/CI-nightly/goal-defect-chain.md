# Test: `goal-defect-chain` (`workflow` / `CI-nightly`)

> **Topic:** [goal-defect](../../topics/goal-defect/index.md) · **Goal:**
> [a bug description becomes a shipped fix](../../../goals/goal-defect.md) ·
> **Layer view:** [CI-nightly](../../topics/goal-defect/CI-nightly.md).
> This test drives the defect verb's whole deterministic helper chain — through
> its LAND tail — end to end, nightly.

| Field | Value |
|-------|-------|
| Name | `goal-defect-chain` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash tests/goal-defect-chain.test.sh` |
| Tier | `free` |

## What it is

The defect verb's CHAIN drill: one hermetic temp sandbox, the helper chain in
pipeline order — a **real** worktree is created (`--caller defect` →
`cj-def-*`), the D-ID atomic-claim engine previews its mint
(`cj-id-claim.sh --prefix D --floor <N> --dry-run` → a `D[0-9]{6}` id, zero
claim dirs created), the read-only `pr-check` runs, the true BEFORE+AFTER recap
pair renders (`=== About to land ===` then `=== Landed / PR opened ===` — the
bracket the landing verbs emit around `/land-and-deploy`), the post-land sync
tail previews against a temp fixture manifest
(`POST_LAND_SYNC_MANIFEST=<fixture> post-land-sync.sh --dry-run` — the real
`~/.claude` is never read or written), and the worktree janitor previews with
`--dry-run`.

## How to run

```bash
bash tests/goal-defect-chain.test.sh
# via the contract:
/CJ_test_run goal-defect-chain
/CJ_test_run --category workflow
/CJ_test_run --layer CI-nightly
```

## Explanation

This is the `goal-defect` topic's **CI-nightly** point: heavier than the per-PR
budget (a real `git worktree add` + fixture repos per run), so
`scripts/test.sh` registers it under the `TEST_FAST=1` guard — the per-PR gate
SKIPs it, the nightly full suite (`.github/workflows/nightly.yml`) runs it
every night (the `test-deploy` re-layering pattern). The defect verb is a
LANDING verb (it merges in-pipeline, unlike the PR-stop feature/task verbs), so
this drill deliberately covers the land-tail seams — the recap pair and the
post-land sync preview — that the other two chains don't have. The gstack
`/investigate`, `/ship` and `/land-and-deploy` tails stay out of reach
(upstream skills; the drill stops at this repo's deterministic seams), and the
agent-executed pipeline prose is out of scope by design (see the
[dream doc](../../../goals/goal-defect.md)'s posture section).

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
