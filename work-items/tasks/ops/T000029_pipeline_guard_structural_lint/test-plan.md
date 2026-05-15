---
type: test-plan
parent: T000029
title: "T000029 pipeline guard structural lint — Test Plan"
date: 2026-05-14
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

T000029 adds an executable invariant to `scripts/validate.sh` — a new "Error check 12: pipeline.md Step 6 guard present" — and retires two PR #115 v2 follow-up TODOs in `TODOS.md`. The check greps `skills/CJ_personal-pipeline/pipeline.md` for the literal token `[ -x ./scripts/validate.sh ]` (the load-bearing doc-as-code guard at pipeline.md:528 that the pipeline orchestrator-model reads at runtime to enforce the T000028 / Approach D workbench-coupling boundary).

Files modified:
- `scripts/validate.sh` — additive (new Error check 12 block; uses existing `ERRORS` counter)
- `TODOS.md` — two strikethroughs + two `**RETIRED:**` lines

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | validate.sh exits 0 on T000029 branch (guard token present) | Run `./scripts/validate.sh` from repo root on the T000029 branch | Exit code 0; output includes `=== Check 12: pipeline.md Step 6 guard present ===` and `PASS: pipeline.md contains the validate.sh presence guard`; Validation Summary shows 0 errors | Pass |
| 2 | Manual regression — guard removal trips check 12 | (1) Temporarily delete the literal `[ -x ./scripts/validate.sh ]` token from `skills/CJ_personal-pipeline/pipeline.md` Step 6 item 2. (2) Run `./scripts/validate.sh`. (3) Restore the token before commit. | Exit code != 0; output includes `FAIL: pipeline.md missing '[ -x ./scripts/validate.sh ]' guard token`; Validation Summary shows ERRORS > 0 | Pass |
| 3 | Validation Summary clean after check 12 added | Run `./scripts/validate.sh` on T000029 branch | Validation Summary final block shows "0 errors" (all 12 checks pass; no regressions from the additive new check on the other 11) | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (validate.sh is bash; no compile step)
- [ ] L1 regression suite passes (other 11 Error checks still green)
- [ ] Manual reproduction of guard-removal regression confirms check 12 actually fires (Smoke 2)
- [ ] Pipeline.md is NOT modified by T000029 (the lint is the only enforcement surface; pipeline.md text stays as-is per design)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS / feat/T000029-pipeline-guard-structural-lint | local | Pass |
