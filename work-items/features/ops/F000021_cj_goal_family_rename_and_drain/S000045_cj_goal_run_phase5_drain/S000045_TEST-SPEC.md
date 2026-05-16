---
type: test-spec
parent: S000045
feature: F000021
title: "Phase 5 drain logic in /CJ_goal_run — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | TODOS.md diff parser correctness | `^\+### ` grep on a synthetic diff returns expected heading count | `printf '+### new TODO\n+- not a heading\n' \| grep -cE '^\+### '` (expect 1) |
| S2 | core | AC-2 | N==0 silent skip path exists in run.md | Phase 5 section in run.md contains `new_todos_count: 0` and silent-skip branch | `grep -q 'new_todos_count' skills/CJ_goal_run/run.md && grep -q 'silent.*skip' skills/CJ_goal_run/run.md` |
| S3 | usability | AC-6 | `--no-drain` flag is parsed in Step 1 | run.md Step 1 handles `--no-drain` via the existing flag-discard pattern | `grep -q 'no-drain' skills/CJ_goal_run/run.md` |
| S4 | observability | AC-7 | Telemetry schema documented in SKILL.md | SKILL.md or run.md lists the new fields | `grep -q 'drained_count' skills/CJ_goal_run/SKILL.md skills/CJ_goal_run/run.md` |
| S5 | integration | AC-1, AC-2 | Phase 5 section structurally valid | run.md has `## Phase 5` heading with sub-steps | `awk '/^## Phase 5/,/^## /' skills/CJ_goal_run/run.md \| wc -l` (expect > 20 lines) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | Phase 5 silent-skip on refactor PR | 1. Run `/CJ_goal_run <refactor-design>` on a design doc whose feature explicitly adds 0 TODOs to TODOS.md. 2. After /land-and-deploy emits green, observe Phase 5 behavior. | Phase 5 emits "Phase 5: no new TODOs detected. Done." then exits green. No AUQ. | PASS if no AUQ AND telemetry line has `new_todos_count: 0` AND `end_state: green`. |
| E2 | core | AC-3, AC-4 | Phase 5 happy-path drain (N=3) | 1. Run `/CJ_goal_run <design>` on a design doc whose feature adds 3 TODOs to TODOS.md. 2. Phase 5 surfaces AUQ "Drain 3 new TODOs? (recommended: yes)". 3. Answer yes. 4. Wait for 3 child PRs to ship sequentially. | 3 child PRs created and merged via /CJ_goal_todo_fix invocations. Each TODO row marked DONE in TODOS.md. | PASS if 3 PRs visible in `gh pr list --state merged` post-run AND TODOS.md has 3 strikethrough'd rows. |
| E3 | core | AC-3 | Phase 5 cap behavior (N=7) | 1. Run /CJ_goal_run on a synthetic design that adds 7 TODOs. 2. Phase 5 AUQs "Drain 7? (recommended: no)". 3. Answer "Drain top 5, defer rest". | 5 children drained; 2 remain as active rows in TODOS.md. `drained_partial` end_state. | PASS if telemetry has `drained_count: 5` AND `end_state: drained_partial` AND `drained_pr_urls.length = 5`. |
| E4 | resilience | AC-5 | Halt-on-red mid-drain | 1. Run Phase 5 with N=3. 2. Manually red-flag the 2nd child's /ship Gate #2 review. | Loop STOPS at 2nd child. 1 PR merged, 2 not started. `drained_partial`. | PASS if telemetry has `drained_count: 1` AND remaining 2 TODOs are still active in TODOS.md. |
| E5 | usability | AC-6 | `--no-drain` flag bypass | 1. Run `/CJ_goal_run <design> --no-drain` on a design that adds 5 TODOs. | Pipeline completes Phases 1-4 normally. Phase 5 is fully skipped (no AUQ, no drain). end_state=green. | PASS if no Phase 5 output AND telemetry has `no_drain_flag: true` AND `new_todos_count` is unwritten (or 0). |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent /CJ_goal_run Phase 5 + standalone /CJ_goal_todo_fix race on same TODO heading | Lockfile is owned by S000046; this story consumes but doesn't test it. | LOW: S000046 TEST-SPEC covers it. Verified once at the lockfile level. |
| Drain-of-drain (Phase 5 child PR introduces its own new TODO) | F000021 explicit NOT-in-scope (deferred v5+). | MEDIUM: documented in F000021 design. Will produce "new TODOs created during drain" follow-up if it bites in practice. |
| Phase 5 timing across long /land-and-deploy windows (deploy takes 10+ min) | Wall-clock not load-tested; cap=5 bounds it at ~25 min worst-case. | LOW: documented in F000021 design Section 4 (Performance). |
| Telemetry parser regression (sunset trip-wire reads new fields without breakage) | Trip-wire schema-tolerant by default (jq selects specific fields). | NIL: trip-wire ignores unknown fields. |
