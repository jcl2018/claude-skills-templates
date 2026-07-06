# Test: `cj-goal-jq-crlf` (`regression` / `CI-push`)

<!-- SEEDED STUB — the authoritative per-test front door (What it is / How
     to run / Explanation). Seeded by /CJ_test_audit from the
     spec/test-spec-custom.md categories: axis. Safe to edit: the audit seeds
     this only when absent (idempotent; present => skip). Fill each section and
     link the relevant docs/tests/<family>.md units-detail page. -->

| Field | Value |
|-------|-------|
| Name | `cj-goal-jq-crlf` |
| Category | `regression` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/regression/CI-push/cj-goal-jq-crlf.test.sh` |
| Tier | `free` |

## What it is

The orchestrator-helper jq-CRLF drill: the CR-stripping jq() wrapper is present in the five cj-goal helpers and, under a CRLF-emitting jq shim, strips CR from jq output while preserving jq's non-zero exit status — so a Windows jq's CRLF can no longer re-taint the worktree/sync/pr-check phases.

## How to run

```bash
bash tests/regression/CI-push/cj-goal-jq-crlf.test.sh
```

Run via the category contract: `/CJ_test_run cj-goal-jq-crlf` (single test),
`/CJ_test_run --category regression` (the whole category), or
`/CJ_test_run --layer CI-push` (the whole layer).

## Explanation

This regression test exists because a Windows jq build emits CRLF line
endings, and a stray carriage return riding a jq substitution once broke the
goal orchestrators' shell helpers: the tainted value failed the
source-directory guard and silently skipped the sync and pr-check phases — an
entire class of quiet Windows-only breakage. The fix gave each of the five
orchestrator helpers (the goal-common phase driver, the worktree init and
cleanup helpers, the version-queue preflight, and the gates-update check) a
CR-stripping `jq()` wrapper mirroring the shared library's. This drill keeps
the class closed: it structurally asserts the wrapper is present in all five
helpers, then runs them under a PATH-prepended CRLF-emitting jq shim and
asserts CR is stripped from output while jq's non-zero exit status still
propagates without pipefail, ending with a worktree-phase end-to-end pass. It
runs per-PR as part of the full suite, model-free.

It is also the declared proof of the orchestrator-helper jq-CRLF row in the
defect-coverage ledger (`spec/test-spec-custom.md`, `defect_coverage:`); the
sibling spec-engine jq-CRLF surface is proven separately by the workflow-spec
render suite's CRLF-jq drill. The per-unit breakdown behind this front door
lives on the [test-family units-detail page](../../test.md); the whole catalog
is at [docs/test-catalog.md](../../../test-catalog.md).
