---
type: test-plan
parent: D000025
title: "CJ_goal_investigate D-ID allocator/resolver shallow find -maxdepth 2 — Test Plan"
date: 2026-05-17
author: test
status: Final
---

## Scope

Fix to `skills/CJ_goal_investigate/pipeline.md`: removed `-maxdepth 2` from
all three `find "$DEFECTS_ROOT"` sites (Step 2 exact-D-ID resolver, Step 2
BASENAME_HITS fuzzy matcher, Step 7.4 highest-N allocator) and reworked the
allocator to take the max over the union of filesystem + `git log --all`
subject + `TODOS.md` D-IDs. Prose corrected in pipeline.md Step 2 and
`skills/CJ_goal_investigate/SKILL.md`. Regression coverage added in
`tests/cj-goal-investigate-did-allocator.test.sh`, wired into
`scripts/test.sh`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Highest-N allocator reaches a depth-3 nested-domain defect | Isolated fixture `a/b/D000099_*` (depth 3) + `x/D000050_*` (depth 2); run the fixed unbounded filesystem scan | Filesystem max N = 99 (not 50). Negative control: old `-maxdepth 2` scan returns 50 | Pass |
| 2 | Exact-D-ID resolver finds a nested-domain defect | `find "$DEFECTS_ROOT" -type d -name "D000099_*"` against the fixture | Resolves the single match at `.../a/b/D000099_nested_fixture` | Pass |
| 3 | BASENAME_HITS fuzzy matcher finds a nested-domain defect | Fuzzy fragment against the fixture with the `grep -E '/D[0-9]{6}_'` filter | Resolves `.../a/b/D000099_nested_fixture` | Pass |
| 4 | Allocator unions filesystem + git-log + TODOS.md D-IDs | Fixture fs max=99, isolated TODOS.md D000150, stubbed git subject D000200 | Union max = 200 → next D-ID = D000201 (a git/TODOS-only D-ID is never re-minted) | Pass |
| 5 | Regression guard: no `-maxdepth 2` reappears | `grep` pipeline.md for `find "$DEFECTS_ROOT" ... -maxdepth 2` | No match — fix intact | Pass |

## Verification Steps

- [x] `./scripts/validate.sh` — RESULT: PASS (0 errors, 0 warnings)
- [x] `bash tests/cj-goal-investigate-did-allocator.test.sh` — 5/5 assertions OK, RESULT: PASS
- [x] `./scripts/test.sh` — new test green inside the suite; only failure is the pre-existing, unrelated `scripts/test-deploy.sh` version-drift sandbox failure (verified to reproduce identically on a clean `git stash -u` tree — not introduced by this fix; flagged as a separate task)
- [x] Manual reproduction of original bug confirms fix — buggy `-maxdepth 2` scan misses 11 depth-3 `ops/*` defects; D000025 minted via the fixed union algorithm with no collision
- [x] POSIX/BSD portability — fix uses only macOS-safe `find`/`sed -E`/`git -C`/`grep -oE`

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (BSD find/sed), stock bash | branch `claude/friendly-cartwright-8d0f52` | Pass |
