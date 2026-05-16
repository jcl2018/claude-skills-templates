---
type: design
parent: F000021
title: "CJ_goal family rename and native drain semantics — Feature Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Source design doc:
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md
     /autoplan REVIEW REPORT appended to source (CEO + Eng + DX phases). -->

## Problem

`/CJ_run` (v0.5.0, the current feature-ship pipeline) and `/CJ_goal` (v1.1.0,
shipped v3.5.5) are functionally adjacent but conceptually disconnected.
`/CJ_run <design-doc>` ships a feature pipeline; when complete, the merged PR
almost always carries follow-up scope into TODOS.md — `PARTIAL` annotations,
`When:` markers, autoplan-review deferrals. The pipeline declares "green" the
moment the feature PR merges, even though it's manufactured TODO debt as part
of the same run. `/CJ_goal` drains that debt one row at a time. To drain
meaningfully, users invoke `/loop /CJ_goal` and babysit a sequence of
per-TODO /ship Gate #2 reviews.

Two friction points: (1) `/CJ_run`'s "completeness" claim is weak — every run
leaves TODO debt; the fix is to treat completeness as a first-class shipping
concept (feature green = feature shipped + its own debt drained). (2)
`/CJ_goal` requires `/loop` to be useful at backlog-scale; the native shape is
single-shot ("fix one TODO"). The user wants a dedicated "fix all easy-to-fix
TODOs" command that doesn't depend on the operator typing `/loop`, and should
be schedule-friendly (e.g., daily cron that prepares 3 ready-for-review PRs).

## Shape of the solution

Pivot reshapes the two skills as a family:

- **`/CJ_goal_run`** (replaces `/CJ_run`) — feature-ship pipeline + post-ship
  drain of TODOs this run created. Feature is "complete" when the parent ships
  AND its in-scope debt is drained or explicitly skipped.
- **`/CJ_goal_todo_fix`** (replaces `/CJ_goal`) — native drain-until-cap for
  the global easy-fix backlog. No `/loop` dependency. Schedule-compatible.

