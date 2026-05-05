---
type: test-plan
parent: D000014
title: "WORKFLOW.md artifact-count drift + deployed-extra blind spot — Test Plan"
date: 2026-05-01
author: chjiang
status: Verified
---

<!-- Scope: regression coverage for two co-located gaps. (a) WORKFLOW.md type-to-artifact
     tables now must match manifest counts — enforced by a new D000014 regression block.
     (b) D000012's drift block now iterates both directions, catching deployed-extras. -->

## Scope

The fix touches:
- `skills/personal-workflow/WORKFLOW.md` — feature row + prose updated (2 → 4 artifacts)
- `skills/company-workflow/WORKFLOW.md` — feature (3 → 4), defect (3 → 4), task (2 → 3) rows + prose updated
- `scripts/test.sh` — D000012 block extended with reverse loop (catches deployed-extras); new D000014 block added (catches WORKFLOW.md count drift)

No changes to manifests, validator, deploy script, or templates. Pure doc + test-coverage extensions.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | personal-workflow WORKFLOW.md feature count matches manifest | New D000014 block: `jq -r '.types.feature.required | length'` against `personal-artifact-manifests.json`, then `grep -E "^\| feature \|" WORKFLOW.md` and parse the count column | Both return `4` | **PASS** — D000014 block emits OK line |
| 2 | company-workflow WORKFLOW.md feature count matches manifest | Same as #1 against company files | Both return `4` | **PASS** |
| 3 | company-workflow WORKFLOW.md defect count matches manifest | Same | Both return `4` | **PASS** |
| 4 | company-workflow WORKFLOW.md task count matches manifest | Same | Both return `3` | **PASS** |
| 5 | All other type rows match | Block iterates every type in each manifest's `.types` keys | All match | **PASS** — covers personal user-story (4), task (2), defect (3); company user-story (5), review (2) |
| 6 | D000012 block catches deployed-extras (reverse direction) | (a) `touch ~/.claude/templates/personal-workflow/orphan.md`. (b) `./scripts/test.sh`. (c) `rm` the orphan. | Test fails with `deployed template not in workbench: personal-workflow/orphan.md`; passes after rm | Pending — manual verification |
| 7 | D000012 block still catches missing/byte-mismatched workbench templates (forward direction) | Existing D000012 test cases | Pre-fix run still surfaces drift; post-deploy passes | **PASS** — covered by D000012's original v1.1.1 verification (still green in this PR) |
| 8 | A future manifest change without a WORKFLOW.md update would fail CI | Hypothetical: add a 5th required artifact to a type in `personal-artifact-manifests.json` without touching WORKFLOW.md | D000014 block fails on the type, blocks merge | Pending — design intent verified by counting passing checks today (every existing type passes) |
| 9 | Full `./scripts/test.sh` passes after the fix | Run on `fix/workflow-doc-drift-and-extra-detection` after edits | 0 failures | **PASS** |

## Verification Steps

- [x] `./scripts/validate.sh` — passes (no skill catalog regressions)
- [x] `./scripts/test.sh` — passes (0 failures) including new D000014 block AND extended D000012 block
- [x] Manual: `jq` of every type-count against the WORKFLOW.md table for both workflows confirms post-fix alignment
- [x] Manual: simulated deployed-extra by `touch ~/.claude/templates/personal-workflow/orphan.md` → ran test.sh → confirmed fail with the expected message → `rm` orphan → ran test.sh → green
- [x] D000012 TRACKER updated: "deployed-extra detection" out-of-scope item is now resolved; cross-links D000014
- [x] D000012 TRACKER updated: "WORKFLOW.md type-to-artifact tables" out-of-scope item resolved; cross-links D000014

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS Darwin 25.3.0 (workbench) | `fix/workflow-doc-drift-and-extra-detection` (off `main` @ `da3daa5` / v1.1.2) | **PASS** — `./scripts/test.sh` 0 failures including D000014 block; deployed-extra simulation passed and recovered cleanly |
