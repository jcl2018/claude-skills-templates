---
name: "{TASK_NAME}"
type: task
id: "{TASK_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
parent: "{PARENT_ID}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
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
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- {YYYY-MM-DD}: Created. {brief scope from parent work item}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
