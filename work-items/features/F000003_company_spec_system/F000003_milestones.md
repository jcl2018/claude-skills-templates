---
type: milestones
template-version: 1
parent: F000003_company_spec_system
updated: 2026-04-13
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Copy spec templates to templates/company-workflow/ | -- | Done | chjiang | 13 files from ~/Downloads/spec/templates/, byte-identical | -- |
| 2 | Create template-registry.json | -- | Done | chjiang | Declares workbench + company-workflow sets | #1 |
| 3 | Create skills/company-workflow/ scaffold | -- | Done | chjiang | SKILL.md, contract.json, reference/, philosophy/, fixtures/ | #1 |
| 4 | Add catalog entry + verify zero regression | -- | Done | chjiang | validate.sh PASS, test.sh PASS, root templates unchanged | #2, #3 |
| 5 | Create company-artifact-manifests.json | -- | Not Started | chjiang | 5 type entries mirroring artifact-manifests.json structure | #3 |
| 6 | Implement check subcommand in SKILL.md | -- | Not Started | chjiang | Template parsing + comparison logic | #5 |
| 7 | Test enforcement against all 5 types | -- | Not Started | chjiang | Complete + incomplete work items per type | #6 |
| 8 | Verify /docs check independence | -- | Not Started | chjiang | Run before/after, identical output | #6 |
| 9 | Add create subcommand to SKILL.md | -- | Not Started | chjiang | Template reading + placeholder substitution + artifact mapping | #3 |
| 10 | Implement ID generation | -- | Not Started | chjiang | Scan work-items/ for highest prefix, increment | #9 |
| 11 | Run E2E tests for all 5 types | -- | Not Started | chjiang | Scaffold + validate for each type | #9, #10 |

## Dependency Graph

```
#1 Copy templates --+-- #2 Registry --+-- #4 Verify regression
                    |                  |
                    +-- #3 Scaffold ---+
                         |
                         +-- #5 Manifest --> #6 Check --> #7 Test enforcement
                         |                           +--> #8 Independence check
                         |
                         +-- #9 Create --> #10 ID gen --> #11 E2E tests
```
