---
name: "Uncovered AC Fixture"
type: user-story
workflow_type: user-story
id: "S999001"
status: active
created: "2026-05-11"
updated: "2026-05-11"
url: ""
repo: "test-repo"
branch: "feat/test"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Story scoped (acceptance criteria defined)
- [x] Working branch created (`branch` field populated)
- [x] Tasks broken down (child task items created if needed)

### Phase 2: Implement
- [ ] Core implementation committed (>=1 commit SHA in Log)
- [ ] Acceptance criteria met
- [ ] All P0 cases in TEST-SPEC.md marked Pass; remaining cases marked Pending/Skip with reason
- [ ] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Acceptance Criteria

<!-- One AC per PRD story; one of them (AC-3) has no test row so /wc-qa flags it as uncovered. -->

- [ ] AC-1: feature loads
- [ ] AC-2: feature accepts input
- [ ] AC-3: feature exports CSV (uncovered by TEST-SPEC — /wc-qa should flag this)

## Todos

- [ ] Wire up the export endpoint (AC-3)

## Log

- 2026-05-11: Created. Fixture for /wc-qa uncovered-AC diagnostic.

## PRs

## Files

## Insights

- AC-3 deliberately has no TEST-SPEC row so /wc-qa exercises the "uncovered AC" warning path.

## Journal

<!-- Empty on first run — /wc-qa's first-run fallback uses receipts.scaffold SHA. -->
