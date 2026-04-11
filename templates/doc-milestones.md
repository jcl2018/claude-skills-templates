---
type: milestones
template-version: 1            # bump when template structure changes
parent: {USER_STORY_ID}        # the user story these milestones belong to
feature: {FEATURE_ID}          # the parent feature
updated: {YYYY-MM-DD}          # last update date
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here, not in scrum docs.
     Scrum docs embed a read-only snapshot; post-meeting sync (GENERATION-GUIDE Step 8)
     writes meeting changes back here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| {n} | {milestone name} ({optional task ID}) | {YYYY-MM-DD or —} | {status} | {person} | {context, scope, what "done" means} | {#n or —} |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
{ASCII dependency graph showing flow from left to right}
```
