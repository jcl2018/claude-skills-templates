---
type: test-spec
parent: S000021
feature: F000012
title: "Per-type implement/qa pipeline branching — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke = automated regression in test suite. E2E = manual user-scenario walkthrough.
     Soft cap: 5 rows per tier. AC column maps to SPEC story numbers. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Defect fixture: scaffold + implement + qa runs end-to-end without "Wrong type" error | New defect path is wired through both skills | manual: `/scaffold-work-item <doc> --type defect`, then `/implement-from-spec <fixture-dir>`, then `/qa-work-item <fixture-dir>`; observe success |
| S2 | resilience | AC-4 | User-story regression: re-run on existing S000020 (or fresh user-story fixture) produces identical journal/output to v1.10.0 | No regression on the today-path | manual: `/implement-from-spec work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/S000020_implement_engine_and_hook` (idempotent NO-OP); diff journal entries with pre-merge state |
| S3 | core | AC-3 | Malformed frontmatter (missing `type:` field) produces explicit error and exits without writing | Type-detection error path | manual: scaffold a fixture, hand-edit `_TRACKER.md` to remove `type:`, run skill, observe error |
| S4 | core | AC-5 | SKILL.md error tables reflect new error vocabulary (no "Wrong type" rows) | Documentation matches code | `! grep -qE "Wrong type" skills/implement-from-spec/SKILL.md skills/qa-work-item/SKILL.md` |
| S5 | resilience | AC-6 | Re-run on completed defect work-item is NO-OP (idempotent) | Idempotency carries per-type | manual: complete a defect fixture; re-run `/implement-from-spec`; observe "INFO: already implemented" |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-3 | User scaffolds a defect, implements it, QAs it, ships it through the F000010 pipeline | 1. `/scaffold-work-item <design-doc> --type defect` (use sibling S000022's design context); 2. `/implement-from-spec <D000xxx-dir>`; 3. `/qa-work-item <D000xxx-dir>`; 4. `/ship`; 5. observe gates and journal | Each pipeline phase succeeds; journal has [impl-pass] + [qa-pass] entries; tracker Phase 1/2 gates green; PR created | PASS if user-visible flow matches the user-story flow; FAIL on any "Wrong type" error or hard-fail |
| E2 | resilience | AC-4 | Existing user-story work-item still flows end-to-end identically to v1.10.0 | 1. Pick an existing un-shipped user-story (or scaffold one); 2. Run `/implement-from-spec <S-dir>`; 3. Run `/qa-work-item <S-dir>`; 4. Compare journal output, AUQ prompts, and tracker state vs. v1.10.0 expectation | No new prompts, no missing prompts, journal entries identical in shape | PASS if no observable behavior change for user-story type |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Task type happy path | No real task work-items exist yet to test against | Low — code path ships and structure mirrors defect; first task post-merge is the de facto E2E |
| Feature-level `/implement-from-spec <feature-dir>` AUQ-pick-child preserved | Existing path; not directly modified | Low — preserved by code path inspection during implementation |
| Defect QA test-plan with non-trivial test logic (multi-step assertions) | v1 treats all rows as smoke-equivalent; complex E2E for defects is out of scope | Medium — if a future defect needs E2E-like verification, may surface as a real-world miss |
