---
type: milestones
template-version: 1
parent: S000003_template_registry
feature: F000003_company_spec_system
updated: 2026-04-11
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Copy company templates to templates/company-workflow/ | — | Not Started | chjiang | 13 files from ~/Downloads/spec/templates/ | — |
| 2 | Create template-registry.json | — | Not Started | chjiang | Declare `templates` and `company-workflow` sets | #1 |
| 3 | Verify root templates unchanged | — | Not Started | chjiang | git diff templates/*.md shows empty | #1 |

## Dependency Graph

```
#1 Copy templates ──→ #2 Create registry
      │
      └──→ #3 Verify root unchanged
```
