---
type: test-spec
parent: S000025
feature: F000013
title: "Nightly CI workflow + first run validation + TODOS update — Test Specification"
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
| S1 | core | AC-1 | Workflow file exists with both triggers | Cron + workflow_dispatch wiring is correct | `grep -E '(cron:|workflow_dispatch:)' .github/workflows/eval-nightly.yml` (expect 2 matches) |
| S2 | core | AC-1 | Workflow has 15-min timeout | Cost-bound is enforced at the workflow level | `grep 'timeout-minutes: 15' .github/workflows/eval-nightly.yml` |
| S3 | core | AC-1 | Workflow references ANTHROPIC_API_KEY secret | Auth wiring is in place | `grep 'ANTHROPIC_API_KEY' .github/workflows/eval-nightly.yml` |
| S4 | core | AC-5 | TODOS.md marks eval harness DONE-V1 with F000013 link | Originating TODO is updated to reflect V1 ship | `grep -A 2 'Behavioral eval harness' TODOS.md \| grep 'DONE-V1\|F000013'` |
| S5 | usability | AC-9 (P1) | Workflow YAML is valid (parses without errors) | Workflow won't fail to load on first cron fire | `gh workflow view eval-nightly.yml` (expect successful parse) OR `bunx js-yaml .github/workflows/eval-nightly.yml >/dev/null` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. Each row should be one user-visible scenario. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2, AC-4 | Maintainer manually triggers first run and observes metrics | 1. Verify `gh secret list` shows `ANTHROPIC_API_KEY`; if missing, set via `gh secret set`. 2. Run `gh workflow run eval-nightly.yml --ref main`. 3. Watch via `gh run watch`. 4. Read job summary + per-step logs. | Workflow completes within 15 min; PASS/FAIL count visible; per-case cost numbers extractable from logs. | Pass: workflow completes; metrics observable. Fail: workflow times out, fails to install claude, or output is missing cost/wall-clock data. |
| E2 | core | AC-3 | Maintainer evaluates V1 success criteria from first run | 1. From E1's observed numbers, compute total cost and total wall-clock. 2. Compare to V1 success criteria ($1.50, 12 min). 3. Record both numbers in S000025_TRACKER's Log section. 4. Decide ship/revise: ≤ criterion → ship; 50% over → open follow-up. | Either: V1 success criteria stand and ROADMAP milestone #4 marked Done; OR a follow-up is opened with specific ask (cut N cases, tighten prompt X). | Pass: decision is data-driven and recorded. Fail: decision is pre-empirical or unrecorded. |
| E3 | resilience | AC-6, AC-7 | Maintainer verifies failure-notification path | 1. `git checkout -b test/notification-verify`. 2. Edit one case's `expected.schema.json` to require an impossible field. 3. `git push -u origin test/notification-verify`. 4. Run `gh workflow run eval-nightly.yml --ref test/notification-verify`. 5. Observe red ✗ in `gh run list`. 6. Read job summary — confirm the corrupted case is named in the failure list. 7. Cleanup: delete branch local + remote. | Workflow run completes with status FAIL; the corrupted case is identified by name in the visible failure surface (job summary). | Pass: red ✗ visible without expanding the log AND failed case is named. Fail: failure is silent OR requires log spelunking to identify. |
| E4 | core | AC-5 | Future contributor reads updated TODOS.md and finds the eval harness work | 1. Read `TODOS.md`. 2. Click the F000013 link in the eval harness entry. 3. Read `F000013_TRACKER.md`. | Contributor can navigate from TODOS.md → F000013 tracker → child stories → V2 trajectory in DESIGN. | Pass: contributor finds V2 work without asking the maintainer. Fail: link is broken, missing, or insufficient context. |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cron actually fires at 09:00 UTC | Can't verify without waiting 24h or hacking the system clock | Cron syntax is verified syntactically (S2 smoke); first cron miss surfaces operationally; if it fires manually via E1, the cron wiring is structurally identical |
| Multi-day stability (does the workflow survive 7 consecutive nightly runs?) | Time-bounded — we'd need a week before V1 ship | Risk: workflow has subtle flakiness that surfaces only over time. Mitigation: V1 first-run is a sanity check; multi-day stability is observed during early V1 use, not blocking V1 ship |
| Cost enforcement under sustained burn (`--max-budget-usd` in a loop) | Single-run only; doesn't catch a case that consistently costs $0.30 even though `--max-budget-usd 0.15` is set | If `--max-budget-usd` enforcement has bugs, cost will exceed budget on first run — captured by E2's success-criteria evaluation |
| Failure path when ANTHROPIC_API_KEY is missing or invalid | Not tested in V1 — assumes secret is set correctly | If secret is missing, workflow fails with a clear auth error; maintainer fixes inline. Not a coverage gap worth pre-empting in V1. |
| Concurrent triggers (cron + manual at same minute) | Not common enough to design for in V1 | If both fire concurrently, GitHub Actions queues them — second waits or both run if billing-tier allows. Either case, no data corruption — fake-`$HOME` per case isolates. |
