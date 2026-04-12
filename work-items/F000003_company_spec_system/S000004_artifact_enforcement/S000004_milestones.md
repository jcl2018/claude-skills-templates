---
type: milestones
template-version: 1
parent: S000004_artifact_enforcement
feature: F000003_company_spec_system
updated: 2026-04-11
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Create company-artifact-manifests.json | — | Not Started | chjiang | 5 type entries mirroring artifact-manifests.json structure | S000003 |
| 2 | Implement check subcommand in SKILL.md | — | Not Started | chjiang | Template parsing + comparison logic | #1 |
| 3 | Test enforcement against all 5 types | — | Not Started | chjiang | Complete + incomplete work items per type | #2 |
| 4 | Verify /docs check independence | — | Not Started | chjiang | Run before/after, identical output | #2 |

## Dependency Graph

```
S000003 (templates in place) ──→ #1 Create manifest ──→ #2 Implement check
                                                              │
                                                   ┌──────────┴──────────┐
                                                   ▼                     ▼
                                           #3 Test all types    #4 Verify independence
```
