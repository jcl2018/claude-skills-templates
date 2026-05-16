---
type: design
parent: S000049
title: "v1.0 single-defect mode — /CJ_goal_investigate skill + pipeline + chain — Story Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- Atomic story design. Brief stubs per section linking back to parent
     feature's design for full context. -->

## Problem

Build the v1.0 single-defect mode of `/CJ_goal_investigate`: skill scaffolding, defect resolver, machine-readable `/investigate` dispatch, RCA + test-plan artifact writes, halt-on-red taxonomy, idempotent re-entry, and the chain to `/CJ_qa-work-item` → `/ship` → `/land-and-deploy`. See parent [F000024_DESIGN.md](../F000024_DESIGN.md) for full context.

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Skill scaffold (SKILL.md + pipeline.md + catalog + routing) | S000049 | this dir |
| Defect resolver + idempotency table | S000049 | implemented in pipeline.md |
| /investigate dispatch + sentinel-wrapped JSON parser | S000049 | implemented in pipeline.md |
| RCA + test-plan artifact writes | S000049 | implemented in pipeline.md |
| Halt-on-red taxonomy (9 end-states) | S000049 | implemented in pipeline.md |
| /CJ_qa-work-item + /ship + /land-and-deploy chain | S000049 | implemented in pipeline.md |
| Dogfood validation (Phase 1 + Phase 7) | S000049 | implemented inline |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Atomic story (no task decomposition) | Single deliverable: one new skill dir with scaffolding + chain logic. Decomposition would over-fragment. |
| 2 | Reuse `/CJ_goal_run` Branch(f) pattern for resume detection | Parallel family-shape; copy the proven idempotency design rather than invent. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Sentinel-wrapped JSON instruction reliability | Phase 1 of impl validates against live `/investigate`. Fallback: regex-parse free-text. |

## Definition of done

- [ ] All acceptance criteria in S000049_TRACKER.md satisfied.
- [ ] Phase 7 dogfood run produces a green or surfacing-only run against a real defect.

## Not in scope

- Drain mode, `--quiet`, `--max-drain` — see parent F000024's Not in scope.
- Family-drain lock — v1.1.
- Sunset criterion — v1.1.
- Freestanding defect convention — v1.1.
- Ad-hoc bugs without scaffolded defect dir — v2.0.

## Pointers

- Parent feature design: [../F000024_DESIGN.md](../F000024_DESIGN.md)
- Parent tracker: [../F000024_TRACKER.md](../F000024_TRACKER.md)
- Story tracker: [S000049_TRACKER.md](S000049_TRACKER.md)
- Story spec: [S000049_SPEC.md](S000049_SPEC.md)
- Story test-spec: [S000049_TEST-SPEC.md](S000049_TEST-SPEC.md)
- /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-worktree-immutable-watching-sparrow-design-20260515-193008.md`
