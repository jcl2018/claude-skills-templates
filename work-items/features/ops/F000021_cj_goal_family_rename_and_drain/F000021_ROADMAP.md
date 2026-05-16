---
type: roadmap
parent: F000021
title: "CJ_goal family rename and native drain semantics — Roadmap"
date: 2026-05-15
author: chjiang
status: Draft
---

<!-- Source design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md
     /autoplan REVIEW REPORT appended (CEO + Eng + DX phases). 4 child user-stories
     after batching PR 1 + PR 2. -->

## Scope

This feature delivers the v4.0.0 → v4.3.0 release train for the CJ_goal family
rename and native drain semantics. `/CJ_run` becomes `/CJ_goal_run` (feature-
ship pipeline + post-ship TODO drain phase). `/CJ_goal` becomes
`/CJ_goal_todo_fix` (native drain-until-cap; no `/loop` dependency;
schedule-compatible). Both skills gain halt-on-red drain loops with per-child
/ship Gate #2 reviews and shared lockfile concurrency safety. Completeness
becomes a first-class shipping concept: feature green = feature shipped + its
own TODO debt drained.

## Non-Goals

- Drain-of-drain recursion (where drain-PRs themselves spawn drain) — deferred to v5+; risk of unbounded scope per-feature outweighs benefit at the current scale of ~10 active TODOs.
- /schedule skill binding — PR S000047 documents the cron pattern only; no schema-binding lock-in.
- Work-item history rename — historical accuracy preserved; only forward-looking references update.
- Autonomous merge of drained PRs — /ship Gate #2 is the autonomy ceiling.
- Migration of v3.6.x deferred TODOs — drains via post-v4.0 `/CJ_goal_todo_fix`.

## Success Criteria

<!-- Measurable outcomes observable from outside. -->

- [ ] `/CJ_goal_run <design>` on a single-story design produces 1 feature PR + 0-5 drain PRs in one invocation, capped at 5 children.
- [ ] `/CJ_goal_todo_fix` with no args drains up to 10 easy-fix TODOs; emits "Drained N of M attempted. K remaining." summary.
- [ ] `/CJ_goal_todo_fix --max-drain 3 --quiet` runs from `/schedule` cron without AUQ noise in cron log.
- [ ] Both skills halt-on-red; partial drain emits `drained_partial` end_state with per-child PR URLs in telemetry.
- [ ] Idempotent re-invocation (skip-list + T-tracker idempotency inherited from /CJ_goal v1.1).
- [ ] Aliases `/CJ_run` + `/CJ_goal` work through v4.x with deprecation banner; removed in v5.0.0.
- [ ] All existing `/CJ_run` and `/CJ_goal` workflow tests (`scripts/test.sh`, eval cases) pass post-rename.

## Decomposition

<!-- The user-stories that decompose this feature. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000044](S000044_cj_run_cj_goal_batch_rename/S000044_TRACKER.md) | Batched rename CJ_run → CJ_goal_run + CJ_goal → CJ_goal_todo_fix | Open |
| [S000045](S000045_cj_goal_run_phase5_drain/S000045_TRACKER.md) | Phase 5 drain logic in /CJ_goal_run (~200 LOC) | Open |
| [S000046](S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md) | Native drain semantics + drain-one-todo.sh helper extraction in /CJ_goal_todo_fix | Open |
| [S000047](S000047_cj_goal_todo_fix_quiet_flag/S000047_TRACKER.md) | Schedule-friendly --quiet flag + cron-pattern doc | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000044 (v4.0.0) — batched rename PR | — | Not Started | chjiang | Pure git mv + reference updates; ~800 LOC mechanical diff. Major version bump (rename-only break). | — |
| 2 | Ship S000045 (v4.1.0) — Phase 5 drain in /CJ_goal_run | — | Not Started | chjiang | ~200 LOC new logic. Diff TODOS.md additions, per-child drain loop cap=5. `--no-drain` escape hatch. | #1 |
| 3 | Ship S000046 (v4.2.0) — native drain in /CJ_goal_todo_fix | — | Not Started | chjiang | Default = drain-mode (was: single-shot). `--max-drain N` flag (default 10). Extract `scripts/drain-one-todo.sh` shared helper. | #1 |
| 4 | Ship S000047 (v4.3.0) — schedule-friendly --quiet flag | — | Not Started | chjiang | `--quiet` suppresses summary AUQ; logs to journal. Document /schedule cron pattern in CLAUDE.md/SKILL.md. | #3 |
| 5 | End-to-end feature run | — | Not Started | chjiang | Validate four children compose into dream-state delta: feature green = shipped + drained. | #1, #2, #3, #4 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-05-15: F000021 scaffolded from design doc + autoplan review.

## Dependency Graph

```
S000044 (batched rename, v4.0.0)
   │
   ├─────► S000045 (Phase 5 drain in /CJ_goal_run, v4.1.0)
   │
   └─────► S000046 (native drain + drain-one-todo.sh, v4.2.0)
                  │
                  └─► S000047 (--quiet flag + cron doc, v4.3.0)
                           │
                           └─► E2E feature run (F000021 close-out)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should we keep both old + new telemetry paths permanently, or merge on v5.0.0? | Decide during S000044 implementation; default = fallback-read both paths through v4.x; merge tool deferred. |
| Will the cross-skill drain race (Phase 5 + standalone /CJ_goal_todo_fix concurrent) actually fire in practice? | Verify in S000046 smoke test: dispatch both manually with shared TODO heading; observe lockfile-mediated skip. If never fires in 30 days post-v4.0, deprecate the lockfile in v4.4. |
| Does `--no-drain` need persistence across re-invocations (e.g., `/CJ_goal_run` declined drain once, should re-run skip)? | Default no — re-invocation re-asks. Revisit if operator feedback says noisy. |
