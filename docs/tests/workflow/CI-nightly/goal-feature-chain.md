# Test: `goal-feature-chain` (`workflow` / `CI-nightly`)

> **Topic:** [goal-feature](../../topics/goal-feature/index.md) · **Goal:**
> [a topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
> **Layer view:** [CI-nightly](../../topics/goal-feature/CI-nightly.md).
> This test drives the feature verb's whole deterministic helper chain end to
> end, nightly.

| Field | Value |
|-------|-------|
| Name | `goal-feature-chain` |
| Category | `workflow` |
| Layer | `CI-nightly` |
| Mode | `deterministic` |
| Command | `bash tests/goal-feature-chain.test.sh` |
| Tier | `free` |

## What it is

The feature verb's CHAIN drill: one hermetic temp sandbox, the helper chain in
pipeline order — a **real** worktree is created (`--caller feature` →
`cj-feat-*`) and the isolation verdict asserted from inside it
(`--assert-isolated` → `isolated`), the pre-build sync phase's `--no-sync`
opt-out short-circuits (`PHASE_RESULT=skipped`, no install), the read-only
`pr-check` runs, the design-gate auto-answer seam yields both verdicts
(`AUTO=inactive` bare; `AUTO=continue` under the `CJ_GOAL_E2E_AUTO=1` +
`.cj-e2e-sandbox` double guard), the at-PR 3-part recap renders, and the
worktree janitor previews with `--dry-run` (mutating nothing).

## How to run

```bash
bash tests/goal-feature-chain.test.sh
# via the contract:
/CJ_test_run goal-feature-chain
/CJ_test_run --category workflow
/CJ_test_run --layer CI-nightly
```

## Explanation

This is the `goal-feature` topic's **CI-nightly** point: heavier than the per-PR
budget (a real `git worktree add` per run), so `scripts/test.sh` registers it
under the `TEST_FAST=1` guard — the per-PR gate (`validate.yml`,
`TEST_FAST=1`) SKIPs it, and the nightly full suite
(`.github/workflows/nightly.yml`, no flag) runs it every night, the same
re-layering pattern as the `test-deploy` suite. Where the
[CI-push smoke](../CI-push/goal-feature-smoke.md) probes each phase in
isolation, this drill proves the phases compose: the same sandbox flows through
worktree → sync → pr-check → design-gate seam → recap → cleanup, each phase's
documented contract fields asserted. It reaches helper SCRIPTS only — the
agent-executed pipeline prose is deliberately out of scope (see the
[dream doc](../../../goals/goal-feature.md)'s posture section).

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
