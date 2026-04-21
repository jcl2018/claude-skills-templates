---
type: milestones
template-version: 1
parent: F000004
updated: 2026-04-20
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
| 3 | Decompose into child user-stories | 2026-04-20 | Done | chjiang | Originally 3 stories (S000004 resolution, S000005 always-on loading, S000006 on-demand matching). Consolidated 2026-04-19 → 2 stories (S000005 merged with on-demand). Extended 2026-04-20 → 3 stories with S000006_personal_workflow_port added for /personal-workflow parity. Now: S000004 + S000005 + S000006 | #2 |
| 4 | Implement resolution + surfacing (company-workflow) | — | In Progress | chjiang | S000004 landed (PR #38); S000005 in Phase 2 | #3 |
| 5 | Seed knowledge folder | — | Not Started | chjiang | One cpp coding guide file + one company domain stub, plus a fixture demonstrating valid layout | #3 |
| 6 | Graceful degradation when folder absent | — | Not Started | chjiang | Verify zero regression for existing validate/scaffolding flows with no knowledge folder configured — company-workflow AND personal-workflow | #4 |
| 7 | Document in SKILL.md + WORKFLOW.md | — | Not Started | chjiang | User-facing docs for where the folder lives, the convention, and how knowledge gets surfaced. Mirrored in both skills' WORKFLOW.md files | #4, #5 |
| 8 | ~~Parity port to /personal-workflow (S000006)~~ | — | **Deferred 2026-04-20** | chjiang | /autoplan dual-voice CEO review returned 5/6 CONFIRMED-NO. Evidence gate: reopen when a specific personal-repo task where missing knowledge-loading is an observed blocker surfaces. Artifacts retained for resumability. See F000004_TRACKER.md Log 2026-04-20 entry for full rationale | #4, #7 |
| 9 | Ship | — | Not Started | chjiang | PR, review, merge — per-story; feature closes when S000004 + S000005 have shipped (S000006 deferred) | #6, #7 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 Scope --> #2 Design surfacing --> #3 Decompose stories --+--> #4 Implement --+--> #6 Graceful degradation --+
                                                            |                   |                              |
                                                            +--> #5 Seed -------+--> #7 Document --------------+--> #9 Ship
                                                                                |
                                                                                +--> #8 Port to /personal-workflow (DEFERRED — evidence gate)
```
