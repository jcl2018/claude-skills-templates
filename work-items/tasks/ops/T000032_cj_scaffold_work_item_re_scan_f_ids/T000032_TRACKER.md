---
name: "`/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S)"
type: task
id: "T000032"
status: active
created: "2026-05-16"
updated: "2026-05-16"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/cheeky-popping-kahn"
branch: "worktree-cheeky-popping-kahn"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/cj_scaffold_work_item_re_scan_f_ids`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/cj_scaffold_work_item_re_scan_f_ids/`
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
- [x] `/CJ_personal-workflow check` — validation passed (validate.sh exit 0)
- [x] Test-plan verified (all scenarios passing — smoke green)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] Implement: `/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-16: Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### `/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S)

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_scaffold-work-item/scaffold.md` — added Source 3 (origin/main post-fetch) to Step 5.1 fresh-ID generation; updated section intro and Result paragraph to reflect three sources.
- `work-items/tasks/ops/T000032_cj_scaffold_work_item_re_scan_f_ids/T000032_TRACKER.md` — Files + Phase 2 gates + Todos checkbox updates.

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal_todo_fix -->

F000023 collision shipped through F000024 (PR #140). Root cause: scaffolder picked F000023 based on the worktree's view of `work-items/features/ops/`, which lagged behind `origin/main` by a few hours. `b0e4f67` (v4.5.2, PR #134) shipped its own `F000023_retire_cj_company_workflow` while the worktree was in flight, but the scaffolder didn't see it. The collision was caught at `/ship` Step 4 (during the post-merge audit), forcing a mid-flight rename (F000023 → F000024) across 7 files in the version-bump commit.

**Fix shape:** add a pre-scaffold step that runs `git fetch origin <base>` and includes `origin/<base>:work-items/features/**/F[0-9]*` directories in the F-ID collision scan, not just `find work-items/`. Same fix applies to S-IDs, D-IDs, T-IDs. Cheap: one fetch + one `git ls-tree origin/main work-items/` invocation, parse for ID prefixes, union with local scan.

**Why P2, not P1:** rename mid-flight is recoverable (we did it in this session). But every operator working in long-lived worktrees while origin/main moves will hit this eventually — it's a latent footgun. Cost to fix is small; cost to rediscover via another late rename is annoying.

**Reference:** F000024 / PR #140 commit `f6f1914` for the rename pattern (CHANGELOG header, work-item dirs, frontmatter); skill files were unaffected because the F-ID wasn't baked into impl (good design property to preserve).


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-16 [qa-smoke-summary] green — test-plan row 1 (manual verification): diff matches TRACKER Insights fix shape; bash block syntactically valid; validate.sh passed
- 2026-05-16 [qa-pass] task — smoke green, E2E n/a for type=task

<!-- Source: TODOS.md ### `/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S) -->

- 2026-05-16 [auto-pipeline-clean] run_id=20260516-002506-72708 — zero taste/user-challenge decisions; all gates auto-mechanical or silent
