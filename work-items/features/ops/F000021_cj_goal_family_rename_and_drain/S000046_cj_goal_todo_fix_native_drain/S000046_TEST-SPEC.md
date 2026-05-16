---
type: test-spec
parent: S000046
feature: F000021
title: "Native drain + drain-one-todo.sh helper in /CJ_goal_todo_fix — Test Specification"
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
| S1 | core | AC-6 | drain-one-todo.sh exists + executable | The shared helper is on disk and chmod'd | `test -x skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` |
| S2 | core | AC-6 | drain-one-todo.sh shellcheck-clean | Static analysis catches obvious bugs | `shellcheck skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` |
| S3 | core | AC-6 | S000045's Phase 5 calls drain-one-todo.sh (no inline duplicate) | After refactor, run.md no longer contains the per-TODO inner loop inline | `grep -c 'drain-one-todo.sh' skills/CJ_goal_run/run.md` (expect ≥ 1) AND `grep -c 'preflight.*scaffold.*pipeline.*ship.*deploy' skills/CJ_goal_run/run.md` (expect 0; the chain only lives in the helper) |
| S4 | core | AC-1, AC-3 | Default drain mode flag parsing in todo_fix.sh | Script handles `(no args)` as drain mode AND `<T-ID>` as single-shot | `bash -n skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (parse-only) + grep for `--max-drain` and `if [ -z "$ARG" ]` patterns |
| S5 | resilience | AC-7 | Lockfile acquire/release works | Synthetic: acquire lock for heading-H, second acquire returns "locked" | `(acquire heading-H) && (acquire heading-H again returns BUSY) && (release) && (acquire returns OK)` smoke harness in tests/ |
| S6 | observability | AC-9 | nothing_to_drain end_state path exists | Empty Phase 1 enumeration produces nothing_to_drain telemetry | `grep -q 'nothing_to_drain' skills/CJ_goal_todo_fix/scripts/todo_fix.sh skills/CJ_goal_todo_fix/SKILL.md` |
| S7 | observability | AC-10 | Telemetry fallback-read both paths | Skill reads both CJ_goal.jsonl + CJ_goal_todo_fix.jsonl | `grep -q 'CJ_goal\.jsonl' skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (fallback read) |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-8 | Default drain on 7-row TODOS.md | 1. Stage TODOS.md with 7 easy-fix rows. 2. Run `/CJ_goal_todo_fix`. 3. Wait for drain to complete. 4. Inspect stdout for Phase 3 summary. | All 7 rows drained sequentially; 7 PRs merged; 7 strikethrough'd rows in TODOS.md. Phase 3 summary line printed: "Drained 7 of 7 attempted. PRs: [...]. Remaining: 0." | PASS if `gh pr list --state merged --limit 10` shows 7 fresh PRs AND TODOS.md has 7 fewer active rows AND stdout contains the summary line. |
| E2 | core | AC-2 | --max-drain 3 cap | 1. Stage TODOS.md with 12 easy-fix rows. 2. Run `/CJ_goal_todo_fix --max-drain 3`. | 3 rows drained; 9 remain. `drained_partial` end_state. | PASS if telemetry has `drained_count: 3` AND TODOS.md has 9 remaining active rows. |
| E3 | core | AC-3 | Single-TODO mode (T-ID form) | 1. Stage TODOS.md with row "T000099 — fix typo". 2. Run `/CJ_goal_todo_fix T000099`. | One PR drained for T000099 specifically. End_state=green. Behavior matches /CJ_goal v1.1 exactly. | PASS if exactly 1 PR merged AND T000099 row marked DONE. |
| E4 | core | AC-4 | Fuzzy single-TODO mode | 1. Stage TODOS.md with row "T000099 — fix typo in README". 2. Run `/CJ_goal_todo_fix "fix typo"`. | Same as E3 (one PR drained). | PASS if exactly 1 PR merged AND no AUQ about ambiguity. |
| E5 | core | AC-5 | --dry-run preview | 1. Stage TODOS.md with 5 easy-fix rows. 2. Run `/CJ_goal_todo_fix --dry-run`. | Phase 1 enumerates 5; Phase 2 is skipped; no PRs created; no writes to disk. Phase 3 prints "Would drain 5: [...]." | PASS if `git status` shows no changes AND no PRs created AND output matches preview format. |
| E6 | resilience | AC-7, AC-11 | Concurrent drain race (cross-skill) | 1. In terminal 1: start `/CJ_goal_run` Phase 5 drain that will hit heading H. 2. In terminal 2: simultaneously start `/CJ_goal_todo_fix H`. 3. Observe behavior. | First-to-acquire-lock proceeds; second skips H with `[lock-skip]` log. No double-scaffold; no two PRs for H. | PASS if exactly 1 PR exists for H AND second skill's log shows lock-skip line. |
| E7 | observability | AC-9 | nothing_to_drain when TODOS.md is empty-of-easy-fix | 1. Stage TODOS.md with only sensitive-surface rows (all blocked by preflight). 2. Run `/CJ_goal_todo_fix`. | "No easy-fix TODOs available." printed. end_state=nothing_to_drain. Exit code 0. | PASS if exit 0 AND telemetry end_state=nothing_to_drain. |
| E8 | observability | AC-10 | Telemetry fallback-read after rename | 1. Pre-populate `~/.gstack/analytics/CJ_goal.jsonl` with 4 invocation lines. 2. Run /CJ_goal_todo_fix twice (writes 2 lines to new file). 3. Trigger sunset trip-wire condition. | Trip-wire sees `INVOCATION_COUNT >= 6` (4 old + 2 new) AND `halt-count` calculation merges both files. | PASS if trip-wire output shows merged count from both paths. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Drain-of-drain (drained PR itself adds a new TODO that would also pass preflight) | F000021 explicit NOT-in-scope (deferred v5+). | MEDIUM: documented in F000021 design. Operator drains via subsequent invocation. |
| Lockfile zombie-cleanup if skill crashes mid-iteration | Per-day TTL is the safety net (file replaces daily). | LOW: zombie locks expire automatically within 24h. |
| `--max-drain 0` edge case | Behavior: error with "use --dry-run for preview" (per SPEC Open Q). | NIL: trivial input-validation. |
| Refactor of S000045's Phase 5 (whether the inline diff is fully replaced) | Smoke S3 grep-tests; E2E behavior unchanged by refactor. | LOW: caught by grep + S000045's existing eval cases. |
| Performance: cap=10 wall-clock cost (10 × ~5 min = ~50 min worst case) | Documented in F000021 Section 4. Cap is the bound. | LOW: operator-tunable via `--max-drain`. |
