---
type: milestones
template-version: 1
parent: S000005_always_on_loading
feature: F000004
updated: 2026-04-16
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Finalize injection mechanism | — | Not Started | chjiang | Confirm architecture decision: skill emits paths, Claude reads via Read tool | — |
| 2 | Define `.knowledge.yml` supported subset | — | Not Started | chjiang | `surface: always \| on-demand`, `triggers: [list]`; flat keys only; document what's unsupported | — |
| 3 | Build fixtures | — | Not Started | chjiang | `valid-knowledge-dir/` with always-on category, on-demand category, missing-yml category, malformed-yml category | #2 |
| 4 | Add Knowledge Loading section to SKILL.md | — | Not Started | chjiang | Bash block for enumeration + parsing + emit; Claude-facing instruction to Read listed paths | #1, #2 |
| 5 | Update WORKFLOW.md with `.knowledge.yml` schema and always-on example | — | Not Started | chjiang | One worked example; link to fixture | #4 |
| 6 | Tier 1 smoke tests | — | Not Started | chjiang | 7 greps (see TEST-SPEC S1–S7) wired into `scripts/test.sh` | #3, #4 |
| 7 | Tier 2 E2E tests | — | Not Started | chjiang | 4 canary-based scenarios (see TEST-SPEC E1–E4) | #3, #4 |
| 8 | Regression check on existing fixtures | — | Not Started | chjiang | `fixtures/valid-feature-dir/` validate output byte-identical w/ and w/o empty knowledge dir | #4 |
| 9 | PR + review + ship | — | Not Started | chjiang | Depends on S000004 landing first | #6, #7, #8 |

## Dependency Graph

```
#1 Mechanism decision --+
                        +--> #4 SKILL.md loading block --+--> #6 Smoke tests --+
#2 yml subset -----------+                               +--> #7 E2E tests ----+--> #9 Ship
                         |                               +--> #8 Regression ---+
                         +--> #3 Fixtures ---------------+
                                                         +--> #5 WORKFLOW.md docs
```
