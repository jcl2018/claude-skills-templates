---
type: test-plan
parent: T000049
title: "Add a validate.sh check (plus a parallel scripts/test.sh integration assertion) that fails when README.md is out of sync with scripts/generate-readme.sh output, so a stale catalog-derived README cannot pass validation — Test Plan"
date: 2026-06-13
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Adds a hard regression check (`scripts/validate.sh` **Check 25**) that diffs the
on-disk `README.md` against the live stdout of `scripts/generate-readme.sh`
(README is fully generated from `skills-catalog.json`). A drifted/stale
catalog-derived README now fails validation instead of passing silently. A
parallel `scripts/test.sh` integration assertion (inside the manual-skill-creation
cycle, Step 3d) proves the check both PASSes on the in-sync tree and FIRES on a
drifted README. The new check is registered as the `validate-check-25` units row
in `spec/test-spec-custom.md` (required — validate.sh Check 24's reverse-coverage
sweep makes any unregistered `=== Check N:` banner a hard failure).

Files modified:
- `scripts/validate.sh` — new Check 25 (read-only; generator writes only to stdout).
- `scripts/test.sh` — Step 3d positive + negative assertions for Check 25.
- `spec/test-spec-custom.md` — `validate-check-25` units row + the numbered-checks prose index.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Check 25 PASSes on the in-sync live tree | `bash scripts/validate.sh` on the current tree | `PASS: README.md matches generate-readme.sh output`; RESULT: PASS (0 errors / 0 warnings) | Done |
| 2 | Check 25 FIRES on a drifted README | `echo x >> README.md && bash scripts/validate.sh` | `ERROR: README.md is stale vs generate-readme.sh — run: bash scripts/generate-readme.sh > README.md`; non-zero exit | Done |
| 3 | Check 25 returns green after restore | `git checkout README.md && bash scripts/validate.sh` | RESULT: PASS again | Done |
| 4 | Check is read-only (does not mutate README) | Run Check 25, then `git diff --quiet README.md` | README unmodified by the check | Done |
| 5 | Check 24 reverse-coverage stays clean | `bash scripts/validate.sh` after registering the units row | Check 24 `FINDINGS=0`; no `validate-check-25` reverse finding | Done |
| 6 | Parallel test.sh assertion (Step 3d) is green in isolation | Run the Step 3d block against the live tree | All three Check-25 assertions OK; ERRORS=0 | Done |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] `bash scripts/validate.sh` → RESULT: PASS (0 errors / 0 warnings) with Check 25 active
- [x] Proved Check 25 fires: drifted README → README-stale ERROR + non-zero exit; restored green
- [x] `shellcheck --norc scripts/validate.sh scripts/test.sh` → no NEW findings (only pre-existing SC1091 on the `lib.sh` source line)
- [x] Check 24 coverage cross-check clean (`FINDINGS=0`) after registering the `validate-check-25` units row
- [x] New test.sh Step 3d assertions run green in isolation (ERRORS=0; README left unmodified)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | cj-task-readme-sync-check | Pass — validate.sh green (Check 25 active), check fires on drift, shellcheck no new findings |
