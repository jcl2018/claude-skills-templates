---
type: test-plan
parent: T000053
title: "Fix the awk -v multi-line PR-body splice — Test Plan"
date: 2026-06-22
author: Charlie
status: Draft
---

## Scope

Replace the BSD-awk-fragile `awk -v v="$_INSERT"` PR-body splice idiom (which
wipes the PR body on macOS when `$_INSERT` is multi-line) with temp-file
composition + `gh pr edit --body-file` + a post-edit line-count sanity assert,
in the three cj_goal pipeline docs that carry the executable block
(`skills/CJ_goal_feature/pipeline.md`, `skills/CJ_goal_defect/pipeline.md`,
`skills/CJ_goal_task/pipeline.md`). Also reconcile the `/CJ_goal_task`
registered-doc scratch-path (T000044). Markdown skill surfaces only — no scripts
change.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | No `awk -v` with a multi-line payload remains | `grep -rn 'awk -v v="$_INSERT"' skills/` | Zero matches | Pending |
| 2 | Each replacement bash block is shellcheck-clean | Extract each fenced `bash` splice block, run `shellcheck` (no-rc) | No errors/warnings | Pending |
| 3 | New idiom uses `--body-file` not `--body "$_NEW_BODY"` | `grep -n 'gh pr edit' skills/CJ_goal_{feature,defect,task}/pipeline.md` | Uses `--body-file` | Pending |
| 4 | Post-edit line-count sanity assert present | grep for the floor/re-fetch guard in each block | Guard present in all 3 | Pending |
| 5 | Task registered-doc read path matches producer | `grep -n 'registered-doc-verdicts.md' skills/CJ_goal_task/pipeline.md` | Reads `.cj-goal-feature/registered-doc-verdicts.md` | Pending |
| 6 | Repo health green | `./scripts/validate.sh` | Exit 0, all checks pass | Pending |

## Verification Steps

- [ ] `grep -rn 'awk -v v=' skills/` returns no PR-body splice hit
- [ ] Each extracted bash block passes `shellcheck`
- [ ] `./scripts/validate.sh` passes (doc-spec, test-spec, catalog, USAGE freshness)
- [ ] `./scripts/test.sh` relevant lanes green (pipeline doc surfaces unchanged structurally)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (BSD awk) | todo/T000053-awk-pr-body-splice | Pending |
