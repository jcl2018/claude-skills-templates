---
type: test-spec
parent: S000123
feature: F000073
title: "Remove the portability gate from the cj_goal build path — Test Specification"
version: 1
status: Draft
date: 2026-07-02
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Gate-reference grep is empty | No `phase portability-audit`, `portability-red`, or `halted_at_portability` remains in the script + the four orchestrators | `grep -rn "phase portability-audit\|portability-red\|halted_at_portability" scripts/cj-goal-common.sh skills/CJ_goal_feature skills/CJ_goal_task skills/CJ_goal_defect skills/CJ_goal_todo_fix` (expect no matches) |
| S2 | integration | AC-3 | Full validate suite passes | Check 18 still strict, Check 24 marker cross-check consistent, Check 27 workflow docs fresh after regenerate | `./scripts/validate.sh` |
| S3 | resilience | AC-4 | Full test suite passes | No reference to the deleted test/integration block; the `task`-enum probe repointed and green | `./scripts/test.sh` |
| S4 | integration | AC-3 | Workflow docs are regenerated + fresh | `spec/workflow-spec.md` edits render cleanly and match on-disk docs | `bash scripts/workflow-spec.sh --render-docs --check` (expect no diff) |
| S5 | core | AC-4 | Deleted gate test is gone; engine fixture kept | `tests/cj-goal-common-portability.test.sh` absent, engine test present | `test ! -f tests/cj-goal-common-portability.test.sh && echo OK`; `grep -rq "cj-portability-audit" scripts/test.sh && echo ENGINE-KEPT` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | A cj_goal orchestrator no longer runs a portability gate | Read `skills/CJ_goal_feature/pipeline.md` (or dry-run reasoning through the chain) around the former Step 5.7 | The chain goes ...qa-audit checkpoint → `/ship` with no portability node; no `--phase portability-audit` call remains | PASS if the portability gate node/step is absent and `/ship` follows the QA-audit checkpoint directly |
| E2 | integration | AC-3, AC-5 | The separate portability test still functions unchanged | Run `/CJ_portability-audit` in this repo; inspect `validate.sh` Check 18 output | `/CJ_portability-audit` produces its per-skill verdicts; Check 18 still runs strict and reports a clean baseline | PASS if the standalone audit + Check 18 behave exactly as before the change |
| E3 | usability | AC-5 | Operator docs are consistent with the removal | Read `CLAUDE.md` for the "Pre-ship portability gate" section + `halted_at_portability` mentions | The gate section is gone and no halt-taxonomy prose references `halted_at_portability`; the standalone `/CJ_portability-audit` + Check 18 prose remains | PASS if no stale gate prose remains and the separate-test prose is intact |

<!-- No dedicated E2E test skill for this feature. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A full live happy-path cj_goal run to a PR with the gate removed | The workbench defers full happy-path-to-PR E2E on the gstack-in-CI blocker; the `level: workflow` eval cases target gstack-independent paths (dry-run / halt). | A behavioral regression only observable in a full live run could slip; mitigated by the grep + validate + test smoke checks and the dry-run reasoning E2E (E1). |
| Consumer-repo behavior after the change | Consumer repos never had the engine, so the gate already no-op'd there (`PHASE_RESULT=skipped`); nothing observable changes for them. | Negligible — the removal only affects the workbench's own build path. |
