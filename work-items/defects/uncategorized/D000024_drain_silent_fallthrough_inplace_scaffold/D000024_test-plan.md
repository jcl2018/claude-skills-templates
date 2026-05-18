---
type: test-plan
parent: D000024
title: "drain-one-todo silent in-place scaffold when worktree helper unavailable — Test Plan"
date: 2026-05-18
author: chjiang
status: Draft
---

<!-- Regression test plan for D000024 (drain-one-todo silent in-place scaffold
     when worktree helper unavailable). Scope: ONE fix (defect) — verify drain
     mode FAILS LOUD (halts, no in-place scaffold) when cj-worktree-init.sh is
     unreachable, AND no regression for the safe graceful-degradation states or
     the in-repo / deployed happy path. Distinct from D000021 (path
     resolution). -->

## Scope

The fix replaces the silent comment-only fallthrough at
`skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh:246-248` with a fail-loud
guard `if [ ! -x "$_WT_HELPER" ]` (release lock, stderr diagnostic,
`RESULT: STATUS=halted; ... REASON=worktree-helper-unavailable`, `exit 2`).
Files modified:

- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (fail-loud guard block)
- `tests/drain-one-todo-helper-unavailable.test.sh` (new regression test)
- `scripts/test.sh` (suite wiring, after the D000021 block)

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Fail-loud guard present (static convention assertion) | `tests/drain-one-todo-helper-unavailable.test.sh` Case 1 — assert `drain-one-todo.sh` halts loud (`RESULT: STATUS=halted; REASON=worktree-helper-unavailable`) on unreachable helper | Fail-loud guard present | Pass |
| 2 | Deployed layout + unreachable helper → halt loud, no in-place scaffold (behavioral — the true defect signal) | `tests/drain-one-todo-helper-unavailable.test.sh` Case 2 — simulated deployed layout, helper unreachable, run drain dispatch; assert (a) non-zero exit (2), (b) emitted `RESULT: STATUS=halted; ... REASON=worktree-helper-unavailable`, (c) `todo_fix.sh` tripwire never fires (no in-place scaffold) | Halts loud; no delegation; worktree isolation preserved | Pass |
| 3 | Pre-fix regression proof (revert) | `git stash` the source fix only; re-run cases 1+2 | Both FAIL (Failures: 4: dispatch exited 0, tripwire fired, no halted RESULT) | Pass |
| 4 | Safe graceful-degradation + happy path unchanged | `tests/cj-worktree-init.test.sh` + `tests/drain-one-todo-worktree-resolve.test.sh` (existing) | 5/5 + green — reachable-but-non-created states and in-repo/deployed happy path preserved | Pass |

## Verification Steps

- [x] `tests/drain-one-todo-helper-unavailable.test.sh` PASS post-fix (Failures: 0, RESULT: PASS, exit=0) — orchestrator-verified, not trusting subagent
- [x] Same test FAILS pre-fix (Failures: 4) — revert-proven regression coverage
- [x] `./scripts/validate.sh` PASS (0 errors / 0 warnings)
- [x] `./scripts/test.sh` — new test green; `tests/cj-worktree-init.test.sh` 5/5 green; D000021 sibling test green; F000025 wiring green
- [x] `bash -n` clean on edited scripts
- [x] Pre-existing `test-deploy.sh` suite failure isolated as orthogonal via `git stash -u` (stale global-deploy version artifact 4.6.11 vs 4.6.7 — not introduced by this fix; same artifact D000021's RCA documented)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin), zsh | branch `claude/serene-bhabha-13ca63` | Pass |
| Simulated deployed layout + unreachable helper | test harness (Case 2) | Pass |
