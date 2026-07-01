---
type: test-spec
parent: S000121
feature: F000071
title: "Local-E2E harness + materialized report + workflow docs (Part B/C) — Test Specification"
version: 1
status: Draft
date: 2026-06-30
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story (Part B + Part C of F000071). Smoke = automated
     regression (CI-green, no Claude); E2E = LOCAL manual verification (needs
     gstack + key + gh + budget). Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | resilience | AC-1 | Harness SKIPs with no prerequisites | `scripts/e2e-local.sh` with `CJ_E2E_LOCAL` unset prints a SKIP reason, exits 0, and never invokes `claude` | `bash tests/e2e-local.test.sh` |
| S2 | core | AC-2 | Sandbox provision/teardown | `lib/sandbox.sh` makes a clone + `.cj-e2e-sandbox` marker + a LOCAL bare origin; teardown removes the tmpdir | `bash tests/e2e-local.test.sh` |
| S3 | observability | AC-3, AC-4 | Report generator on synthetic evidence | `lib/report.sh` writes a `<verb>-<ts>.md` with DETERMINISTIC-vs-`claude --print` rows + a legend + a `.json` sibling; artifacts land under gitignored `reports/` while `EXAMPLE.md` stays tracked | `bash tests/e2e-local.test.sh` |
| S4 | usability | AC-6 | Workflow-docs freshness | the `### scripts/e2e-local.sh` roster entry renders and `docs/workflows/utilities-and-phase-steps.md` byte-matches a fresh render (Check 27) | `bash scripts/validate.sh` |
| S5 | core | AC-8 | Whole repo green | `validate.sh` 0 errors (incl. Check 24 coverage for the new units row + Check 26 catalog freshness) AND `test.sh` green with the e2e-local family SKIPping | `bash scripts/validate.sh && bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. These are LOCAL-ONLY
     (need gstack + ANTHROPIC_API_KEY + gh + budget); they do NOT run in CI. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-9 | A real `/CJ_goal_task` build runs unattended to the `/ship` boundary | Locally (gstack + key + gh present): `CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh`; let it provision the sandbox and drive `/CJ_goal_task` via the seam | The run reaches at least the qa-audit gate (ideally the `/ship` boundary); the bare origin receives the pushed branch AND `gh pr create` is blocked (no real PR); `end_state` is `halted_at_ship` (sandbox SUCCESS) or `halted_at_qa_audit` | PASS if it reaches ≥ qa-audit with no real PR; FAIL if it opens a real PR or halts before qa-audit on an infra error |
| E2 | observability | AC-4 | The materialized report is legible | After E1, open the echoed `reports/<verb>-<ts>.md` | The coverage table labels each row DETERMINISTIC vs `claude --print`, the rows match the real post-run evidence (the `work-items/tasks/T*/` dir, the diff, the `end_state`), and a `.json` sibling exists | PASS if the report distinguishes deterministic from model steps and the rows reflect real evidence; FAIL on a bare checkmark or template rows |
| E3 | security | AC-3 | The run cannot touch the real repo or open a real PR | During E1, confirm the working repo is untouched and no PR appears on the real remote | All writes are confined to the `mktemp` sandbox; the real repo tree is unchanged; no PR is created on the real GitHub remote | PASS if the real repo + remote are untouched; FAIL if any write escapes the sandbox or a real PR is opened |

<!-- Post-ship rows: none. The deterministic half is smoke-asserted pre-ship;
     the real-run half is a LOCAL manual E2E (not CI). -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The real `/CJ_goal_task` model run in CI | Blocked four ways (gstack absent, read-only eval tools, per-case budget, interactive AUQs) — the honest proof is the LOCAL E2E rows above | The real-run proof is local + manual; CI proves only the deterministic half (SKIP path, sandbox lib, report generator) |
| The other cj_goal verbs (feature/defect/todo) as harness cases | This story ships the `CJ_goal_task` case only (feature needs office-hours handling) — deferred follow-on | Low — `task` is the simplest unattended path and exercises the same seam + `/ship` boundary |
| A real PR against a scratch GitHub repo (the `real-pr` depth) | Deferred follow-on; the LOCAL bare origin proves the no-remote backstop without a real remote | Low — the bare-origin stop is the load-bearing auto-ship backstop and is asserted |
