---
type: test-spec
parent: S000128
feature: F000078
title: "Two-axis model + engines + populated workflow category — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 acceptance
     criterion. Smoke = automated regression (CI). E2E = manual user-scenario
     verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-4 | `--validate` accepts the new enums + rejects out-of-enum + enforces `agentic⇒¬free` | The category `{workflow, regression, infra}` + layer `{CI-push, CI-nightly, pipeline-gate, local-hook}` + units-layer `{local-hook, CI-push, CI-nightly}` enums validate; a bad category/layer/mode value and a `mode: agentic` + `tier: free` row both error | `scripts/test-spec.sh --validate` (+ fixture-repo negative cases in `tests/test-spec.test.sh`) |
| S2 | core | AC-2, AC-3 | Seed byte-identity + no dangling unit layer | `spec/test-spec.md` is byte-identical to `test-spec.sh --seed` (3-way lockstep); every `units:` row's re-mapped `layer` exists in `layers[]` (no `layer: ci` remains) | `tests/test-spec.test.sh` seed-identity drill + `scripts/test-spec.sh --validate` |
| S3 | usability | AC-5 | `--list-categories` TSV + `--check-structure` 2-deep + advisory backfill | `--list-categories` emits `name category layer mode command tier doc purpose`; `--check-structure` validates 2-deep `tests/<category>/<layer>/`, exempts command-only rows from check (b), reports the 29 flat tests as advisory findings, exits 0 | `scripts/test-spec.sh --list-categories` + `--check-structure` (fixture drills in `tests/test-spec.test.sh`) |
| S4 | usability | AC-6 | `test-run.sh` selection + free-tier default | `--category workflow`, `--layer CI-nightly`, `--category`+`--layer` composition, and single-NAME each select correctly; a default run stays free-tier (no model spend) | `scripts/test-run.sh --dry-run --category workflow` / `--layer CI-nightly` (fixture drills in `tests/test-run.test.sh`) |
| S5 | resilience | AC-8, AC-10 | Owner gates green + portability | `validate.sh` Checks 24/26/27/28 pass (no doc orphans, fresh render, workflow coverage incl. reused `workflow-cj-goal-feature-runs`); `scripts/windows-smoke.sh` + shellcheck clean | `bash scripts/validate.sh` + `bash scripts/windows-smoke.sh` + `shellcheck scripts/test-spec.sh scripts/test-run.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Each row is one user-visible scenario. AC column maps to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-7, AC-9 | Workflow category ships populated with front-door docs | Inspect `tests/workflow/{CI-push,CI-nightly,local-hook}/`; open each of the 4 workflow tests' `docs/tests/<category>/<layer>/<name>.md`; check `docs/tests/index.md`; run `test-spec.sh --seed-docs` on a repo missing one doc | portability-smoke (CI-push), portability-deploy (CI-nightly), goal-feature-eval (CI-nightly), doc-sync (CI-nightly) each present as a file row or command row; each doc carries `## What it is` / `## How to run` / `## Explanation`; the index lists all four; `--seed-docs` creates a missing 2-deep stub and moves no script | PASS if all four exist with the three front-door sections, indexed, and `--seed-docs` seeds the correct nested path idempotently; FAIL if any is empty/missing or a stub lands at the wrong depth |
| E2 | usability | AC-5, AC-6 | Maintainer reads + runs the two-axis contract end to end | From a clean tree, run `test-spec.sh --list-categories`, then `test-spec.sh --check-structure`, then `test-run.sh --category workflow --dry-run` and `test-run.sh --layer CI-nightly --dry-run`, then a bare-NAME `test-run.sh <name> --dry-run` | The TSV reads clearly (kind + when + mode at a glance); `--check-structure` reports the 29 flat tests as advisory backfill (not a red gate); each selection prints the expected run plan; the default plan is free-tier | PASS if the maintainer can answer "what kind is this test and when does it fire?" from the TSV alone and every selection resolves to the right command set with no model spend on the default plan |
| E3 | resilience | AC-2, AC-3, AC-8 | Full staged greening of the atomic change | Run the build order's greening: `bash scripts/validate.sh`, then `bash scripts/test.sh` (incl. the seed-identity + render-freshness suites), then `shellcheck` | validate.sh green (Checks 24/26/27/28); test.sh green including the 3-way-lockstep seed-identity test and the Check-26 render-freshness suite; shellcheck clean; no mid-run red from a partial enum flip | PASS if all three pass in one clean tree with the full 83-row re-map + seed lockstep in place; FAIL on any red (esp. a seed drift or a stale rendered family doc) |

<!-- E2E test skill: none dedicated — the greening is driven via the existing
     validate.sh / test.sh / windows-smoke.sh runners and manual inspection. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The 29 flat `tests/*.test.sh` migration into `tests/regression/<layer>/` | Deferred backfill increment (out of scope this story) — Approach C rejected as one unreviewable diff | Regression tests stay flat + surface only as advisory `--check-structure` backfill findings until the backfill ships; no red gate today |
| The feature→workflow / defect→regression mapping-enforcement gate | Deferred; convention-only this increment | A feature could ship without a workflow test / a defect without a regression test until the gate is wired — caught only by human review |
| The category↔behavior link as a checked invariant | Deferred; convention-only (Check 28 enforces orchestrator↔`level:workflow`, NOT category↔behavior) | A `category=workflow` test could back a mis-leveled behavior without a deterministic catch until the cross-check is wired |
| The live CI cron/trigger ↔ `categories:` row `layer` consistency | `layer` on a category row is descriptive metadata; the real trigger stays in `.github/workflows/*.yml`, kept consistent by hand | A category row's `layer` could drift from the actual workflow schedule (documented drift risk, review fix #9) |
| doc-sync workflow test agentic backing (eval case vs `cj-audit-skills` unit) | The exact backing is an open question settled in implement | If mis-wired, the doc-sync workflow behavior could lack a real coverage-linked unit — verified during implement, not pre-decided here |
