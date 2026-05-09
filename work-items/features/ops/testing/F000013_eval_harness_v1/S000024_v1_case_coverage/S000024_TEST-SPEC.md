---
type: test-spec
parent: S000024
feature: F000013
title: "V1 eval case coverage — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-7 | All V1 cases PASS via the harness | Full suite is green on main; no case is broken before S000025's CI plumbing | `bash scripts/eval.sh` |
| S2 | core | AC-2 | S000022 case FAILS on a test branch with parser fix reverted | The case has actual regression-detection capability, not just paperwork | manual: `git checkout -b test/s000022-revert; git revert <S000022-fix-commit>; bash scripts/eval.sh personal-workflow check-step18-faithful-comma-split` (expect FAIL); cleanup via `git checkout main; git branch -D test/s000022-revert` |
| S3 | core | AC-3 | `check-passing-feature` case explicitly returns overall=PASS | Baseline case validates the skill's happy-path behavior | `bash scripts/eval.sh personal-workflow check-passing-feature` (expect PASS) |
| S4 | core | AC-4 | `check-missing-frontmatter` case explicitly returns overall=FAIL | Failure-detection case actually surfaces the failure | `bash scripts/eval.sh personal-workflow check-missing-frontmatter` (expect PASS — meaning the schema correctly asserts FAIL output) |
| S5 | resilience | AC-10 (P1) | Per-case observed cost ≤ $0.10 during authoring | Cases stay within `--max-budget-usd 0.15` headroom for nightly cost criterion | manual: log per-case cost during authoring (visible in `claude` CLI output); record in tracker journal if any case exceeds $0.10 |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. Each row should be one user-visible scenario. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2 | Maintainer verifies S000022 regression-detection on a test branch | 1. `git checkout -b test/s000022-revert`. 2. Identify the S000022 fix commit (squash from F000012 / S000022 PR). 3. `git revert <commit>`. 4. Run `bash scripts/eval.sh personal-workflow check-step18-faithful-comma-split`. 5. Observe FAIL with diagnostic output. 6. Cleanup branch. | Case fails with a useful diff between observed JSON and expected schema, identifying the comma-split miss. | Pass: case fails on revert AND passes on main. Fail: case passes on revert (regression undetected) OR fails on main (test fixture broken). |
| E2 | core | AC-7 | Maintainer runs full suite locally and confirms all green | 1. Clean checkout of main. 2. Run `bash scripts/eval.sh`. 3. Read summary. | All 6–10 cases report PASS; final summary shows `PASS: N FAIL: 0`. | Pass: all PASS. Fail: any FAIL or unexpected error. |
| E3 | usability | AC-8 | Future contributor reads S000022 case prompt.md and understands the coverage caveat | 1. Read `tests/eval/personal-workflow/check-step18-faithful-comma-split/prompt.md`. | Contributor understands: this case tests Claude's spec execution, not the parser logic in isolation; parser unit tests are V2 scope. | Pass: contributor can articulate the caveat unprompted. Fail: contributor assumes the case fully covers the parser logic. |
| E4 | core | AC-5, AC-6 | Maintainer adds a new case (4th personal-workflow OR system-health) and it integrates | 1. Author the new case directory. 2. Run `bash scripts/eval.sh <skill> <new-case-name>`. 3. Iterate prompt.md until PASS. | New case integrates without runner changes; `bash scripts/eval.sh` discovers it automatically. | Pass: case lands in V1 case count without modifying eval.sh. Fail: requires runner changes. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Parser logic in isolation (the comma-split function itself) | The parser is described in English prose inside `check.md`, not extracted into a callable bash function. Unit-testing requires extraction = V2 scope. | S000022 case catches Claude misreading the spec, but not a deliberately-buggy spec that Claude executes faithfully. |
| LLM run-to-run variance under fixed prompt | Single-shot evals don't catch flaky prompts; some cases may pass 9/10 runs and fail 1/10 randomly | First nightly CI run will surface flaky cases via failure-rate observation; iterate prompts to harden before V1 ship |
| Cross-skill interaction (e.g., personal-workflow check called from inside another skill) | V1 evals each skill in isolation | V2 cases for orchestrating skills (scaffold-work-item, implement-from-spec, qa-work-item) will exercise cross-skill calls naturally |
| Performance regressions (skill takes 2× as long after a refactor) | The harness asserts on output shape, not runtime | Runtime is observable in CI logs but not asserted; if regression-on-runtime becomes a concern, add a per-case `max_duration_s` field to the runner (V2) |
| `--max-budget-usd` enforcement edge cases (mid-output truncation) | Not testable without burning real tokens at the ceiling | First nightly CI surfaces it empirically; V1 success criterion accepts the risk |
