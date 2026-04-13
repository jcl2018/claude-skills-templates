---
type: milestones
template-version: 1
parent: S000001_workflow_implementation
feature: F000001_workflow_alpha
updated: 2026-04-13
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Workflow router skill (SKILL.md + 4 subcommands) | — | Done | chjiang | Branch detection, work item resolution, phase detection, status menu | — |
| 2 | Template consolidation (4 tracker templates) | — | Done | chjiang | Solo-dev gates, removed review type, removed scrum, structured IDs | — |
| 3 | Add hierarchy field to artifact-manifests.json | — | Done | chjiang | Schema: feature->user-story (min 1), user-story->task (min 1) | — |
| 4 | Separate claims.json gate in check.md | — | Done | chjiang | Steps 1-5 skip if missing, Steps 6+ run regardless | — |
| 5 | Implement Steps 15-17 in check.md | — | Done | chjiang | Structural check + orphan detection, tree report, graph artifact | #3, #4 |
| 6 | Add badge taxonomy mapping | — | Done | chjiang | Map all existing statuses to 4 badge categories with severity | #5 |
| 7 | Add lifecycle cross-reference | — | Done | chjiang | "Broken down" checked + 0 children = LIFECYCLE_INCONSISTENT | #5 |
| 8 | Create tree.md + SKILL.md routing | — | Done | chjiang | /docs tree standalone subcommand, structural badges only | #5 |
| 9 | Human-readable report (Step 19) | — | Done | chjiang | .docs/work-item-report.md with tree, badge summary, findings | #5 |
| 10 | Update catalog + validate | — | Done | chjiang | Version bumps, test suite passes | #8 |
| 11 | Remove GENERATION-GUIDE templates | — | Done | chjiang | Deleted template, cleaned references in catalog/CLAUDE.md/PHILOSOPHY.md | — |
| 12 | Update tracker template Phase 1 + Phase 2 | — | Done | chjiang | Required doc lists per type, /office-hours design doc reference | — |
| 13 | Make doc triplet self-contained | — | Done | chjiang | PRD/ARCHITECTURE/TEST-SPEC expanded to cover all 3 consolidated areas | — |

## Dependency Graph

```
#1 workflow router ──────────────────────────────────────────────► #10 catalog
#2 template consolidation ───────────────────────────────────────► #10
#3 hierarchy field ──┐
                     ├──► #5 Steps 15-17 ──┬──► #6 badge taxonomy
#4 claims gate ──────┘                     ├──► #7 lifecycle xref
                                           ├──► #8 tree.md ──────► #10
                                           └──► #9 report
#11 GENERATION-GUIDE cleanup (independent)
#12 tracker template updates (independent)
#13 doc triplet update (independent)
```
