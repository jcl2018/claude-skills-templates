---
type: test-spec
parent: S000042
feature: F000020
title: "/CJ_suggest preflight-aware mode + --limit flag (WI-A) — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE WI-A. Smoke + E2E together cover every SPEC P0 acceptance criterion.
     Soft cap: 5 rows per tier; modest exceedance ok if justified. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | suggest.sh accepts --for-skill flag without error | flag parsing | `bash skills/CJ_suggest/scripts/suggest.sh --for-skill cj-goal --limit 5 >/dev/null && echo PASS` |
| S2 | core | AC-2 | suggest.sh accepts --limit N | flag parsing + LIMIT honored | `bash skills/CJ_suggest/scripts/suggest.sh --for-skill cj-goal --limit 15 \| awk 'NR>2 {n++} END{print (n<=15?"PASS":"FAIL")}'` |
| S3 | core | AC-3 | --for-skill cj-goal excludes a P1-tagged row from output | predicate gating works | `bash scripts/test-cj-suggest-preflight.sh p1` (synthetic TODOS.md fixture; assert excluded row not present) |
| S4 | core | AC-3 | --for-skill cj-goal excludes a sensitive-surface-tagged row | predicate gating works | `bash scripts/test-cj-suggest-preflight.sh sensitive` (synthetic TODOS.md fixture; assert excluded row not present) |
| S5 | resilience | AC-5 | suggest.sh with no flags returns top-5 unchanged | regression | `diff <(bash skills/CJ_suggest/scripts/suggest.sh) <(bash skills/CJ_suggest/scripts/suggest.sh) && echo PASS` (deterministic output; same invocation twice) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 AC-2 | Operator runs /CJ_suggest --for-skill cj-goal --limit 15 against real TODOS.md | `cd <repo> && bash skills/CJ_suggest/scripts/suggest.sh --for-skill cj-goal --limit 15` | Output table shows up to 15 rows, none with P1 priority, none size L\|XL, none matching sensitive-surface regex, none with design-needed keyword | All 4 exclusion criteria honored; output ranked by existing scoring |
| E2 | core | AC-4 | Operator runs /CJ_goal (no args); /CJ_goal shells out to /CJ_suggest with new flags | `cd <repo> && /CJ_goal` (observe transcript) | goal.sh transcript shows `/CJ_suggest --for-skill cj-goal --limit 15` invocation; first surviving row matches one /CJ_goal can preflight-pass | Integration is transparent; no operator action required |
| E3 | core post-ship | AC-bundle | /loop /CJ_goal session that previously starved at iter 10 now drains 12+ iterations with mixed-priority TODOs | `cd <repo> && /loop /CJ_goal` (run for 15+ iterations, observe end_states) | At least 12 iterations dispatch a /CJ_run successfully; halts only on genuine STOP signals (CI failure, /ship Gate #2 decline) not on `halted_at_resolve` from queue starvation | Per-iteration end_state grep verifies continue-set membership |
| E4 | resilience | AC-5 | Existing interactive /CJ_suggest user runs `/CJ_suggest` (no flags); behavior identical to pre-WI-A | `cd <repo> && /CJ_suggest` | Top-5 ranked output, identical format and content to pre-WI-A version | Byte-diff between pre/post outputs (or visual confirmation if scoring is timestamp-sensitive) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Pre-filter behavior when TODOS.md has 0 eligible rows after filter | Edge case; handled by /CJ_goal's existing `halted_at_resolve` path | Acceptable per OQ-5 (parent design) — `halted_at_resolve` is honest signaling. |
| Drift detection between /CJ_suggest predicate set and /CJ_goal preflight | Defense-in-depth (keeping /CJ_goal preflight) catches drift at runtime; no automated drift test | Acceptable; preflight failure surfaces as halt with clear log; manual sync if drift painful. |
| --for-skill with unknown skill name | Out of scope for v1; only cj-goal supported | Acceptable; future consumers add their own blocks; unknown name should error with clear message (smoke test could cover this in future expansion) |
