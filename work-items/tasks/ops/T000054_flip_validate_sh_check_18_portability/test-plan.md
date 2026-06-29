---
type: test-plan
parent: T000054
title: "Flip validate.sh Check 18 (portability audit) to strict-by-default globally by defaulting PORTABILITY_STRICT to 1 so every commit and CI run hard-fails on a portability finding — Test Plan"
date: 2026-06-28
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Flip `validate.sh` Check 18 (portability audit) from advisory-globally to
**strict-by-default**: `${PORTABILITY_STRICT:-0}` → `${PORTABILITY_STRICT:-1}`, so
a portability finding ERRORs on every commit (pre-commit hook), CI, and manual
run; `PORTABILITY_STRICT=0` is the WIP escape hatch. Files: `scripts/validate.sh`
(the flip + banner/message/comment prose + the Check 21 stale cross-ref),
`spec/test-spec-custom.md` (validate-check-18 `disposition: advisory` →
`hard-fail`), `scripts/test.sh` (S000083g wording + new S000083g2 strict-default
guard), and prose sync in `CLAUDE.md`, `docs/architecture.md`,
`skills-catalog.json` + `README.md` (regen) + `skills/CJ_portability-audit/{SKILL,USAGE}.md`,
plus the `TODOS.md` row strike.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Check 18 defaults strict | `grep -E 'PORTABILITY_STRICT:-1' scripts/validate.sh` | Match present in Check 18 (strict-by-default) | Pass |
| 2 | validate.sh green on the clean catalog | `bash scripts/validate.sh` | Check 18 banner reads "(strict)"; 0 errors / 0 warnings (catalog clean ⇒ strict still PASSes) | Pass |
| 3 | test-spec disposition updated + valid | `grep -A7 'id: validate-check-18' spec/test-spec-custom.md; bash scripts/test-spec.sh --validate` | `disposition: hard-fail`; `OK schema_version=1` | Pass |
| 4 | Parallel test.sh guard fires | `bash scripts/test.sh` (S000083g2) | S000083g2 green — validate.sh defaults PORTABILITY_STRICT to 1 | Pass |
| 5 | No work-item IDs leaked into human-docs | `bash scripts/validate.sh` (Check 19) | Check 19 PASS (README + docs carry no `T0000NN`) | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] `bash scripts/validate.sh` → 0 errors / 0 warnings (Check 18 strict, Check 19 clean)
- [x] `scripts/test-spec.sh --validate` + `--check-coverage` green
- [ ] `bash scripts/test.sh` full suite passes (incl. S000083g2)
- [ ] README regenerated + byte-matches generator (Check 25)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
