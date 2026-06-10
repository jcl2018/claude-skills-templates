---
type: design
parent: S000101
title: "test-pipeline registry + parser + generated view + hard sync/coverage checks — Story Design"
version: 1
status: Draft
date: 2026-06-10
author: chjiang
reviewers: []
---

<!-- Atomic story deriving directly from the parent feature's /office-hours
     session — per tracker-user-story.md, this DESIGN is a brief stub; the
     authoritative cross-story design lives in the parent's
     F000059_DESIGN.md. All 7 sections kept (structural completeness is
     enforced by /CJ_personal-workflow check); content is intentionally
     brief. -->

## Problem

See [../F000059_DESIGN.md](../F000059_DESIGN.md) `## Problem`: the repo's
verification surface (~24 numbered validate checks in two ID grammars + 2
warning checks, ~29 test.sh units including one silently-unwired test file,
3 standalone suites, 3 CI workflows, 2 hooks, 3 ratchets) has no check-level
human-readable map; spec/gate-spec.md deliberately stops at the layer model.
This story builds the entire fix in one atomic unit.

## Shape of the solution

One PR delivering the full two-layer mechanism: spec/test-pipeline.md (machine
registry, ~65 rows), scripts/test-pipeline.sh (parser/renderer, gate-spec.sh
idiom), docs/test-pipeline.md (generated view, third
generate-doc-views.sh output), validate.sh Check 23 extension (hard view-sync)
+ new hard Check 24 (forward/reverse/floor coverage cross-check), doc-spec
registration for both docs with the Common seed grown 10 → 11 in lockstep
copies, tests/test-pipeline-spec.test.sh (registered in test.sh) with four
drift drills, the Step-0 stray-test triage, the self-inclusion loop-back, and
the secondary-doc sweep. See the SPEC's Architecture section for the data
flow.

## Big decisions

Owned by the parent: see [../F000059_DESIGN.md](../F000059_DESIGN.md)
`## Big decisions` (generated-view approach over hand-written alternatives;
Check 24 hard from day one; orthogonal disposition/skip axes; ID-free rendered
fields; runner-path anchors for test rows; mechanism-neutral seed string;
test-pipeline naming). Story-local tradeoffs are recorded in
[S000101_SPEC.md](S000101_SPEC.md) `## Tradeoffs`.

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| cj-goal-feature-smoke triage outcome (register vs retire) | Step 0, decided after reading the file against landed feature-verb behavior; both outcomes keep the Check 24 baseline clean |
| Inline-family anchors fossilize test.sh's editorial segmentation | Accepted (parent DESIGN risk table); anchors = most stable literal strings available |
| Single-commit atomicity: doc + registry + seed copies + heredoc + regenerated views must land together | Checks 15a + 23 fail half-states at the pre-commit hook; commit feature code before doc-sync |

## Definition of done

The parent's Definition of done is carried 1:1 by this story — see
[../F000059_DESIGN.md](../F000059_DESIGN.md) and this story's
`## Acceptance Criteria` in [S000101_TRACKER.md](S000101_TRACKER.md) for the
expanded, testable form (registry + parser + generated view + both hard
checks green on a clean baseline + seed lockstep + registered tests + drift
drills + secondary-doc sweep).

## Not in scope

See [../F000059_DESIGN.md](../F000059_DESIGN.md) `## Not in scope`: no
semantic meaning-sync (stays with the advisory registered-doc audit), no
pipeline-gate registry rows (gate-spec owns), no reverse-sweep of future
standalone suites / off-grammar inline families (forward-anchor-only
boundary), no new skill, no resurrecting retired Check 12.

## Pointers

- Parent feature design: [../F000059_DESIGN.md](../F000059_DESIGN.md)
- Parent tracker: [../F000059_TRACKER.md](../F000059_TRACKER.md)
- Roadmap: [../F000059_ROADMAP.md](../F000059_ROADMAP.md)
- Story tracker: [S000101_TRACKER.md](S000101_TRACKER.md)
- Spec: [S000101_SPEC.md](S000101_SPEC.md)
- Test spec: [S000101_TEST-SPEC.md](S000101_TEST-SPEC.md)
- Source design doc (carries the Registry inventory appendix — the scaffold input): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-hardcore-napier-1efc3f-design-20260610-071551.md`
