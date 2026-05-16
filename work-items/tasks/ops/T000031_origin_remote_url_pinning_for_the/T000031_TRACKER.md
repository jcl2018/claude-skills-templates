---
name: "Origin remote URL pinning for the upgrade path (P4, S)"
type: task
id: "T000031"
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
2. Create working branch: `git checkout -b feat/origin_remote_url_pinning_for_the`
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
   → design doc at `~/.gstack/projects/origin_remote_url_pinning_for_the/`
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

- [x] Implement: Origin remote URL pinning for the upgrade path (P4, S) — capture `git remote get-url origin` at install time as `manifest.upstream_url`; verify it matches at update-check time before emitting the upgrade banner. Backward-compatible: empty/absent field skips the check.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-15: Created. Auto-scaffolded by /CJ_goal_todo_fix from TODOS.md ### Origin remote URL pinning for the upgrade path (P4, S)
- 2026-05-15: Implemented. `scripts/skills-deploy` captures `git remote get-url origin` of the source repo at install time, writes it to `manifest.upstream_url`. `scripts/skills-update-check` reads the pinned URL, compares against current `origin` URL, and suppresses the upgrade banner + warns to stderr on mismatch. 4 new tests (U29-U32) in `scripts/test-deploy.sh` cover capture, mismatch-suppression, match-emits-banner, and pre-T000031-manifest backward compat.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/skills-deploy` — added `upstream_url` capture + manifest write
- `scripts/skills-update-check` — added origin-URL verify gate in `cmd_default`
- `scripts/test-deploy.sh` — added tests U29-U32
- `work-items/tasks/ops/T000031_origin_remote_url_pinning_for_the/T000031_TRACKER.md`
- `work-items/tasks/ops/T000031_origin_remote_url_pinning_for_the/test-plan.md`

## Insights

<!-- Auto-injected from TODOS.md body by /CJ_goal_todo_fix -->

The "Upgrade now" body block runs `git -C "$source" pull --ff-only origin main` based on `manifest.source` from `~/.claude/.skills-templates.json`. A user who can write that manifest can redirect upgrades to attacker-controlled code. Mitigation: at install time, store `manifest.upstream_url` (the expected `origin` URL) and have skills-update-check verify `git -C "$source" remote get-url origin` matches before recommending upgrade. Same trust boundary already applies to skills-deploy install, so this is hardening, not a new defense. **Depends on:** any real-world threat scenario where this matters.


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: TODOS.md ### Origin remote URL pinning for the upgrade path (P4, S) -->
