---
type: roadmap
parent: F000010
title: "Personal-workflow pipeline skills — Roadmap"
date: 2026-05-08
author: chjiang
status: Draft
---

## Scope

Three new LLM-driven skills (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`) that automate steps 2, 3, 4 of the personal-workflow lifecycle defined in the May 5 tracker re-cut. Each skill takes a single path argument, reads handoff docs, internally delegates to fresh-context subagents where appropriate, and produces a clean handoff to the next step. Eliminates the two manual steps the user identified (design-doc → work-item, and E2E testing). User invokes the three skills sequentially with explicit path arguments — no orchestrator in v1 (captured as TODOS.md P3 follow-up).

## Non-Goals

- `/personal-pipeline` orchestrator wrapping the three skills — deferred per office-hours Approach A choice; captured as P3/M TODO. Decide after 2+ weeks of real use.
- Behavioral eval harness with golden tasks + regression fixtures — TODOS.md P1; deferred per Step 0A. Manual fixture-based tests in v1.
- Cross-machine support for non-script E2E — v2 generalization. v1 assumes script-driven smoke + LLM-judged E2E.
- Auto-iteration over child user-stories — rejected (Issue 1.2 option B); explicit per-user-story invocation only.
- `/office-hours` or `/ship` or `/land-and-deploy` integration — out per Premise 3; these stay outside the pipeline.
- Subagent validator in /scaffold-work-item and code reviewer in /implement-from-spec — already conditional in source design; defer until concrete failures motivate them.

## Success Criteria

- [ ] User can run `/scaffold-work-item <design-doc-path>` and produce a work-item directory that passes `/personal-workflow check` on the first run, with no manual edits required
- [ ] User can run `/implement-from-spec <user-story-dir>` on any user-story and the skill writes code per SPEC, updates the tracker journal, and transitions Phase 1 → Phase 2 lifecycle gates
- [ ] User can run `/qa-work-item <user-story-dir>` and the skill runs smoke (script-driven) + E2E (QA engineer subagent), writes structured findings to the tracker, and gates Phase 2 → Phase 3 transition on green smoke + green E2E
- [ ] Each skill is idempotent: invoking on already-completed input produces a no-op visible to the user (e.g., "F000010 already scaffolded; nothing to do")
- [ ] Each skill calls `/personal-workflow check <work-item-dir>` at start (refuses if input invalid) and end (errors if writes broke compliance)
- [ ] Each skill ships with one golden fixture in `skills/{name}/fixtures/`; manual snapshot-diff workflow documented in the skill's SKILL.md
- [ ] Bootstrap: re-scaffold F000010 via the new `/scaffold-work-item` after S000017 ships, output matches hand-scaffolded baseline (modulo timestamps and IDs)
- [ ] At least one full pipeline run on a real new work item before v1 declared ready

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000017](S000017_scaffold_work_item/S000017_TRACKER.md) | scaffold-work-item skill | Open |
| [S000018](S000018_implement_from_spec/S000018_TRACKER.md) | implement-from-spec skill | Open |
| [S000019](S000019_qa_work_item/S000019_TRACKER.md) | qa-work-item skill | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Hand-scaffold F000010 (this work item) | 2026-05-08 | Done | chjiang | Bootstrap to unblock S000017 design | — |
| 2 | Ship S000017 `/scaffold-work-item` | — | Not Started | chjiang | Gating skill; others depend on its output. Validate by re-scaffolding F000010 and diffing | #1 |
| 3 | Ship S000019 `/qa-work-item` | — | Not Started | chjiang | Validates QA engineer subagent pattern; smaller surface than implement | #2 |
| 4 | Ship S000018 `/implement-from-spec` | — | Not Started | chjiang | Riskiest skill (LLM non-determinism on code writes); benefits from validated handoff pattern | #3 |
| 5 | End-to-end pipeline run on a real work item | — | Not Started | chjiang | v1 readiness criterion; pick a new feature/defect and exercise scaffold → implement → qa | #4 |
| 6 | Decide on `/personal-pipeline` orchestrator (TODOS.md P3) | — | Deferred | chjiang | Revisit after 2+ weeks of real use of the three skills | #5 |

### Delivery History

<!-- Append-only record of merged PRs, version bumps, and ship dates. -->

- 2026-05-08: F000010 hand-scaffolded as bootstrap. No PR yet.

## Dependency Graph

```
#1 hand-scaffold F000010
        │
        ▼
#2 ship /scaffold-work-item (S000017)  ◄── gating skill; others read its outputs
        │
        ▼
#3 ship /qa-work-item (S000019)  ◄── validates QA-engineer subagent pattern early
        │
        ▼
#4 ship /implement-from-spec (S000018)  ◄── riskiest; benefits from validated pattern
        │
        ▼
#5 end-to-end pipeline run on a real work item
        │
        ▼
#6 decide on /personal-pipeline orchestrator (TODOS.md P3)
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Where does the QA engineer prompt template live (SKILL.md hardcoded vs separate prompts/ file vs TEST-SPEC frontmatter)? | S000019 implementation |
| `/implement-from-spec` propose-vs-write heuristic | S000018 implementation |
| Scaffold updating parent design doc footer (Status: SCAFFOLDED → work-items/...) | S000017 implementation |
| Multi-story decomposition logic in /scaffold-work-item (auto N children vs AskUserQuestion to confirm) | S000017 implementation; recommendation is AskUserQuestion |
| Subagent failure semantics (timeout, empty response, error) within each skill | S000019 first (most subagent-heavy), patterns flow back to S000018 |
