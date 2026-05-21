---
type: design
parent: S000058
title: "/cj_goal_defect skill — reshape of investigate v1.1 + no-doc bug-report scaffolding — Design"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
reviewers: []
---

<!-- Atomic story under F000027. Design context comes from the parent feature's
     /office-hours session; see F000027_DESIGN.md for the cross-story picture. -->

## Problem

There is no single "fix a bug" front door that starts from a plain bug description with no pre-existing defect dir. `/CJ_goal_investigate` exists but assumes a scaffolded defect work-item and lives inside the cluttered five-orchestrator family this refactor collapses. The author wants `/cj_goal_defect "<bug description>"` to take a raw report, root-cause it under the Iron-Law, and ship a fix on the proven human-gated tail.

## Shape of the solution

`/cj_goal_defect "<bug>"`: worktree (via `cj-worktree-init.sh --caller defect`) → scaffold a no-doc bug report at `.inbox/<slug>/DRAFT.md` → `/investigate` as an Agent subagent (sentinel-wrapped JSON, Iron-Law: no fix without root cause) → on root cause, write RCA + test-plan and promote `.inbox` → `work-items/defects/.../D000NNN_<slug>/` → `/CJ_qa-work-item` → `/ship` (human Gate #2) → `/land-and-deploy --suppress-readiness-gate` → tracker journal + telemetry. ~80% reuse of investigate v1.1's flat `pipeline.md`. See parent [F000027_DESIGN.md](../F000027_DESIGN.md).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `defect` keeps the human `/ship` Gate #2 then deploys. | Symmetry with current investigate; the human diff review is the autonomy ceiling for bug fixes (Open Question 4 RESOLVED). |
| 2 | No-doc bug-report scaffolding via `.inbox/<slug>/DRAFT.md`, promoted only after Iron-Law passes. | Starts from a raw description with no pre-existing defect dir; promotion-after-root-cause keeps `work-items/defects/` clean of un-investigated stubs. |
| 3 | Reshape investigate v1.1's flat pipeline (~80% reuse) rather than wrap it. | Flat orchestration (depth ≤ 2) avoids the nested-subagent wall; wrapping would re-inherit it. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| `/investigate` returns DONE_WITH_CONCERNS or no root cause. | Inherit investigate v1.1's halt taxonomy: HALT with `next_action=`/`resume_cmd=`; do not promote `.inbox` or ship. |
| `.inbox` promotion races a parallel run on the same slug. | Promote only after Iron-Law passes; reuse investigate's fix-in-tree validation against `git log`. |

## Definition of done

- [ ] `/cj_goal_defect "<bug>"` scaffolds `.inbox/<slug>/DRAFT.md`, root-causes via `/investigate`, promotes to a `D000NNN_<slug>/` defect dir, passes Gate #2, deploys.
- [ ] Iron-Law holds: no fix promotes/ships without a populated root cause.
- [ ] Nesting depth ≤ 2; halt taxonomy + telemetry inherit investigate v1.1.

## Not in scope

- `feature`-style PR-stop — `defect` deploys after the human `/ship` gate (the tails genuinely differ; no shared tail doc). See parent DESIGN.
- Drain mode / family-drain lock for defects — not part of this story.

## Pointers

- Parent feature design: [../F000027_DESIGN.md](../F000027_DESIGN.md)
- Story tracker: [S000058_TRACKER.md](S000058_TRACKER.md)
- Story spec: [S000058_SPEC.md](S000058_SPEC.md)
- Reuse source: current `/CJ_goal_investigate` v1.1 `pipeline.md`
