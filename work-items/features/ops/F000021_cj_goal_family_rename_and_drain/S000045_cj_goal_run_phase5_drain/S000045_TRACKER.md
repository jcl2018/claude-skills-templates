---
name: "Phase 5 drain logic in /CJ_goal_run"
type: user-story
id: "S000045"
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
2. Create working branch: `git checkout -b feat/cj_goal_run_phase5_drain` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] /office-hours design referenced (parent F000021 design)
- [ ] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work
- [ ] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version (4.0.0 → 4.1.0), updates changelog
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `/CJ_goal_run <design-doc>` Phase 5 diffs `TODOS.md` additions in the merged PR (`git diff <parent>..HEAD -- TODOS.md`).
- [ ] Phase 5 counts new `^### ` headings → N.
- [ ] If N == 0: Phase 5 silently skips and emits `end_state=green` with `new_todos_count: 0` in telemetry.
- [ ] If N > 0: AUQ surfaces "Drain N new TODOs? [yes/no/show-list]" (recommended: yes if N ≤ cap=5, no otherwise).
- [ ] On yes: per-TODO drain loop (cap=5) reuses `/CJ_goal_todo_fix` invocation as a subroutine (preflight → scaffold T-task → /CJ_personal-pipeline → /ship Gate #2 [per child] → /land-and-deploy → TODOS.md DONE-mark).
- [ ] On per-child halt-red: STOP the loop, emit `drained_partial` end_state with per-child PR URLs in telemetry.
- [ ] On cap reached: STOP cleanly, emit `drained_partial` with "K TODOs remain; run /CJ_goal_todo_fix to drain" message.
- [ ] On all green: emit `drained_complete` end_state.
- [ ] New `--no-drain` flag bypasses Phase 5 entirely (escape hatch).
- [ ] Telemetry line includes `new_todos_count`, `drained_count`, `drained_pr_urls` array.
- [ ] Squash-merged PR via `gh pr merge <PR#> --squash --delete-branch` (no `--auto`).

## Todos

- [ ] Add Phase 5 section to `skills/CJ_goal_run/run.md` (was `CJ_run/run.md`).
- [ ] Implement TODOS.md diff parser (`git diff <parent>..HEAD -- TODOS.md | grep -E '^\+### '`).
- [ ] Implement N-count threshold logic (skip silently when N == 0; AUQ when N > 0).
- [ ] Implement per-TODO drain loop calling `/CJ_goal_todo_fix <T-or-heading>` per child (cap=5).
- [ ] Halt-on-red preserves existing halt classes from `/CJ_run` (no new halts in this story; new classes `drained_complete`/`drained_partial` defined in F000021).
- [ ] Update `skills/CJ_goal_run/SKILL.md` to document Phase 5 and `--no-drain` flag.
- [ ] Add `--no-drain` flag parsing to Step 1 of `run.md`.
- [ ] Telemetry: extend `~/.gstack/analytics/CJ_goal_run.jsonl` schema with `new_todos_count`, `drained_count`, `drained_pr_urls`.
- [ ] Update CHANGELOG.md v4.1.0 entry.
- [ ] Add eval case `tests/eval/CJ_goal_run/phase5-drain-zero-todos/`.
- [ ] Add eval case `tests/eval/CJ_goal_run/phase5-drain-three-todos/`.

## Log

- 2026-05-15: Created. Phase 5 drain logic adds ~200 LOC to /CJ_goal_run: diff TODOS.md additions in merged PR, AUQ if N > 0, per-child drain loop cap=5, halt-on-red.

## PRs

## Files

- skills/CJ_goal_run/run.md (~200 LOC added — Phase 5 section)
- skills/CJ_goal_run/SKILL.md (documents Phase 5 + --no-drain flag)
- VERSION (4.0.0 → 4.1.0)
- CHANGELOG.md (v4.1.0 entry)
- tests/eval/CJ_goal_run/phase5-drain-zero-todos/ (new)
- tests/eval/CJ_goal_run/phase5-drain-three-todos/ (new)

## Insights

- TODOS.md diff parsing uses `git diff <parent>..HEAD -- TODOS.md`. `<parent>` = the PR's base SHA. `^+### ` grep catches new top-level TODO headings. Excludes contextual lines (`^+- `, `^+  `).
- Recommended Y/N decision: AUQ recommends "yes" iff N ≤ cap=5 (achievable in one pass). If N > 5, AUQ recommends "no" — partial drain isn't really completeness, and operator should choose deliberately.
- Halt-on-red preserves existing /CJ_run halt classes (no NEW halt classes are introduced in this story; the F000021-level new classes `drained_complete`/`drained_partial` map to existing halt mechanics).
- `--no-drain` escape hatch is critical: operators sometimes know the TODOs from this run are out-of-scope to drain right now (e.g., need different reviewers, different time window). Forcing drain would be wrong.

## Journal

- [decision] 2026-05-15: Cap=5 hardcoded for /CJ_goal_run Phase 5 (vs config). Greppable in SKILL.md; P5 explicit-over-clever. Smaller than /CJ_goal_todo_fix's cap=10 because Phase 5 scope is "this run's TODOs" (naturally smaller).
- [decision] 2026-05-15: Per-child /ship Gate #2 (sequential), not batched. Same pattern as /CJ_run Branch (b) multi-story today. Batching would create "review 5 diffs at once" UX which is worse than 5 sequential targeted reviews.
- [decision] 2026-05-15: Phase 5 emits `green` (not `drained_complete`) when `new_todos_count: 0` — drain didn't have to fire because no debt was created. Telemetry distinguishes via the `new_todos_count` field.
