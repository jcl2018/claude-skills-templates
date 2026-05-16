---
type: design
parent: S000045
title: "Phase 5 drain logic in /CJ_goal_run — User Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Brief stub. See parent F000021_DESIGN.md for full context. -->

## Problem

The renamed /CJ_goal_run (post-S000044) still declares "green" the moment the
feature PR merges, even though /autoplan + /ship gates frequently push
follow-up scope into TODOS.md. Operator manually invokes /loop /CJ_goal to
drain the new debt — drain is operator-driven, not skill-driven.

## Shape of the solution

Add Phase 5 after /land-and-deploy completes. Diff TODOS.md additions in the
merged PR (`git diff <parent>..HEAD -- TODOS.md`); count new `^### `
headings → N. Skip silently if N == 0 (emit green with
`new_todos_count: 0`). Otherwise AUQ: "Drain N new TODOs?" Recommended yes
if N ≤ cap=5, no otherwise. On yes: per-TODO loop (cap=5) calling
/CJ_goal_todo_fix as subroutine. Halt-on-red; partial = `drained_partial`;
all green = `drained_complete`. New `--no-drain` escape hatch.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Cap=5 for Phase 5 drain | Phase 5 scope is "this run's TODOs" (naturally smaller than backlog). Bounded wall-clock cost: 5 children × ~5 min each = ~25 min worst case. |
| 2 | Per-child /ship Gate #2 (sequential), not batched | Same as /CJ_run Branch (b) multi-story today. Sequential reviews give targeted attention vs. "review 5 diffs at once." |
| 3 | New flag: `--no-drain` (escape hatch) | Operator may know the TODOs from this run need different reviewers/timing; forcing drain would be wrong. |
| 4 | TODOS.md diff threshold: 0 new → skip silently, > 0 → AUQ | Refactor PRs sometimes legitimately produce 0 new TODOs; silently skipping vs always-AUQ keeps the happy path quiet. |
| 5 | AUQ recommendation: yes iff N ≤ cap=5, no otherwise | If N > 5, partial drain isn't completeness; operator should deliberately choose. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| TODOS.md diff parser false-positives (e.g., heading reformatting marked as new) | Smoke test S1 in TEST-SPEC: verify diff parser only catches `^\+### ` lines, not context. |
| Drain loop introduces a new TODO that the drain itself would then need to drain (recursion) | F000021 NOT-in-scope: drain-of-drain deferred to v5+. This story emits `drained_complete` even if the drained PRs added their own TODOs. |
| Cross-skill drain race with concurrent /CJ_goal_todo_fix | Shared lockfile at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt` (implemented in S000046; this story uses it). |
| `--no-drain` flag conflicts with /CJ_goal_run's existing 3-input-shape arg parsing | Reuses existing flag-discard pattern (`--auto`/`--manual` already accepted-and-discarded by /CJ_personal-pipeline); should be a 5-line add. |

## Definition of done

- [ ] Phase 5 implemented in `skills/CJ_goal_run/run.md` (~200 LOC).
- [ ] `--no-drain` flag parses correctly and bypasses Phase 5.
- [ ] Telemetry schema extended with `new_todos_count`, `drained_count`, `drained_pr_urls`.
- [ ] Eval cases cover N=0 silent-skip + N=3 happy-path.
- [ ] Halt-on-red preserved (no new halt classes introduced beyond F000021's `drained_*`).
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch`.

## Not in scope

- Native drain semantics in /CJ_goal_todo_fix — S000046.
- `--quiet` flag — S000047.
- Drain-of-drain recursion — deferred v5+.
- Shared lockfile implementation — done in S000046 (this story consumes it).

## Pointers

- Parent feature tracker: [../F000021_TRACKER.md](../F000021_TRACKER.md)
- Parent feature design: [../F000021_DESIGN.md](../F000021_DESIGN.md)
- Sibling S000046: [../S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md](../S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md`
