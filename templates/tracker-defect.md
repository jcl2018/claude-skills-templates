---
name: "{DEFECT_NAME}"
type: defect
workflow_type: defect
id: "{DEFECT_ID}"
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
- [ ] Defect scoped (reproduction steps documented)
- [ ] Working branch created (`branch` field populated)
- [ ] Symptom documented in Log

### Phase 2: Implement
- [ ] Root cause identified (RCA in Insights section)
- [ ] Hypothesis tested with evidence (finding entries in Journal)
- [ ] Fix committed (>=1 commit SHA in Log)
- [ ] Regression test added
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
