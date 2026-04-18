---
type: milestones
template-version: 1
parent: S000006_on_demand_matching
feature: F000004
updated: 2026-04-16
---

## Milestones

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Refactor S000005's yml parser + file enumeration into a shared helper | — | Not Started | chjiang | Avoid duplication across always-on + on-demand; single source of truth for `.knowledge.yml` subset | — |
| 2 | Draft the exact Claude-facing instruction text for matching + Read | — | Not Started | chjiang | Must specify: tokenization rule, single-vs-phrase trigger handling, case-insensitivity, match log format | — |
| 3 | Add On-Demand Matching section to SKILL.md | — | Not Started | chjiang | Bash block emits `## On-Demand Knowledge Candidates`; instruction block tells Claude to match + Read | #1, #2 |
| 4 | Extend fixture `valid-knowledge-dir/` with on-demand categories | — | Not Started | chjiang | Cases: single-word trigger, phrase trigger, empty-triggers, malformed-yml | — |
| 5 | Update WORKFLOW.md with on-demand schema + trigger-authoring guidance | — | Not Started | chjiang | Worked examples; matching semantics explained; security callout on prompt injection | #3 |
| 6 | Tier 1 smoke tests | — | Not Started | chjiang | 8 greps (see TEST-SPEC S1–S8) wired into `scripts/test.sh` | #3, #4 |
| 7 | Tier 2 E2E tests | — | Not Started | chjiang | 8 canary scenarios (see TEST-SPEC E1–E8) | #3, #4 |
| 8 | Regression check | — | Not Started | chjiang | Validate output on existing fixtures byte-identical w/ and w/o on-demand categories | #3 |
| 9 | PR + review + ship | — | Not Started | chjiang | Depends on S000004 + S000005 (via shared helper) | #6, #7, #8 |

## Dependency Graph

```
#1 Shared helper --+
                   +--> #3 SKILL.md matching block --+--> #6 Smoke tests --+
#2 Instruction text+                                 +--> #7 E2E tests ----+--> #9 Ship
                                                     +--> #8 Regression ---+
#4 Fixtures -------+
                   +--> #5 WORKFLOW.md docs
```
