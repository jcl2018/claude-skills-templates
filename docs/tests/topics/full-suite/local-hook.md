# full-suite @ local-hook — run it before you push

Realizes the [full-suite dream](../../../goals/full-suite.md)'s **green before it
ships** property at the earliest practical point: the developer's own machine,
before the push.

## What runs here, and what it achieves

| Test | Mode | Achieves | How (in one line) |
|------|------|----------|-------------------|
| [`suite-local`](../../infra/local-hook/suite-local.md) | deterministic | **First green signal** | the documented run-locally-before-push discipline: `bash scripts/test.sh` (plus shellcheck) locally, because the per-PR CI gate fails on ANY finding. |

## How this layer achieves the dream

A red CI run costs a full push round trip; the local full run catches the same
failure minutes earlier, with the change's context still warm. The pre-commit
hook deliberately runs only the faster `validate.sh` (see
[validator @ local-hook](../validator/local-hook.md)) — the full suite is too
heavy for every commit, so it runs at the *push* cadence instead: a manual,
documented discipline rather than an installed hook.

No agentic test is declared at this layer for the full-suite topic — the suite
is deterministic by nature, and the topic contract treats the local-hook agentic
point as advisory (`test-spec.sh --check-topic-contract` prints a per-topic
`note:` for it, never a finding).

## How to run

```bash
bash scripts/test.sh              # the full local run, before pushing
/CJ_test_run suite-local
/CJ_test_run --topic full-suite
```

For what the suite is made of, see the [test-catalog index](../../../test-catalog.md)
and the [test family doc](../../test.md).
