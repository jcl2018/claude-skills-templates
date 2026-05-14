---
type: test-spec
parent: "S000037"
feature: "F000016"
title: "Rewrite ship-feature.md Branch (b) multi-story loop — Test Specification"
version: 1
status: Draft
date: 2026-05-13
spec: S000037_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | ship-feature.md Branch (b) does not contain "Per-child invocation needed" halt text | Old halt message is removed | `grep -c 'Per-child invocation needed' skills/CJ_run/run.md` → 0 |
| S2 | core | AC-1 | ship-feature.md Branch (b) contains loop pattern | Loop is present | `grep -c 'while IFS= read -r CHILD_DIR' skills/CJ_run/run.md` → ≥1 |
| S3 | integration | AC-5 | ship-feature.md contains CHILDREN_TOTAL | State extension present | `grep -c 'CHILDREN_TOTAL' skills/CJ_run/run.md` → ≥1 |
| S4 | observability | AC-6 | ship-feature.md contains multi_story_mode (not multi_story_scaffold_only) | Telemetry rename applied | `grep -c 'multi_story_mode' skills/CJ_run/run.md` → ≥1 && `grep -c 'multi_story_scaffold_only' skills/CJ_run/run.md` → 0 |
| S5 | core | AC-1 | validate.sh passes after changes | No structural drift | `./scripts/validate.sh 2>&1 | tail -5` → exits 0 |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,2,3 | Happy path: 2-child feature design doc ships 2 PRs | 1. Create a minimal 2-story feature design doc via /office-hours (or use a fixture). 2. Run `/CJ_ship-feature <doc>`. 3. Observe: /autoplan gate fires, loop runs for child 1 (branch created, scaffold copied, pipeline impl+qa, /ship AUQ fires, /land-and-deploy). 4. Loop runs for child 2 (same sequence). 5. Feature summary printed with 2 PR URLs. | Two separate PRs appear on GitHub, each with diff = one child's scaffold + impl+qa. Step 6.2 prints "Children shipped: 2/2". | PASS: 2 PRs merged to main, each isolated. FAIL: any manual intervention needed, or combined PR created. |
| E2 | core | AC-3 | Resume guard: re-run after partial failure | 1. Run E1 but inject a pipeline failure on child 2 (e.g. make the SPEC have a validation error). 2. Observe: child 1 ships, child 2 fails, loop halts. 3. Fix the validation error. 4. Re-run `/CJ_ship-feature <doc>`. 5. Observe: child 1 is skipped (already merged), child 2 ships. | Child 1 skip message appears. Child 2 proceeds and ships. Final state: "Children shipped: 2/2". | PASS: child 1 is skipped on re-run; child 2 ships successfully. FAIL: child 1 re-dispatched (duplicate PR or error). |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| N > 3 children | v1 surfaces AUQ for N > 3; test would require creating 4+ child stories | Low — AUQ gate prevents overflow; full auto-dispatch is v2 |
| git failure mid-loop (e.g. branch creation fails) | Requires injecting git errors in CI; complex setup | Low — git errors are surfaced to operator; recovery path is documented in S000037_DESIGN.md |
