# Test: `drain-one-todo-helper-unavailable` (`regression` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `drain-one-todo-helper-unavailable` |
| Category | `regression` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/regression/CI-push/drain-one-todo-helper-unavailable.test.sh` |
| Tier | `free` |

## What it is

The drain fail-loud drill: when the worktree-init helper is unreachable everywhere (manifest source gone AND the in-repo fallback absent), the TODO drain halts with a named RESULT and a non-zero exit instead of silently scaffolding the drained TODO into the current (possibly dirty) branch.

## How to run

```bash
bash tests/regression/CI-push/drain-one-todo-helper-unavailable.test.sh
```

Run via the category contract: `/CJ_test_run drain-one-todo-helper-unavailable` (single test),
`/CJ_test_run --category regression` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This regression test exists because the TODO drain once failed SILENTLY when
its worktree-init helper could not be found anywhere (the manifest's source
checkout gone AND the in-repo fallback absent): instead of stopping, the drain
fell through and scaffolded the drained TODO directly into the operator's
current — possibly dirty — branch, destroying the per-TODO worktree isolation
and once landing a drain scaffold on top of unrelated uncommitted work. The
fix made the unreachable-helper case fail LOUD: the drain releases its lock,
prints a remediation message, emits a halted RESULT line, and exits non-zero
so the drain loop stops. This drill keeps that behavior pinned with a static
guard-presence assertion plus a behavioral case that builds a simulated
deployed layout with the helper unreachable everywhere and asserts the halt,
the RESULT line, and that the in-place scaffold tripwire never fires. It runs
per-PR as part of the full suite, model-free.

It is also the declared proof of the drain fail-loud row in the
defect-coverage ledger (`spec/test-spec-custom.md`, `defect_coverage:`). The
per-unit breakdown behind this front door lives on the
[test-family units-detail page](../../test.md); the whole catalog is at
[docs/test-catalog.md](../../../test-catalog.md).
