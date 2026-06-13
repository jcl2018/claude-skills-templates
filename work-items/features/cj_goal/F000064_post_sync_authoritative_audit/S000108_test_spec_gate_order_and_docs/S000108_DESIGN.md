---
type: design
parent: S000108
title: "test-spec gate-order swap + docs + named tests — Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- Atomic story — brief stub; see parent F000064_DESIGN.md for the full feature design. -->

## Problem

The reorder changes the canonical gate sequence (doc-sync must now precede qa-audit) and
the prose/charts/tests that describe the old QA → checkpoint → doc-sync order. The
`spec/test-spec` registry is the single source of truth (Check 24) and `docs/workflow.md`'s
per-`CJ_goal_*` ASCII charts are Check-15b-enforced, so they must be updated in lockstep,
along with the three named tests (one of which fails on the reorder until updated).

## Shape of the solution

Swap the `qa-audit` / `doc-sync` gate `order:` values in `spec/test-spec-custom.md` (45 ↔ 50)
and update the `qa-audit` gate `backing:`/`checks:` prose to name the orchestrator-level
post-sync audit + checkpoint. Update the docs: root `CLAUDE.md` ordering prose, the four
per-`CJ_goal_*` ASCII charts in `docs/workflow.md`, the four SKILL.md Overview chains, and
the catalog `description` fields. Update the three named tests: the `scripts/test.sh`
zzz-test-scaffold fixture, `tests/cj-goal-doc-sync-wiring.test.sh` (the ORDERING assertion),
and any per-pipeline halt-marker tests. Confirm Check 24 + Check 15b + full `scripts/test.sh`
are green.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Keep the test-spec registry the single source of truth for the gate sequence | Check 24 enforces it; the `order:` swap must keep the registry valid + the coverage cross-check green. |
| 2 | Update the Check-15b ASCII charts in lockstep | Check 15b errors if the charts don't reflect the reordered sequence. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `cj-goal-doc-sync-wiring.test.sh` fails on the reorder until its ORDERING assertion is updated | Update the assertion as an explicit step; it is the canary that proves the reorder landed. |
| Implement-subagent blind spot: forgetting the zzz-test-scaffold fixture or halt-marker tests | List all three named tests as explicit implementation steps. |

## Definition of done

- [ ] Gate order swapped + qa-audit backing updated; Check 24 + Check 15b + full `scripts/test.sh` green; docs + the three named tests updated for the new ordering.

## Not in scope

- The qa.md split (S000106) and the pipeline reorder (S000107) — this story documents + tests the behavior they implement.
- Any change to ship safety (Check 19 stays unchanged).

## Pointers

- Parent feature design: [../F000064_DESIGN.md](../F000064_DESIGN.md)
- Parent tracker: [../F000064_TRACKER.md](../F000064_TRACKER.md)
- Story tracker: [S000108_TRACKER.md](S000108_TRACKER.md)
