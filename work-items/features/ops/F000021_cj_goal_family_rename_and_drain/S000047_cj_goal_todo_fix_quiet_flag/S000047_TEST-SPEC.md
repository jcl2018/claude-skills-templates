---
type: test-spec
parent: S000047
feature: F000021
title: "Schedule-friendly --quiet flag + cron doc in /CJ_goal_todo_fix — Test Specification"
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
| S1 | core | AC-1 | --quiet flag is parsed in todo_fix.sh | Script handles `--quiet` arg | `grep -q '\-\-quiet' skills/CJ_goal_todo_fix/scripts/todo_fix.sh` |
| S2 | core | AC-2 | Phase 3 has the [scheduled-drain-summary] journal-write branch | Script contains the journal-write path for quiet mode | `grep -q 'scheduled-drain-summary' skills/CJ_goal_todo_fix/scripts/todo_fix.sh` |
| S3 | core | AC-3 | --quiet does NOT touch /ship Gate #2 invocation | No code in todo_fix.sh suppresses /ship's own prompts | `! grep -E '/ship.*--quiet|--suppress.*ship' skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (must NOT find these) |
| S4 | observability | AC-4 | scheduled_run telemetry field is documented | SKILL.md or todo_fix.sh references the field | `grep -q 'scheduled_run' skills/CJ_goal_todo_fix/SKILL.md skills/CJ_goal_todo_fix/scripts/todo_fix.sh` |
| S5 | usability | AC-6 | CLAUDE.md has the cron-pattern example | grep the example | `grep -q '/CJ_goal_todo_fix.*--quiet' CLAUDE.md` |
| S6 | usability | AC-7 | SKILL.md documents --quiet | --quiet section in SKILL.md | `grep -q '\-\-quiet' skills/CJ_goal_todo_fix/SKILL.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | --quiet suppresses Phase 3 AUQ | 1. Stage TODOS.md with 3 easy-fix rows. 2. Run `/CJ_goal_todo_fix --max-drain 3 --quiet`. 3. Approve each /ship Gate #2 as it surfaces. 4. After drain completes, check stdout + journal. | Stdout has minimal output (no Phase 3 summary AUQ). Journal entry `[scheduled-drain-summary] drained=3, attempted=3` written. | PASS if stdout doesn't contain "Drained N of M attempted. Continue (y/n)?" AND journal has the line. |
| E2 | core | AC-3 | /ship Gate #2 surfaces despite --quiet | 1. Same as E1 step 2. 2. Observe each child PR. | /ship Gate #2 (diff-review AUQ) STILL surfaces per child. | PASS if 3 interactive Gate #2 AUQs surfaced (one per child) AND drain completed. |
| E3 | observability | AC-4 | scheduled_run telemetry | 1. Run E1's scenario with `--quiet`. 2. Inspect `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`'s last line. | Line contains `"scheduled_run": true`. | PASS if jq query `.scheduled_run` returns `true` on the last line. |
| E4 | observability | AC-4 | scheduled_run = false without --quiet | 1. Run `/CJ_goal_todo_fix --max-drain 3` (no --quiet). 2. Inspect telemetry's last line. | Line contains `"scheduled_run": false`. | PASS if jq query returns `false`. |
| E5 | resilience | AC-5 | Halt-on-red preserved with --quiet | 1. Run `/CJ_goal_todo_fix --max-drain 3 --quiet`. 2. Red-flag the 2nd child's /ship Gate #2. | Loop stops. Halt entry written to tracker journal. `drained_partial` telemetry. | PASS if `drained_count: 1` in telemetry AND halt entry visible. |
| E6 | observability | AC-8 | --quiet + nothing_to_drain silent | 1. Stage TODOS.md with 0 easy-fix rows. 2. Run `/CJ_goal_todo_fix --quiet`. | Stdout has no print of "no easy-fix TODOs". Journal session log has `[scheduled-drain-summary] nothing_to_drain` entry. | PASS if stdout is empty (or just trailing newline) AND session log has the entry. |
| E7 | core | AC-9 | --quiet composes with --max-drain | Already covered by E1. | Same as E1. | (overlap with E1) |
| E8 | usability | AC-6 post-ship | Cron-pattern example resolves end-to-end | 1. After PR merges, in fresh shell run `/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am` (or equivalent). 2. Observe at 9am the next day. | /schedule binds the invocation; at 9am next day, drain runs; PRs queue; no notifications. | (post-ship — verify after merge + 24h wait. Or simulate by running the wrapped command directly.) PASS if direct invocation produces same behavior as E1. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| /schedule plugin binding behavior | Out of scope (doc-only integration). | LOW: pattern documented; operator integrates manually. |
| Multi-day cron run accumulation (Day 1 drains 3, Day 2 drains 3, etc.) | Per-day TTL on lockfile (from S000046) is the safety net; multi-day behavior should be additive. | LOW: covered by Day 1 + Day 2 E2E if needed; current scale doesn't warrant. |
| --quiet + drain-of-drain (drained PR creates new TODO mid-cron) | F000021 explicit NOT-in-scope (deferred v5+). | MEDIUM: documented. |
| --quiet + halt at /autoplan or /CJ_personal-pipeline (mid-child drain) | Halt-on-red handles it (E5 covers); halt class names unchanged. | LOW: existing halt mechanics. |
