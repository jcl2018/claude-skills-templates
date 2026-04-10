---
type: prd
feature: work-pipeline
title: "Work Pipeline — Product Requirements"
version: 1
status: Active
date: 2026-04-09
author: chjiang
---

## Problem Statement

Claude Code sessions are stateless: context about what you are working on, why, and what phase you are in is lost between sessions. Without a structured work lifecycle, implementation starts without requirements, reviews lack context, and shipping has no acceptance gate. The repo owner needs a phase-driven pipeline that tracks work items from idea through shipped.

## Mental Model

Five skills form the pipeline: `/work` (router) detects current phase from branch and manifest state. Four phase skills handle the lifecycle: Track (capture and scaffold) -> Implement (build or debug) -> Review (diff review with context) -> Ship (acceptance gate + PR). Quality gates are provided by `/system-health --scope`. Each phase skill loads work item context automatically. Journal entries record decisions at each transition.

## User Stories

### P0 (Must-Have)

| # | Tag | What it asks | As a... | I want to... | So that... |
|---|-----|-------------|---------|-------------|------------|
| 1 | core | Can I scaffold a work item with doc triplets? | developer | run `/work-track` to create a tracked work item with PRD + ARCH + TEST-SPEC from templates | every work item starts with structured requirements |
| 2 | core | Does /work route to the correct phase? | developer | run `/work` and have it detect my current phase and suggest the right skill | I never have to remember which skill to invoke |
| 3 | core | Does /work-implement load work context? | developer | start implementing and have the skill auto-load my PRD, architecture, and journal | I have full context without manual file hunting |
| 4 | integration | Does /work-ship validate acceptance criteria? | developer | have shipping blocked until TEST-SPEC acceptance criteria are met | nothing ships without passing its own spec |
| 5 | observability | Does the journal track phase transitions? | developer | have each phase skill append a timestamped journal entry | I can trace the history of decisions on any work item |

### P1 (Important)

None for v1.

### P2 (Nice-to-Have)

None for v1.

## Acceptance Criteria

### Story #1: Scaffold [core]

```
GIVEN templates/ contains PRD-TEMPLATE.md, ARCHITECTURE-TEMPLATE.md, TEST-SPEC-TEMPLATE.md
WHEN  I run /work-track to create a new work item
THEN  a docs/{family}/ directory is created with PRD.md, ARCHITECTURE.md, TEST-SPEC.md
  AND frontmatter fields are populated from the work item metadata
```

### Story #2: Router [core]

```
GIVEN I am on a branch with a work manifest
WHEN  I run /work
THEN  it displays the current phase and suggests the appropriate phase skill
```

### Story #3: Context loading [core]

```
GIVEN a work item exists with PRD.md, ARCHITECTURE.md, and a journal
WHEN  /work-implement starts
THEN  it loads the PRD, architecture, and journal into context automatically
```

### Story #4: Acceptance gate [integration]

```
GIVEN a work item has a TEST-SPEC.md with acceptance criteria
WHEN  /work-ship runs
THEN  it validates that acceptance criteria are met before proceeding
  AND it blocks shipping if criteria are not satisfied
```

### Story #5: Journal tracking [observability]

```
GIVEN a work item is in any phase
WHEN  a phase skill runs (track, implement, review, or ship)
THEN  a timestamped journal entry is appended to the work item's journal
  AND the entry records the phase, action taken, and key decisions
```

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|-------------|
| Work item completeness | Every work item has PRD + ARCH + TEST-SPEC | /system-health --scope validates structure |
| Phase coverage | All 4 phases used for shipped items | Journal shows track -> implement -> review -> ship |
| Acceptance gate hit rate | 100% of shipped items pass TEST-SPEC criteria | /work-ship validates before shipping |

## Out of Scope

- Multi-user collaboration on the same work item
- Integration with external issue trackers (GitHub Issues, Linear)

## Assumptions

- Work items live in the project repo at ./work-items/ (not in home-setup)
- Branch naming follows conventions: feature-*, feat-*, defect-*, fix-*, task-*, chore-*
- Templates are deployed to ~/.claude/templates/ and accessible during scaffolding
- The /review and /ship gstack skills are available for delegation
