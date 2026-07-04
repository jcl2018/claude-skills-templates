---
type: design
parent: S000129
feature: F000079
title: "Deterministic-agentic split of inline doc-sync + test-sync — Story Design"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
reviewers: []
---

## Approach

The single atomic change that moves the SLOW agentic doc/test sync off the cj_goal
build path while keeping the FAST deterministic sync (that the per-PR gate needs)
inline.

**doc-sync (Step 5.5).** Swap the `/CJ_document-release` Skill invocation for a
deterministic `--render-docs` regen (test-spec.sh + workflow-spec.sh) that commits
any `docs/`-only delta. Keep the `Step 5.5: Doc-sync` heading + the two halt
markers, reframed: `[doc-sync-red]` = a render engine returned non-zero;
`[doc-sync-non-doc-write]` = the defensive guard that the regen only touched
`docs/`. Each pipeline preserves its own resume_cmd / telemetry parent_skill /
journal target.

**test-sync (QA 8.6a/8.6b).** Add a `DEFER_SYNC: true` sibling to `DEFER_AUDIT` in
the QA dispatch. In qa.md 8.6.0, detect it; in 8.6a/8.6b, run the DETERMINISTIC
new-surface-row obligation always, but SKIP the agent-judged AMENDMENT sweep when
`DEFER_SYNC = true`. Standalone QA (no directive) keeps the full sweep.

**Safety net.** The EXISTING nightly `audit-nightly.yml` (`/CJ_doc_audit` +
`/CJ_test_audit`) already catches the deferred prose/overlay drift and files the
`audit-drift` issue — no new job.

**Enforcement (two-axis contract).** A `level: integration` behavior
`build-gate-no-inline-slow-sync` linked to the extended
`tests/cj-goal-doc-sync-wiring.test.sh` guard (checks 7-9), plus a
`category: workflow, layer: CI-push, mode: deterministic` test `cj-goal-gate-shape`
so `/CJ_test_run` runs it by name and `/CJ_test_audit` reports it wired — the
complement to the nightly `doc-sync` workflow test.

## Alternatives considered

- **Blanket removal of both sync steps** — rejected: some 8.6a writes are REQUIRED
  for `validate.sh` Check 24, and removing the Step 5.5 regen risks stale catalogs
  (Check 26/27). The split keeps those inline (fast) and defers only the slow
  agentic part.
- **A `level: workflow` enforcement behavior** — rejected: Check 28 reserves
  `level: workflow` for one-orchestrator-per-behavior coverage; the invariant spans
  four orchestrators + qa.md, so `level: integration` is correct (mirrors
  `workflow-doc-audit-runs`).
- **A new nightly job** — rejected: the existing audit already covers the drift.

## Risks

- Self-modifying pipeline: the run's own Step 5.5 uses the pipeline text loaded at
  invocation; the edit affects future runs. Verified by the guard.
- The registered-doc-verdicts surfacing (Step 4.6) previously read a scratch file
  `/CJ_document-release` wrote at its Step 6.7; with no inline call it degrades to a
  best-effort no-op (never halts) — acceptable, documented.
