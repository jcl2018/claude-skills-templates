---
type: design
parent: S000046
title: "Native drain semantics + drain-one-todo.sh helper extraction in /CJ_goal_todo_fix — User Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Brief stub. See parent F000021_DESIGN.md for full context. -->

## Problem

Post-S000044 rename, /CJ_goal_todo_fix retains the single-shot shape from
/CJ_goal v1.1 — "fix ONE TODO". To drain at backlog-scale, operator types
`/loop /CJ_goal_todo_fix` and babysits per-TODO Gate #2 reviews. The user
wants a self-sufficient drain command (no `/loop` dependency) that's
cron-eligible. Plus: S000045's Phase 5 drain and this story's Phase 2 drain
share the same per-TODO inner loop — extract into a shared helper (DRY).

## Shape of the solution

Three changes in one PR:

1. Extract per-TODO loop body into `scripts/drain-one-todo.sh` (~150 LOC shared helper).
2. Refactor S000045's Phase 5 in /CJ_goal_run/run.md to call the helper.
3. Add native drain mode to /CJ_goal_todo_fix: default (no args) = drain up to N=10 easy-fix TODOs; `--max-drain N` flag; preserves single-TODO mode + `--dry-run`. Plus shared lockfile and `nothing_to_drain` end_state.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Default cap = 10 | TODOS.md typically has 5-15 active easy-fix rows; 10 clears most of backlog in one session. Larger than /CJ_goal_run Phase 5's cap=5 because scope is broader (global backlog vs this-run's TODOs). |
| 2 | Default mode = drain (was single-shot) | User's explicit pivot intent. Single-TODO mode preserved via positional arg form (`/CJ_goal_todo_fix T000NNN`) for backward compatibility. |
| 3 | Extract drain-one-todo.sh in THIS story (not S000045) | S000045 needs Phase 5 to work somehow; this story owns the canonical extraction. S000045's Phase 5 ships inline first (v4.1.0), then refactors to call the helper here (v4.2.0). Order: S000045 ships → this story refactors. |
| 4 | Shared lockfile at /tmp/cj-goal-active-headings-$(date +%Y%m%d).txt | Per-day TTL self-cleaning; no GC. Extends /CJ_goal v1.1's existing skip-list mechanic to cross-invocation form. |
| 5 | New `nothing_to_drain` end_state | Empty Phase 1 enumeration needs explicit signal so cron/schedule can distinguish "no work today" from "failure". |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `drain-one-todo.sh` refactor introduces regression in /CJ_goal v1.1 single-TODO behavior | Run existing /CJ_goal eval cases against the renamed skill post-refactor; smoke test S3 in TEST-SPEC. |
| Lockfile race conditions (atomic check-and-write) | Use `flock` or `mkdir`-as-mutex pattern; document in script header. Smoke test S5 covers acquire/release. |
| `nothing_to_drain` end_state breaks downstream tooling expecting only green/red | Add to F000021 NEW HALT CLASSES table; document in CHANGELOG.md v4.2.0 entry. |
| /CJ_suggest preflight-aware enumeration (v3.6.0) skips too aggressively after rename | Smoke test S2 verifies enumeration count > 0 against a known-good TODOS.md fixture. |

## Definition of done

- [ ] `scripts/drain-one-todo.sh` extracted; passes shellcheck.
- [ ] S000045's Phase 5 refactored to call the helper (verified by grep: no inline drain logic in run.md).
- [ ] /CJ_goal_todo_fix default mode = drain-up-to-10.
- [ ] `--max-drain`, `--dry-run`, single-TODO mode all working.
- [ ] Shared lockfile implemented; cross-invocation race smoke-tested.
- [ ] `nothing_to_drain` end_state implemented.
- [ ] Telemetry write to new path; fallback-read both old + new.
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch`.

## Not in scope

- `--quiet` flag — S000047.
- /schedule cron-binding — S000047 (doc only).
- Drain-of-drain recursion — deferred v5+.

## Pointers

- Parent feature tracker: [../F000021_TRACKER.md](../F000021_TRACKER.md)
- Parent feature design: [../F000021_DESIGN.md](../F000021_DESIGN.md)
- Sibling S000045 (Phase 5 in /CJ_goal_run): [../S000045_cj_goal_run_phase5_drain/S000045_TRACKER.md](../S000045_cj_goal_run_phase5_drain/S000045_TRACKER.md)
- /CJ_goal v1.1 preflight filter logic (existing): `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (was `goal.sh`)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md`
