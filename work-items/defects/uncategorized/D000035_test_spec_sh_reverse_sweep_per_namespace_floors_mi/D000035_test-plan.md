---
type: test-plan
parent: D000035
title: "test-spec.sh reverse-sweep per-namespace floors misfire in non-workbench consumer repos — Test Plan"
date: 2026-06-15
author: CJ_goal_defect
status: Draft
---

## Scope

Surface-existence-gate the reverse-sweep floor block in `_run_coverage()`
(`scripts/test-spec.sh`). Regression coverage added in `tests/test-spec.test.sh`
(section 8, cases a/b/c).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Consumer surface (no shell validate/test-files/hooks) | Fixture: units against a vitest `*.test.ts` + a workflow; no shell surfaces. `--check-coverage` | exit 0, `OK coverage`, NO `FINDING: floor` lines | Pass |
| 2 | Present-but-zero-token namespace still fires | Full-surface fixture, `setup-hooks.sh` present but with no `if install_hook` lines. `--check-coverage` | exit 1, `FINDING: floor — ... ZERO live tokens in the 'hooks' namespace` | Pass |
| 3 | Rules-only registry unchanged | Fixture with no `units:` rows. `--check-coverage` | exit 0, `coverage cross-check inactive`, no floor findings | Pass |
| 4 | Workbench own coverage (no regression) | `bash scripts/test-spec.sh --check-coverage` in the workbench | `OK coverage rows=69 reverse_tokens=49 findings=0`, exit 0 | Pass |
| 5 | Reserved-path collision (family-row gating) | Consumer declares only a `ci` row but has a husky `scripts/setup-hooks.sh` + own `scripts/validate.sh` (non-workbench grammar). `--check-coverage` | exit 0, `OK coverage`, NO floor findings (no rows in those families) | Pass |

## Verification Steps

- [x] `bash tests/test-spec.test.sh` — all cases green incl. new (a)/(b)/(c)
- [x] `bash scripts/test-spec.sh --check-coverage` — workbench OK, findings=0 (no regression)
- [x] `bash scripts/test-spec.sh --validate` — `OK schema_version=1`
- [x] `diff <(test-spec.sh --seed) spec/test-spec.md` — SEED BYTE-IDENTICAL: PASS
- [x] `bash scripts/validate.sh` — Check 24 PASS, overall PASS
- [x] POSIX portability: `dash scripts/test-spec.sh --check-coverage` on the consumer fixture → exit 0
- [ ] Post-land: redeploy so `~/.claude/_cj-shared/scripts/test-spec.sh` is refreshed (`skills-deploy install` / `post-land-sync.sh`)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (bash) | branch `claude/dazzling-jemison-feb6e8` | Pass |
| dash (POSIX) | same | Pass |
