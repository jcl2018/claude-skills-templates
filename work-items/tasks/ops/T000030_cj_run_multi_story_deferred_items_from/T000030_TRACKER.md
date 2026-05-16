---
name: "/CJ_run multi-story: deferred items from autoplan review (P3, M)"
type: task
id: "T000030"
status: active
created: "2026-05-15"
updated: "2026-05-15"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/dreamy-enchanting-dongarra"
branch: "worktree-dreamy-enchanting-dongarra"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/cj_run_multi_story_deferred_items_from`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/cj_run_multi_story_deferred_items_from/`
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
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: /CJ_run multi-story: deferred items from autoplan review (P3, M) — copied the 5 deferred decisions into F000016_TRACKER.md as a new "Deferred decisions" section so reviewers won't re-litigate.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-15: Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### /CJ_run multi-story: deferred items from autoplan review (P3, M)
- 2026-05-15: Implemented. Added "## Deferred decisions" section to F000016_TRACKER.md with the 5 deferred items (budget-gate, --no-auto-iterate, --run-id, migration guide, dependency-aware batching) so future reviewers don't re-litigate.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/F000016_TRACKER.md`
- `work-items/tasks/ops/T000030_cj_run_multi_story_deferred_items_from/T000030_TRACKER.md`

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal_todo_fix -->

Deferred during autoplan review for the multi-story auto-iterate feature (branch claude/awesome-pasteur-36565c):
- **Blocking budget gate before loop** — auto-iterate mode implies acceptance; a preflight log line "N children × impl+qa+ship+land" with no AUQ is the right middle ground (already in impl sketch). Full AUQ gate deferred.
- **`--no-auto-iterate` escape hatch** — user confirmed full-auto intent; opt-out is invoking `/CJ_run` per child manually. Defer to v0.3.0 if demand surfaces.
- **run_id passthrough `--run-id` flag** — pipeline audit trail is useless in wrapper mode but not harmful. Requires pipeline interface change; defer to v0.3.0.
- **Migration guide for `--work-item-dir`** — additive flag, no breaking changes to existing callers; CHANGELOG note is sufficient for v0.2.0.
- **Dependency-aware batching** (Codex CEO) — `--work-item-dir` sequentially respects `S[0-9]*` sort order; `blocked_by` preflight halt is the safety net. Full dependency-aware scheduler deferred.
**Reference:** autoplan review 2026-05-13 on branch claude/awesome-pasteur-36565c.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### /CJ_run multi-story: deferred items from autoplan review (P3, M) -->
