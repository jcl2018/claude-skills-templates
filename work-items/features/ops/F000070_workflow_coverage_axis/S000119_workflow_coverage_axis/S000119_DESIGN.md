---
type: design
parent: F000070
title: "Eval-backed level:workflow coverage + forward/reverse gate — Story Design"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Brief by intent — the cross-story shape lives in
     the parent F000070_DESIGN.md; this captures the story-scope decisions. -->

## Problem

A `CJ_goal_*` orchestrator can be fully documented in `spec/workflow-spec.md`
(rendered to `docs/workflows/`) with ZERO test proving the workflow runs. The
`level: workflow` slot in the F000066 behaviors axis is empty (0 such behaviors
today) and nothing forces it filled. This story builds the real eval-backed test
per orchestrator plus the forward/reverse gate that makes
"documented-but-untested" structurally impossible.

## Shape of the solution

A single implementation chain (9 steps): add 3 real eval cases
(`feature`/`task`/`defect`), declare 4 `level: workflow` behaviors + 4
`behavior_coverage:` rows, extend the behaviors parser to a 6th `workflow`
column, add `workflow-spec.sh --list-orchestrators` +
`test-spec.sh --check-workflow-coverage`, wire a new HARD registry-gated
`validate.sh` check (+ `zzz-test-scaffold` fixture), surface in `/CJ_test_audit`
(Stage 1 verbatim + Stage 2 substance), and add the new-machinery tests. See the
parent [F000070_DESIGN.md](../F000070_DESIGN.md) for the cross-story rationale.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Real Claude-driven eval cases (the `CJ_goal_todo_fix` pattern), not shell/`--dry-run` stubs | Reviews proved stubs hollow; an eval case actually runs the workflow up to a gstack-independent decision. |
| 2 | Eval cases target gstack-independent paths (`halted_at_too_complex`, `--dry-run dry_run_preview`) | They must RUN without gstack-in-CI; the full happy-path E2E is a deferred upgrade. |
| 3 | Explicit optional `workflow:` 6th TSV column + registry-sourced `--list-orchestrators` | Closes OQ1/OQ2; budgeted parser change (findings 3/6) + correct consumer-skip source (finding 4). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| 6th-column parser must touch the flush `printf` + ~line-580 read with the `-` unwrap | Implement-time: verify the `$1`-only consumers stay positional-safe. |
| New `validate.sh` check needs the parallel `zzz-test-scaffold` fixture edit | Pre-flight the recurring blind spot in the implement prompt. |
| Declaring `level: workflow` auto-activates Checks 3–6 | Wire `anchor` (live `-F` grep) + ≥1 coverage row per behavior. |

## Definition of done

- [ ] See [S000119_TRACKER.md](S000119_TRACKER.md) Acceptance Criteria — all checked.
- [ ] `test-spec.sh --check-workflow-coverage` green from birth; new `validate.sh` check in plain CI; negative + consumer fixtures pass.
- [ ] `scripts/test.sh` green; `validate.sh` 0 errors.

## Not in scope

- The generated `docs/tests/workflow-coverage.md` view — deferred follow-up.
- The full happy-path-to-PR eval E2E (reaching `/ship`) — gated on the gstack-in-CI blocker.
- Editing the four `CJ_goal_*` `pipeline.md`/`SKILL.md` files.

## Pointers

- Parent feature design: [../F000070_DESIGN.md](../F000070_DESIGN.md)
- Parent tracker: [../F000070_TRACKER.md](../F000070_TRACKER.md)
- This story: [S000119_TRACKER.md](S000119_TRACKER.md) · [S000119_SPEC.md](S000119_SPEC.md) · [S000119_TEST-SPEC.md](S000119_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-dreamy-wilbur-17be66-design-20260629-194540.md`
