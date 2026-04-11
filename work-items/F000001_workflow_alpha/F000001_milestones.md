---
type: milestones
template-version: 1
parent: ""
feature: F000001_workflow_alpha
updated: 2026-04-11
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Router + shared context resolution | — | Done | chjiang | SKILL.md: branch detection, work item lookup, phase detection, status menu | — |
| 2 | Track subcommand | — | Done | chjiang | create, journal, milestones, list, close, scrum, child-items | — |
| 3 | Implement subcommand | — | Done | chjiang | Build-forward (features) + debug-backward (defects) | — |
| 4 | Review subcommand | — | Done | chjiang | Contract gate → delegates to gstack /review | #1 |
| 5 | Ship subcommand | — | Done | chjiang | TEST-SPEC validation + contract gate → delegates to gstack /ship | #1 |
| 6 | v1 documentation | 2026-04-11 | In Progress | chjiang | This work item: PRD + ARCHITECTURE + TEST-SPEC | #1, #2, #3, #4, #5 |
| 7 | Final E2E validation | 2026-04-11 | In Progress | chjiang | Create work item using workflow itself, run contracts + tests | #6 |

## Dependency Graph

```
#1 Router ──> #4 Review
          ──> #5 Ship
#2 Track (independent)
#3 Implement (independent)
#1, #2, #3, #4, #5 ──> #6 Documentation ──> #7 E2E Validation
```
