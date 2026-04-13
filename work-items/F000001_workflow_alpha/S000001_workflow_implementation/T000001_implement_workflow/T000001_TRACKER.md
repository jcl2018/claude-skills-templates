---
name: "Workflow Alpha Implementation"
type: task
id: "T000001_implement_workflow"
status: closed
created: "2026-04-11"
updated: "2026-04-13"
parent: "S000001_workflow_implementation"
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
3. Update Todos section -- check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` -- verify no regressions
2. Run tests: `./scripts/test.sh` (or project-specific test command)
3. Run `/review` for code review (if PR exists)

**Gates:**
- [x] `/docs check` -- validation passed
- [x] Test verification passed

### Phase 4: Ship

1. Run `/ship` -- creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` -- merges PR and verifies deployment

**Gates:**
- [x] `/ship` -- PR created (#22, #24)
- [x] `/land-and-deploy` -- merged and deployed

## Todos

### Completed (from T000001 router)
- [x] SKILL.md: branch detection, work item resolution, phase detection, status menu
- [x] track.md: create, journal, milestones, list, close, child-items, evidence synthesis
- [x] implement.md: build-forward (features) + debug-backward (defects)
- [x] review.md: contract gate + gstack /review delegation
- [x] ship.md: /ship + /land-and-deploy delegation

### Completed (from T000002 structural check)
- [x] Add `hierarchy` field to artifact-manifests.json
- [x] Separate claims.json gate in check.md (Steps 1-5 skip if missing, Steps 6+ run)
- [x] Add Step 15: structural completeness check + orphan/misplaced detection + placement rules
- [x] Add Step 16: completeness counts + tree report with all 4 badges per node
- [x] Add Step 17: graph artifact emission to `.docs/work-item-graph.json`
- [x] Add badge taxonomy mapping (all existing statuses -> 4 categories with severity)
- [x] Add lifecycle cross-reference ("broken down" checked + 0 children = LIFECYCLE_INCONSISTENT)
- [x] Create `skills/docs/tree.md` for `/docs tree` subcommand
- [x] Update `skills/docs/SKILL.md` with `/docs tree` routing
- [x] Update `skills-catalog.json` (version bump, add tree.md to files)

### Completed (from T000003 human-readable report)
- [x] Add Step 19 to check.md: write `.docs/work-item-report.md` after structural output
- [x] Report format: markdown with tree, badge summary table, findings by severity, structural summary
- [x] Update 4 tracker templates with runbook lifecycle phases
- [x] Migrate 8 existing trackers with checkbox state preservation
- [x] Add `.docs/` to .gitignore, untrack existing .docs/ files

### Remaining (from T000004 close-out)
- [x] Run `/docs check` -- verify consolidated hierarchy passes
- [x] Run `./scripts/test.sh` -- full validation (PASS, 0 failures)

## Log

- 2026-04-11: Created as T000001_router_implementation. Router + 4 subcommand files.
- 2026-04-11: T000002 structural check implemented (154a4b3).
- 2026-04-12: T000003 human-readable report shipped (#24).
- 2026-04-13: Consolidated T000001-T000004 into single task. All implementation complete, review gates remaining.
- 2026-04-13: Closed. Tests pass, PRs #22 and #24 merged to main.

## PRs

- #22 -- feat: structural completeness check, tree report, and graph artifact
- #24 -- feat: human-readable report + runbook lifecycle phases

## Files

- skills/docs/check.md
- skills/docs/tree.md
- skills/docs/SKILL.md
- artifact-manifests.json
- skills-catalog.json
- templates/tracker-feature.md
- templates/tracker-defect.md
- templates/tracker-task.md
- templates/tracker-user-story.md
- .gitignore

## Insights

## Journal
