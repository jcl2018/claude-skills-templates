---
type: milestones
template-version: 1
parent: S000003_structural_completeness
feature: F000001_workflow_alpha
updated: 2026-04-11
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Add hierarchy field to artifact-manifests.json | — | Not Started | chjiang | Schema: feature→user-story (min 1), user-story→task (min 1) | — |
| 2 | Separate claims.json gate in check.md | — | Not Started | chjiang | Steps 1-5 skip if missing, Steps 6+ run regardless | — |
| 3 | Implement Steps 15-17 in check.md | — | Not Started | chjiang | Structural check + orphan detection, tree report, graph artifact | #1, #2 |
| 4 | Add badge taxonomy mapping | — | Not Started | chjiang | Map all existing statuses to 4 badge categories with severity | #3 |
| 5 | Add lifecycle cross-reference | — | Not Started | chjiang | "Broken down" checked + 0 children = LIFECYCLE_INCONSISTENT | #3 |
| 6 | Create tree.md + SKILL.md routing | — | Not Started | chjiang | /docs tree standalone subcommand, structural badges only | #3 |
| 7 | Update catalog + validate | — | Not Started | chjiang | Version bump, add tree.md, run validate.sh | #6 |

## Dependency Graph

```
#1 hierarchy field ──┐
                     ├──► #3 Steps 15-17 ──┬──► #4 badge taxonomy
#2 claims gate ──────┘                     ├──► #5 lifecycle xref
                                           └──► #6 tree.md ──► #7 catalog
```
