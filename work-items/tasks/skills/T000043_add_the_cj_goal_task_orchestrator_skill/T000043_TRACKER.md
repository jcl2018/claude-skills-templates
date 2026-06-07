---
name: "add the CJ_goal_task orchestrator skill (the small-task verb)"
type: task
id: "T000043"
status: active
created: "2026-06-07"
updated: "2026-06-07"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/tender-elion-267bd0"
branch: "feat/cj-goal-task"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/add_the_cj_goal_task_orchestrator_skill`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (TODOS.md cj_goal_task row; design settled via the cj_goal_feature design gate)
- [x] Working branch created (`branch` field populated: feat/cj-goal-task)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/add_the_cj_goal_task_orchestrator_skill/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/CJ_personal-workflow check` — validation passed (scripts/validate.sh: 0 errors)
- [x] Test-plan verified (all scenarios passing; scripts/test.sh: 0 failures)
- [ ] `/ship` — PR created (PR-stop: opens the PR, then STOP)
- [ ] `/land-and-deploy` — merged and deployed (separate manual human step after PR review)

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Build the `skills/CJ_goal_task/` skill (SKILL.md + pipeline.md + USAGE.md + scripts/cj-task-scaffold.sh)
- [x] Wire `--mode task` / `--caller task` / `cj-task-*` into the 3 shared scripts
- [x] Catalog + routing + docs + tests
- [x] QA green (validate.sh + test.sh)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-07: Created. Auto-scaffolded by /CJ_goal_task from topic: add the CJ_goal_task orchestrator skill (the small-task verb) — dogfooded the new cj-task-scaffold.sh.
- 2026-06-07: Built the CJ_goal_task orchestrator (fresh flat verb mirroring /CJ_goal_feature; design settled via the cj_goal_feature design gate: fresh flat orchestrator + PR-stop-only + hard complexity gate). Added family wiring, catalog/routing/docs, and tests. validate.sh 0 errors / test.sh 0 failures.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_goal_task/SKILL.md`, `pipeline.md`, `USAGE.md`, `scripts/cj-task-scaffold.sh` (new)
- `scripts/cj-goal-common.sh`, `cj-worktree-init.sh`, `cj-worktree-cleanup.sh` (`--mode task` / `--caller task` / `cj-task-*`)
- `skills-catalog.json`, `rules/skill-routing.md`, `permission-policy.md`
- `docs/workflow.md`, `docs/philosophy.md`, `CLAUDE.md`, `README.md`
- `scripts/validate.sh`, `scripts/test.sh`, `tests/cj-task-scaffold.test.sh` (new), `tests/cj-worktree-init.test.sh`, `tests/cj-worktree-cleanup.test.sh`
- `.gitignore` (`.cj-goal-task/` scratch)

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): add the CJ_goal_task orchestrator skill (the small-task verb)

- `cj_goal_task` ≈ `cj_goal_todo_fix` minus the TODOS-row gate, plus a free-text topic — so the scaffold (`cj-task-scaffold.sh`) adapts `todo_fix.sh`'s task-scaffold path to a `--topic` string. Built as a fresh flat orchestrator (NOT a todo_fix mode) to avoid the nested-subagent wall (the F000027 "reshape not wrapper" lesson).
- The design phase is replaced by an automatic HARD complexity gate (no AUQ): design-rework → /CJ_goal_feature, bug/investigation → /CJ_goal_defect, explicit-large-scope → /CJ_goal_feature. Bare "design" is deliberately NOT matched (so "refine the design doc" is allowed) — reused todo_fix Gate 5's proven keyword set.
- `--mode task` was ADDED to cj-goal-common.sh (unlike todo, which has no mode) because task is a feature/defect-style verb that routes through the shared worktree/cleanup/portability phases and earns its own `cj-task-*` prefix + telemetry stream.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: add the CJ_goal_task orchestrator skill (the small-task verb) -->
