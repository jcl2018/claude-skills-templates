---
type: test-spec
parent: S000124
feature: F000074
title: "Category-axis foundation — Test Specification"
version: 1
status: Draft
date: 2026-07-02
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion (AC-1..AC-5). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Category subcommands work AND pre-existing subcommands stay green | The new `test-spec.sh` category subcommands list/validate the `workflow`+`CI` categories while `--validate` / `--check-coverage` / `--render-docs --check` / `--check-workflow-coverage` still exit 0 unchanged | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --list-categories` |
| S2 | core | AC-1 | `--seed` emits the portable category contract | `test-spec.sh --seed` output contains the category axis and validates | `bash scripts/test-spec.sh --seed \| head` |
| S3 | usability | AC-2 | Five structural checks are reported, never crash | `--check-structure` prints checks (a–e) with `FINDING:` lines for gaps and exit code stays 0 (findings are the product) | `bash scripts/test-spec.sh --check-structure` |
| S4 | core | AC-3, AC-5 | Additive + idempotent | Re-running the audit seeds no duplicate doc stubs; existing units/behaviors/runners axes + `docs/tests/<family>.md` render are intact; no `*.test.sh` scripts moved | `bash scripts/test.sh` (full suite green) |
| S5 | usability | AC-4 | `/CJ_test_run` selection + dry-run | `test-run.sh --category workflow --dry-run` and a single-name `--dry-run` print the plan, execute nothing, and select the right tests; default tier is free | `bash scripts/test-run.sh --category workflow --dry-run` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-2, AC-3 | Standalone audit reports five checks + seeds stubs | Run `/CJ_test_audit` in this repo, then re-run it | First run reports checks (a–e) with any findings + seeds missing `docs/tests/<category>/<name>.md` stubs + index rows; the re-run is a NO-OP (no duplicate stubs); no scripts moved | Both runs succeed; report shows the five checks; re-run is idempotent; `git status` shows no moved test scripts |
| E2 | usability | AC-4 | Category + single-name run selection | Run `/CJ_test_run --category workflow`, `--category CI`, and `<single-test-name>` (e.g. `windows`) | Each invocation selects + runs the right tests reusing the `docs/tests/` name; the default run touches no paid model | The right tests run per category/name; no paid-model spend on the default; ledger/report reflects the selected runners |
| E3 | integration | AC-5 | Green + additive end to end | Run `bash scripts/validate.sh` and `bash scripts/test.sh`; open the doc/test audit | All green; both skills' SKILL.md + USAGE.md + CLAUDE.md describe the category model | `validate.sh` + `test.sh` exit 0; the doc/test audit is green post-doc-sync; existing axes + family docs unchanged |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Physical migration of `*.test.sh` into `tests/<category>/` | Deferred out of this PR (foundation-first staging) | The on-disk reorganization + `test.sh` discovery rewrite land in a follow-up run; this PR only proves the additive axis. |
| Re-expressed `validate.sh` Checks 24/26/28 against the category contract | Deferred — they keep validating the existing grammar to stay green | The category contract is not yet the CI gate; a documented-but-uncovered category test is caught only by the audit, not a hard validate check, until the follow-up. |
| Consumer greenfield adoption of `tests/<category>/` layout | Out of V1 scope (workbench performs the one-time move later) | A brand-new consumer repo relies on the audit's honest "category contract not adopted / inactive" note rather than a proven greenfield path. |
