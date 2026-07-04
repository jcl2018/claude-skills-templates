---
type: test-plan
parent: D000039
title: "cj-id-claim.sh reap regex misses feature-style {ID}_TRACKER.md — Test Plan"
date: 2026-07-04
author: Charlie Jiang (via /CJ_goal_defect)
status: Complete
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

Broadens the two work-item-tracker matchers in `scripts/cj-id-claim.sh`
(`id_on_origin` regex + `id_has_workitem_dir` find glob) so they match the
slug-less FEATURE tracker `{ID}_TRACKER.md` in addition to the slug-bearing
`{ID}_{slug}_TRACKER.md`. Regression coverage added in `tests/cj-id-claim.test.sh`
(Cases 8a + 8b); `scripts/test.sh` summary string updated.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 8a | Merged slug-less feature claim IS reaped on origin | Push `F000048_TRACKER.md` to origin/main, pre-create stale `cj-id-claims/F000048`, run `cj-id-claim.sh --prefix F --floor 47` | Stale claim reaped → mint re-hands `F000048` (not F000049) | Pass |
| 8b | Materialized slug-less feature ID advances reuse | With a local `F000090_TRACKER.md` present, same-branch reuse | Advances to `F000091` instead of re-handing `F000090` | Pass |
| 3 / 6.0 | Slug-bearing shape unchanged (existing) | Existing `_demo_` slug cases | Match as before (no regression) | Pass |

## Verification Steps

- [x] `bash scripts/validate.sh` green (29 checks, Errors: 0, Warnings: 0)
- [x] `bash tests/cj-id-claim.test.sh` — full suite `RESULT: PASS, Failures: 0`
- [x] Before/after proof: Case 8a FAILS on reverted-to-broken source, PASSES after fix
- [x] Adversarial over-match check: `F000053` does not match `F000530`
- [ ] Full `scripts/test.sh` — NOT run here (known-red on this Windows host for unrelated jq-CRLF reasons; Linux CI covers it on the PR)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| Windows 10 / Git Bash (GNU sed 4.9) | branch `claude/compassionate-shirley-75499a` | Pass (validate.sh + targeted test) |
| Ubuntu CI (validate.yml) | on the PR | Pending (runs on push) |
