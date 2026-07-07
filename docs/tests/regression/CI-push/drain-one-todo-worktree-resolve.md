# Test: `drain-one-todo-worktree-resolve` (`regression` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `drain-one-todo-worktree-resolve` |
| Category | `regression` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/regression/CI-push/drain-one-todo-worktree-resolve.test.sh` |
| Tier | `free` |

## What it is

The drain deployed-path drill: a deployed drain helper resolves the worktree-init helper via the manifest source path (not a deploy-relative guess) and creates a real per-iteration worktree, so drained TODOs never collide on one branch.

## How to run

```bash
bash tests/regression/CI-push/drain-one-todo-worktree-resolve.test.sh
```

Run via the category contract: `/CJ_test_run drain-one-todo-worktree-resolve` (single test),
`/CJ_test_run --category regression` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This regression test exists because the TODO drain once resolved its
worktree-init helper with a path computed relative to its own deployed
location — which pointed at a directory that does not exist under the deployed
skills home, so the guard silently fell through and every drained TODO ran
in-place on the current branch, colliding at the ship gate instead of each
getting its own worktree. The fix resolves the helper via the source checkout
recorded in the install manifest (the same convention the other drain and
preamble scripts use), keeping the location-relative path only as the in-repo
fallback. This drill pins both halves: a static convention assertion on the
resolution code, plus a behavioral case that builds a simulated deployed
layout and asserts a real per-iteration worktree is actually created. It runs
per-PR as part of the full suite, model-free.

It is also the declared proof of the drain deployed-path row in the
defect-coverage ledger (`spec/test-spec-custom.md`, `defect_coverage:`). The
per-unit breakdown behind this front door lives on the
[test-family units-detail page](../../test.md); the whole catalog is at
[docs/test-catalog.md](../../../test-catalog.md).
