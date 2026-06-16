---
type: design
parent: S000110
title: "Behaviors + coverage in the test-spec contract — Design"
version: 1
status: Draft
date: 2026-06-16
author: chjiang
reviewers: []
---

<!-- Atomic-story design. The cross-story shape lives in the parent feature's
     DESIGN (F000066_DESIGN.md); this story IS the whole v1, so the detail here
     is intentionally brief and points to the parent + the SPEC. -->

## Problem

The `test-spec` contract has no vocabulary for **what behavior the software must
prove**. It is closed-world over existing tests, so an untested-but-required
behavior is invisible (the portfolio "is a short put valid?" pain). See parent
[F000066_DESIGN.md](../F000066_DESIGN.md) for the full framing.

## Shape of the solution

Add two overlay-only arrays to the test-spec registry — `behaviors:` (obligations,
each with a closed `level` enum) and `behavior_coverage:` (a many-to-many relation
linking a behavior to a test-bearing `units[]` row + a `source`/`anchor` for
semantic evidence). Prose + the enum go in the byte-identical general seed; the
rows live per-repo in the overlay. `test-spec.sh` gains the parser, six
deterministic conformance checks, two plumbing items, and the absent/inactive
parity path; `validate.sh` Check 24 runs the new checks; `/CJ_test_audit` gains an
agent-judged Stage-2 substance sub-check. Full requirement + architecture detail is
in [S000110_SPEC.md](S000110_SPEC.md).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `schema_version` stays `1`; arrays are optional-on-schema-1, overlay-only; seed machine block UNCHANGED | Preserves the byte-identical-seed test + the one-fenced-yaml-block invariant. See parent decision 1. |
| 2 | `level` on the behavior, not on `units[]`; the agent-judged Stage-2 check is load-bearing (P5) | See parent decisions 2–3. |
| 3 | Atomic story — no task children | The v1 is one cohesive, tightly-coupled change; decomposing adds ceremony without parallelism (WORKFLOW.md allows atomic stories). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| False confidence from coarse self-attested behavior rows (Codex risk #2). | QA verifies `/CJ_test_audit` Stage-2 flags a vague/over-claimed/mis-leveled row. |
| Parser bleed: the new top-level keys leaking into rules/units/layers/gates parsing. | Boundary-regex edit to all four existing per-block parsers; covered by a TEST-SPEC parser round-trip row. |
| Rules-only consumer-parity regression. | A no-`behaviors:` repo must report "behavior coverage inactive" + stay green; covered by a TEST-SPEC consumer-parity row. |

## Definition of done

- [ ] All S000110 acceptance criteria in the TRACKER are met.
- [ ] `validate.sh` + `test.sh` green; the ~8 dogfood rows green on the live tree.
- [ ] `spec/test-spec.md` byte-identical to `test-spec.sh --seed`.

## Not in scope

- Approach B (pyramid quotas, level-distribution reporting, diff-aware enforcement) — deferred fast-follow.
- Approach C (executable-spec behaviors) — rejected; fights portability.
- A deterministic `source != unit.source` guard — P5 (agent-judged) owns it in v1.
- `--reconcile` migration nudge for already-adopted repos — opt-in is enough for v1.

## Pointers

- Parent feature design: [../F000066_DESIGN.md](../F000066_DESIGN.md)
- Parent tracker: [../F000066_TRACKER.md](../F000066_TRACKER.md)
- This story's spec: [S000110_SPEC.md](S000110_SPEC.md)
- This story's test spec: [S000110_TEST-SPEC.md](S000110_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-angry-wozniak-0b3ea3-design-20260615-175911.md`
