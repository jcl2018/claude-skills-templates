---
type: test-spec
parent: {USER_STORY_ID}
feature: {FEATURE_ID}
title: "{User Story Name} — Test Specification"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
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
| S1 | {tag} | AC-{n} | {description} | {what passes/fails} | `{command}` |

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
| E1 | {tag} | AC-{n} | {description} | {step-by-step what user does} | {what user sees} | {pass/fail criteria} |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| {untested scenario} | {reason} | {what could go wrong} |
