---
name: "{FEATURE_NAME}"
type: feature
workflow_type: feature
id: "{FEATURE_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
url: "{JIRA_OR_TFS_URL}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [ ] Feature scoped (acceptance criteria defined)
- [ ] Working branch created (`branch` field populated)
- [ ] Feature summary + DESIGN + milestones created (feature-summary.md + DESIGN.md + milestones.md)
- [ ] Tasks broken down (child task items created)

### Phase 2: Implement
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] All child tasks completed or deferred
- [ ] Each child user-story's TEST-SPEC has all P0 cases Pass
- [ ] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix
- [ ] Feature summary + milestones pass alignment check (constituent user-stories listed; success criteria match nested PRDs)

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] {criterion}

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief feature description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
