---
type: roadmap
parent: F000025
title: "Default worktree for /CJ_goal_run + /CJ_goal_todo_fix — Roadmap"
date: 2026-05-16
author: chjiang
status: Approved
---

## Scope

Auto-create a `.claude/worktrees/cj-{type}-{ts}-{pid}/` worktree at the preamble of
`/CJ_goal_run` and `/CJ_goal_todo_fix` (single-TODO mode) when running on `main`
without arguments-less invocation. Per-TODO worktree creation in drain mode happens
inside `scripts/drain-one-todo.sh` via `--force-create`. Conductor-managed sessions
(already inside a worktree) detect and no-op. `--no-worktree` opts out. `--quiet`
mode runs without AUQ and gates the `[worktree]` echo. One shared bash helper at
`scripts/cj-worktree-init.sh` emits single-line JSON output that preambles parse
with `jq -r '.field'` — no `eval`.

## Non-Goals

- `/CJ_goal_investigate` SKILL.md preamble edit — workbench main has no
  `skills/CJ_goal_investigate/` (source-of-truth on unmerged worktree). Tracked as
  a deferred TODOS.md row; fires once the parent worktree lands.
- Auto-cleanup after `/land-and-deploy` — CLAUDE.md already documents the manual
  cleanup workflow (`gh api -X DELETE` + `git worktree remove`).
- `--worktree-name <name>` override flag — `cj-{type}-{ts}-{pid}` default suffices.

## Success Criteria

- [ ] From the main checkout, `/CJ_goal_run <design-doc>` creates `.claude/worktrees/cj-run-{ts}-{pid}/` on branch `cj-run-{ts}-{pid}`, cds in, runs the full pipeline there. Main checkout `git status` shows no new untracked files post-run.
- [ ] From the main checkout, `/CJ_goal_todo_fix T000045` (single-TODO mode) creates `.claude/worktrees/cj-todo-{ts}-{pid}/`, cds in, runs there.
- [ ] From the main checkout, `/CJ_goal_todo_fix --max-drain 3` creates three distinct per-iteration worktrees (one per drained TODO), each with its own branch + PR.
- [ ] From inside `.claude/worktrees/cheeky-popping-kahn/`, `/CJ_goal_run` detects the existing worktree, emits `[worktree] already in cheeky-popping-kahn`, runs in-place.
- [ ] `/CJ_goal_run --no-worktree <design-doc>` runs on the current branch without worktree creation.
- [ ] `/CJ_goal_todo_fix --quiet --max-drain 3` runs with no AUQ and no stdout `[worktree]` echo.
- [ ] In a consumer repo without `.skills-templates.json`, preamble emits `[worktree] WARN: helper unreachable; running on current branch` (not silent).
- [ ] `scripts/validate.sh` and `scripts/test.sh` pass after the change.
- [ ] `tests/cj-worktree-init.test.sh` passes 5 cases (on-main creates, in-worktree detects, --no-worktree opts out, --force-create overrides, dirty-check halts).

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000054](S000054_default_worktree_helper_and_callers/S000054_TRACKER.md) | Shared helper + caller integrations | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000054 ships (helper + both callers + drain loop + tests + TODOS row + CLAUDE.md note) | 2026-05-16 | In Progress | chjiang | Single user-story; all build work | — |
| 2 | `/CJ_goal_investigate` preamble copy-paste (followup) | TBD | Not Started | — | Blocked on `immutable-watching-sparrow` worktree merging to main | (external) |

### Delivery History

- 2026-05-16: Scaffolded F000025 + S000054 via /CJ_personal-pipeline (RUN_ID 20260516-135932-66386).

## Dependency Graph

```
#1 S000054 (helper + callers) --> #2 /CJ_goal_investigate preamble (followup, blocked on external worktree merge)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Should `--worktree-name <name>` override be added in v1? | Deferred; revisit if asked |
| Auto-cleanup after `/land-and-deploy`? | Deferred to a followup TODO |
