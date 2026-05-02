---
type: scrum-meeting
template-version: 1            # bump when template structure changes
parent: {FEATURE_ID}          # e.g., F12345 — the feature this scrum tracks
date: {YYYY-MM-DD}            # meeting date
attendees:                     # who was in the meeting
  - {name}
next_meeting: {YYYY-MM-DD}    # scheduled next meeting date
prev_scrum: {filename}         # e.g., scrum-2026-03-26.md — for carried-forward items
---

## Feature: {Feature Name} ({FEATURE_ID})

## Progress This Period
<!-- GENERATION: Pull from git log --since={prev_meeting_date} across tracked branches
     in the feature's branches: field. Group commits by milestone/task ID. -->

| Item | Status | Update |
|------|--------|--------|
| {milestone or task name} ({ID}) | {Done/In Progress/Blocked} | {what happened since last meeting} |

## Decisions
<!-- Record decisions made DURING the meeting. Each row = one decision.
     Impact = what changes as a result of this decision. -->

| Decision | Impact |
|----------|--------|
| {what was decided} | {what changes because of this} |

## Discussion
<!-- Topics discussed in the meeting that aren't decisions or action items.
     Capture key points, questions raised, and deferred topics. -->

- {topic}: {key points}

## Milestones
<!-- GENERATION: Snapshot from milestones.md. Notes column intentionally omitted for
     brevity — the scrum snapshot focuses on status, not descriptions. Dates abbreviated
     to MM/DD (year context is obvious in-meeting); canonical milestones.md uses YYYY-MM-DD. -->

| # | Milestone | Target | Status | Owner | Blocked By |
|---|-----------|--------|--------|-------|------------|
| {n} | {name} | {MM/DD} | {Done/In Progress/Not Started/At Risk} | {person} | {#n or —} |

{summary line: e.g., "Pre-Alpha: #3->#4 and #7 feed into #8 (UI Alpha). Post-Alpha: #9 and #10."}

## PRs
<!-- GENERATION: Pull from feature item's ## PRs section and check tracked branches.
     Snapshot at meeting time — PRs may change after. -->

| PR | Branch | Status | Owner | Notes |
|----|--------|--------|-------|-------|
| {PR# or description} | {branch name} | {Open/In Review/Merged/Closed} | {person} | {context} |

## Risk Flags
<!-- GENERATION: Auto-detect from milestone dates, branch staleness, unstarted items.
     Severity: HIGH (past due, blocked), MEDIUM (approaching, stale), LOW (informational).
     Items carried 3+ meetings auto-generate a MEDIUM risk flag. -->

- **{SEVERITY}:** {description of risk}

## Action Items
<!-- Items from previous meeting that are still open get "(carried since MM/DD)" tag.
     GENERATION: Read prev_scrum's Action Items, carry forward any with Status != Done.
     The date is when the action was originally created, not when it was last carried. -->

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| {action from last meeting still open} | {person} | {date} | Open (carried since {MM/DD}) |
| {new action from this meeting} | {person} | {date} | Open |

---

## Example: Filled-in scrum doc (F12345, 2026-03-26)

Below is a concrete example of what this template looks like when populated for
a real meeting. Use this as a reference when filling in your own.

```
## Feature: User Dashboard Redesign (F12345)

## Progress This Period

| Item | Status | Update |
|------|--------|--------|
| #2 Data layer refactor (T12300) | In Progress | PR#100 merged. Ready to integrate with UI PR |
| #3 New layout (S12345) | In Progress | Regression passed. First version ready to merge |

## Decisions

| Decision | Impact |
|----------|--------|
| Ready to merge both PRs (#2 data + #3 layout) | Land the first working version this week |
| Alice takes table view (#4) | Alice owns responsive table for mobile and desktop |

## Discussion

- Next priority after merge: table view (#4)
- API optimization (#5) can proceed in parallel
- Initial table view spec: two modes (compact, expanded), must support 1k+ rows

## Milestones

| # | Milestone | Target | Status | Owner | Blocked By |
|---|-----------|--------|--------|-------|------------|
| 1 | Feature planning | 02/27 | Done | Bob | — |
| 2 | Data layer refactor (T12300) | 02/27 | In Progress | Bob | — |
| 3 | New layout (S12345) | 03/27 | In Progress | Alice | — |
| 4 | Responsive table view | TBD | Not Started | Alice | #3 |

## PRs

| PR | Branch | Status | Owner | Notes |
|----|--------|--------|-------|-------|
| PR#101 | alice/S12345-layout | Ready to merge | Alice | New layout + data integration |
| PR#102 | alice/S12345-tests | Ready to merge | Alice | Test coverage for new layout |

## Risk Flags

- **MEDIUM:** Milestone #2 target (02/27) passed — work done, waiting to merge.

## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| Merge PR#101 + PR#102 | Bob + Alice | 03/28 | Open |
| Finalize specs for table view (#4) | Alice + Bob | — | Open |
```
