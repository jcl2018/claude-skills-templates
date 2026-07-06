# Test: `validate-hook` (`infra` / `local-hook`)

> **Topic:** [validator](../../topics/validator/index.md) · **Goal:**
> [no structural break ever lands](../../../goals/validator.md) ·
> **Layer view:** [local-hook](../../topics/validator/local-hook.md).
> This is the validator's **local-hook** level: the same checks that gate CI,
> run at `git commit` before the change ever leaves the machine.

| Field | Value |
|-------|-------|
| Name | `validate-hook` |
| Category | `infra` |
| Layer | `local-hook` |
| Mode | `deterministic` |
| Command | `bash scripts/validate.sh` |
| Tier | `free` |

## What it is

The repo validator executed as the **pre-commit hook**: the workbench hook
installed by `scripts/setup-hooks.sh` runs exactly `bash scripts/validate.sh`
at `git commit`, so a structurally broken tree (catalog drift, an orphan doc, a
stale generated catalog, a broken contract) is caught locally before it is
committed, let alone pushed. Same command as the per-PR
[`validate`](../CI-push/validate.md) test — a distinct execution context (your
machine, at commit time).

## How to run

```bash
bash scripts/validate.sh        # what the pre-commit hook runs at git commit
```

Run via the category contract: `/CJ_test_run validate-hook` (single test),
`/CJ_test_run --category infra` (the whole category),
`/CJ_test_run --layer local-hook` (the whole layer), or
`/CJ_test_run --topic validator` (the whole topic).

To (re)install the hook that fires this automatically: `bash scripts/setup-hooks.sh`.

## Explanation

The [validator dream](../../../goals/validator.md) needs a proof at every
verification layer, and this is the earliest one: the commit boundary. CI
(the [`validate`](../CI-push/validate.md) row) catches the same faults, but only
after a push — the hook catches them seconds after the edit, on the machine that
made it, keeping broken commits out of the history entirely. The consumer-side
`cj-contract-gate.sh` hook is a different, engine-only subset and is deliberately
NOT this row's evidence — this row is the workbench's own full-validator hook.

For the per-check breakdown of everything the validator asserts, see the
[validate family doc](../../validate.md); for the layer-level "how", see
[validator @ local-hook](../../topics/validator/local-hook.md).
