---
type: milestones
template-version: 1
parent: F000005_work_copilot
updated: 2026-04-22
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Design approved (office-hours + PRDs for 3 stories) | 2026-04-25 | Not Started | chjiang | Decide the exact Copilot surfaces, installer shape, and template delivery path | — |
| 2 | Prompt packaging shipped (S000007) | 2026-05-02 | Not Started | chjiang | `.prompt.md` that mirrors `/company-workflow check`; reads templates + manifest | #1 |
| 3 | Template delivery + install (S000008) | 2026-05-06 | Not Started | chjiang | Templates land in target repo's `.github/prompts/`; installer works on Windows | #1 |
| 4 | Always-on instructions (S000009) | 2026-05-06 | Not Started | chjiang | `copilot-instructions.md` with work-item conventions (hierarchy, naming, lifecycle) | #1 |
| 5 | End-to-end verification on work machine | 2026-05-08 | Not Started | chjiang | Install on the Windows work box, scaffold + validate a real work item via Copilot chat | #2, #3, #4 |
| 6 | Feature shipped (`/ship` + `/land-and-deploy`) | 2026-05-10 | Not Started | chjiang | Merge to main, tag, update catalog | #5 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 design approved
      |
      +--> #2 prompt packaging (S000007) ---+
      |                                      |
      +--> #3 template delivery (S000008) ---+--> #5 work-machine verify --> #6 ship
      |                                      |
      +--> #4 always-on instructions (S000009)
```
