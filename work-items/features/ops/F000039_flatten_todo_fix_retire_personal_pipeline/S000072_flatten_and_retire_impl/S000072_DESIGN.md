---
type: design
parent: S000072
title: "Flatten todo_fix + retire /CJ_personal-pipeline (implementation) — Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic implementation story. The parent feature's design carries the full
     rationale; this stub keeps each section to a sentence or two and links up. -->

## Problem

`/CJ_goal_todo_fix` is the last live caller of the experimental `/CJ_personal-pipeline`
middle layer (single-TODO mode at `todo_fix.sh:870`; drain mode via
`drain-one-todo.sh`). This story carries the implementation that flattens both modes to
dispatch impl→qa leaf subagents directly and deletes `/CJ_personal-pipeline`. See
[parent F000039_DESIGN.md](../F000039_DESIGN.md#problem) for the full problem framing.

## Shape of the solution

Replace the personal-pipeline dispatch with `/CJ_implement-from-spec` →
`/CJ_qa-work-item` leaf Agent subagents (CJ_goal_feature Steps 3.2-3.3, minus scaffold —
todo_fix already scaffolds the T-task dir in pure bash). Rename the halt taxonomy,
delete the skill, and sweep ~18 live-surface references including `validate.sh` Check 12
(paired with `test.sh`) and the catalog `depends.skills`. Full file-by-file plan in
[S000072_SPEC.md](S000072_SPEC.md). One cohesive change → no task children.

## Big decisions

Inherited from the parent feature (see [F000039_DESIGN.md ## Big decisions](../F000039_DESIGN.md#big-decisions)):
Approach A (one PR); "retire" = straight delete with no shim; drop `--suppress-final-gate`
rather than translate it; rename the halt taxonomy to `halted_at_impl`/`halted_at_qa`;
leave `/CJ_personal-workflow` (the validator) untouched.

## Risks & open questions

The single highest-risk item is the `validate.sh` Check 12 removal — it must be paired
with the `test.sh` ~line 1138 reconciliation in the SAME change, or test.sh goes red on
the deleted `pipeline.md`. This is the known implement-subagent blind spot. The
`depends.skills` final list is the open question (include `CJ_scaffold-work-item`?),
resolved during implementation. See [parent ## Risks & open questions](../F000039_DESIGN.md#risks--open-questions).

## Definition of done

`/CJ_goal_todo_fix` (both modes) dispatches impl→qa with no personal-pipeline reference;
the skill is deleted; catalog/docs/rules/README/sibling-skills/handoff-gate/validate.sh
Check 12/test.sh all cleaned; halt taxonomy renamed; `validate.sh` + `test.sh` green;
the live-surface grep sweep returns nothing. Full checklist in
[S000072_SPEC.md ## Acceptance Criteria](S000072_SPEC.md#acceptance-criteria) and
[S000072_TRACKER.md ## Acceptance Criteria](S000072_TRACKER.md#acceptance-criteria).

## Not in scope

A new portability guard for `/CJ_goal_todo_fix`; `work-items/` history references;
the stale `[qa-severity-scale-fictional]` learning pointer; Approach C re-consolidation.
See [parent ## Not in scope](../F000039_DESIGN.md#not-in-scope).

## Pointers

- Parent feature design: [../F000039_DESIGN.md](../F000039_DESIGN.md)
- Parent tracker: [../F000039_TRACKER.md](../F000039_TRACKER.md)
- This story's spec: [S000072_SPEC.md](S000072_SPEC.md)
- This story's test spec: [S000072_TEST-SPEC.md](S000072_TEST-SPEC.md)
- Prior art: F000027 (flattened feature/defect off personal-pipeline)
