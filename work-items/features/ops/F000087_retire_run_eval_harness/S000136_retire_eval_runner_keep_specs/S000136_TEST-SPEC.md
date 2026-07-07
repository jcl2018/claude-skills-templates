---
type: test-spec
parent: S000136
feature: F000087
title: "Retire the eval runner, keep the specs + Check 28 gate — Test Specification"
version: 1
status: Draft
date: 2026-07-06
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Smoke = automated regression (CI). E2E = manual
     user-scenario verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | No dangling `eval.sh` reference after delete | `scripts/eval.sh` is gone and a repo-wide sweep finds no reference in scripts/tests/workflows/spec engines (only work-item docs, if any) | `test ! -f scripts/eval.sh && ! grep -rn "eval\.sh" scripts tests .github/workflows spec` |
| S2 | core | AC-2, AC-3 | Coverage cross-check green — `suite-eval` re-anchored, `run-eval` gone | `test-spec.sh --check-coverage` finds `suite-eval`'s forward anchor live in the `tests/eval/` spec; no unit declares the deleted `scripts/eval.sh`; `eval` stays in `run-test-sh` `covers:`; `findings=0` | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --check-coverage` |
| S3 | core | AC-4 | Workflow coverage intact + topic contract clean after category-row removal | `--check-workflow-coverage` reports 4/4 orchestrators wired; `--check-topic-contract` exits 0 with only advisory notes (`cj-goal-eval` no longer labeled) | `bash scripts/test-spec.sh --check-workflow-coverage && bash scripts/test-spec.sh --check-topic-contract` |
| S4 | usability | AC-5 | Eval prompts honest + non-leaking, anchors preserved | No `tests/eval/<skill>/<case>/prompt.md` states its expected output (the `dry_run_preview` leak removed); every `level: workflow` behavior's `prompt.md` anchor still matches live under `--check-workflow-coverage` | `! grep -rn "dry_run_preview" tests/eval/*/*/prompt.md && bash scripts/test-spec.sh --check-workflow-coverage` |
| S5 | resilience | AC-6 | Full deterministic gate green after all edits + catalog regen | Checks 15/15a/17/19 (docs), Check 24 (coverage), Check 26/27 (catalogs fresh), Check 28 (workflow), Check 30 (topic contract), `--check-structure` (no empty required subfolder); plus the full suite + shellcheck | `bash scripts/validate.sh && bash scripts/test-spec.sh --check-structure && bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | integration | AC-2, AC-4 | Audit operator confirms the eval family is not orphaned after retiring the runner | Run `/CJ_test_audit` against the workbench repo and read the Stage-1 report + coverage cross-check | The `eval` family stays declared (`run-test-sh` `covers:` + `suite-eval` `family: eval`); NO orphaned eval family finding; the removed `goal-*-eval` `categories:` rows raise no orphan; Check 28 shows 4/4 orchestrators | PASS if the Stage-1 report shows no orphaned eval family and no dangling `suite-eval` anchor; FAIL if the audit flags an orphan, a dangling anchor, or a broken workflow-coverage row |
| E2 | usability | AC-5 | Maintainer reads a de-leaked eval prompt to run an in-session verification | Open a de-leaked `tests/eval/<skill>/<case>/prompt.md` (e.g. `CJ_goal_feature/dry-run-plan/prompt.md`) and drive the scenario in-session against the fixture | The prompt states the scenario + fixture and lets Claude reach a verdict WITHOUT the answer being pre-stated; the `behavior_coverage` anchor line is still present verbatim | PASS if the prompt is a runnable, non-leaking spec and the anchor string is intact; FAIL if the expected output is still stated or an anchor was removed |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The eval cases actually PASSING when driven in-session (the replacement verification) | Verification is now an in-session Claude ask, not an automated runner — there is no deterministic per-case pass/fail to assert in CI (that was exactly the paid harness being retired) | The in-session verification could be skipped by an operator; mitigated by the specs staying durable + Check 28 keeping the anchors honest on every push |
| Portability's agentic test (`portability-version-agentic`) behavior | Out of scope — a different topic; the un-enroll prerequisite is moot (F000086 demoted the agentic point to advisory) | None new — this story does not touch portability |
| CHANGELOG.md history that mentions `cj-goal-eval` / the eval rows | CHANGELOG is a historical record — past releases genuinely shipped `scripts/eval.sh`, so its entries are not rewritten (the new release entry is added by `/ship`) | Correct-as-history, not drift. NOTE: CLAUDE.md's concrete dangling refs (the `eval.sh` scripts-reference row + the `cj-goal-eval` labeled-topic count) WERE fixed inline in this story — not deferred — along with `docs/philosophy.md` / `docs/reference.md` / `docs/tests/test-hierarchy.md` |
| Phase 2 `categories: workflow` row policy (defect/todo_fix) | Deliberate deferral — the roadmap Phase 2 ripple is a separate follow-up, flagged in TODOS | The roadmap's first-class-workflow-rows intent is regressed for feature+task; accepted, tracked |
