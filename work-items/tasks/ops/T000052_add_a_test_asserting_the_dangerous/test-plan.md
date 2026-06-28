---
type: test-plan
parent: T000052
title: "Add a test asserting the dangerous multi-line 'awk -v' PR-body splice idiom never reappears in the four CJ_goal_* pipeline.md files — Test Plan"
date: 2026-06-28
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Adds a new guard test `tests/cj-goal-pr-body-splice-guard.test.sh` (wired into
`scripts/test.sh`, registered as a `units:` row in `spec/test-spec-custom.md`)
that asserts the dangerous multi-line `awk -v <var>="$payload"` PR-body splice
idiom — the one T000053/PR #279 removed — cannot creep back into any of the four
`CJ_goal_*` `pipeline.md` files. Files modified:
`tests/cj-goal-pr-body-splice-guard.test.sh` (new), `scripts/test.sh` (runner
block), `spec/test-spec-custom.md` (units row).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Guard passes on the clean baseline | `bash tests/cj-goal-pr-body-splice-guard.test.sh` | Exit 0; all 4 pipeline.md report "no dangerous 'awk -v' payload" | Pass |
| 2 | Guard fails when the wiper idiom is injected | Inject `awk -v v="$_INSERT"` into a temp copy of a pipeline.md and run the guard against it | Exit non-zero; the offending file+line is named | Pass |
| 3 | Test is wired into the suite | `grep -F cj-goal-pr-body-splice-guard.test.sh scripts/test.sh` | A runner block invokes the test | Pass |
| 4 | Unit is registered in the test contract | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --check-coverage` | Validates; the new unit anchors live; no reverse-sweep orphan | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] Guard passes on the clean baseline (exit 0)
- [x] Guard fails on an injected dangerous idiom (exit 1, names file+line)
- [x] `scripts/test-spec.sh --validate` + `--check-coverage` green (unit registered + anchored)
- [ ] `scripts/test.sh` full suite passes
- [ ] `scripts/validate.sh` green

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
