---
name: "{FEATURE_NAME}"
type: feature
id: "{FEATURE_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [ ] Acceptance criteria scoped
- [ ] Working branch created (`branch` field populated)
- [ ] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Broken down into child tasks/stories

### Phase 2: Implement
- [ ] Doc triplet read (build-forward mode)
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] Child tasks completed or deferred
- [ ] Files section updated

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

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
