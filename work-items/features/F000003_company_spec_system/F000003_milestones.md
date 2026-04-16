---
type: milestones
template-version: 1
parent: F000003_company_spec_system
updated: 2026-04-15
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Copy spec templates to templates/company-workflow/ | -- | Done | chjiang | 13 files, byte-identical | -- |
| 2 | Create template-registry.json | -- | Done | chjiang | workbench + company-workflow sets | #1 |
| 3 | Create skills/company-workflow/ scaffold | -- | Done | chjiang | SKILL.md, contract.json, reference/, philosophy/, fixtures/ | #1 |
| 4 | Verify zero regression + catalog entry | -- | Done | chjiang | validate.sh + test.sh PASS | #2, #3 |
| 5 | Strip gstack from SKILL.md | -- | Done | chjiang | Zero gstack deps, standalone | #3 |
| 6 | Create company-artifact-manifests.json | -- | Done | chjiang | 5 type entries, mirrors artifact-manifests.json schema | #3 |
| 7 | Implement directory mode validate in SKILL.md | -- | Done | chjiang | Unified validate command (file + dir modes) | #6 |
| 8 | Fix templates (tracker-review.md, tracker-feature.md) | -- | Done | chjiang | Phase headings, remove Handoff, remove N/A language | #7 |
| 9 | Add directory fixtures + test verification | -- | Done | chjiang | valid-feature-dir/ + invalid-missing-artifact-dir/ | #7 |
| 10 | Doc-driven workflow in PRD | -- | Done | chjiang | 3-step workflow, validate usage at steps 1-2 | #7 |
| 11 | Delivery to work machine | -- | Done | chjiang | skills-deploy install deploys skill + templates | #9 |
| 12 | Create examples/ (1 per template) | -- | Pending | chjiang | 13 filled-in examples for AI doc generation | #7 |
| 13 | Close all children | -- | Done | chjiang | S000003 + T000002 closed, exemplary doc-driven dev | #10, #11, #12 |

## Dependency Graph

```
#1 Copy templates --+-- #2 Registry --+-- #4 Regression check
                    |                  |
                    +-- #3 Scaffold ---+-- #5 Strip gstack
                         |
                         +-- #6 Manifest --> #7 Dir validate --> #8 Fix templates
                                         |                   +--> #9 Dir fixtures
                                         |                          |
                                         +--> #10 Doc-driven PRD   +--> #11 Delivery
                                         |                                     |
                                         +--> #12 Examples ----+               |
                                                               |               |
                                                +-- #13 Close -+---------------+
```
