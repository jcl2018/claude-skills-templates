# Topic: goal-feature — how the goal is achieved

**The dream:** [a one-line topic becomes a reviewable PR](../../../goals/goal-feature.md).
That page is the WHAT (the end goal + the three properties + the deliberate
deterministic-only posture). This subdir is the HOW — the tests that realize it,
grouped by the verification **layer** they run at.

## The property → test → layer map

| Property (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Entry + phase shape** | worktree entry + worktree/ship/telemetry phases + leaf targets, probed in isolation (dry-run) | `goal-feature-smoke` | [CI-push](CI-push.md) |
| **Chain composition** | the whole helper chain in one sandbox: real worktree + assert-isolated → sync opt-out → pr-check → design-gate seam → recap → dry-run cleanup | `goal-feature-chain` | [CI-nightly](CI-nightly.md) |
| **Gate-seam safety** | the full cj-e2e-gate verdict matrix (double guard, allowlist, never auto-waive) | `goal-feature-gate-seam` | [local-hook](local-hook.md) |

## Coverage matrix (property × layer)

| | CI-push (per-PR, fast) | CI-nightly (composed) | local-hook |
|---|:---:|:---:|:---:|
| Entry + phase shape | ✅ `goal-feature-smoke` | ✅ (re-proven in the chain) | — |
| Chain composition | — | ✅ `goal-feature-chain` | — |
| Gate-seam safety | — | ✅ (both verdicts in the chain) | ✅ `goal-feature-gate-seam` |

All three required deterministic points are filled; there is **no required
agentic point** — this topic is enrolled deterministic-only
(`topic_contracts_deterministic:` in `spec/test-spec-custom.md`), so the
agent-executed pipeline prose has no required proof (the posture named in the
[dream doc](../../../goals/goal-feature.md)). The `goal-feature-eval` agentic
row remains declared + runnable on demand while it exists, required by nothing.

## Run it end to end

```bash
/CJ_test_run --topic goal-feature      # every goal-feature test the current tier allows
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`,
`--layer local-hook`. The chain drill also runs in the nightly full suite
(`bash scripts/test.sh`, no `TEST_FAST`).

## The subtests (front-door docs)

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `goal-feature-smoke` | workflow / CI-push / deterministic | [doc](../../workflow/CI-push/goal-feature-smoke.md) |
| `goal-feature-chain` | workflow / CI-nightly / deterministic | [doc](../../workflow/CI-nightly/goal-feature-chain.md) |
| `goal-feature-gate-seam` | workflow / local-hook / deterministic | [doc](../../workflow/local-hook/goal-feature-gate-seam.md) |
| `goal-feature-eval` (tolerated, not required) | workflow / local-hook / agentic | [doc](../../workflow/local-hook/goal-feature-eval.md) |

> This subdir is required by the topic contract: an enrolled topic (either
> enrollment list in `spec/test-spec-custom.md`) must carry this `index.md`, a
> page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
