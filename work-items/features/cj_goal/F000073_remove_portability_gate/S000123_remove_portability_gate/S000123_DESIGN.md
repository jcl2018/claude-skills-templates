---
type: design
parent: S000123
title: "Remove the portability gate from the cj_goal build path — Story Design"
version: 1
status: Draft
date: 2026-07-02
author: chang
reviewers: []
---

<!-- Atomic user-story design. Content is intentionally brief; the parent
     feature's DESIGN (F000073_DESIGN.md) and the source /office-hours doc
     carry the full rationale. The precise, load-bearing file inventory lives
     in this story's SPEC.md so implement + QA have the full scope. -->

## Problem

The four `CJ_goal_*` orchestrators run a workbench-only pre-ship portability gate
(`cj-goal-common.sh --phase portability-audit`) that HALTs on a dishonest
`portability` declaration. Portability audits `skills-catalog.json`, which only
exists in this repo, so the gate is dead weight in consumer repos and redundant in
the workbench (Check 18 already hard-fails a dishonest declaration on every
commit + CI). This story removes the gate from the build path entirely, leaving
portability as a separate test only.

## Shape of the solution

Full extraction (parent Approach A). One atomic change across six file groups —
the script, the four orchestrators, the test-spec overlay, the workflow-spec
registry (+ regenerated docs), the tests, and `CLAUDE.md`. The authoritative,
line-referenced file inventory is in this story's SPEC.md `## Architecture`
(carried faithfully from the source design doc's "Precise file inventory"). The
standalone portability test (engine + Check 18 + `/CJ_portability-audit` +
their contract rows/fixtures) is explicitly untouched.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Remove, don't unwire or soften | See parent F000073_DESIGN.md Big decisions #1 — B leaves dead code, C keeps the gate running. |
| 2 | Repoint the `test.sh` `task`-enum probe rather than delete it | The probe uses the (now-deleted) portability phase only as a mode-agnostic vehicle to prove the `task` enum is accepted; that coverage must be preserved via a surviving phase (`--phase recap --mode task` or `--phase sync --mode task --dry-run`). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Self-modifying pipeline (this run edits the orchestrator executing it). | Parent F000073_DESIGN.md Risks row 1 — the run proceeds to `/ship` since the gate is removed by intent; verified by QA success criterion 5. |
| A stray leftover reference (`[portability-red]` etc.) trips Check 24 or the grep criterion. | QA success criteria 1 + 2. |

## Definition of done

- [ ] See this story's SPEC.md `## Acceptance Criteria` (Given/When/Then) and the parent ROADMAP success criteria 1–5.

## Not in scope

- The standalone portability test — engine (`cj-portability-audit.sh`), `validate.sh` Check 18, `/CJ_portability-audit` skill, the Check 18/engine unit rows, the F000047/S000083 engine fixture block. See parent F000073_DESIGN.md `## Not in scope`.

## Pointers

- Parent feature design: [../F000073_DESIGN.md](../F000073_DESIGN.md)
- Parent tracker: [../F000073_TRACKER.md](../F000073_TRACKER.md)
- This story's SPEC (authoritative file inventory): [S000123_SPEC.md](S000123_SPEC.md)
- This story's TEST-SPEC: [S000123_TEST-SPEC.md](S000123_TEST-SPEC.md)
- Source /office-hours design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-inspiring-torvalds-0e7e5d-design-20260701-235812.md`
