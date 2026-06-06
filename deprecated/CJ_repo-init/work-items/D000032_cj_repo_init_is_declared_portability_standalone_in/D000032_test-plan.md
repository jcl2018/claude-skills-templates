---
type: test-plan
parent: D000032
title: "CJ_repo-init genuinely standalone + audit is_exec precision — Test Plan"
date: 2026-06-05
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

Bundle CJ_repo-init's engine (genuinely standalone) + fix the portability audit's
`is_exec` precision so seed-data string literals in a bundled `.sh` aren't
false-flagged. Files: `skills/CJ_repo-init/{SKILL.md,USAGE.md,scripts/cj-repo-init.sh}`,
`skills-catalog.json`, `scripts/cj-portability-audit.sh`,
`tests/{cj-repo-init.test.sh,..}`, `scripts/test.sh`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | CJ_repo-init genuinely standalone | `bash scripts/cj-portability-audit.sh --no-adjudication` | `CJ_repo-init … portable`, `FINDINGS=0` (no adjudication) | Pass |
| 2 | No other skill regressed | same command, full table | no `findings:` line for any skill | Pass |
| 3 | Audit `is_exec` precision (seed literal not flagged) | `scripts/test.sh` S000083i (bundled `.sh` writing `"CLAUDE.md"` as a seed literal) | NOT a finding | Pass |
| 4 | Real detection intact | `scripts/test.sh` S000083a–h | unchanged (a still flags a real root-helper exec; b/c precision still correct) | Pass |
| 5 | Engine still works from the bundled path | `bash tests/cj-repo-init.test.sh` (ENGINE repointed) | all assertions pass | Pass |

## Verification Steps

- [x] `bash scripts/cj-portability-audit.sh --no-adjudication` → CJ_repo-init `portable`, `FINDINGS=0`
- [x] `bash scripts/cj-portability-audit.sh` (default) → `FINDINGS=0`
- [x] `bash scripts/test.sh` → `Failures: 0` (incl. S000083a–i + `cj-repo-init.test.sh`)
- [x] `bash scripts/validate.sh` → 0 errors / 0 warnings (Check 18 portability advisory clean)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin 25.5.0), bash 3.2 | branch cj-def-20260605-003802-77237 | Pass |
