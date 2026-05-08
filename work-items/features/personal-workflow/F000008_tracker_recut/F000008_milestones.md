---
type: milestones
template-version: 1
parent: F000008
updated: 2026-05-05
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | S000014: new templates + manifest + check.md updates land on branch | 2026-05-06 | Not Started | chjiang | doc-SPEC.md + doc-ROADMAP.md created; 4 old doc templates deleted; manifest v3.0.0; check.md Step 18 (5 line edits) + 4 incidentals; WORKFLOW.md 7 lines | — |
| 2 | S000015: 13 historical work items + F000008 itself swept to new shape | 2026-05-07 | Not Started | chjiang | 5 features → ROADMAP merge; 8 user-stories → SPEC merge + DESIGN stubs; F000008's feature-summary+milestones → ROADMAP; F000008's children's PRD+ARCH → SPEC | #1 |
| 3 | S000016: examples + fixtures + repo-level surfaces updated | 2026-05-07 | Not Started | chjiang | example-doc-{SPEC,ROADMAP}.md created, 4 example docs deleted, 2 example trackers rewritten; PHILOSOPHY/CONTRIBUTING/template-registry/scripts updated | #1 |
| 4 | `/personal-workflow check` + `./scripts/test.sh` + `./scripts/validate.sh` all pass | 2026-05-08 | Not Started | chjiang | Acceptance gate before /ship | #2, #3 |
| 5 | VERSION bump v1.5.0 + CHANGELOG entry | 2026-05-08 | Not Started | chjiang | Done as part of /ship workflow | #4 |
| 6 | /ship + /land-and-deploy | 2026-05-08 | Not Started | chjiang | Single sweep PR; auto-merge after CI; remote branch cleanup per CLAUDE.md note | #5 |

## Dependency Graph

```
#1 (S000014: templates + manifest + check.md)
   ├──> #2 (S000015: historical migration including F000008 self-migration)
   └──> #3 (S000016: examples + fixtures + repo-level surfaces)
              ↓ (both required)
              #4 (validation + check pass)
                 ↓
                 #5 (version + changelog)
                    ↓
                    #6 (ship + deploy)
```
