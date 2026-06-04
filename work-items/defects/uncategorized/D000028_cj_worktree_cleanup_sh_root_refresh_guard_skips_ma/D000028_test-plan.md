---
type: test-plan
parent: D000028
title: "cj-worktree-cleanup.sh root-refresh guard — Test Plan"
date: 2026-06-04
author: chjiang
status: Final
---

## Scope

One fix: the root-refresh guard in `scripts/cj-worktree-cleanup.sh` now uses
`git status --porcelain --untracked-files=no` (skips the `checkout main && pull`
only on a dirty *tracked* tree). Regression coverage lives in
`tests/cj-worktree-cleanup.test.sh` (already registered in `scripts/test.sh`).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Untracked-only root refreshes (the bug) | Sandbox root with only an untracked file + a bare-origin upstream; run the cleanup root-refresh | `ROOT_REFRESH=ok` (refresh proceeds) | Pass |
| 2 | Dirty *tracked* root still skips | Sandbox root with a modified committed file; run the cleanup root-refresh | `ROOT_REFRESH=skipped` + "dirty tracked tree" note | Pass |
| 3 | Per-worktree dirty rail unchanged | A `cj-*` worktree with untracked scratch + MERGED PR | worktree SKIPPED (`reason=dirty`) — untracked still counts here | Pass |
| 4 | Negative control | Restore the bare-`--porcelain` guard | Case 12b FAILs (test discriminates the bug) | Pass |

These map to `tests/cj-worktree-cleanup.test.sh` Case 12 (dirty tracked root →
skipped) and Case 12b (untracked-only root → ok), plus the pre-existing dirty
per-worktree rail case.

## Verification Steps

- [x] `bash -n scripts/cj-worktree-cleanup.sh` clean; `shellcheck` clean
- [x] `bash tests/cj-worktree-cleanup.test.sh` → 18 assertions, 0 failures
- [x] `./scripts/test.sh` → full suite PASS (includes this test)
- [x] `./scripts/validate.sh` → 0 errors / 0 warnings, PASS
- [x] Negative control confirms the new case fails against the buggy guard
