---
name: "`skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S)"
type: task
id: "T000025"
status: active
created: "2026-05-14"
updated: "2026-05-14"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/skills_deploy_install_pins_manifest`
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
   → design doc at `~/.gstack/projects/skills_deploy_install_pins_manifest/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

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

- [ ] Implement: `skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S)

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-14: Created. Auto-scaffolded by /CJ_goal from TODOS.md ### `skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S)

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal -->

`scripts/skills-deploy install` records `manifest.source` (in `~/.claude/.skills-templates.json`) as the running clone's `REPO_ROOT`, computed from the script's own path. When invoked from `.claude/worktrees/<name>/scripts/skills-deploy`, the manifest gets pinned to that ephemeral worktree path. Once the worktree is removed (Conductor cleanup, `git worktree remove`, etc.), `skills-deploy doctor` reports `FAIL: source path '<dead-worktree>' no longer exists` and emits WARN for every skill as `source directory missing in repo` — even though the per-skill SKILL.md symlinks in `~/.claude/skills/CJ_*/` still resolve correctly to the main checkout (symlinks use absolute paths to `/Users/chjiang/Documents/projects/claude-skills-templates/skills/...`, not the worktree). Update-check and the gstack-update-check fallback also key off `manifest.source` for `git pull --ff-only` during inline upgrades, so a stale source silently breaks the upgrade path too. **Workaround (already applied 2026-05-11):** re-run `skills-deploy install` from the main checkout, not a worktree. **Fix options:** (a) detect when `REPO_ROOT` is under `<toplevel>/.claude/worktrees/` and refuse with an instructive error pointing at the main toplevel — strictest, safest; (b) auto-resolve via `git rev-parse --path-format=absolute --git-common-dir` to find the main repo's git-dir and record THAT toplevel as `source` regardless of which worktree the script ran from — silently does the right thing; (c) print a WARN-and-continue, keeping current behavior but visible. Option (b) is the "boil the lake" pick — also fixes future Conductor / per-feature-worktree flows where running from main isn't always convenient. **When:** before the next time a worktree-based install pollutes the manifest (high-frequency hit because Conductor + per-feature worktree workflows run scripts from worktree paths by default). **Reference:** found 2026-05-11 while investigating "CJ_ skills missing in autocomplete in other repos" — root cause was a different vector (autocomplete was just stale state, resolved when user re-tested), but `skills-deploy doctor` from a worktree surfaced the pinned-to-deleted-worktree manifest. Manifest re-anchored to main checkout; learning logged via `gstack-learnings-log` under key `skills_deploy_source_pins_to_cwd`.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### `skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S) -->

- 2026-05-15T06:39:16Z [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/work-items/tasks/skills/T000025_skills_deploy_install_pins_manifest; scaffold skipped.
- 2026-05-15T06:41:08Z [impl] Edited scripts/skills-deploy: manifest `source` now resolves to main repo toplevel via `git rev-parse --path-format=absolute --git-common-dir` (with REPO_ROOT fallback). Files: 1.
- 2026-05-15T06:41:08Z [qa-smoke-summary] green — validate.sh PASS (errors:0, warnings:0); resolution smoke test verified: main checkout and worktree both yield /Users/chjiang/Documents/projects/claude-skills-templates.
- 2026-05-15T06:41:08Z [qa-pass] green — task-type qa; test-plan Case 1 (manual verification) confirmed via smoke test.
- 2026-05-15T06:41:27Z [auto-pipeline-clean] run_id=20260514-233901-32562; suppress-final-gate set; 1 mechanical, 0 taste, 0 user-challenge-approved.
