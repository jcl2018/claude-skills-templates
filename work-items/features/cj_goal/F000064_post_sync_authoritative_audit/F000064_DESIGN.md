---
type: design
parent: F000064
title: "Reorder cj_goal doc/test audit to run after doc-sync (post-sync authoritative audit) — Feature Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

In all four `cj_goal_*` orchestrators (CJ_goal_feature, CJ_goal_defect, CJ_goal_task,
CJ_goal_todo_fix), the post-QA audit checkpoint surfaces the **pre-doc-sync**
`/CJ_doc_audit` + `/CJ_test_audit` findings to the operator, but the doc-mutating step
`/CJ_document-release` (Step 5.5 doc-sync) runs **after** that checkpoint. The doc/test
audit lives inside the QA subagent (qa.md Step 8.6) and runs before doc-sync touches any
docs.

Two consequences: (1) the operator's Continue/Halt decision is fed by a pre-fix audit —
they see findings computed against docs that doc-sync is about to change, and cannot tell
which findings reflect the final PR state; (2) the deep Stage-3 implementation-drift audit
only ever runs pre-doc-sync and is never re-confirmed against the post-sync docs
(`/CJ_document-release`'s own Step 6.7 audit is requirement-compliance only — no Stage-3
drift). This is a decision-quality wrinkle, **not** a safety hole: the hard `validate.sh`
gates (Checks 15/16/17/19/24) still run post-sync at `/ship`, so nothing broken can
actually ship. The fix improves the *signal the operator decides on*, not ship safety.

## Shape of the solution

Mechanism C-i — **audit once, post-sync, read-only**. Split qa.md Step 8.6: the
spec-overlay *writes* (8.6a/8.6b) stay inline in QA on every green path (pre-sync, so the
new pre-doc-sync commit + doc-sync fold them into the PR); the three-stage doc/test
*audits* (8.6c/8.6d) become deferrable and move to the orchestrator level, running after
doc-sync. Each orchestrator gains an explicit automated **pre-doc-sync commit** (closing
the F000038 manual-pre-commit gotcha as a bonus), then runs doc-sync **ahead** of the
audit + checkpoint, then runs the post-sync audit as ONE combined depth-2 fresh-context
subagent. The QA-audit checkpoint is re-pointed to consume the post-sync report.

New cj_goal sequence (replaces QA → checkpoint → doc-sync):

```
implement (writes code; does NOT commit)
   ▼
QA  (smoke/E2E + spec-overlay WRITES 8.6a/8.6b only; audit DEFERRED when orchestrator-driven)
   ▼
pre-doc-sync COMMIT  (NEW automated step — git add + commit the QA-green code + 8.6a/8.6b overlays; idempotent)
   ▼
doc-sync  (/CJ_document-release — folds doc updates into the PR; needs the commit above)
   ▼
doc/test AUDIT  (orchestrator-level, post-sync, ONE combined depth-2 fresh-context subagent
                 running /CJ_doc_audit + /CJ_test_audit; READ-ONLY)
   ▼
QA-audit checkpoint  (operator Continue/Halt on the POST-sync audit)
   ▼
portability gate  →  /ship  (commits the tracker journal lines + opens PR)  →  PR
```

