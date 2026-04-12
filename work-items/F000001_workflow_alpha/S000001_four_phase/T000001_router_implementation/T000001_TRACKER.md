---
name: "Router Implementation"
type: task
id: "T000001_router_implementation"
status: active
created: "2026-04-11"
updated: "2026-04-11"
parent: "S000001_four_phase"
repo: "claude-skills-templates"
branch: "feat/workflow-alpha"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Populate Files section with expected changed files
4. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Files section populated

### Phase 2: Implement

1. Work from parent's acceptance criteria + your Todos
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify no regressions
2. Run tests: `./scripts/test.sh` (or project-specific test command)
3. Run `/review` for code review (if PR exists)

❌ If tests fail: fix, re-run

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] Test verification passed

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] SKILL.md: branch detection, work item resolution, phase detection, status menu
- [x] track.md: create, journal, milestones, list, close, child-items, evidence synthesis
- [x] implement.md: build-forward (features) + debug-backward (defects)
- [x] review.md: contract gate + gstack /review delegation
- [x] ship.md: /ship + /land-and-deploy delegation

## Log

- 2026-04-11: Created. Router + 4 subcommand files implementation.

## PRs

## Files

- skills/workflow/SKILL.md
- skills/workflow/track.md
- skills/workflow/implement.md
- skills/workflow/review.md
- skills/workflow/ship.md

## Insights

## Journal
