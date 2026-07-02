---
type: design
parent: S000122
feature: F000072
title: "runners: axis + test-run.sh engine + run ledger + /CJ_test_run wrapper — Design"
version: 1
status: Approved
date: 2026-07-01
author: chang
reviewers: []
---

<!-- The atomic-story design. The full design context is the parent feature's
     F000072_DESIGN.md plus the APPROVED /office-hours doc it distills; this
     stub records the story-scope shape. Brief by design — see parent for the
     cross-story rationale. -->

## Problem

See parent [F000072_DESIGN.md](../F000072_DESIGN.md): the test contract is
audited (wired?) but never executed (passes?). This single story ships the whole
executable half — the `runners:` overlay axis, the `test-run.sh` engine, the
workbench's own runner rows, the `/CJ_test_run` wrapper, and the fixture tests.

## Shape of the solution

One PR, five components (parent DESIGN "Shape of the solution" items 1–5):
grammar in `scripts/test-spec.sh` (+ `--list-runners`, `--list-units
--with-family`), the deterministic `scripts/test-run.sh` engine (plan → tiered
execute → `.md` report + `.json` ledger), workbench overlay `runners:` rows,
the thin `/CJ_test_run` skill wrapper + shipping paperwork, and
`tests/test-run.test.sh` fixture tests. Detail lives in this story's
[S000122_SPEC.md](S000122_SPEC.md).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| All five components (atomic story) | S000122 | [S000122_SPEC.md](S000122_SPEC.md) |

## Big decisions

Inherited from the parent — see [F000072_DESIGN.md](../F000072_DESIGN.md)
`## Big decisions` (contract-defines-what-runs, cost-tier UX law, no false
pass, runner-granularity verdicts, CR-safe jq, fixture-only tests). Story-local
tradeoffs are in [S000122_SPEC.md](S000122_SPEC.md) `## Tradeoffs`.

| # | Decision | Why |
|---|----------|-----|
| 1 | Ship as ONE atomic story | The five components form one cohesive grammar+engine+wrapper change; splitting them would create artificial seams (parent Approach A) |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| jq-CRLF defect blocks commits on the operator's Windows machine until fixed | Prerequisite lands via separate /CJ_goal_defect run before implement (parent ROADMAP milestone #1) |
| Five sensitive surfaces in the diff (`test-spec.sh`, `skills-catalog.json`, `spec/test-spec-custom.md`, `rules/skill-routing.md`, `spec/workflow-spec.md`) | Sensitive-surface QA discipline at /CJ_implement-from-spec + /CJ_qa-work-item |

## Definition of done

- [ ] All ten Acceptance Criteria in [S000122_TRACKER.md](S000122_TRACKER.md) verified.
- [ ] Full `validate.sh` + `scripts/test.sh` green; `/CJ_test_run` invocable standalone.

## Not in scope

See parent [F000072_DESIGN.md](../F000072_DESIGN.md) `## Not in scope`: the
audit-side ledger check, `--changed`, the mapping table, general-seed edits,
new CI surface, and the jq-CRLF fix itself.

## Pointers

- Parent feature design: [../F000072_DESIGN.md](../F000072_DESIGN.md)
- Parent tracker: [../F000072_TRACKER.md](../F000072_TRACKER.md)
- Story tracker: [S000122_TRACKER.md](S000122_TRACKER.md)
- Spec: [S000122_SPEC.md](S000122_SPEC.md)
- Test spec: [S000122_TEST-SPEC.md](S000122_TEST-SPEC.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-dazzling-shirley-87c62e-design-20260701-161358.md`
