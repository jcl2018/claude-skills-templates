---
type: test-plan
parent: D000021
title: "drain-one-todo worktree-init path resolution — Test Plan"
date: 2026-05-17
author: chjiang
status: Draft
---

<!-- Regression test plan for D000021 (drain-one-todo worktree-init path
     resolution). Scope: ONE fix (defect) — verify drain mode resolves
     cj-worktree-init.sh from the deployed location AND no regression for
     in-repo / no-manifest consumers. -->

## Scope

The fix changes how `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh`
resolves `cj-worktree-init.sh`: manifest-`.source`
(`~/.claude/.skills-templates.json`) primary, `BASH_SOURCE`-relative path as
in-repo / no-manifest fallback. Files modified:

- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (resolution block)
- `tests/drain-one-todo-worktree-resolve.test.sh` (new regression test)
- `scripts/test.sh` (suite wiring)

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Manifest-`.source` resolution present (static convention assertion) | `tests/drain-one-todo-worktree-resolve.test.sh` Case 1 — grep `drain-one-todo.sh` for the `~/.claude/.skills-templates.json` `.source` resolution | Resolution block present | Pass |
| 2 | Deployed-layout drain creates a per-iteration worktree (behavioral — the true defect signal) | `tests/drain-one-todo-worktree-resolve.test.sh` Case 2 — build a simulated deployed layout (deployed `drain-one-todo.sh` + manifest `.source` → workbench checkout), run drain dispatch, assert a real `cj-todo-*` worktree is created | Per-iteration `cj-todo-*` worktree created (absent pre-fix) | Pass |
| 3 | Pre-fix regression proof (revert) | Revert the fix, re-run cases 1+2 | Both cases FAIL (Failures: 2, RESULT: FAIL) | Pass |
| 4 | In-repo / no-manifest fallback unchanged | `tests/cj-worktree-init.test.sh` (existing) | 5/5 green — fallback behavior preserved | Pass |

## Verification Steps

- [x] `tests/drain-one-todo-worktree-resolve.test.sh` PASS post-fix (Failures: 0, RESULT: PASS, exit=0)
- [x] Same test FAILS pre-fix (both cases) — revert-proven regression coverage
- [x] `./scripts/validate.sh` PASS (0 errors / 0 warnings)
- [x] `./scripts/test.sh` — new test green; `tests/cj-worktree-init.test.sh` 5/5 green; F000025 wiring block green
- [x] `bash -n` clean on all edited scripts
- [x] Pre-existing `test-deploy.sh` suite failure isolated as orthogonal via `git stash` (stale global-deploy version artifact 4.6.10 vs 4.6.7 — not introduced by this fix)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin), zsh | branch `claude/wonderful-raman-afec8b` | Pass |
| Simulated deployed layout (`~/.claude/skills/CJ_goal_todo_fix/scripts/` + manifest `.source`) | test harness (Case 2) | Pass |
