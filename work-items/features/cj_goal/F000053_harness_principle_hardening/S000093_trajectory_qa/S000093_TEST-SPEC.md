---
type: test-spec
parent: S000093
feature: F000053
title: "Trajectory QA — QA that cannot lie about correctness — Test Specification"
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
| S1 | observability | AC-2 | Receipt-shape assertion: a QA run on a fixture work-item writes an execution receipt with all `receipts.qa` keys (`completed_at`, `test_rows_run`, `ac_ids_covered`, `ac_ids_uncovered`, `diff_audit.changed_files_without_tests`, `ready_for_ship`) | Receipt is emitted and structurally complete; a missing key fails | `bash scripts/test.sh` (zzz-test-scaffold receipt block) |
| S2 | core | AC-1 | Date-only marker no longer short-circuits: a `[qa-pass]` dated-today from an earlier-than-HEAD commit does NOT satisfy the `qa.md` Step 3 NO-OP; QA proceeds to re-validate | The dangerous date-only branch is closed (HEAD-match still short-circuits) | `bash scripts/test.sh` (qa.md Step 3 NO-OP block) |
| S3 | resilience | AC-3, AC-4 | Artifacts-only flagged RED: a fixture work-item with artifacts present but NO execution receipt yields a RED verdict, not a pass | Fail-closed verdict — no receipt ⇒ RED (covers the artifacts-only / never-executed case) | `bash scripts/test.sh` (fail-closed verdict block) |
| S4 | core | AC-5 | Second-run-no-duplicate-gate-transition: running QA twice on the same SHA (reusing the Step 6.5 run-start marker) produces exactly one Phase-2 gate transition and no journal thrash | Write-idempotency of re-execution | `bash scripts/test.sh` (idempotent-writes block) |

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
| E1 | core | AC-1, AC-3 | Same-SHA resume with a mutated untracked file re-validates and goes RED on a missing receipt | On a user-story whose two QA-owned gates are checked and that has a same-day earlier-commit `[qa-pass]`, delete/withhold the execution receipt, mutate an untracked/fixture file, then resume QA at the same SHA | QA does NOT short-circuit on the date-only marker; it re-validates (re-runs smoke + looks for the receipt) and reads RED because the receipt is missing | PASS = QA re-runs and verdict is RED with a "missing/incomplete receipt" reason; FAIL = QA short-circuits GREEN off the date-only marker without re-validating |
| E2 | core | AC-1, AC-2 | Same-SHA resume with a complete HEAD-matching receipt re-validates cheaply WITHOUT re-paying the E2E budget | On the same work-item, provide a complete `receipts.qa` receipt whose SHA matches HEAD and whose ACs all have passing rows, then resume QA at the same SHA | QA re-validates (re-runs smoke + reads the receipt), reads GREEN, and does NOT re-dispatch the ~5-min E2E subagent (receipt vouches for HEAD) | PASS = GREEN, smoke re-ran, E2E subagent NOT re-dispatched; FAIL = E2E re-runs unconditionally OR a stale receipt is accepted |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The `CJ_goal_feature/pipeline.md` `LAST_PHASE ∈ {qa,ship}` resume re-dispatch is exercised only via the E1/E2 manual E2E, not a standalone smoke row | The phase-skip lives in orchestrator prose (`pipeline.md`) driven by a live cj_goal resume, not a unit-callable shell function; a deterministic smoke fixture for the full orchestrator resume is disproportionate | A regression in the orchestrator's re-dispatch (vs the qa.md marker) could slip past CI smoke; mitigated by the E1/E2 manual E2E walking the real resume |
| Cross-machine / stale-clock receipt timestamps | `completed_at` is recorded by the running host; clock skew across machines is out of scope for a workbench-only (macOS + Git-Bash) story | A receipt written on a skewed clock could mis-order against journal entries; low risk given single-operator workbench scope |
| Receipt-home decision (generalize `.cj-goal-feature/${branch}.state` vs sibling file) is not independently tested | The home is an implementation choice resolved in Phase 2; tests assert the receipt SHAPE + behavior, not its on-disk path | If S1 and S3 diverge on the home, the shared-schema invariant is the guard; a path mismatch surfaces in S1/S3 integration, not here |
