---
name: "{DEFECT_NAME}"
type: defect
id: "{DEFECT_ID}"
status: active
created: "{YYYY-MM-DD}"
updated: "{YYYY-MM-DD}"
repo: "{REPO_PATH}"
branch: "{BRANCH_NAME}"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [ ] Reproduction steps documented
- [ ] Working branch created (`branch` field populated)
- [ ] Initial symptom logged in Log

### Phase 2: Implement
- [ ] Root cause identified (RCA in Insights section)
- [ ] Hypothesis tested with evidence (finding entries in Journal)
- [ ] Fix committed (>=1 commit SHA in Log)
- [ ] Regression test added
- [ ] Files section updated

### Phase 3: Review
- [ ] Doc review completed
- [ ] Doc generation finalized
- [ ] Test verification passed

### Phase 4: Ship
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

<!-- Steps to reproduce the defect. Include environment details. -->

1. {step}

## Todos

<!-- Actionable items for this defect fix. -->

- [ ] {todo}

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- {YYYY-MM-DD}: Created. {brief defect description}

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

## Insights

<!-- Root cause analysis, patterns discovered, related defects. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->
