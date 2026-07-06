# Test: `goal-feature-gate-seam` (`workflow` / `local-hook`)

> **Topic:** [goal-feature](../../topics/goal-feature/index.md) · **Goal:**
> [a topic becomes a reviewable PR](../../../goals/goal-feature.md) ·
> **Layer view:** [local-hook](../../topics/goal-feature/local-hook.md).
> This test proves the feature verb's build-gate auto-answer seam is safe,
> deterministically.

| Field | Value |
|-------|-------|
| Name | `goal-feature-gate-seam` |
| Category | `workflow` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash tests/cj-e2e-gate.test.sh` |
| Tier | `free` |

## What it is

The full verdict matrix of `scripts/cj-e2e-gate.sh` — the pure, deterministic
helper the `/CJ_goal_feature` pipeline consults at its design-summary gate:
flag-only and marker-only are both `inactive` (the double hard guard), the
design-gate auto-approves (`continue`) only under both guards, a qa-audit digest
with findings always `halt`s (never auto-waived), and any non-allowlisted gate
id (ship / merge / land) stays `inactive` forever. No Claude, no network.

## What it proves for the feature verb

`/CJ_goal_feature` is the only orchestrator with a live `design-gate` call site
for this seam — the one interactive gate between the operator's design approval
and the autonomous build spend. This suite proves that seam can never fire in a
normal run (double guard), can never auto-answer a gstack ship/merge gate
(allowlist), and behaves exactly as the pipeline prose branches on it.

## How to run

```bash
bash tests/cj-e2e-gate.test.sh
# via the contract:
/CJ_test_run goal-feature-gate-seam
/CJ_test_run --category workflow
/CJ_test_run --layer local-hook
```

## Explanation

This is the `goal-feature` topic's **local-hook deterministic** point: a quick,
zero-model-spend check a maintainer runs on demand before gate-adjacent changes
leave the machine (it also runs per-PR inside the full suite — a `local-hook`
row's `layer` is descriptive placement, and this one is deliberately cheap
everywhere). It reuses an existing deterministic test of the feature pipeline's
gate plumbing rather than adding a new harness — zero new maintenance, per the
topic's deterministic-only enrollment posture (see the
[dream doc](../../../goals/goal-feature.md)). If the auto-answer harness is
ever retired, the documented fallback is re-declaring
[`goal-feature-chain`](../CI-nightly/goal-feature-chain.md) at this layer (two
rows sharing one command — the `test-deploy` / `portability-deploy` precedent).

For the per-unit breakdown of the registered test sub-suites, see the
[test family doc](../../test.md).
