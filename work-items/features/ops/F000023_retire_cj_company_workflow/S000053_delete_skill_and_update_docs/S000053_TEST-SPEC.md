---
type: test-spec
parent: S000053
feature: F000023
title: "Delete skill and update docs — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | `deprecated/CJ_company-workflow/` is gone AND catalog entry is gone | The two filesystem-level deletes both landed | `[ ! -d deprecated/CJ_company-workflow ] && ! jq -e '.[] \| select(.name == "CJ_company-workflow")' skills-catalog.json` (expect exit 0) |
| S2 | core | AC-3, AC-8 | No remaining runtime path references to `deprecated/CJ_company-workflow/` | The cleanup is thorough; grep returns nothing in .sh/.py/.json | `grep -rn 'deprecated/CJ_company-workflow' --include='*.sh' --include='*.py' --include='*.json' . \| wc -l` (expect 0) |
| S3 | core | AC-1..7 | Full local test suite PASSes after all edits | The entire post-retirement world is internally consistent | `./scripts/validate.sh && ./scripts/test.sh; echo "exit=$?"` (expect exit=0) |
| S4 | core | AC-5 | `template-registry.json` no longer references CJ_company-workflow | Stale registry entry is gone | `[ ! -f template-registry.json ] \|\| ! grep -q 'CJ_company-workflow' template-registry.json` (expect exit 0) |
| S5 | core | AC-4 | CLAUDE.md and README.md no longer describe `work-copilot/` as byte-mirror | Docs match reality after the inversion | `! grep -niE 'byte-?mirror' CLAUDE.md README.md` (expect exit 0) |

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-6 | `copilot-deploy.py doctor` PASS against a real target repo | (1) Identify a known Copilot target repo (e.g., `~/Documents/projects/<some-consumer>/`)<br>(2) Run `./scripts/copilot-deploy.py doctor <target_repo>`<br>(3) Inspect output | Step 2 exits 0; output shows the bundle deployment is consistent with `work-copilot/`; no errors about missing source files. | PASS if doctor reports clean; FAIL on any error referencing `deprecated/CJ_company-workflow/` or a missing source file. |
| E2 | resilience | AC-7 | `skills-deploy install --include-deprecated` graceful no-op | (1) Run `./scripts/skills-deploy install --include-deprecated`<br>(2) Inspect output | Step 1 exits 0; output is a benign message (no error trace; no "missing entry" failure). | PASS if exit 0 with benign output; FAIL if the script errors on the missing catalog entry. |
| E3 | core | AC-3 | `test.sh` PASSes after the prune | (1) Confirm S000052 has merged and is reflected locally (`git pull --ff-only`)<br>(2) After all S000053 edits, run `./scripts/test.sh`<br>(3) Inspect output | Step 2 exits 0; no assertion failures referencing `deprecated/CJ_company-workflow/`. | PASS if exit 0; FAIL if any assertion fails or any zombie block ran against deleted paths. |
| E4 | observability | AC-8 | Final grep audit | Run `grep -rn 'CJ_company-workflow' .` | Output contains only documentation mentions (CHANGELOG.md, work-items/, prior /office-hours design doc reference) — no runtime path references in scripts/, skills/, or top-level config JSON. | Reviewer manually inspects each hit; PASS if every hit is a doc/comment, FAIL if any is a runtime path. |
| E5 | usability | AC-9 | Skill .md textual polish (optional) | Open `skills/CJ_personal-workflow/check.md`, `skills/CJ_implement-from-spec/implement.md`, `skills/CJ_personal-pipeline/pipeline.md`; spot-check the textual references to CJ_company-workflow | References are either updated to reflect the post-retirement world or explicitly retained as historical comparisons; no broken pointers. | Subjective PASS if reader is not confused; FAIL only on a broken cross-reference (e.g., link to a deleted file). This row is P1; failure is non-blocking. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior of Copilot consumers running an OLDER deployed bundle copy | Out of scope per parent feature non-goal ("No automated migration for already-deployed bundles"). Existing deployments are copies, not symlinks; they continue to work unchanged. | Risk is structural-zero — old bundles don't know about upstream changes. |
| Re-running an already-merged S000052 PR's tests against the post-S000053 main | Implicitly covered by S3 smoke. Re-running stale PR CI is not informative because S000052's validate.sh change is already baseline by the time S000053 lands. | Acceptable; CI-level regression coverage handles it. |
| Cross-bash-version compatibility of any `work-copilot/`-targeted ported assertions | Out of scope; the workbench's local bash is the test surface. | If a future contributor with a different bash version trips it, their `test.sh` PASS on their machine catches it. |
| Behavior of `skills-deploy install` (without `--include-deprecated`) — this case is the common path | Implicitly covered by S3 smoke (test.sh exercises it). E2 explicitly tests the less-common `--include-deprecated` flag. | Acceptable. |
