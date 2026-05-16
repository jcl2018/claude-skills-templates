---
type: design
parent: S000047
title: "Schedule-friendly --quiet flag + cron doc in /CJ_goal_todo_fix — User Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Brief stub. See parent F000021_DESIGN.md for full context. -->

## Problem

Post-S000046, /CJ_goal_todo_fix has native drain semantics — but it still
emits a Phase 3 summary AUQ at the end. If wired into `/schedule create`
(cron-style), the AUQ surfaces noisily in the cron output / operator
notifications. Need a `--quiet` flag that lets `/schedule` invocations run
silently, writing summary to journal instead of AUQ.

## Shape of the solution

Add `--quiet` flag to /CJ_goal_todo_fix:
- When set: Phase 3 writes `[scheduled-drain-summary]` journal entry to a per-day log file; no AUQ surfaces.
- Telemetry gains `scheduled_run: true|false` field for retro attribution.
- Document cron-pattern example: `/schedule create "/CJ_goal_todo_fix --max-drain 3 --quiet" daily 9am`.
- /ship Gate #2 is NOT suppressed (autonomy ceiling preserved per F000021 constraint).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `--quiet` suppresses summary AUQ ONLY, NOT /ship Gate #2 | Per F000021 constraint: "schedule-friendly = PRs queue for review at cadence; NOT auto-merge." Maintains autonomy ceiling. |
| 2 | Journal-entry replacement for AUQ | `[scheduled-drain-summary]` line written to the drained work-item's tracker; readable post-cron via `grep`. |
| 3 | New telemetry field `scheduled_run` (bool) | Retro tooling distinguishes cron vs operator drain. |
| 4 | Doc-only /schedule integration | No /schedule schema-binding in v4. Cron-pattern example in CLAUDE.md + SKILL.md is sufficient. /schedule binding is a separate concern. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Operator forgets `--quiet` was set, doesn't see summary, drained PRs queue unreviewed forever | LOW — `gh pr list` shows them. `[scheduled-drain-summary]` journal entry is searchable. Document the trade-off explicitly in SKILL.md. |
| `--quiet` interacts unexpectedly with `--max-drain N` or single-TODO mode | Smoke S3 in TEST-SPEC: combine flags + verify behavior. |
| Halt-on-red entries still get written when `--quiet`? | Yes — only summary AUQ is suppressed; halt logging is unchanged. |
| Cron output capture: where does the skill print "no easy-fix TODOs available"? | When `--quiet` + `nothing_to_drain`: skip the stdout print; write `[scheduled-drain-summary] nothing_to_drain` journal entry only. |

## Definition of done

- [ ] `--quiet` flag parses correctly.
- [ ] Summary AUQ suppressed; journal entry written instead.
- [ ] /ship Gate #2 still surfaces per child (autonomy ceiling).
- [ ] Telemetry has `scheduled_run` field.
- [ ] CLAUDE.md (workbench) has cron-pattern example.
- [ ] SKILL.md documents `--quiet` + cron-pattern.
- [ ] Squash-merged PR.

## Not in scope

- /schedule schema-binding — doc only.
- Auto-merge of drained PRs — deferred indefinitely (autonomy ceiling).
- Per-host cron syntax (we delegate to /schedule's own format).

## Pointers

- Parent feature tracker: [../F000021_TRACKER.md](../F000021_TRACKER.md)
- Parent feature design: [../F000021_DESIGN.md](../F000021_DESIGN.md)
- Sibling S000046 (native drain): [../S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md](../S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md`
