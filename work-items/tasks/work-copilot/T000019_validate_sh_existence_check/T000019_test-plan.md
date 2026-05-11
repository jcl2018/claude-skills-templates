---
type: test-plan
parent: T000019
title: "scripts/validate.sh existence check — Test Plan"
date: 2026-05-11
author: chjiang
status: Draft
---

## Scope

Adds an existence check to `scripts/validate.sh` that asserts work-copilot/-only files are present:
- `work-copilot/prompts/*.prompt.md` (gated to currently-shipped subset)
- `work-copilot/domain/*.template.md` (gated to currently-shipped subset)

Distinct from the existing `MIRROR_SPECS` Error check 10 (byte-identity vs upstream). Catches a different drift mode: file deleted/never-shipped, not file content drift.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Current state PASS | Run `./scripts/validate.sh`. `work-copilot/prompts/{validate,qa}.prompt.md` are on disk; other prompts not yet shipped. | Validation exits 0; new existence check PASSes for the gated subset (validate + qa only). | Pending |
| 2 | Synthetic deletion FAIL | `mv work-copilot/prompts/qa.prompt.md /tmp/qa.bak`. Run `./scripts/validate.sh`. Restore: `mv /tmp/qa.bak work-copilot/prompts/qa.prompt.md`. | Validation exits non-zero with `FAIL: work-copilot/prompts/qa.prompt.md is required but not present`. Restoring brings it back to PASS. | Pending |
| 3 | Existing MIRROR_SPECS still works | Don't change MIRROR_SPECS-protected paths. Run `./scripts/validate.sh`. | All existing MIRROR_SPECS PASS/FAIL behavior preserved; the new existence check doesn't shadow or duplicate Error check 10. | Pending |
| 4 | Future-proofed for unshipped prompts | `work-copilot/prompts/implement.prompt.md` does not yet exist on disk. Run `./scripts/validate.sh`. | Validation exits 0 — the check is gated to the currently-shipped subset only. (When S000031 ships, the gating list expands and this test row is rewritten.) | Pending |

## Verification Steps

- [ ] Local build succeeds (bash 3.2+ on macOS; bash 4.x on Linux)
- [ ] `./scripts/test.sh` still passes end-to-end (the existing test harness)
- [ ] Synthetic-delete test (case 2) fires red, restore brings green
- [ ] Re-running S000030 QA (`/CJ_qa-work-item work-items/features/work-copilot/F000015_work_copilot_pipeline/S000030_wc_qa`) now passes smoke S5 (AC-1)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS bash 3.2 | claude/zealous-antonelli-5f8036 | Pending |
| Linux bash 5 (CI) | claude/zealous-antonelli-5f8036 | Pending |
