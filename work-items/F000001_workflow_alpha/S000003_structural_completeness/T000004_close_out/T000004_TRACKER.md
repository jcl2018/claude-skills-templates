---
name: "Close out S000003"
type: task
id: "T000004_close_out"
status: active
created: "2026-04-12"
updated: "2026-04-12"
parent: "S000003_structural_completeness"
repo: "claude-skills-templates"
branch: ""
blocked_by: "T000003"
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
- [ ] Working branch created (`branch` field populated)
- [x] Files section populated

### Phase 2: Implement

1. Work from parent's acceptance criteria + your Todos
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify no regressions
2. Run tests: `./scripts/test.sh` (or project-specific test command)
3. Run `/review` for code review (if PR exists)

❌ If tests fail: fix, re-run

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] Test verification passed
- [ ] `/review` — code review passed

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [ ] Verify MISPLACED AC: create a temporary task directly under a feature, confirm `/docs check` flags it as MISPLACED, then remove
- [ ] Run `./scripts/test.sh` — check off S000003 Phase 3 "Test verification passed" gate
- [ ] Run `/docs check` — verify TEST-SPEC covers all P0 stories, check off S000003 Phase 3 "Doc triplet alignment" gate
- [ ] Close S000003 tracker (status: closed, all Phase 3 gates checked)

## Log

- 2026-04-12: Created. Final cleanup to close out S000003_structural_completeness.

## PRs

## Files

- work-items/F000001_workflow_alpha/S000003_structural_completeness/S000003_TRACKER.md

## Insights

## Journal