The `CJ_goal_*` naming convention telegraphs intent: every `_goal_*` skill
ships toward a clearly-defined "done" state, not a brittle "ship one thing and
move on." Aliases (`/CJ_run`, `/CJ_goal`) retained through v4.x with
one-line deprecation banner; removed in v5.0.0 (soft cutover protects
operator muscle memory).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Batched mechanical rename: /CJ_run → /CJ_goal_run + /CJ_goal → /CJ_goal_todo_fix | S000044 | [S000044_cj_run_cj_goal_batch_rename/S000044_TRACKER.md](S000044_cj_run_cj_goal_batch_rename/S000044_TRACKER.md) |
| Phase 5 drain logic in /CJ_goal_run (~200 LOC; TODOS.md diff + per-child drain loop, cap=5) | S000045 | [S000045_cj_goal_run_phase5_drain/S000045_TRACKER.md](S000045_cj_goal_run_phase5_drain/S000045_TRACKER.md) |
| Native drain semantics in /CJ_goal_todo_fix (default=drain-mode; cap=10) + extract scripts/drain-one-todo.sh shared helper | S000046 | [S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md](S000046_cj_goal_todo_fix_native_drain/S000046_TRACKER.md) |
| Schedule-friendly mode: --quiet flag + cron-pattern doc | S000047 | [S000047_cj_goal_todo_fix_quiet_flag/S000047_TRACKER.md](S000047_cj_goal_todo_fix_quiet_flag/S000047_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B (renames + native drain) with user's no-/loop refinement, NOT Approach A (renames + post-run drain AUQ) or Approach C (flag-only, no rename) | Approach A leaves /CJ_goal dependent on /loop; Approach C contradicts user's explicit "two pivots + naming-family" ask. B matches pivot intent + makes /CJ_goal_todo_fix self-sufficient and cron-eligible. |
| 2 | Batch PR 1 + PR 2 into a single chore rename PR (S000044), NOT split into two PRs | Both renames are pure `git mv` + reference updates, fully reviewable in one diff. Cuts chain 5→4. Avoids awkward intermediate state where one rename is shipped and the other isn't. Autoplan gate confirmed (auto-approved per P3 pragmatic). |
| 3 | Extract `scripts/drain-one-todo.sh` shared helper in S000046, NOT inline-duplicate the per-TODO loop in /CJ_goal_run Phase 5 and /CJ_goal_todo_fix Phase 2 | Otherwise ~150 LOC duplicates. P4 DRY: same preflight → scaffold → pipeline → ship → deploy chain in both call sites. |
| 4 | Hardcode drain caps (5 for /CJ_goal_run Phase 5, 10 for /CJ_goal_todo_fix), NOT config-file | Small numbers, greppable in SKILL.md, explicit-over-clever (P5). /CJ_goal_run cap < /CJ_goal_todo_fix cap because Phase 5 scope is "this run's TODOs" (naturally smaller). |
| 5 | Per-child /ship Gate #2 (sequential), NOT batched gate | Same as /CJ_run Branch (b) multi-story today. Batching creates "review 5 diffs at once" UX which is worse than 5 sequential targeted reviews. |
| 6 | Defer drain-of-drain recursion to v5+ (out of scope) | Risk of unbounded scope per-feature; current scale (10 active TODOs) doesn't justify recursion. v5 reconsider if backlog grows. |
| 7 | Document /schedule pattern only (PR S000047), NOT bind to /schedule skill | Smaller blast radius. /schedule binding is an integration concern, not part of the drain primitive. |
| 8 | Keep `_todo_fix` suffix asymmetry (vs parallel-verb `_drain` or parallel-noun `_todos`) | "todo_fix" matches mental model ("fix the TODOs"). "drain" is the mechanic, not the user goal. "todos" alone is too ambiguous (read? edit? clear?). P5 explicit-over-clever. |
| 9 | Soft cutover: aliases through v4.x, removed in v5.0.0 | Protects operator muscle memory (the largest UX cost of a rename). Clean v5 cutover with 4 minor releases of grace. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Operator types `/CJ_run` post-v5.0.0 expecting it to work | LOW severity. Skill prints clear error: "Renamed to /CJ_goal_run in v4.0.0; removed in v5.0.0." Verify in v5.0.0 ship test. |
| Drain cap exhausted (N > 5 in /CJ_goal_run Phase 5) | LOW. `drained_partial` end state with explicit "K TODOs remain; run /CJ_goal_todo_fix to drain" message. Telemetry distinguishes from green. Verify in S000045 smoke tests. |
| Cross-skill drain race on same TODO (concurrent /CJ_goal_run Phase 5 + /CJ_goal_todo_fix run) | LOW. Shared lockfile at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`; loser skips that TODO this session. Per-day TTL self-cleaning. Verify in S000046 concurrency smoke. |
| Telemetry path drift mid-v4.x (operator on v4.1, fallback read on old path `~/.gstack/analytics/CJ_run.jsonl`) | LOW. Skill reads both old + new paths; merges before sunset trip-wire reads. Verify in S000044 alias smoke. |
| `/schedule create` runs `/CJ_goal_todo_fix` when operator absent — drained PRs queue up unreviewed | MEDIUM. `--quiet` flag suppresses summary AUQ noise; operator sees PRs in normal `gh pr list` flow. Not a failure mode; expected behavior. Document in S000047 cron-pattern example. |
| `drain-one-todo.sh` not extracted in S000046 (forgotten) | LOW. Caught by ENG FINDING #1 in autoplan review; S000046 explicit task. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. -->

- [ ] All 4 child user-stories shipped (S000044, S000045, S000046, S000047) with passing tests.
- [ ] `/CJ_goal_run <design-doc>` on a single-story design produces 1 feature PR + 0-5 drain PRs in one invocation, capped at 5 children.
- [ ] `/CJ_goal_todo_fix` with no args drains up to 10 easy-fix TODOs and cleanly emits a summary (drained N of M, K remaining). No `/loop` needed.
- [ ] `/CJ_goal_todo_fix --max-drain 3 --quiet` invocable from `/schedule` cron; produces 3 PRs queued for review without AUQ noise.
- [ ] Both skills halt-on-red; partial drain emits `drained_partial` with per-child PR URLs in telemetry.
- [ ] Idempotent on re-invocation (skip-list + T-tracker idempotency inherited from /CJ_goal v1.1).
- [ ] Old `/CJ_run` and `/CJ_goal` invocations succeed during v4.x with deprecation banner.
- [ ] Existing `/CJ_run` workflow tests (`scripts/test.sh`, eval cases) pass against the renamed skills.

## Not in scope

<!-- Explicit non-goals. -->

- Drain-of-drain recursion — deferred to v5+; risk of unbounded scope per-feature outweighs benefit at current scale (10 active TODOs).
- /schedule skill binding — PR S000047 documents the cron pattern only, no schema-binding lock-in to the /schedule skill.
- Work-item history rename — explicitly NOT in scope. Historical work-item journals retain old slash-command names for accuracy; only forward-looking references update.
- /CJ_run → /CJ_goal_run telemetry merge tool — fallback read covers v4.x; explicit merger deferred.
- Migration of v3.6.x deferred TODOs — operator drains via `/CJ_goal_todo_fix` post-v4.0; no automated migration.
- Autonomous merge of drained PRs — /ship Gate #2 is the autonomy ceiling. "Schedule-friendly" means PRs queue for review at cadence, NOT auto-merge.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000021_TRACKER.md](F000021_TRACKER.md)
- Roadmap: [F000021_ROADMAP.md](F000021_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-165033.md`
- Predecessor: `/CJ_run` v0.5.0 (in `skills/CJ_run/`) and `/CJ_goal` v1.1.0 (in `skills/CJ_goal/`)
- Related: F000017 `/CJ_run` entry point, F000018 `/CJ_run` suppress-readiness-gate, F000019 `/CJ_goal` TODO bridge, F000020 `/CJ_goal` v1.1 polish
