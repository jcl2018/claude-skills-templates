---
type: test-plan
parent: T000014_migrate_company_workflow_paths
title: "Migrate company-workflow paths — Test Plan"
date: 2026-05-02
author: chjiang
status: Draft
---

<!-- Scope: ONE task. T000014 is the verification gate for F000006's relocation work.
     Cases are concrete and reproducible against a fresh SKILLS_DEPLOY_TARGET.
     For broader story-scope coverage, see S000013_TEST-SPEC.md. -->

## Scope

T000014 verifies that F000006's relocation does not regress F000005's deprecation lifecycle and that the work-copilot byte-mirror invariant continues to hold byte-identity at the new source paths. Files exercised: `scripts/skills-deploy` (install/doctor), `scripts/validate.sh` (full run + Error check 10), `scripts/test.sh` (full run), `skills-catalog.json` (path inspection), `~/.claude/skills/company-workflow/` (destination dir post-install), and the install manifest's path field.

No code changes happen in this task — verification only. If any case fails, the fix lands in S000013 and the cases re-run.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `validate.sh` Error check 10 — mirror invariant byte-identity | `./scripts/validate.sh` from repo root | Exit 0; Error check 10 reports PASS for all 7 MIRROR_SPECS entries (templates flat, WORKFLOW.md single, reference flat, philosophy flat, examples flat, fixtures recursive, company-artifact-manifests.json manifest-shape); no FAIL or unexpected WARN | Pass |
| 2 | `test.sh` full run | `./scripts/test.sh` from repo root | Exit 0; "Failures: 0" line in output; no test was skipped due to missing path; the COMPANY_PATH constants resolve correctly throughout | Pass |
| 3 | Clean-target install (default mode) skips company-workflow | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install` 3. `ls $SKILLS_DEPLOY_TARGET/skills/` 4. Inspect stdout for the WARN line | personal-workflow and system-health installed at `$SKILLS_DEPLOY_TARGET/skills/`; no company-workflow dir; stdout contains exactly one line: `WARN: skipping deprecated skill: company-workflow (use --include-deprecated to install)` | Pass |
| 4 | Clean-target install with --include-deprecated installs from new path | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install --include-deprecated` 3. `ls $SKILLS_DEPLOY_TARGET/skills/company-workflow/SKILL.md` 4. `jq '.skills["company-workflow"].path' $SKILLS_DEPLOY_TARGET/manifest.json` | company-workflow installed at destination; manifest path field = `"deprecated/company-workflow/SKILL.md"` (NOT `"skills/company-workflow/SKILL.md"`); install summary reports company-workflow as installed | Pass |
| 5 | doctor reports company-workflow under INFO not WARN | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install` (default — does not install company-workflow) 3. `scripts/skills-deploy doctor` | doctor output contains an INFO line for company-workflow (annotation: "deprecated — not installed by default"); zero WARN lines for company-workflow | Pass |
| 6 | Idempotent re-install (no-op if already installed) | 1. `export SKILLS_DEPLOY_TARGET=$(mktemp -d)` 2. `scripts/skills-deploy install --include-deprecated` 3. `scripts/skills-deploy install --include-deprecated` (run again) | Second invocation is a no-op; exit 0; no errors; no duplicate manifest entries; output indicates company-workflow already installed | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] Local build succeeds (Mac primary)
- [x] L1 regression suite passes — `./scripts/validate.sh && ./scripts/test.sh` exit 0
- [x] Manual reproduction of original concern: open `skills/` and confirm no `company-workflow/` entry visible
- [x] Manual inspection of `deprecated/company-workflow/templates/` confirms 14 template files relocated
- [x] `git log --follow deprecated/company-workflow/SKILL.md` traces back to pre-move history (blame preserved)
- [x] `grep -rn 'skills/company-workflow' scripts/ skills-catalog.json` returns 0 unexpected matches (only intentional refs in comments or removal-checks)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0, zsh, feat/relocate-deprecated-skills branch | local | Pass |
| GitHub Actions Mac runner (CI) | branch HEAD | Pass |
