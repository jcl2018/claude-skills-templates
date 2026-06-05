---
type: test-plan
parent: D000030
title: "/CJ_document-release can't resolve its config helper outside the workbench repo — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

The fix changes `skills/CJ_document-release/SKILL.md` (4 executable helper call
sites + 3 prose references now resolve the helper repo-local-first then via the
manifest `.source`), `skills/CJ_document-release/USAGE.md` (behavior note +
`last-updated` bump), and `tests/cj-document-release.test.sh` (3 new
assertions). No change to the helper script itself, the catalog, or `test.sh`
wiring.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | No bare-path helper invocation remains | `grep -cF 'bash scripts/cj-document-release-config.sh' skills/CJ_document-release/SKILL.md` | `0` (asserted by `tests/cj-document-release.test.sh` #25) | Pass |
| 2 | Resolved form + `.source` reach-back wired | `grep -cF 'bash "$_CFG_HELPER"' SKILL.md` ≥ 4 AND `.skills-templates.json` referenced | count 7; reach-back present (`tests/cj-document-release.test.sh` #26) | Pass |
| 3 | Real helper is cwd-toplevel portable (original bug scenario) | From a temp `git init` repo with a valid `cj-document-release.json` and NO `scripts/` dir, run `bash "$REPO_ROOT/scripts/cj-document-release-config.sh" --validate` | exit 0, `OK schema_version=1` against the TEMP repo's config (`tests/cj-document-release.test.sh` #27) | Pass |

## Verification Steps

- [x] `bash tests/cj-document-release.test.sh` → `PASS` rc=0 (all 27 assertions, incl. #25–#27)
- [x] `bash scripts/validate.sh` → `Errors: 0  Warnings: 0  RESULT: PASS` (Check 14 USAGE-drift NOT flagged; Check 18 portability FINDINGS=0)
- [x] `grep` confirms 0 bare-path / 7 resolved-form invocations in SKILL.md
- [x] Original bug scenario (helper invoked from a repo with no `scripts/`) now resolves + parses that repo's config

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin 25.5.0), bash 3.2 | branch cj-def-20260604-225342-6085 | Pass |
