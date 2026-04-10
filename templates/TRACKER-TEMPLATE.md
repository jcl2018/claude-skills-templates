---
name: "{ITEM_NAME}"
type: {feature|defect|task|user-story}
id: "{ITEM_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [ ] Scoped (acceptance criteria defined)
- [ ] Working branch created (`branch` field populated)
- [ ] Doc triplet created (PRD + ARCHITECTURE + TEST-SPEC) or N/A for small items
- [ ] Tasks broken down (child items created, if applicable)

### Phase 2: Implement
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] All child tasks completed or deferred
- [ ] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix
- [ ] Doc triplet passes /align-feature-contract (if applicable)

### Phase 4: Ship
- [ ] Tests pass
- [ ] Code review completed
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Acceptance Criteria

<!-- What "done" looks like. Each criterion should be testable and specific. -->

- [ ] {criterion}

## Todos

<!-- Actionable items. Break into child tasks for large features. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track, updated during Implement. -->

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

## Journal

<!-- Structured entries from /work-track journal. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
