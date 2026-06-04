---
type: test-plan
parent: T000036
title: "Post-run worktree-cleanup janitor for the three CJ_goal_* orchestrators — Test Plan"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Adds a post-run worktree-cleanup janitor to the three `CJ_goal_*` orchestrators. Files changed:

- `scripts/cj-worktree-cleanup.sh` (NEW) — the PR-state-gated sweep + `--dry-run` + `git worktree prune` + guarded root-main refresh.
- `scripts/cj-goal-common.sh` (MODIFIED) — new `--phase cleanup` dispatch (feature + defect only).
- `skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`, `skills/CJ_goal_todo_fix/SKILL.md`, `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (MODIFIED) — terminal cleanup wiring at the four real post-land seams.
- `skills/CJ_goal_feature/SKILL.md`, `skills/CJ_goal_defect/SKILL.md`, `skills/CJ_goal_todo_fix/SKILL.md` (MODIFIED) — chain-diagram / overview doc touches.
- `tests/cj-worktree-cleanup.test.sh` (NEW) + `scripts/test.sh` (MODIFIED — register the new test, discovery is NOT glob-based).
- `CLAUDE.md` (MODIFIED) — Scripts-reference table row + Worktree-cleanup merge-convention note.

The cases below are the behavior-test rows for `tests/cj-worktree-cleanup.test.sh` (fake `git`/`gh` or fixture worktrees), plus static-grep wiring/registration assertions. The janitor is best-effort and never halts — there is no red-path that aborts a run; the "negative" assertions are SKIP/no-mutation, not failures.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `--dry-run` mutates nothing | Run `cj-worktree-cleanup.sh --dry-run --caller feature` against fixture worktrees that include a MERGED-PR cj-* worktree | Prints `WOULD-REMOVE`/`WOULD-SKIP`; no `git worktree remove`/`prune`/`checkout`/`pull` executed; filesystem + worktree list unchanged; exit 0 | Pending |
| 2 | `PR_STATE=MERGED` removed | Fixture cj-feat worktree, clean tree, fake pr-check returns `PR_CHECK=ok PR_EXISTS=1 PR_STATE=MERGED`; run without `--dry-run` | Worktree REMOVED; appears in `REMOVED=` report; exit 0 | Pending |
| 3 | `PR_STATE=CLOSED` removed | Same as #2 but fake pr-check returns `PR_STATE=CLOSED` | Worktree REMOVED (v1 treats CLOSED == MERGED); exit 0 | Pending |
| 4 | `PR_STATE=OPEN` skipped | Fake pr-check returns `PR_CHECK=ok PR_EXISTS=1 PR_STATE=OPEN` | Worktree SKIPPED with reason "still in review"; not removed; exit 0 | Pending |
| 5 | `PR_EXISTS=0` skipped | Fake pr-check returns `PR_CHECK=ok PR_EXISTS=0` (no PR — in-flight drain sibling) | Worktree SKIPPED with reason "no PR"; not removed; exit 0 | Pending |
| 6 | `PR_CHECK=skipped` (gh offline) skipped | Fake pr-check returns `PR_CHECK=skipped` (gh offline/unauth) | Worktree SKIPPED with reason "can't prove landed"; not removed; exit 0 | Pending |
| 7 | Current worktree never removed | `_CURRENT` == a cj-* fixture worktree whose fake PR is MERGED | That worktree SKIPPED with reason "current"; never removed even though PR is MERGED; exit 0 | Pending |
| 8 | Locked skipped | Fixture cj-* worktree marked `locked` in `git worktree list --porcelain`, fake PR MERGED | Worktree SKIPPED with reason "locked"; not removed; exit 0 | Pending |
| 9 | Dirty skipped | Fixture cj-* worktree with non-empty `git -C <path> status --porcelain`, fake PR MERGED | Worktree SKIPPED with reason "dirty"; not removed; exit 0 | Pending |
| 10 | Non-cj worktree untouched | Fixture worktree on a `claude/*` (or `chore/`/`feat/`) branch, fake PR MERGED | Worktree NOT enumerated for removal (branch fails `^cj-(feat|def|todo)-`); untouched; exit 0 | Pending |
| 11 | Prune invoked | Any successful (non-dry-run) sweep | `git worktree prune` is invoked; `PRUNED=ok` in report | Pending |
| 12 | Root-refresh guarded on dirty root | `git -C "$_ROOT" status --porcelain` non-empty | Root refresh SKIPPED (`ROOT_REFRESH=skipped`); no `checkout main`/`pull` on root; exit 0. Inverse: clean root ⇒ `checkout main` + `pull --ff-only` run, `ROOT_REFRESH=ok` | Pending |
| 13 | cwd-not-a-repo ⇒ `RESULT=skipped` | Run from a non-git directory | Emits `RESULT=skipped`; exits 0; no git mutation attempted | Pending |
| 14 | `cj-goal-common.sh --phase cleanup` never emits `failed` | Run `cj-goal-common.sh --phase cleanup --mode feature` with the helper reachable AND with the helper unreachable | Reachable → `PHASE=cleanup` + `PHASE_RESULT=ok`; unreachable → `PHASE_RESULT=skipped`; NEVER `PHASE_RESULT=failed`; exit 0 in both | Pending |
| 15 | `--phase cleanup` registered (usage + validation) | Run `cj-goal-common.sh --phase cleanup --mode defect`; also run with a bogus `--mode todo` | `cleanup` accepted by the `--phase` validation `case`; usage string lists `cleanup`; `--mode todo` still rejected at usage-check (cleanup passes `--caller "$MODE"`, never introduces `--mode todo`) | Pending |
| 16 | Terminal wiring present at all four seams (static grep) | grep `skills/CJ_goal_feature/pipeline.md` Step 6, `skills/CJ_goal_defect/pipeline.md` after Step 10, `skills/CJ_goal_todo_fix/SKILL.md` agent-layer terminal, `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` per-iteration terminal | feature/defect invoke `cj-goal-common.sh --phase cleanup --mode <mode>`; todo single-mode + drain invoke `cj-worktree-cleanup.sh --caller todo` directly | Pending |
| 17 | New test registered in `scripts/test.sh` | grep `scripts/test.sh` for a `cj-worktree-cleanup.test.sh` runner block | Hand-written runner block present (discovery is NOT glob-based); `scripts/test.sh` runs the new test | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `tests/cj-worktree-cleanup.test.sh` passes standalone
- [ ] `tests/cj-worktree-cleanup.test.sh` passes inside `scripts/test.sh` (registered runner block fires)
- [ ] `scripts/validate.sh` stays green (no new validate.sh check added; no `zzz-test-scaffold` fixture edit needed)
- [ ] `scripts/test.sh` full suite green
- [ ] Manual: a real `--dry-run` invocation in the workbench lists the stale cj-* worktrees and removes nothing
- [ ] Manual: after a defect/todo run lands its PR, its worktree + other MERGED/CLOSED cj-* worktrees are gone, root is on `main` pulled current, and the run still reports green

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, this repo) | cj-feat-20260603-230308-47489 | Pending |
