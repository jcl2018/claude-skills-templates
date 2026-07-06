# Topic: goal-task — how the goal is achieved

**The dream:** [a small ad-hoc task becomes a reviewable PR](../../../goals/goal-task.md).
That page is the WHAT (the end goal + the three properties + the deliberate
deterministic-only posture). This subdir is the HOW — the tests that realize it,
grouped by the verification **layer** they run at.

## The property → test → layer map

| Property (from the dream) | How it is achieved | Test | Layer |
|---------------------------|--------------------|------|-------|
| **Gate + scaffold correctness** | complexity-gate refusals + dry-run + live T-ID scaffold + idempotency, sandbox-isolated | `goal-task-scaffold` | [CI-push](CI-push.md) |
| **Chain composition** | the whole helper chain in one sandbox: real worktree → real scaffold inside it → recap → dry-run cleanup | `goal-task-chain` | [CI-nightly](CI-nightly.md) |
| **E2E-harness readiness** | the deterministic half of the local happy-path harness (SKIP gate, sandbox, report, auth gate) | `goal-task-e2e-det` | [local-hook](local-hook.md) |

## Coverage matrix (property × layer)

| | CI-push (per-PR, fast) | CI-nightly (composed) | local-hook |
|---|:---:|:---:|:---:|
| Gate + scaffold correctness | ✅ `goal-task-scaffold` | ✅ (re-proven in the chain) | — |
| Chain composition | — | ✅ `goal-task-chain` | — |
| E2E-harness readiness | — | — | ✅ `goal-task-e2e-det` |

All three required deterministic points are filled; there is **no required
agentic point** — this topic is enrolled deterministic-only
(`topic_contracts_deterministic:` in `spec/test-spec-custom.md`), so the
agent-executed pipeline prose has no required proof (the posture named in the
[dream doc](../../../goals/goal-task.md)). The `goal-task-eval` agentic row and
the real `e2e-local` harness run remain declared + runnable on demand while
they exist, required by nothing.

## Run it end to end

```bash
/CJ_test_run --topic goal-task         # every goal-task test the current tier allows
```

Or by layer: `/CJ_test_run --layer CI-push`, `--layer CI-nightly`,
`--layer local-hook`. The chain drill also runs in the nightly full suite
(`bash scripts/test.sh`, no `TEST_FAST`).

## The subtests (front-door docs)

| Test | Category / Layer / Mode | Front door |
|------|-------------------------|-----------|
| `goal-task-scaffold` | workflow / CI-push / deterministic | [doc](../../workflow/CI-push/goal-task-scaffold.md) |
| `goal-task-chain` | workflow / CI-nightly / deterministic | [doc](../../workflow/CI-nightly/goal-task-chain.md) |
| `goal-task-e2e-det` | workflow / local-hook / deterministic | [doc](../../workflow/local-hook/goal-task-e2e-det.md) |
| `goal-task-eval` (tolerated, not required) | workflow / local-hook / agentic | [doc](../../workflow/local-hook/goal-task-eval.md) |

> This subdir is required by the topic contract: an enrolled topic (either
> enrollment list in `spec/test-spec-custom.md`) must carry this `index.md`, a
> page per layer it covers, and a link back to its dream doc — enforced by
> `test-spec.sh --check-topic-docs` (`validate.sh` Check 31).
