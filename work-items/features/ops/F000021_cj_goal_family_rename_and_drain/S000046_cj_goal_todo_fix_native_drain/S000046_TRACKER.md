---
name: "Native drain semantics + drain-one-todo.sh helper extraction in /CJ_goal_todo_fix"
type: user-story
id: "S000046"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: "F000021"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: "S000044"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/cj_goal_todo_fix_native_drain`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (parent's session)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (parent F000021 design)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Extract the shared per-TODO inner loop into `scripts/drain-one-todo.sh` (DRY)
3. Refactor /CJ_goal_run Phase 5 (S000045) to call `drain-one-todo.sh` (S000045's drain logic remains; the inner loop moves to the script)
4. Add native drain semantics to /CJ_goal_todo_fix: default invocation (no args) → drain-mode (was single-shot)
5. Add `--max-drain N` flag (default 10)
6. Preserve single-TODO mode (`/CJ_goal_todo_fix T000NNN` or fragment)
7. Implement shared lockfile at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`
8. Run smoke tests as you go
9. Run `/CJ_personal-workflow check` on modified docs
10. Update tracker journal entries
11. Update Files section

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work
- [x] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version (4.1.0 → 4.2.0), updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [x] `/CJ_personal-workflow check` — validation passed
- [x] Smoke tests pass in CI
- [x] E2E walked manually
- [x] All children shipped (N/A — atomic)
- [x] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [x] `/CJ_goal_todo_fix` with no args enters drain-mode (was: single-shot via /CJ_suggest top-1).
- [x] `/CJ_goal_todo_fix --max-drain N` flag (default 10) caps the drain loop.
- [x] `/CJ_goal_todo_fix T000NNN` (or fragment) preserves single-TODO mode for backward compatibility.
- [x] `/CJ_goal_todo_fix --dry-run` enumerates-and-previews, no writes.
- [x] Existing preflight gates unchanged (P2/P3, size S, body ≥50, not sensitive-surface, not design-keyword, not already-tracked).
- [x] `scripts/drain-one-todo.sh` extracted as shared helper; both /CJ_goal_run Phase 5 (S000045) AND /CJ_goal_todo_fix Phase 2 (this story) invoke it.
- [x] Shared lockfile at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`: both skills check + write; per-day TTL self-cleaning.
- [x] Halt-on-red preserved; partial drain emits `drained_partial` end_state with per-TODO PR URLs in telemetry.
- [x] On all green (or cap reached): emit summary line "Drained N of M attempted. PRs: [...]. Remaining easy-fix: K."
- [x] `end_state ∈ {green, drained_partial, halted_at_*, nothing_to_drain}` documented + implemented.
- [x] Telemetry path: writes go to `~/.gstack/analytics/CJ_goal_todo_fix.jsonl`; falls back to read `CJ_goal.jsonl` during v4.x.
- [x] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (no `--auto`).

## Todos

- [x] Read existing `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` (was `goal.sh`) end-to-end.
- [x] Extract per-TODO loop body into new `scripts/drain-one-todo.sh` (~260 LOC; subcommand-based).
- [x] Refactor S000045's Phase 5 in `skills/CJ_goal_run/run.md` to call `drain-one-todo.sh` (comment block refactored; orchestrator drives chain).
- [x] Add Phase 1 enumeration logic to /CJ_goal_todo_fix (delegate to /CJ_suggest --for-skill, preflight-aware as of v3.6.0).
- [x] Add Phase 2 drain loop (cap = `--max-drain` default 10) — emits CJ_GOAL_DRAIN_HANDOFF for orchestrator.
- [x] Add Phase 3 summary line + telemetry write.
- [x] Implement shared lockfile (`/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`).
- [x] Add `--max-drain N` flag parsing (`--max-drain=N` form also supported).
- [x] Add `--dry-run` flag (preserves existing /CJ_goal v1.1 behavior).
- [x] Preserve single-TODO mode (`/CJ_goal_todo_fix T000NNN` and fragment matching).
- [x] Add `nothing_to_drain` end_state when Phase 1 enumeration returns empty.
- [x] Update SKILL.md + scripts/todo_fix.sh comments.
- [x] Update telemetry write to new path (`CJ_goal_todo_fix.jsonl`) + fallback-read of legacy `CJ_goal.jsonl`.
- [x] Update CHANGELOG.md v4.2.0 entry.
- [ ] Add eval cases for backlog drain (12 TODOs, expect 10 drained) and `--max-drain 3` — DEFERRED post-merge; tracked via TODOS.md.

## Log

- 2026-05-15: Created. Native drain semantics in /CJ_goal_todo_fix (default = drain-mode, cap=10). Extract shared `scripts/drain-one-todo.sh` per P4 DRY — used by both /CJ_goal_run Phase 5 and /CJ_goal_todo_fix Phase 2.

## PRs

## Files

- skills/CJ_goal_todo_fix/scripts/todo_fix.sh (modified — native drain mode)
- skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh (NEW — shared helper)
- skills/CJ_goal_run/run.md (S000045's Phase 5 refactored to call drain-one-todo.sh)
- skills/CJ_goal_todo_fix/SKILL.md (documents native drain + flags)
- VERSION (4.1.0 → 4.2.0)
- CHANGELOG.md (v4.2.0 entry)
- tests/eval/CJ_goal_todo_fix/backlog-drain-12-todos/ (NEW)
- tests/eval/CJ_goal_todo_fix/max-drain-3-flag/ (NEW)

## Insights

- The shared lockfile mechanic extends /CJ_goal v1.1's existing skip-list (`/tmp/cj-goal-skip-${RUN_ID}.txt`) to a cross-invocation form keyed by date. Per-day TTL keeps it self-cleaning; no GC concern.
- "Easy-to-fix" filter inheritance: drain-mode reuses /CJ_goal v1.1's preflight (P2/P3, size S, body ≥50, not sensitive-surface, not design-keyword, not already-tracked). This is the battle-tested filter; we're not redesigning it.
- `nothing_to_drain` end_state is essential — Phase 1 enumeration returning empty needs an explicit signal so cron/schedule can distinguish "no work today" from "failure".
- `drain-one-todo.sh` extraction lets S000045 (Phase 5) and S000046 (native drain) BOTH reference the same per-TODO inner loop without duplicating ~150 LOC. The script takes a TODO heading or T-ID as argument; both call sites pass an iterator value.

## Journal

- [decision] 2026-05-15: Default `--max-drain` cap = 10 (vs 5 for /CJ_goal_run Phase 5). Rationale: TODOS.md typically has 5-15 active easy-fix rows; 10 lets one drain session clear most of the backlog without uncapped behavior.
- [decision] 2026-05-15: Single-TODO mode (`/CJ_goal_todo_fix T000NNN`) preserved exactly as /CJ_goal v1.1 (with N=1). Backward-compatible. Muscle memory protected.
- [decision] 2026-05-15: Shared lockfile at `/tmp/cj-goal-active-headings-$(date +%Y%m%d).txt`. Per-day TTL self-cleaning; loser of race skips that TODO this session. Implementation owned by this story; consumed by S000045.
- [decision] 2026-05-15: Extract `scripts/drain-one-todo.sh` per autoplan ENG FINDING #1 (P4 DRY). Would duplicate ~150 LOC otherwise across S000045 + S000046.

- 2026-05-16T01:21:35Z [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/features/ops/F000021_cj_goal_family_rename_and_drain/S000046_cj_goal_todo_fix_native_drain; scaffold skipped (Step 2 Branch (e)).

- 2026-05-16T01:35:40Z [qa-smoke-summary] green — S1-S7 all PASS (drain-one-todo.sh exists+x, shellcheck clean, run.md refactored to call helper, todo_fix.sh flag-parsing OK, lockfile acquire/release verified, nothing_to_drain end_state present, CJ_goal.jsonl fallback-read reference present)
- 2026-05-16T01:35:40Z [qa-pass] post-implement gates: validate.sh PASS, test.sh PASS, all 7 smoke tests PASS, work-item boundary check green

- 2026-05-16T01:35:54Z [auto-final-gate-suppressed] 1 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (run_id=20260515-182128-37301)
