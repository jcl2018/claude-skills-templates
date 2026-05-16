---
type: test-spec
parent: S000052
feature: F000023
title: "Invert mirror and collapse validator — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | validate.sh PASSes after Error check 10 is removed | The rewritten validator still exits 0 on the canonical repo state | `./scripts/validate.sh; echo "exit=$?"` (expect exit=0) |
| S2 | core | AC-2 | MIRROR_SPECS keyword no longer appears in validate.sh | The byte-identity machinery is genuinely removed, not just bypassed | `grep -n MIRROR_SPECS scripts/validate.sh \| wc -l` (expect 0) |
| S3 | core | AC-2, AC-3 | Every previously-mirrored path appears in EXPECTED_BUNDLE_FILES | Coverage hasn't shrunk — the 7 mirror paths plus F000015 bundle-only files are enumerated | `awk '/EXPECTED_BUNDLE_FILES=/,/\)/' scripts/validate.sh \| grep -cE 'work-copilot/(templates\|WORKFLOW\|reference\|philosophy\|examples\|fixtures\|copilot-artifact-manifests\|prompts\|domain)'` (expect ≥1 hit per family) |
| S4 | resilience | AC-1, AC-4 | validate.sh PASSes on the canonical state from a fresh checkout | The change is reproducible — not dependent on uncommitted local state | `git stash && ./scripts/validate.sh; echo "exit=$?"; git stash pop` (expect exit=0 in the middle) |

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | Deleting a previously-mirrored file is caught by the expanded check | (1) `mv work-copilot/WORKFLOW.md /tmp/wf.md`<br>(2) `./scripts/validate.sh`<br>(3) `mv /tmp/wf.md work-copilot/WORKFLOW.md` | Step 2 fails (non-zero exit) and prints an error naming `work-copilot/WORKFLOW.md` as missing. Step 3 restores the baseline. | PASS if validate.sh names the specific missing path in stderr/stdout and exits non-zero; FAIL if it passes silently. |
| E2 | core | AC-3 | Deleting a F000015 bundle-only file is still caught | (1) Pick any file under `work-copilot/prompts/` (e.g., `qa.prompt.md`); `mv` it to /tmp<br>(2) `./scripts/validate.sh`<br>(3) Restore the file | Step 2 fails with a missing-file message naming the deleted path. Step 3 restores baseline; validate.sh PASSes again. | PASS if validate.sh identifies the deleted bundle-only file; FAIL if F000015 coverage was dropped during the array refactor. |
| E3 | resilience | AC-4 | Pre-edit byte-identity baseline run | (1) On a clean checkout (`git status` shows no changes to validate.sh), run `./scripts/validate.sh` BEFORE starting the rewrite<br>(2) Confirm exit=0 (PASS)<br>(3) Only then proceed with the rewrite | A clean PASS confirms there is no pre-existing drift between `deprecated/CJ_company-workflow/` and `work-copilot/`. If RED here, halt — investigate drift before removing the cross-check. | PASS = exit 0 and no MIRROR_SPECS drift output. FAIL = halt the story, fix the drift first. |
| E4 | usability | AC-5 | Section legibility — flat vs enumerator choice is consistent | Open `scripts/validate.sh`, scroll to Error check 10b | The EXPECTED_BUNDLE_FILES section is either a flat array OR uses an enumerator helper. No half-and-half. Comments name what's covered. | Subjective PASS if a future maintainer can find a specific file in <30 seconds; FAIL if the section is structurally inconsistent. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior of `./scripts/test.sh` after Error check 10 is removed | `test.sh` coupling to `deprecated/CJ_company-workflow/` is S000053's scope; test.sh may go red after S000052 lands and stay red until S000053 ships. Smoke run on test.sh is intentionally deferred. | Brief window where `test.sh` is red. Mitigated by S000053 being the immediate followup. Acceptable for an internal-workbench retirement. |
| Behavior of `./scripts/copilot-deploy.py doctor` against an actual target repo | Requires a target-repo fixture; folded into S000053's full-test-suite acceptance criterion. S000052 only changes `validate.sh`, which copilot-deploy.py does not invoke. | The deploy path is unaffected by this story's diff — risk is structurally minimal. |
| Verifying that Error check 10b's expansion compiles correctly under bash 3.2 (macOS default) vs bash 5+ | The implementer runs on macOS by default; the workbench's bash version is the test surface. Cross-version validation deferred. | If a future contributor with a different bash version trips this, validate.sh PASS on their machine catches it. Acceptable. |