| Concern | User-story | Artifact |
|---------|-----------|----------|
| qa.md Step 8.6 split: 8.6a/8.6b inline, 8.6c/8.6d deferrable via `DEFER_AUDIT: true`; standalone keeps inline audit | S000106 | [S000106_qa_audit_defer_split/S000106_TRACKER.md](S000106_qa_audit_defer_split/S000106_TRACKER.md) |
| The four cj_goal pipelines: pre-doc-sync commit + doc-sync→audit→checkpoint reorder + post-sync read-only audit step + checkpoint re-point + embed `DEFER_AUDIT: true` | S000107 | [S000107_pipelines_reorder_postsync/S000107_TRACKER.md](S000107_pipelines_reorder_postsync/S000107_TRACKER.md) |
| test-spec registry gate-order swap + qa-audit backing prose; docs (CLAUDE.md, workflow.md charts, SKILL.md chains, catalog); the three named tests | S000108 | [S000108_test_spec_gate_order_and_docs/S000108_TRACKER.md](S000108_test_spec_gate_order_and_docs/S000108_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C (structural reorder — move doc-sync ahead of the audit + checkpoint) over A (annotate-only) and B (re-audit twice) | A papers over the ordering and the "reachable" tag is heuristic; B runs the expensive 3-stage audit twice for little gain and still decides the checkpoint on the stale pre-sync audit. C makes the operator's decision honest about the docs that will actually ship. |
| 2 | Within C, mechanism C-i (audit once, post-sync) over C-ii (audit twice, additive) | Per Premise 3, doc-sync (upstream `/document-release`) only updates release-style docs and does not regenerate `workflow.md`/`philosophy.md`, so a second post-sync audit mostly re-reports unchanged drift — wasted cost. Run the one audit at the authoritative post-sync point. |
| 3 | The defer signal is a literal `DEFER_AUDIT: true` directive embedded in the QA Agent-tool dispatch prompt, NOT an argv `--flag` | `/CJ_qa-work-item` is dispatched as a subagent prompt (pipeline.md ROLE/TASK block), not a CLI with argv; the literal string in the pipeline.md prompt templates gives greppability. (OQ1 resolved.) |
| 4 | Add an explicit automated pre-doc-sync commit step per pipeline | `/CJ_document-release` Step 2 hard-refuses on uncommitted non-doc changes (`[doc-sync-red]`); the implement+QA subagents write but do not commit, and `/ship` (the committer) runs after doc-sync. Today the feature pipeline only avoids the halt via the operator manually committing (F000038 gotcha, PR #195). The reorder MUST formalize this commit; it closes the long-standing manual gotcha. |
| 5 | The post-sync audit is READ-ONLY (no overlay/doc fixes post-sync) | Preserves the "everything in the PR is post-sync-clean" invariant. If the audit surfaces a needed fix, the operator Halts at the checkpoint and re-runs so the fix lands pre-sync on the next pass. (Addresses reviewer finding 1c.) |
| 6 | doc-sync / post-sync audit / checkpoint record NO new phase boundary (pure-read / idempotent); only the pre-doc-sync commit records a boundary (or is made idempotent) | doc-sync is green-noop on a clean tree and the audit is now read-only, so a resume re-runs sync→audit→checkpoint without skipping, exactly as audit+checkpoint are re-run today. The commit IS a state change — skip it when the tree is already clean at HEAD so a resume does not double-commit. (OQ2 resolved.) |
| 7 | The post-sync audit is ONE combined subagent running both `/CJ_doc_audit` + `/CJ_test_audit` (not two) | The skills' standalone contract allows one subagent to judge both audits; dispatching two would double the cost C-i exists to avoid. |
| 8 | Per-file commit topology — enumerate per pipeline, do not "move the audit" symmetrically across four identical files | The defect pipeline commits the fix before QA (Step 7.6) and re-commits the tracker after QA; the feature pipeline commits nothing automatically; task/todo differ again. The new pre-doc-sync commit lands at a different point per file. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Per-file step numbering + commit topology drift — each orchestrator numbers steps independently and has a different existing commit topology; a partial/inconsistent reorder would leave the pipelines inconsistent | Resolve during S000107 implementation — apply per-file, keep each file's numbering, commit points, and halt markers consistent; coordinate all four + qa.md + test-spec in one work-item so they land together. |
| Implement-subagent blind spot: forgetting the parallel test edits (zzz-test-scaffold fixture, `cj-goal-doc-sync-wiring.test.sh` ORDERING assertion, per-pipeline halt-marker tests) | Listed as explicit S000108 implementation steps — do not rely on the implement subagent to remember; `cj-goal-doc-sync-wiring.test.sh` will FAIL on the reorder until updated. |
| Standalone `/CJ_qa-work-item` regressions — standalone runs have no later doc-sync, so QA-time IS their last doc-mutating point and the inline audit must stay correct there | Verify in S000106 — standalone QA (no `DEFER_AUDIT: true` directive) runs 8.6c/8.6d inline exactly as today and keeps emitting `AUDIT_FINDINGS`. |
| `validate.sh` Check 24 / Check 15b drift — the test-spec gate ordering and the per-`CJ_goal_*` ASCII charts in `docs/workflow.md` must reflect the reordered sequence | Verify in S000108 — swap `qa-audit`/`doc-sync` `order:` values + update the charts; Check 24 + Check 15b must stay green and the full `scripts/test.sh` suite must pass. |

## Definition of done

- [ ] In every cj_goal orchestrator, the doc/test audit feeding the post-QA checkpoint runs AFTER doc-sync; the operator's Continue/Halt decision reflects post-sync doc state.
- [ ] The three-stage audit (incl. Stage-3 drift) runs against the post-sync docs, ONCE per run (one combined subagent), READ-ONLY.
- [ ] Each pipeline has an explicit automated, idempotent pre-doc-sync commit so doc-sync never hits the F000038 manual-pre-commit halt during an autonomous build.
- [ ] Standalone `/CJ_qa-work-item` still runs its inline Step 8.6 audit unchanged.
- [ ] `spec/test-spec.md` / `spec/test-spec-custom.md` declare the new gate order AND the updated `qa-audit` backing field; `validate.sh` Check 24 + Check 15b are green; the full `scripts/test.sh` suite passes.
- [ ] The three named tests are updated for the new ordering (zzz-test-scaffold fixture, `cj-goal-doc-sync-wiring.test.sh`, per-pipeline halt-marker tests).
- [ ] No change to ship safety: Check 19 (and 15/16/17/24) still gate at `/ship`; audit findings remain advisory (never flip QA red).

## Not in scope

- A separate second post-sync re-audit (mechanism C-ii) — rejected for double agent cost and a baseline the operator mostly ignores.
- Annotating findings "doc-sync-reachable" vs "manual-only" at the pre-sync checkpoint (Approach A) — rejected as heuristic and papering over the ordering.
- Any change to `/CJ_document-release` functional behavior — its internal Step 6.7 registered-doc requirements audit and PR-body surfacing are untouched; the new post-sync audit is a separate, broader three-stage verification the orchestrator owns.
- Changing the hard doc gate — `validate.sh` Check 19 stays unchanged at `/ship`; audit posture stays advisory (never flips QA red).
- Any upstream gstack modification — the change stays within the workbench's cj_goal pipeline contract + qa.md + the test-spec registry + docs.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. -->

- Parent tracker: [F000064_TRACKER.md](F000064_TRACKER.md)
- Roadmap: [F000064_ROADMAP.md](F000064_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-friendly-sinoussi-cef30d-design-20260613-002420.md`
- Related: F000038 (the manual pre-commit gotcha this formalizes), F000063 (gate-spec folded into test-spec — the gate registry this reorders).
