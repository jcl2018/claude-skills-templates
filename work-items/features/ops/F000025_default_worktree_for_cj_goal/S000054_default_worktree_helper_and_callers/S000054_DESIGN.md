---
type: design
parent: S000054
title: "Shared cj-worktree-init.sh helper + CJ_goal_run/CJ_goal_todo_fix preamble integration — Story Design"
version: 1
status: Approved
date: 2026-05-16
author: chjiang
reviewers: []
---

## Problem

See parent feature design: [../F000025_DESIGN.md](../F000025_DESIGN.md).

This story is atomic and inherits the parent feature's full /office-hours design
doc. Story-local detail (SPEC + TEST-SPEC) is in the sibling files.

## Shape of the solution

Single PR delivering 8 file changes:
1. New `scripts/cj-worktree-init.sh` (~60 lines bash, JSON output)
2. New `tests/cj-worktree-init.test.sh` (5-case helper test)
3. Edit `skills/CJ_goal_run/SKILL.md` (preamble block BEFORE Path Resolution)
4. Edit `skills/CJ_goal_todo_fix/SKILL.md` (preamble block BEFORE Path Resolution; single-TODO mode only)
5. Edit `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (per-iteration helper call with `--force-create --quiet` via BASH_SOURCE)
6. Edit `scripts/test.sh` (regression assertion for preamble wiring + invoke new helper test)
7. Edit `TODOS.md` (deferred row for /CJ_goal_investigate worktree wiring)
8. Edit `CLAUDE.md` (one-line note: /CJ_goal_run + /CJ_goal_todo_fix auto-worktree on main)

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | All implementation lands in one PR (no decomposition) | Atomic — helper + callers + tests + docs must ship together; partial states would leave callers wired to a missing helper |
| 2 | Preamble block goes BEFORE the existing Path Resolution block in each SKILL.md | `cd` after `git worktree add` invalidates pre-cd `_REPO_ROOT`/`_SKILL_DIR`; preamble must run first so path resolution happens against the worktree |
| 3 | Drain loop integration in `drain-one-todo.sh` (not `todo_fix.sh`) | The per-iteration helper call must run once per TODO drained, which is precisely the iteration boundary of `drain-one-todo.sh` |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` may not exist at workbench HEAD; need to verify before editing | Phase 2 impl verifies; if missing, edits `scripts/todo_fix.sh` per-iteration call instead |
| `tests/` dir may not exist at workbench HEAD | Phase 2 creates it (`mkdir -p tests`) |

## Definition of done

See parent feature DESIGN.md "Definition of done" — same criteria.

## Not in scope

Same as parent feature DESIGN.md.

## Pointers

- Parent feature tracker: [../F000025_TRACKER.md](../F000025_TRACKER.md)
- Parent feature design: [../F000025_DESIGN.md](../F000025_DESIGN.md)
- /office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-default-worktree-design-20260516-121928.md`
