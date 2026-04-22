---
type: milestones
template-version: 1
parent: F000004
updated: 2026-04-21
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
| 4 | Implement resolution + surfacing (company-workflow) | 2026-04-20 | Done | chjiang | S000004 shipped (PR #38 v0.11.0); S000005 shipped in two slices (PR #40 v0.12.0 always-on + opt-in gate; PR #41 v0.13.0 on-demand matching) | #3 |
| 5 | ~~Seed knowledge folder~~ | — | **Dropped 2026-04-21** | chjiang | Workbench repo; `$AI_KNOWLEDGE_DIR` is user-owned + external by design; committing seed content would blur the boundary drawn in the 2026-04-19 fixture-scope decision. The 5-line quick-start in WORKFLOW.md + `knowledge-doctor` diagnostic already prove a valid layout end-to-end. Reopen with a new milestone if a user reports the layout isn't discoverable | #3 |
| 6 | Graceful degradation when folder absent | 2026-04-20 | Done | chjiang | Verified: unset / not-found / not-a-dir all emit warning + exit 0; scripts/test.sh case 11 asserts validate stdout byte-identical. Personal-workflow arm deferred with S000006 | #4 |
| 7 | Document in SKILL.md + WORKFLOW.md | 2026-04-20 | Done | chjiang | Company-workflow: `## Knowledge Configuration` in WORKFLOW.md with quick-start, troubleshooting, escape hatches, schema, trigger-authoring, security, caps, doctor. Personal-workflow arm deferred with S000006 | #4, #5 |
| 8 | ~~Parity port to /personal-workflow (S000006)~~ | — | **Deferred 2026-04-20** | chjiang | /autoplan dual-voice CEO review returned 5/6 CONFIRMED-NO. Evidence gate: reopen when a specific personal-repo task where missing knowledge-loading is an observed blocker surfaces. Artifacts retained for resumability. See F000004_TRACKER.md Log 2026-04-20 entry for full rationale | #4, #7 |
| 9 | Ship | 2026-04-21 | Done | chjiang | All S000004 + S000005 PRs merged to main (#38, #40, #41). Feature closed 2026-04-21 after milestone #5 dropped | #6, #7 |

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 Scope --> #2 Design surfacing --> #3 Decompose stories --+--> #4 Implement --+--> #6 Graceful degradation --+
                                                            |                   |                              |
                                                            |                   +--> #7 Document --------------+--> #9 Ship (closed 2026-04-21)
                                                            |
                                                            +--> #5 Seed (DROPPED — external by design)
                                                            +--> #8 Port to /personal-workflow (DEFERRED — evidence gate)
```
