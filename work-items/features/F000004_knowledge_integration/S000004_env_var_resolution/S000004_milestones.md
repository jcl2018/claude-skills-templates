---
type: milestones
template-version: 1
parent: S000004_env_var_resolution
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
| 1 | Draft warning text | — | Not Started | chjiang | One line, ≤100 chars, names `AI_KNOWLEDGE_DIR`, points to WORKFLOW.md anchor | — |
| 2 | Add Knowledge Resolution section to SKILL.md | — | Not Started | chjiang | After Path Resolution, before Template Registry; exposes `$_KNOWLEDGE_DIR`; emits warning on unset/invalid | #1 |
| 3 | Document `AI_KNOWLEDGE_DIR` in WORKFLOW.md | — | Not Started | chjiang | Under Installation; include one-liner export example, explain always-on vs on-demand coming in later stories | #2 |
| 4 | Write Tier 1 smoke tests | — | Not Started | chjiang | 6 grep-based checks (see TEST-SPEC S1–S6); wire into `scripts/test.sh` | #2, #3 |
| 5 | Write Tier 2 E2E tests | — | Not Started | chjiang | 4 scenarios (unset / valid / bad-path / file-not-dir) | #2 |
| 6 | Regression check | — | Not Started | chjiang | Diff validate output on existing fixtures with env unset vs set-valid; assert byte-identical | #2 |
| 7 | PR + review + ship | — | Not Started | chjiang | Follows company-workflow Phase 3 + 4 gates | #4, #5, #6 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 Warning text --> #2 SKILL.md resolution block --+--> #3 WORKFLOW.md docs --+
                                                   |                          |
                                                   +--> #4 Smoke tests -------+
                                                   |                          |
                                                   +--> #5 E2E tests ---------+--> #7 Ship
                                                   |                          |
                                                   +--> #6 Regression check --+
```
