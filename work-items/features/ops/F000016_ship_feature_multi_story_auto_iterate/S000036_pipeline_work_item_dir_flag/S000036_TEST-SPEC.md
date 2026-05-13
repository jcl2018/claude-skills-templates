---
type: test-spec
parent: "S000036"
feature: "F000016"
title: "Add --work-item-dir flag to CJ_personal-pipeline — Test Specification"
version: 1
status: Draft
date: 2026-05-13
spec: S000036_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | pipeline.md contains `--work-item-dir` in arg parser | Flag is wired into the parser | `grep -c '\-\-work-item-dir' skills/CJ_personal-pipeline/pipeline.md` → ≥3 |
| S2 | core | AC-2 | pipeline.md contains Branch (e) text | Branch (e) is present in Step 2 | `grep -c 'Branch (e)' skills/CJ_personal-pipeline/pipeline.md` → ≥1 |
| S3 | core | AC-4 | SKILL.md usage section mentions --work-item-dir | Usage docs updated | `grep -c '\-\-work-item-dir' skills/CJ_personal-pipeline/SKILL.md` → ≥1 |
| S4 | core | AC-5 | skills-catalog.json CJ_personal-pipeline version is 0.2.0 | Version bumped | `jq -r '.[] | select(.name=="CJ_personal-pipeline") | .version' skills-catalog.json` → `0.2.0` |
| S5 | core | AC-1 | validate.sh passes after changes | No structural drift introduced | `./scripts/validate.sh 2>&1 | tail -5` → exits 0 |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,2,3,4 | Standalone --work-item-dir run on existing user-story dir | 1. Pick an existing user-story dir (e.g. work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/S000036_pipeline_work_item_dir_flag). 2. Invoke `/CJ_personal-pipeline --work-item-dir <path>`. 3. Observe: no "design doc not found" error, scaffold phase is skipped, pipeline reaches impl (Step 5). | Pipeline proceeds to impl phase without scaffold errors; journal entry "[orchestrator] --work-item-dir mode" appears in TRACKER.md | PASS: pipeline reaches Step 5 without scaffold-related errors. FAIL: any "design doc" or "SCAFFOLDED →" error fires. |
| E2 | core | AC-1 | Flags combine: --work-item-dir + --suppress-final-gate | Invoke `/CJ_personal-pipeline --work-item-dir <path> --suppress-final-gate`. Observe: both flags active, no AUQ at Step 8.5, telemetry written with work_item_dir_mode=true. | Pipeline completes or halts at a non-flag-related gate; no flag interaction errors. | PASS: no "unknown flag" or "design doc" errors. FAIL: either flag blocks the other. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Full impl+qa run via --work-item-dir | Covered by S000037 E2E (which exercises the full ship-feature multi-story loop) | Low — flag correctness verified in E1; full pipeline correctness is S000037's scope |
| Feature-type dir rejection | No explicit reject; Step 4 boundary check handles it | Low — boundary check fires for missing SPEC.md in user-story SPEC check; not a silent pass |
