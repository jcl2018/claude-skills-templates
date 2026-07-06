# Topic: goal-defect — how the goal is achieved

**The dream:** [a bug description becomes a shipped fix](../../../goals/goal-defect.md).
That page is the WHAT (the end goal + the three properties + the deliberate
deterministic-only posture). This subdir is the HOW — the tests that realize it,
grouped by the verification **layer** they run at.

## The property → test → layer map

| Property (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Entry + phase shape** | worktree entry (cj-def-*) + worktree/ship/telemetry phases + qa/doc-sync leaf targets, probed in isolation (dry-run) | `goal-defect-smoke` | [CI-push](CI-push.md) |
| **Chain + land-tail composition** | the whole helper chain in one sandbox: real worktree → D-ID claim preview → pr-check → the before/after recap pair → a fixture land-sync preview → dry-run cleanup | `goal-defect-chain` | [CI-nightly](CI-nightly.md) |
| **Land-tail safety** | post-land-sync guards refuse a bad .source; --dry-run previews without mutating | `goal-defect-land-sync` | [local-hook](local-hook.md) |

## Coverage matrix (property × layer)

| | CI-push (per-PR, fast) | CI-nightly (composed) | local-hook |
|---|:---:|:---:|:---:|
| Entry + phase shape | ✅ `goal-defect-smoke` | ✅ (re-proven in the chain) | — |
| Chain + land-tail composition | — | ✅ `goal-defect-chain` | — |
| Land-tail safety | — | ✅ (previewed in the chain) | ✅ `goal-defect-land-sync` |

All three required deterministic points are filled; there is **no required
agentic point** — this topic is enrolled deterministic-only
(`topic_contracts_deterministic:` in `spec/test-spec-custom.md`), and the
defect verb declares NO agentic row at all (its on-disk eval case stays
undeclared by choice — the posture named in the
[dream doc](../../../goals/goal-defect.md)).

## Run it end to end

```bash
/CJ_test_run --topic goal-defect       # every goal-defect test the current tier allows
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`,
`--layer local-hook`. The chain drill also runs in the nightly full suite
(`bash scripts/test.sh`, no `TEST_FAST`).

## The subtests (front-door docs)

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `goal-defect-smoke` | workflow / CI-push / deterministic | [doc](../../workflow/CI-push/goal-defect-smoke.md) |
| `goal-defect-chain` | workflow / CI-nightly / deterministic | [doc](../../workflow/CI-nightly/goal-defect-chain.md) |
| `goal-defect-land-sync` | workflow / local-hook / deterministic | [doc](../../workflow/local-hook/goal-defect-land-sync.md) |

> This subdir is required by the topic contract: an enrolled topic (either
> enrollment list in `spec/test-spec-custom.md`) must carry this `index.md`, a
> page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
