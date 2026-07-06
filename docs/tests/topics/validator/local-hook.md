# validator @ local-hook — the commit-boundary catch

Realizes the [validator dream](../../../goals/validator.md)'s **every-boundary
firing** property at the earliest boundary of all: `git commit`, on the machine
that made the change.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`validate-hook`](../../infra/local-hook/validate-hook.md) | deterministic | **Whole-contract coverage, at commit** | the `setup-hooks.sh` pre-commit hook runs exactly `bash scripts/validate.sh`; a structural break blocks the commit itself. |

## How this layer achieves the dream

The hook is the cheapest catch: seconds after the edit, before the break enters
history, with the developer's full context still warm. CI would catch the same
fault, but only after a push and a round trip. The **anywhere-runnable** property
is what makes this affordable — the validator is deterministic, free, and
self-contained, so running it at every commit costs nothing but seconds.

The workbench hook is installed by `bash scripts/setup-hooks.sh` (auto-run by
`setup.sh`). The consumer-side `cj-contract-gate.sh` pre-commit hook is a
different, engine-only subset — deliberately not counted as this topic's
evidence.

No agentic test is declared at this layer for the validator topic — the
validator is deterministic by nature, and the topic contract treats the
local-hook agentic point as advisory (`test-spec.sh --check-topic-contract`
prints a per-topic `note:` for it, never a finding).

## How to run

```bash
bash scripts/validate.sh          # what the hook runs at git commit
bash scripts/setup-hooks.sh       # (re)install the hook
/CJ_test_run validate-hook
/CJ_test_run --topic validator
```

For the per-check breakdown, see the [validate family doc](../../validate.md).
