---
type: test-spec
parent: S000043
feature: F000020
title: "Halt-class semantic rename `_user_declined` → `_auto_declined` (WI-B) — Test Specification"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE WI-B. Atomic semantic rename + halt-class table update. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | grep goal.sh emit-site emits `_auto_declined` (not `_user_declined`) at the auto-default branch | rename complete | `grep -E 'halted_at_sensitive_surface_(auto\|user)_declined' skills/CJ_goal/scripts/goal.sh` (manual review: only `_auto_declined` should be emitted; `_user_declined` only in halt-class lookup as reserved) |
| S2 | core | AC-2 | halt_class_lookup case statement returns "continue" for `_auto_declined` | continue-set membership | `bash -c 'source skills/CJ_goal/scripts/goal.sh; halt_class_lookup halted_at_sensitive_surface_auto_declined'` (expect: `continue`) |
| S3 | core | AC-2 | SKILL.md halt-class table lists `_auto_declined` in continue column | docs in sync | `grep -A2 'halted_at_sensitive_surface_auto_declined' skills/CJ_goal/SKILL.md \| grep -i continue && echo PASS` |
| S4 | resilience | AC-4 | grep finds `_user_declined` only in lookup (as reserved/STOP) — no active emit-site | reservation honored | `grep -nE '_user_declined' skills/CJ_goal/scripts/goal.sh` (manual review: only halt_class_lookup case, never an `end_state="..._user_declined"` assignment) |
| S5 | observability | AC-3 | A simulated sensitive-surface row produces `_auto_declined` via direct script execution | end-to-end gate behavior | `bash scripts/test-cj-goal-sensitive-surface.sh` (synthetic TODOS.md fixture; grep transcript for `_auto_declined`) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 AC-3 | Operator runs /CJ_goal with a sensitive-surface fragment from inside /loop; loop continues | `cd <repo> && /loop /CJ_goal "skills-catalog.json"` (or any sensitive-surface fragment) | Transcript shows: gate fires, end_state=`_auto_declined`, halt-class lookup returns "continue", next /loop iteration begins | At least one `_auto_declined` emitted; no STOP from this gate; loop iterates ≥1 time after gate fires |
| E2 | core post-ship | AC-3 | /loop /CJ_goal session draining 10+ iterations with mixed-priority TODOs (containing 2-3 sensitive-surface rows in top-15) does not halt prematurely | `cd <repo> && /loop /CJ_goal` (run for 15+ iterations with a TODOS.md containing 2-3 sensitive rows in /CJ_suggest top-15) | Loop dispatches /CJ_run on at least 12 iterations; sensitive-surface gate emits `_auto_declined` (continue); only halts on genuine STOP (CI failure, /ship Gate #2 decline) | Per-iteration end_state grep verifies continue-set membership; `_user_declined` count = 0; `_auto_declined` count > 0 (gate fired at least once) |
| E3 | resilience | AC-4 | Operator greps codebase for `_user_declined` to verify reservation | `grep -rn '_user_declined' skills/CJ_goal/` | Hits found only in halt-class lookup (annotated as reserved/STOP) and SKILL.md (annotated as future); no active emit-site | Manual review of grep output |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| External consumers parsing the old `_user_declined` end state (e.g., codex grep alerts, dashboards) | Out of scope of WI-B; surface area is internal-only by audit | Document the rename in CHANGELOG; if breakage surfaces post-ship, add migration grep helper |
| Future interactive AUQ path emitting `_user_declined` | Out of scope (deferred per OQ-3 in parent design) | Acceptable; lands when interactive AUQ at orchestrator layer ships |
| Concurrent WI-A pre-filter blocking sensitive rows from reaching the gate (gate never fires under WI-A's happy path) | E1 explicitly bypasses pre-filter via interactive fragment to test the gate path | Acceptable; defense-in-depth coverage is the test goal |
