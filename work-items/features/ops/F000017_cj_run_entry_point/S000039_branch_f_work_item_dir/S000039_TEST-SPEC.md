---
type: test-spec
parent: S000039
feature: F000017
title: "Branch(f) work-item-dir — Test Specification"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
spec: S000039_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | Phase detection produces correct MODE for 6 fixtures | gate strings + PR check map to expected MODE | `bash tests/branch-f/test-mode-resolution.sh` |
| S2 | core | AC-1 | Work-item-dir input is recognized (not treated as design doc) | Branch(f) dispatch triggers, not Branch(a/b/c/d) | `/CJ_run work-items/.../S000038_.../` and verify telemetry mode |
| S3 | resilience | AC-8 | gh-offline graceful path | with `gh auth logout`, PR state → UNKNOWN → pr_unknown_state | `gh auth logout && /CJ_run <work-item-with-PR>` |
| S4 | observability | AC-11 | Telemetry log entry includes `mode` field | grep CJ_run.jsonl after invocation | `tail -1 ~/.gstack/analytics/CJ_run.jsonl | jq .mode` |
| S5 | integration | AC-9 | Branch(g) → Branch(f) handoff | Branch(g) picks, Branch(f) phase-detects | run /CJ_run with no args; verify mode logged in telemetry |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3 | impl_qa_ship full resume | 1) Work-item with Phase 1 complete, no impl yet. 2) Run `/CJ_run <dir>`. | CJ_personal-pipeline --work-item-dir runs (impl + QA), then /ship + /land-and-deploy | PR created and merged from a partial-state work-item |
| E2 | core | AC-4 | qa_ship resume | 1) Work-item with IMPL_GATE=[x] but QA_GATE=[ ]. 2) Run `/CJ_run <dir>`. | /CJ_qa-work-item runs, then /ship + /land-and-deploy | User sees QA phase start without manual /CJ_qa invocation |
| E3 | core | AC-5 | ship-only resume | 1) Work-item with IMPL_GATE=[x] AND QA_GATE=[x], no PR URL. 2) Run `/CJ_run <dir>`. | /ship runs, then /land-and-deploy | PR created from local commits already on the branch |
| E4 | core | AC-6 | open_pr graceful exit | 1) Work-item with PR URL set, PR open on GitHub. 2) Run `/CJ_run <dir>`. | Message: "PR already open at $URL. Run /land-and-deploy to merge." Exit 0. | No duplicate PR created; user knows what to do |
| E5 | core | AC-7 | already_shipped idempotency | 1) Work-item with PR URL, state MERGED. 2) Run `/CJ_run <dir>`. | Message: "Already shipped. Nothing to do." Exit 0. | NO-OP; safe re-run |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| `pr_unknown_state` AUQ behavior (rare states like DRAFT_DELETED) | Hard to fixture; rare in practice | If gh returns an unexpected state, user gets the AUQ — manual handling |
| Concurrent /CJ_run invocations on same dir | Idempotency owned by sub-skills | Sub-skill contracts (pipeline, ship) handle their own concurrency |
| Defect/task TRACKERs in Branch(f) | v0.2 scope is user-story only | User passes path explicitly for non-user-story; or extend in v0.3 |
| MODE-decision performance with large TRACKERs (>1000 lines) | Realistic TRACKERs are <500 lines | If TRACKER grows huge, phase detection slows linearly (acceptable) |
| Rollback of merged PRs from `already_shipped` re-invoke | Out of scope; no `--force` flag in v0.2 | User must manually rollback via gh / git |
