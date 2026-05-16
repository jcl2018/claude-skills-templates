---
name: "Default worktree for /CJ_goal_run + /CJ_goal_todo_fix"
type: feature
id: "F000025"
status: active
created: "2026-05-16"
updated: "2026-05-16"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Scaffolded from /CJ_personal-pipeline on 2026-05-16 against design doc
     chjiang-feat-default-worktree-design-20260516-121928.md. Single-child
     user-story shape: all build work lives in S000054. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/default_worktree_for_cj_goal`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

- [ ] `scripts/cj-worktree-init.sh` exists, executable, emits single-line JSON contract per design
- [ ] `/CJ_goal_run` SKILL.md preamble auto-creates worktree on main (single-arg invocation)
- [ ] `/CJ_goal_todo_fix` SKILL.md preamble auto-creates worktree on main in single-TODO mode
- [ ] `scripts/drain-one-todo.sh` calls helper with `--force-create` per drained TODO
- [ ] `scripts/test.sh` regression assertion fires when preamble wiring is missing
- [ ] `tests/cj-worktree-init.test.sh` passes 5 cases (on-main creates, in-worktree detects, --no-worktree opts out, --force-create overrides, dirty-check halts)
- [ ] TODOS.md deferred row added for `/CJ_goal_investigate` worktree wiring
- [ ] CLAUDE.md one-line note that `/CJ_goal_run + /CJ_goal_todo_fix` auto-worktree on main
- [ ] `scripts/validate.sh` clean

## Todos

- [ ] S000054 — implement helper + wire two skills + drain-loop integration + 5-case helper test + test.sh regression assertion + TODOS row + CLAUDE.md note

## Log

- 2026-05-16: Created. F000025 feature scaffold per design 20260516-121928.

## PRs

## Files

- `scripts/cj-worktree-init.sh` (new)
- `tests/cj-worktree-init.test.sh` (new)
- `skills/CJ_goal_run/SKILL.md` (modified — preamble worktree-init block)
- `skills/CJ_goal_todo_fix/SKILL.md` (modified — preamble worktree-init block for single-TODO mode)
- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` (modified — per-iteration helper call with --force-create)
- `scripts/test.sh` (modified — regression assertion for preamble wiring)
- `TODOS.md` (modified — deferred row for /CJ_goal_investigate worktree wiring)
- `CLAUDE.md` (modified — one-line note re auto-worktree default)

## Insights

- Design doc passed /autoplan dual-voice Eng review with 12 mechanical fixes auto-applied (eval→JSON, PID-suffix collision, dirty-check, no-arg Branch g skip, BEFORE Path Resolution, --force-create, repo-toplevel anchor, 5-case helper test, visible WARN, explicit caller→prefix map, --quiet gated echo, drain-one-todo BASH_SOURCE resolution).
- `/CJ_goal_investigate` scope-cut per Open Q5: its source-of-truth lives on the `immutable-watching-sparrow` worktree (branch `add-fid-collision-detection-todo`) which has not merged. Deferred TODOS.md row captures the followup.
- Pattern reuses: `skills-update-check` workbench-source resolution; `.claude/worktrees/{name}/` convention from CLAUDE.md; `scripts/todo_fix.sh` → `drain-one-todo.sh` extraction shape (D000017).

## Journal

- [orchestrator] 2026-05-16T13:59:32Z pre-scaffold check: branch (d) clean-slate; Phase 1 scaffolded F000025 feature with 1 user-story child (S000054). RUN_ID=20260516-135932-66386.
- [orchestrator] 2026-05-16T21:16:28Z Phase 2 implement complete: 8 files changed (1 new helper, 1 new test, 2 SKILL.md edits, 1 drain-loop edit, test.sh + TODOS.md + CLAUDE.md updates). validate.sh PASS, test.sh PASS.
- [qa-smoke-summary] 2026-05-16T21:16:28Z green — 5/5 smoke tests pass (helper test, full test.sh suite, JSON shape, preamble wiring, TODOS row). Bonus: CLAUDE.md note verified.
- [qa-pass] 2026-05-16T21:16:28Z Phase 3 smoke complete; e2e=ambiguous (multi-skill feature; user-story-shape E2E rows in S000054_TEST-SPEC.md must be walked manually before /ship).
- [qa-e2e-deferred] 2026-05-16T21:16:48Z Feature E2E coverage requires post-ship walkthrough (live /CJ_goal_run + /CJ_goal_todo_fix invocation). Per CJ_qa-work-item convention, E2E rows tagged post-ship are deferred at this stage; Phase 3 Ship gates include manual E2E walkthrough before /ship.
- [auto-final-gate-suppressed] 2026-05-16T21:17:08Z 0 mechanical, 0 taste, 2 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260516-135932-66386)
