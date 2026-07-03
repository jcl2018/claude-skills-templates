---
type: test-spec
parent: S000126
feature: F000076
title: "Remove the inline audit + checkpoint from the cj_goal paths and relocate it to a CI-nightly job — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier.

     These are the four command/smoke verification rows the design pins
     (grep-empty, validate.sh, test.sh, shellcheck, audit-nightly.sh SKIP),
     runnable in bash CI — NOT interactive happy-path-to-PR E2E. The E2E tier
     holds the by-reading tail-reshape check (the workbench defers full live
     cj_goal E2E on the gstack-in-CI blocker). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | QA-audit-marker grep is empty | No `halted_at_qa_audit`, `qa-audit-declined`, or `qa-audit-waived` remains in the four orchestrators; `DEFER_AUDIT: true` still present in each QA dispatch | `grep -rn "halted_at_qa_audit\|qa-audit-declined\|qa-audit-waived" skills/CJ_goal_feature skills/CJ_goal_task skills/CJ_goal_defect skills/CJ_goal_todo_fix` (expect no matches); `grep -rl "DEFER_AUDIT: true" skills/CJ_goal_*` (expect all four) |
| S2 | integration | AC-3, AC-5 | Full validate suite passes | Check 24 gate-marker drift clean (qa-audit row + markers gone together), Check 26 test-catalog fresh, Check 27 workflow docs fresh, Check 28 workflow coverage | `./scripts/validate.sh` |
| S3 | resilience | AC-4, AC-5 | Full test suite passes | The new `tests/audit-nightly.test.sh` + the updated `cj-audit-skills` / `cj-goal-doc-sync-wiring` tests pass; no reference to a removed checkpoint marker breaks a cross-check | `./scripts/test.sh` |
| S4 | resilience | AC-4 | New runner is shellcheck-clean | `scripts/audit-nightly.sh` has no shellcheck findings (CI `validate.yml` fails on ANY finding) | `shellcheck scripts/audit-nightly.sh` (expect no output, exit 0) |
| S5 | resilience | AC-4 | Nightly runner SKIPs without a key | `scripts/audit-nightly.sh` prints `SKIP` and exits 0 when `ANTHROPIC_API_KEY` is unset — a normal `test.sh` / a secret-less fork never touches a model | `env -u ANTHROPIC_API_KEY bash scripts/audit-nightly.sh; echo "rc=$?"` (expect `SKIP` on stdout, `rc=0`) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | A cj_goal orchestrator's QA tail no longer runs an inline audit or checkpoint | Read each `skills/CJ_goal_*/pipeline.md` (or dry-run reasoning through the tail) around the former Step 5.6 + checkpoint | The tail is Step 5.5 doc-sync → `/ship` with no post-sync audit step and no QA-audit checkpoint AUQ; `DEFER_AUDIT: true` is still passed to the QA dispatch (now meaning "skip inline; nightly covers it") | PASS if no audit/checkpoint node remains between doc-sync and `/ship` in any of the four pipelines and `DEFER_AUDIT: true` is still present |
| E2 | core | AC-3 | The CI-nightly audit job is wired end to end | Read `.github/workflows/audit-nightly.yml` + `scripts/audit-nightly.sh`; trace the `workflow_dispatch` path (or reason through it) | The workflow has the cron + `workflow_dispatch` triggers, `issues:write`, a secret pre-check, installs claude-code, and runs `scripts/audit-nightly.sh`; the runner invokes `/CJ_doc_audit` + `/CJ_test_audit`, parses `FINDINGS=`, and files one `audit-drift` issue | PASS if the workflow + runner form a complete nightly path that would file findings to an `audit-drift` issue when a key is present |
| E3 | integration | AC-5 | Operator docs + registries are consistent with the removal | Read `CLAUDE.md` ("Doc-sync coverage" + "Verification contract"), `spec/test-spec-custom.md`, and `docs/architecture.md` for checkpoint / `qa-audit` gate references | The `qa-audit` gate row + `[qa-audit-*]` markers are gone, the DEFER_AUDIT meaning-shift is documented, the deterministic per-PR gate prose is intact, and no doc describes a checkpoint that no longer runs | PASS if no stale checkpoint/gate prose remains and the deterministic-gate + standalone-audit prose is intact |

<!-- No dedicated E2E test skill for this feature; a full live happy-path cj_goal
     run to a PR is deferred on the gstack-in-CI blocker (see Coverage Gaps). -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A full live happy-path cj_goal run to a PR with the audit relocated | The workbench defers full happy-path-to-PR E2E on the gstack-in-CI blocker; the `level: workflow` eval cases target gstack-independent paths (dry-run / halt). | A behavioral regression only observable in a full live run could slip; mitigated by the grep + validate + test smoke checks (S1-S5) and the by-reading tail-reshape E2E (E1). |
| The nightly job's live `claude --print` invocation + real GitHub-issue create/update/close | `tests/audit-nightly.test.sh` covers only the deterministic half (SKIP-without-key, arg parsing, findings-parse → issue-decision with stubbed `claude`/`gh`); the live model call is gated on `ANTHROPIC_API_KEY` and runs only in the scheduled CI job. | A live-only bug in the `claude --print` prompt or the `gh issue` call could surface first on a real nightly run, not in `test.sh`; mitigated by the stubbed issue-decision unit test + the `workflow_dispatch` manual trigger for a supervised first run. |
| Consumer-repo behavior after the change | The inline audit + checkpoint only ran on the workbench's own orchestrator paths; a consumer repo installing these skills already lacked the audit engines. Nothing observable changes for consumers. | Negligible — the removal only affects the workbench's own build path + adds a workbench-only nightly job. |
