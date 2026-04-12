---
name: "Human-readable work item health report"
type: task
id: "T000003_human_readable_report"
status: active
created: "2026-04-12"
updated: "2026-04-12"
parent: "S000003_structural_completeness"
repo: "claude-skills-templates"
branch: "feat/structural-completeness"
blocked_by: "T000002"
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

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Add Step 19 to check.md: write `.docs/work-item-report.md` after structural output
- [x] Report format: markdown with tree, badge summary table, findings by severity, structural summary
- [x] /docs tree writes `.docs/work-item-tree.md` (structural badges only)
- [x] Update 4 tracker templates with runbook lifecycle phases
- [x] Migrate 8 existing trackers with checkbox state preservation
- [x] Add `.docs/` to .gitignore, untrack existing .docs/ files
- [ ] Run `/docs check` to verify report output
- [ ] Run `./scripts/validate.sh` to confirm no regressions

## Log

- 2026-04-12: Created. Human-readable report to complement work-item-graph.json.
- 2026-04-12: Design doc approved via /office-hours (9/10 after adversarial review). Approach A: prose runbooks.
- 2026-04-12: Implemented. Step 19 in check.md, tree.md report, 4 templates + 8 trackers migrated, .docs/ gitignored.

## PRs

## Files

- skills/docs/check.md
- skills/docs/tree.md
- templates/tracker-task.md
- templates/tracker-user-story.md
- templates/tracker-feature.md
- templates/tracker-defect.md
- .gitignore
- work-items/ (all 8 TRACKER.md files migrated)

## Insights

## Journal
