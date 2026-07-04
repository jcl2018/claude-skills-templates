# Test: `cj-goal-gate-shape` (`workflow` / `CI-push`)

| Field | Value |
|-------|-------|
| Name | `cj-goal-gate-shape` |
| Category | `workflow` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash tests/cj-goal-doc-sync-wiring.test.sh` |
| Tier | `free` |

## What it is

The cj_goal build-gate shape guard — a deterministic (grep, no model) assertion
that all four `CJ_goal_*` orchestrators keep the **slimmed** build tail: Step 5.5
is a fast deterministic doc-regen (NOT the slow `/CJ_document-release` LLM pass),
QA is dispatched with `DEFER_SYNC: true` (so the agent-judged 8.6a/8.6b overlay
sweep is skipped inline), and no inline QA-audit checkpoint survives. It proves
the build-gate deterministic-agentic split stays wired symmetrically across
feature / task / defect / todo_fix.

## How to run

```bash
bash tests/cj-goal-doc-sync-wiring.test.sh
```

Run via the category contract: `/CJ_test_run cj-goal-gate-shape` (single test),
`/CJ_test_run --category workflow` (the whole KIND), or
`/CJ_test_run --layer CI-push` (the whole cadence). It is also executed
transitively by the `suite` infra test (`bash scripts/test.sh`).

## Explanation

This test backs the `build-gate-no-inline-slow-sync` behavior (a
`level: integration` behavior — deliberately NOT `level: workflow`, because the
invariant spans the four orchestrators + `qa.md` rather than one `CJ_goal_*`
orchestrator's run, and the workflow-coverage gate governs only orchestrator ↔
`level: workflow`; this mirrors the `workflow-doc-audit-runs` behavior). It is the
**complement** to the `doc-sync` workflow test at `CI-nightly`: that one proves
the nightly audit *safety net* runs, while this one proves the per-PR build tail
was actually *slimmed* (no inline slow sync). Together they prove the doc/test
sync moved from inline to nightly.

Concretely it asserts: every pipeline keeps a `Step 5.5: Doc-sync` heading + the
`[doc-sync-red]` / `[doc-sync-non-doc-write]` halt markers (reframed to the
deterministic regen), NO pipeline invokes `/CJ_document-release` on the build
path, each Step 5.5 runs the `--render-docs` regen, all four QA dispatches carry
`DEFER_SYNC: true`, and `qa.md` gates the 8.6a/8.6b agentic sweep on `DEFER_SYNC`.

For the per-unit breakdown, see the [test family doc](../../test.md) (the
`test-cj-goal-doc-sync-wiring` units row) and the sibling `doc-sync`
(`workflow`/`CI-nightly`) nightly-audit front door.
