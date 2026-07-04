---
type: test-spec
parent: S000129
feature: F000079
title: "Deterministic-agentic split of inline doc-sync + test-sync — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: Charlie Jiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI). E2E = manual verification before /ship. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-3, AC-5 | The build-gate shape guard passes 9/9 | Every pipeline keeps the `Step 5.5: Doc-sync` heading + both markers, invokes NO `/CJ_document-release`, runs `--render-docs`, and all four QA dispatches + qa.md carry `DEFER_SYNC` | `bash tests/cj-goal-doc-sync-wiring.test.sh` |
| S2 | core | AC-4, AC-6 | Registry validates + coverage + structure | The reframed gate row, the new behavior + coverage (anchor greps live), and the `cj-goal-gate-shape` category row + front-door doc + index all validate | `scripts/test-spec.sh --validate` + `--check-coverage` + `--check-structure` |
| S3 | resilience | AC-6, AC-8, AC-9 | Owner gates green | No doc orphan (front-door declared), fresh render, workflow coverage unchanged (4/4), no work-item IDs in rendered fields | `bash scripts/validate.sh` (Checks 15/24/26/27/28) |
| S4 | resilience | AC-9 | Full suite + lint green | The behavioral suite (incl. the extended guard) + shellcheck pass | `bash scripts/test.sh` + `shellcheck scripts/audit-nightly.sh tests/cj-goal-doc-sync-wiring.test.sh` |
| S5 | usability | AC-2, AC-6 | Category test is name-selectable | `cj-goal-gate-shape` runs via the two-axis contract and reports its plan | `scripts/test-run.sh --dry-run cj-goal-gate-shape` (and `--category workflow --layer CI-push`) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | The slimmed build tail reads correctly across all four orchestrators | Open each `skills/CJ_goal_*/pipeline.md` Step 5.5; confirm it is a deterministic `--render-docs` regen with the two reframed halt markers; open `qa.md` 8.6.0/8.6a/8.6b and confirm `DEFER_SYNC` gates the agentic sweep while the deterministic new-row obligation always runs | Step 5.5 = deterministic regen (no `/CJ_document-release` invocation) in all four; qa.md deterministic-always / agentic-deferred split reads coherently; standalone path (no directive) still runs the full sweep | PASS if a maintainer can trace "orchestrated build = fast deterministic sync inline, slow agentic sync nightly" end to end; FAIL if any pipeline still invokes the LLM doc-sync or qa.md skips the required new-row |
| E2 | resilience | AC-7, AC-10 | The safety net + standalone behavior are intact | Read `scripts/audit-nightly.sh` header (covers deferred sync); run `bash scripts/audit-nightly.sh --dry-run` (self-gates/plan, spends nothing); confirm standalone `/CJ_qa-work-item` prose still runs the full 8.6 sweep | The nightly sweep is documented as the deferred-drift safety net and dry-runs cleanly; standalone skills unchanged | PASS if the deferred drift has a named, honest safety net and no standalone skill regressed; FAIL if audit-nightly changed behavior or a standalone path lost its sweep |
| E3 | resilience | AC-9 | Atomic greening in one clean tree | Run `bash scripts/validate.sh`, then `bash scripts/test.sh`, then `shellcheck` | validate.sh green (24/26/27/28); test.sh green (incl. the extended guard + registry suites); shellcheck clean; no mid-run red | PASS if all three pass together; FAIL on any red (esp. a coverage/anchor drift or a doc orphan) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A live orchestrated `CJ_goal_*` build proving the deterministic Step 5.5 actually commits a regen delta end to end | The full happy-path-to-PR E2E is deferred on the gstack-in-CI blocker (same as the workflow-coverage eval cases) | The Step 5.5 regen is proven by the guard (static) + the deterministic engine checks, not by a live in-CI build |
| The registered-doc-verdicts Step 4.6 now finding no scratch file (best-effort no-op) | Advisory, never-halts path; degradation is by design | The verdict block silently absents from the PR body when doc-sync no longer writes it — acceptable (verdicts still ride the run output) |
| The agentic amendment sweep actually catching a real semantic overlay drift nightly | That is the nightly `/CJ_test_audit`'s job (agentic, model-spend), out of scope for the per-PR deterministic suite | A subtle un-amended overlay row surfaces only in the nightly `audit-drift` issue, not per-PR |
