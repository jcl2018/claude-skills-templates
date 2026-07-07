---
type: design
parent: S000133
title: "Deterministic-only enrollment seam + per-verb goal topics — Story Design"
version: 1
status: Approved
date: 2026-07-06
author: chang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — this DESIGN.md is a brief stub; the parent F000084_DESIGN.md
     carries the cross-story design. Section completeness is structural
     (all 7 sections present); content is deliberately brief. -->

## Problem

See parent [F000084_DESIGN.md](../F000084_DESIGN.md) `## Problem`: the three
primary cj_goal verbs have no topic-contract coverage (feature + task share one
agentic-only `cj-goal-eval` row; defect has none), and the existing enrollment
rule would chain them to agentic tests the operator plans to remove. This story
delivers the whole backfill in one PR.

## Shape of the solution

The four parts of the parent design, in strict order: (1) the
`topic_contracts_deterministic:` contract-engine seam (det-only Check-30 arm +
union iteration in `_run_topic_contract`/`_run_topic_docs` + seed dual-write +
3-arm negative drill), (2) the 4 new deterministic test scripts (1 CI-push defect
smoke + 3 CI-nightly chain drills, `TEST_FAST=1`-gated), (3) the 11 `categories:`
rows + `units:` rows + 9 front-door docs, (4) the Check-31 surfaces (3 dream docs
+ 3 topic subdirs) + prose sweeps + enrollment LAST. Full detail:
[S000133_SPEC.md](S000133_SPEC.md).

## Big decisions

Inherited from the parent (see [F000084_DESIGN.md](../F000084_DESIGN.md)
`## Big decisions`): per-verb topics; deterministic-only enrollment as an ENGINE
seam; Approach B chain drills at CI-nightly under `TEST_FAST=1`; union iteration
preserving the summary/grep contracts; enrollment LAST. Story-local tradeoffs are
recorded in [S000133_SPEC.md](S000133_SPEC.md) `## Tradeoffs`.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Union rework breaks the `enrolled=N findings=M` / inactive-grep contracts other surfaces parse | Negative-drill arm coverage + full `validate.sh` + `test.sh` at QA |
| Exact assertion granularity inside each chain drill | Settled here at TEST-SPEC level; chain step lists are the contract |
| Re-topic'd eval front-door docs may need no prose edit at all | Verify at build time |

## Definition of done

The story's `## Acceptance Criteria` in
[S000133_TRACKER.md](S000133_TRACKER.md) (AC-1 … AC-11), equivalent to the
parent's Definition of done: engines green (Checks 24/26/30/31 +
`--check-structure` + seed-identity), 4 new scripts pass, `TEST_FAST=1` skips the
chains, `cj-goal-eval` label gone, enrollment last, `validate.sh` fully green.

## Not in scope

See parent [F000084_DESIGN.md](../F000084_DESIGN.md) `## Not in scope`: no new
agentic rows, no agentic-removal execution, no todo_fix enrollment, no
`pipeline.md`-prose testing, no `portability`/`topic_contracts:` semantic change,
no CI workflow-file edits.

## Pointers

- Story tracker: [S000133_TRACKER.md](S000133_TRACKER.md)
- Story spec: [S000133_SPEC.md](S000133_SPEC.md)
- Story test spec: [S000133_TEST-SPEC.md](S000133_TEST-SPEC.md)
- Parent feature design: [../F000084_DESIGN.md](../F000084_DESIGN.md)
- Parent roadmap: [../F000084_ROADMAP.md](../F000084_ROADMAP.md)
- Source /office-hours doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-festive-margulis-b0841b-design-20260706-011500.md`
