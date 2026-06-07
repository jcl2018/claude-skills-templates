---
type: test-spec
parent: S000095
feature: F000053
title: "Within-phase receipts — continue from receipts, not transcript — Test Specification"
version: 1
status: Draft
date: 2026-06-06
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. For a single fix or task, use test-plan.md instead.

     Two tiers, distinguished by who edits them and when they run:
     - Smoke = automated regression. Lives in CI. You write it once and
       never touch it again.
     - E2E   = manual user-scenario verification. You sit down and run it
       after implementing and before /ship.

     Soft cap: 5 rows per tier. Validator emits [INFO] advisory if exceeded;
     not a violation. Exceed only when justified — the cap is a forcing
     function to pick the tests that prove the story works, not the tests
     that demonstrate completeness. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     Pick the structural checks that catch real regressions, not all checks
     that could exist. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | After simulating the office-hours boundary, a receipt file exists under `.cj-goal-feature/` and was written atomically (a `mktemp` temp file + `mv`, never an in-place partial write) | A receipt is produced at the boundary via the existing atomic write path | `bash scripts/test.sh` (within-phase-receipts fixture block) |
| S2 | integration | AC-4 | The written receipt's shape matches the shared S000093 receipt schema (required keys present, flat key=value) | The receipt reuses the one shared schema, not a divergent second format | `bash scripts/test.sh` (receipt-schema assertion) |
| S3 | core | AC-3 | Only the office-hours boundary writes a receipt; no generic per-phase compaction hook is wired for other inline steps | Scope stays at the known long inline phases (no generic framework) | `grep`-based scope assertion in `scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section
     below for semantics — applies to E2E rows only; smoke rows do not support
     post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion.

     Post-ship rows: if a row is structurally only verifiable AFTER the PR
     merges to main (e.g., `gh workflow run` against a CI workflow that
     doesn't exist on remote refs until merge), add the literal token
     `post-ship` to the row's Tag column (e.g., Tag = `core post-ship`
     or just `post-ship`). /CJ_qa-work-item Step 4 will filter these rows
     out of the E2E subagent dispatch and record a [qa-e2e-deferred] journal
     entry naming the row + its AC instead of forcing a pretend-green
     adjudication. Verification of post-ship rows happens after merge (via
     manual `gh workflow run` or via post-merge tooling). -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | Post-office-hours step sources the digest from the receipt | Run `/CJ_goal_feature "<topic>"` through the office-hours boundary; inspect that the design-summary digest step reads `$RECEIPT_PATH` and the digest text matches the receipt's content (not a fresh regeneration from context) | The design-summary digest is sourced from the receipt file; `$RECEIPT_PATH` is read by the post-phase step | PASS if digest is byte-traceable to the receipt and the step reads `$RECEIPT_PATH`; FAIL if regenerated from transcript |
| E2 | resilience | AC-1, AC-2 | A resume reads the receipt | After the office-hours phase completes and a receipt is written, resume the run (re-invoke `/CJ_goal_feature`); confirm the orchestrator continues from `$RECEIPT_PATH` rather than depending on the (now non-resident) transcript | The resumed run reads the receipt and proceeds; no dependence on the raw transcript | PASS if resume sources the digest from the receipt with the validate-before-skip contract intact; FAIL if it requires the transcript |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Actual orchestrator-window token reduction is not measured | The harness cannot introspect the live context window; we assert the receipt is written + read, not that the transcript is evicted | A receipt could be written and read while the transcript still lingers in context; the win is structural (continue-from-receipt), not a measured token drop |
| Other long inline phases beyond office-hours | Story is scoped to office-hours only (AC3); no other inline phase is in scope this story | A future long inline phase would not get a receipt until explicitly added |
| Shared-schema co-evolution with S000093 if S000093 changes its schema after this lands | Cross-story schema drift is governed by the "one schema" decision, not re-asserted per build | If S000093 later mutates the schema, this story's receipt could drift; caught by S2 only if both are re-run |
| Concurrent same-branch runs racing the receipt write | Single-run assumption; atomic mktemp+mv guards a single writer, not multi-writer contention | A pathological parallel same-branch run could observe a half-updated receipt chain (mitigated by atomic mv) |
