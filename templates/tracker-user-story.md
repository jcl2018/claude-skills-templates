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
- [ ] Acceptance criteria defined
- [ ] Working branch created (`branch` field populated)
- [ ] Doc triplet produced (PRD + ARCHITECTURE + TEST-SPEC)
- [ ] Milestones created
- [ ] Tasks broken down (if needed)

### Phase 2: Implement
- [ ] Build-forward mode (from doc triplet + acceptance criteria)
- [ ] Implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria verified met

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Doc triplet alignment check (TEST-SPEC)

### Phase 4: Ship
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
