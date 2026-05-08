---
type: test-plan
parent: D000016
title: "test-deploy.sh stale doc-RCA.md template references — Test Plan"
date: 2026-05-08
author: chjiang
status: Draft
---

<!-- Defect-scoped test plan: regression cases for the specific bug, plus
     verification that the wire-into-CI portion of approach C closes the
     meta-bug. -->

## Scope

Two-part fix:
1. `scripts/test-deploy.sh` — replace 5+ references to `doc-RCA.md` (flat top-level path) with `doc-SKILL-DESIGN.md`. Affected tests: T2, T4, T5, T6, T7.
2. `scripts/test.sh` — add invocation of `scripts/test-deploy.sh` after the existing wrapper-grep pre-flight check. Propagate non-zero exit codes.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | test-deploy.sh runs clean end-to-end | `./scripts/test-deploy.sh` from repo root | Exit code 0; all test cases pass; T2/T4-T7 PASS lines visible in stdout | Pending |
| 2 | test.sh now invokes test-deploy.sh | `./scripts/test.sh` and search output for distinct test-deploy.sh phase header | Output shows test-deploy.sh phase between existing phases; exit code 0 | Pending |
| 3 | test.sh fails when test-deploy.sh fails | Temporarily revert one doc-RCA.md → doc-SKILL-DESIGN.md edit (e.g., line 717), run `./scripts/test.sh` | test.sh exit code is non-zero AND failing test name (T2 or similar) is visible in output. Restore the edit before merging. | Pending |
| 4 | wrapper-grep pre-flight still works | Run `./scripts/test.sh`; verify the existing structural assertion that test-deploy.sh defines `jq()` wrapper still PASSes alongside the new runtime invocation | Both the wrapper-grep PASS and the runtime test-deploy.sh PASS appear in output | Pending |
| 5 | No regression in other test.sh phases | Run `./scripts/test.sh` end-to-end; confirm all previously-passing phases still pass | All prior phases PASS; only addition is the new test-deploy.sh phase | Pending |

## Verification Steps

- [ ] Local run: `./scripts/test-deploy.sh` returns 0 (all test cases pass)
- [ ] Local run: `./scripts/test.sh` returns 0 with test-deploy.sh phase visible
- [ ] Negative test (#3 above): temporarily revert one re-point edit, confirm test.sh fails loudly
- [ ] CI run: GitHub Actions `validate` workflow on the PR exits 0 AND the action log shows test-deploy.sh phase output
- [ ] Stability: run `./scripts/test-deploy.sh` 3 times in succession on the fix branch; all 3 runs pass without flakiness in any test (not just T2/T4-T7)
- [ ] Audit: `grep -E 'templates/[a-zA-Z0-9_-]+\.md' scripts/test-deploy.sh | grep -v personal-workflow | grep -v company-workflow` returns no unexpected matches (no other stale flat-path references hiding)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.3.0 (Darwin), bash 5.x, jq + git | feat branch local | Pending |
| GitHub Actions ubuntu-latest (CI) | feat branch PR | Pending |
