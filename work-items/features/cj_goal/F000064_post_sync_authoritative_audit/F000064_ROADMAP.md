---
type: roadmap
parent: F000064
title: "Reorder cj_goal doc/test audit to run after doc-sync (post-sync authoritative audit) — Roadmap"
date: 2026-06-13
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals, decomposition, delivery timeline. -->

## Scope

Reorder the post-QA doc/test audit in all four `cj_goal_*` orchestrators so it runs
**after** `/CJ_document-release` doc-sync, making the operator's post-QA Continue/Halt
checkpoint decide on **post-sync** doc state (the docs that will actually ship in the PR)
rather than a soon-to-change pre-sync snapshot. Implemented as mechanism C-i: the
spec-overlay writes (qa.md 8.6a/8.6b) stay pre-sync with the code; the three-stage doc/test
audits (8.6c/8.6d) become deferrable and move to the orchestrator level, running once,
read-only, as one combined fresh-context subagent after doc-sync. Each pipeline gains an
explicit automated, idempotent pre-doc-sync commit (also closing the long-standing F000038
manual-pre-commit gotcha). The `spec/test-spec` gate registry, the affected docs (CLAUDE.md,
`docs/workflow.md` charts, the four SKILL.md chains, catalog descriptions), and the three
named tests are updated in lockstep.

## Non-Goals

- A separate second post-sync re-audit (mechanism C-ii) — rejected for double agent cost; the audit runs ONCE, post-sync.
- Annotate-only finding tagging at the pre-sync checkpoint (Approach A) — rejected as heuristic.
- Any functional change to `/CJ_document-release` — its Step 6.7 audit + PR-body surfacing are untouched.
- Any change to ship safety — `validate.sh` Check 19 (and 15/16/17/24) still gate at `/ship`; audit findings stay advisory.
- Any upstream gstack modification — the change stays within the workbench surfaces.

## Success Criteria

- [ ] In every cj_goal orchestrator the post-QA-checkpoint audit runs after doc-sync; the operator decides on post-sync doc state.
- [ ] The three-stage audit (incl. Stage-3 drift) runs against post-sync docs, ONCE per run, READ-ONLY.
- [ ] Each pipeline has an explicit automated, idempotent pre-doc-sync commit; no F000038 halt during an autonomous build.
- [ ] Standalone `/CJ_qa-work-item` still runs its inline Step 8.6 audit unchanged.
- [ ] `spec/test-spec.md` / `spec/test-spec-custom.md` declare the new gate order + updated qa-audit backing; `validate.sh` Check 24 + Check 15b green; full `scripts/test.sh` passes.
- [ ] The three named tests updated for the new ordering (zzz-test-scaffold fixture, `cj-goal-doc-sync-wiring.test.sh`, per-pipeline halt-marker tests).

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000106](S000106_qa_audit_defer_split/S000106_TRACKER.md) | qa.md Step 8.6 split + DEFER_AUDIT directive | Open |
| [S000107](S000107_pipelines_reorder_postsync/S000107_TRACKER.md) | The four cj_goal pipelines: pre-doc-sync commit + doc-sync→audit→checkpoint reorder | Open |
| [S000108](S000108_test_spec_gate_order_and_docs/S000108_TRACKER.md) | test-spec gate-order swap + docs + the three named tests | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Owner = primary person responsible. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000106 (qa.md 8.6 split + defer directive) | — | Not Started | chjiang | The deferrable-audit foundation; the pipelines consume its `DEFER_AUDIT: true` signal | — |
| 2 | Ship S000107 (four pipelines reorder + pre-doc-sync commit + post-sync audit) | — | Not Started | chjiang | Per-file commit topology; consumes S000106's defer signal | #1 |
| 3 | Ship S000108 (test-spec gate order + docs + named tests) | — | Not Started | chjiang | The gate registry + ASCII charts + named tests must reflect the reordered sequence | #2 |
| 4 | End-to-end pipeline run | — | Not Started | chjiang | Drive a cj_goal run; confirm the post-QA checkpoint surfaces the post-sync audit; full `scripts/test.sh` green | #3 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-13: F000064 scaffolded from `/office-hours` design (post-sync authoritative audit).

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 S000106 qa.md 8.6 split (defer directive)
      --> #2 S000107 four pipelines reorder + pre-doc-sync commit + post-sync audit
            --> #3 S000108 test-spec gate order + docs + named tests
                  --> #4 End-to-end pipeline run
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Per-file step numbering + commit topology — where exactly the pre-doc-sync commit lands in each of the four pipelines given their differing existing commit points | Resolve during S000107 implementation; apply per-file, keep numbering + halt markers consistent. |
