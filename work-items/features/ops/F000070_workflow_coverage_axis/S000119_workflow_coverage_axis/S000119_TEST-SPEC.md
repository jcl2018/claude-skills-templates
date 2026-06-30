---
type: test-spec
parent: S000119
feature: F000070
title: "Eval-backed level:workflow coverage + forward/reverse gate — Test Specification"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | The merged test-spec registry validates with the 4 new `level: workflow` behaviors + 4 `behavior_coverage:` rows | `--validate` passes; `workflow:` enum-check accepts declared orchestrators, rejects unknown | `scripts/test-spec.sh --validate` |
| S2 | resilience | AC-4 | Forward + reverse workflow-coverage gate is green from birth | every orchestrator has a matching `level: workflow` behavior; no orphan behavior; exit 0 | `scripts/test-spec.sh --check-workflow-coverage` |
| S3 | core | AC-3 | 6th `workflow` column round-trips through the behaviors parser incl. the `-` placeholder unwrap | `--list-behaviors` emits the `workflow:` value (or "" for `-`); positional `$1` consumers unaffected | `scripts/test-spec.sh --list-behaviors` |
| S4 | usability | AC-7 | `workflow-spec.sh --list-orchestrators` emits orchestrator-kind names only | exactly the 4 `CJ_goal_*` names, no roster entries | `scripts/workflow-spec.sh --list-orchestrators` |
| S5 | integration | AC-4 | The new `validate.sh` check runs the gate with 0 errors and is exercised by the integration fixture | `validate.sh` reports 0 errors; `zzz-test-scaffold` covers the new check | `scripts/validate.sh && scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion.

     Post-ship rows: the eval-case execution is structurally only runnable where
     ANTHROPIC_API_KEY lives (nightly eval-nightly.yml / local eval.sh), so it is
     tagged `post-ship` and verified after the secret is set / locally with a key —
     /CJ_qa-work-item Step 4 filters it from the in-pipeline E2E dispatch. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | resilience | AC-4 | Negative: 5th orchestrator with no workflow behavior FAILS the gate | Add a hypothetical 5th `orchestrator`-kind entry to a temp `workflow-spec.md` fixture with NO matching `level: workflow` behavior; run `test-spec.sh --check-workflow-coverage` | A forward FINDING names the orphan orchestrator; non-zero exit | Gate FAILS (finding emitted) — not a silent pass |
| E2 | integration | AC-6 | Consumer posture: absent registries SKIP cleanly | In a temp dir with no `spec/workflow-spec.md` or no `spec/test-spec.md`, run `test-spec.sh --check-workflow-coverage` (via `REPO_ROOT`/`*_SPEC_PATH` overrides) | `inactive` note printed; exit 0; no error, no false finding | Clean SKIP, exit 0 |
| E3 | observability | AC-5 | `/CJ_test_audit` surfaces the gate (Stage 1 verbatim) + judges substance (Stage 2) | Run `/CJ_test_audit` standalone in this repo; read the Stage 1 + Stage 2 sections | Stage 1 prints `--check-workflow-coverage` output `stage1/`-prefixed; Stage 2 has a per-`level:workflow`-behavior substance verdict | Both stages present + correct |
| E4 | integration post-ship | AC-1 | The 3 new eval cases actually run and pass under `eval.sh` | With `ANTHROPIC_API_KEY` set, run `scripts/eval.sh` (or the nightly workflow) for `CJ_goal_task/halt-too-complex`, `CJ_goal_feature/dry-run-plan`, `CJ_goal_defect/dry-run-plan` | `task` emits `halted_at_too_complex` + routing suggestion; `feature`/`defect` emit `dry_run_preview`; all `--json-schema`-valid | All 3 cases pass schema validation |

<!-- E2E test skill: none (validated via test-spec.sh / validate.sh / eval.sh CLIs). -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The full happy-path-to-PR eval E2E per orchestrator (reaching `/ship`/`/office-hours`) | Gated on the gstack-in-CI blocker; this story scopes to gstack-independent halt/dry-run paths | A workflow's post-gstack tail (ship/land) is not eval-covered yet — deferred follow-up upgrades the SAME behavior |
| The generated `docs/tests/workflow-coverage.md` view freshness | The view is DEFERRED (not built here); Check 26 freshness does not yet apply to it | A future hand-edit of a not-yet-existing generated view — n/a until the follow-up builds it |
| Eval-case execution in plain CI | `tests/eval/` needs `ANTHROPIC_API_KEY`, absent in plain CI | The eval (works-when-run) runs nightly/local only; the GATE (plain CI) covers the structural guarantee regardless |
