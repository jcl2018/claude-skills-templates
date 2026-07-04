---
type: test-spec
parent: S000130
feature: F000080
title: "Delete agentic cron wrappers + re-layer the 3 tests to local-hook + prose sweep — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated/deterministic regression. E2E = manual verification run
     after implementing and before /ship. AC column maps each row to a SPEC #. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | The two cron wrappers are gone; only the deterministic nightly remains | Deleting the agentic cron wrappers succeeded | `test ! -e .github/workflows/eval-nightly.yml && test ! -e .github/workflows/audit-nightly.yml && ls .github/workflows/*nightly*.yml` |
| S2 | core | AC-2 | The 3 tests are declared at `local-hook` and the 2 orphan units are gone | The test-contract re-layer is valid + no orphan-unit finding | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --check-coverage && bash scripts/test-spec.sh --list-categories --layer local-hook` |
| S3 | usability | AC-3 | Declared doc paths equal on-disk paths; no CI-nightly orphan under docs/tests | The doc-spec + index + moved docs agree with disk | `bash scripts/doc-spec.sh --check-on-disk` |
| S4 | resilience | AC-5 | The category structural contract holds after the moves | The re-layered rows + moved docs produce no structural finding | `bash scripts/test-spec.sh --check-structure` (expect findings=0) |
| S5 | resilience | AC-4, AC-5 | The full repo gate is green (Checks 15/15a/16/24/26/27/28 + shellcheck) | The whole change is landable | `./scripts/validate.sh && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Each row is one user-visible scenario. AC column maps to a SPEC AC. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | observability | AC-4 | No doc claims a nightly-CI eval/audit that no longer runs | `grep -rn "nightly in CI" CLAUDE.md docs/ spec/ skills/` and grep for "eval-nightly.yml" / "audit-nightly.yml" nightly framing across the same tree | Only historical CHANGELOG lines and this work-item's own artifacts mention the old nightly framing; no live doc/spec/skill asserts a nightly-CI audit/eval | PASS if every remaining reference is historical (CHANGELOG) or descriptive of the on-demand/local path; FAIL if any live doc still claims the deleted nightly job runs |
| E2 | usability | AC-3 | A maintainer opening a re-layered test doc gets truthful how-to-run guidance | Open `docs/tests/workflow/local-hook/doc-sync.md` (and the two eval docs); read `## How to run`; confirm the `docs/tests/index.md` link resolves to the local-hook path | Each `## How to run` describes an on-demand/local run (`bash scripts/audit-nightly.sh` / `bash scripts/eval.sh …` + the `/CJ_test_run` invocation) with no "runs nightly in CI" framing; the INDEX link opens the moved doc | PASS if the doc reads truthfully and the INDEX link resolves; FAIL on a dead link or a stale "nightly" claim |
| E3 | resilience | AC-5 | The workflow-coverage gate (Check 28) still passes after re-layering | Run `bash scripts/test-spec.sh --check-workflow-coverage` and confirm the orchestrator/behavior counts | Check 28 passes: orchestrators=4, behaviors=4; the `level: workflow` behaviors + eval `behavior_coverage` rows are untouched by the category re-layer | PASS if the gate is green with 4/4; FAIL if any workflow behavior lost its coverage |

<!-- No dedicated E2E test skill for this story; the checks above are run manually. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The on-demand agentic runs themselves (`scripts/eval.sh`, `scripts/audit-nightly.sh` actually spending tokens and producing findings) | They are `tier: paid` / model-spending; the design's interim safety net is a MANUAL hand-run before merge, not an automated smoke test | A latent break in the runners' agentic behavior would only surface on a manual local run, not in CI (the deliberate "deterministic-only CI" trade-off) |
| Semantic prose-freshness drift after this PR merges | The nightly auto-catch is deliberately removed; the interim net is the operator hand-running `/CJ_doc_audit` + `/CJ_test_audit` | New prose drift lands without an automatic catch until an agentic nightly is re-enabled (accepted "for now") |
| That `test-audit-nightly` (`tests/audit-nightly.test.sh`) still passes anchored on the retained script | Covered transitively by `./scripts/test.sh` (S5) rather than an explicit row | If the script were accidentally deleted alongside the workflow, `test.sh` (S5) would catch it — so the risk is low |
