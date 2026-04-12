---
type: milestones
template-version: 1
parent: ""
feature: F000003_company_spec_system
updated: 2026-04-11
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Copy spec templates to templates/company-workflow/ (T000002) | — | Not Started | chjiang | One-time import from ~/Downloads/spec/templates/, 13 files | — |
| 2 | Create skills/company-workflow/ scaffold (T000002) | — | Not Started | chjiang | SKILL.md, contract.json, reference/, philosophy/, fixtures/ | — |
| 3 | Create template-registry.json (S000003) | — | Not Started | chjiang | Declares `templates` and `company-workflow` sets | #1 |
| 4 | Add catalog entry for company-workflow | — | Not Started | chjiang | Update skills-catalog.json | #2 |
| 5 | Implement validation entry point | — | Not Started | chjiang | company-workflow validate → exit 0/1 | #2 |
| 6 | Verify zero regression | — | Not Started | chjiang | validate.sh + test.sh pass, existing templates unchanged | #1, #3, #4 |
| 7 | Test skills-deploy subfolder support | — | Not Started | chjiang | If fails, create T000003 | #1, #2 |

## Dependency Graph

```
#1 Copy templates ──→ #3 Registry ──→ #6 Verify regression
      │                                    ↑
      └──→ #2 Skill scaffold ──→ #4 Catalog ──┘
                │
                └──→ #5 Validation
                │
                └──→ #7 Deploy test
```
