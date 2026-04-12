---
name: "{STORY_NAME}"
type: user-story
id: "{STORY_ID}"
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

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Extract from design doc into doc triplet: requirements → `PRD.md`, architecture decisions → `ARCHITECTURE.md`, test scenarios → `TEST-SPEC.md`
   (use templates from `templates/doc-PRD.md`, `doc-ARCHITECTURE.md`, `doc-TEST-SPEC.md`)
6. Create milestones from PRD acceptance criteria
7. Break into child tasks if scope warrants decomposition

**Gates:**
- [ ] Acceptance criteria defined
- [ ] Working branch created (`branch` field populated)
- [ ] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Milestones created
- [ ] Tasks broken down (if needed)

### Phase 2: Implement

1. Work from doc triplet + acceptance criteria (build-forward mode)
2. Commit changes incrementally with descriptive messages
3. Update Todos section — remove completed items, add new discoveries
4. Update Files section with all changed file paths

**Gates:**
- [ ] Implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Review

1. Run `/docs check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/docs tree` — verify hierarchy and structural completeness
3. Run tests: `./scripts/test.sh`
4. Review TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
5. Run `/review` for code review (if PR exists)

❌ If `/docs check` finds issues: fix findings, re-run until clean

**Gates:**
- [ ] `/docs check` — validation passed
- [ ] `/docs tree` — structure verified
- [ ] Test verification passed
- [ ] Doc triplet alignment verified (TEST-SPEC covers P0 stories)
- [ ] `/review` — code review passed

### Phase 4: Ship

1. Run `/ship` — creates PR, bumps version, updates changelog
2. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] {criterion}

## Todos

<!-- Actionable items for this story. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief story description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Non-obvious findings worth remembering. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
