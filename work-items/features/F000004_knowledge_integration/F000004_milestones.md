---
type: milestones
template-version: 1
parent: F000004_knowledge_integration
feature: F000004
updated: 2026-04-16
---

## Milestones
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here, not in scrum docs.
     Scrum docs embed a read-only snapshot; post-meeting sync (GENERATION-GUIDE Step 8)
     writes meeting changes back here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Scope knowledge concept + folder convention | 2026-04-16 | Done | chjiang | `AI_KNOWLEDGE_DIR` env var; flexible top-level categories; nesting allowed; warn every invocation when unset | — |
| 2 | Design surfacing mechanism | 2026-04-16 | Done | chjiang | Two-tier: always-on + on-demand. Per-category `.knowledge.yml` with `surface` + `triggers`. Natural-language match (case-insensitive whole-word, quoted phrases). See F000004_TRACKER.md Journal for full rationale | #1 |
| 3 | Decompose into child user-stories | 2026-04-16 | Done | chjiang | S000004 (resolution), S000005 (always-on loading), S000006 (on-demand matching) all scaffolded with 5 artifacts each | #2 |
| 4 | Implement resolution + surfacing | — | Not Started | chjiang | Child user-story implementation (see decomposition) | #3 |
| 5 | Seed knowledge folder | — | Not Started | chjiang | One cpp coding guide file + one company domain stub, plus a fixture demonstrating valid layout | #3 |
| 6 | Graceful degradation when folder absent | — | Not Started | chjiang | Verify zero regression for existing validate/scaffolding flows with no knowledge folder configured | #4 |
| 7 | Document in SKILL.md + WORKFLOW.md | — | Not Started | chjiang | User-facing docs for where the folder lives, the convention, and how knowledge gets surfaced | #4, #5 |
| 8 | Ship | — | Not Started | chjiang | PR, review, merge | #6, #7 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 Scope --> #2 Design surfacing --> #3 Decompose stories --+--> #4 Implement --+--> #6 Graceful degradation --+
                                                            |                   |                              |
                                                            +--> #5 Seed -------+--> #7 Document --------------+--> #8 Ship
```
