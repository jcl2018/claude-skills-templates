---
type: milestones
template-version: 1
parent: S000005_scaffold_work_items
feature: F000003_company_spec_system
updated: 2026-04-12
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Add create subcommand to SKILL.md | — | Not Started | chjiang | Template reading + placeholder substitution + artifact mapping | S000003 |
| 2 | Implement ID generation | — | Not Started | chjiang | Scan work-items/ for highest prefix, increment | #1 |
| 3 | Run E2E tests E1-E5 (one per type) | — | Not Started | chjiang | Scaffold + validate for each of 5 types | #1, #2 |
| 4 | Run E2E test E8 (all types in sequence) | — | Not Started | chjiang | Full integration test | #3 |

## Dependency Graph

```
S000003 (templates in place) ──→ #1 Create subcommand ──→ #2 ID generation
                                                               │
                                                    ┌──────────┘
                                                    ▼
                                              #3 E2E per type ──→ #4 Full sequence
```
