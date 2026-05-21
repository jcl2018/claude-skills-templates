---
type: design
parent: S000059
title: "/cj_goal_feature skill — office-hours-inline -> silent build -> PR-stop, strengthened resume — Design"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
reviewers: []
---

<!-- Atomic story under F000027. Design context comes from the parent feature's
     /office-hours session; see F000027_DESIGN.md for the cross-story picture. -->

## Problem

The author wants a single "build a feature" front door that starts from a one-line topic, runs the one interactive design phase (office-hours), then silently builds and stops at a PR for human review — without the nested-subagent wall that `run → personal-pipeline → scaffold/impl/qa` hit, and without auto-deploy (unsafe-by-construction here). This is the riskier of the two verbs and the one defect-first sequencing leaves unexercised until late.

## Shape of the solution

`/cj_goal_feature "<topic>"`: worktree (`cj-worktree-init.sh --caller feature`) → `/office-hours` inline (the one interactive phase; emits an APPROVED design doc) → silent scaffold/impl/qa leaf subagents (no AUQ) → `/ship` inline, diff-review AUQ suppressed → **STOP** at the PR. No autoplan, no auto-merge/deploy. Resume tracks `last_completed_phase` + per-phase HEAD SHA + PR number, validating before skipping. See parent [F000027_DESIGN.md](../F000027_DESIGN.md).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | `feature` terminates at the PR; no auto-merge/deploy. | The handoff-gate denylist blocks exactly the skill surfaces every feature touches; auto-deploy of skill-work is unsafe-by-construction (D3 REVISED at GATE #1). PR-stop is correct. |
| 2 | No autoplan; the human PR review is the architecture gate. | With auto-deploy gone, every run PR-stops and gets a human review; the prior "autoplan only on the auto-deploy branch" rule was incoherent (Open Question 2 RESOLVED). |
| 3 | Resume tracks `last_completed_phase` + per-phase HEAD SHA + PR number, validate-before-skip; office-hours resume uses the recorded path + APPROVED re-confirm. | The A/S/P/M flag model was too lossy and could skip into a later phase on stale state or re-run office-hours on an unchanged APPROVED doc (GATE #1). |
| 4 | office-hours runs inline at top level; leaves dispatched directly (depth ≤ 2). | office-hours is AUQ-heavy and subagents can't AUQ; flat dispatch avoids the nested-subagent wall. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Auto-merge override (Open Question 1) — author may re-open. | Author decides at approval; strong recommendation is to leave it dropped (PR-stop correct). Out of scope for this story unless re-opened. |
| office-hours doc-path recovery via recorded path could be fragile across parallel runs. | v1 uses the recorded path + APPROVED re-confirm; a machine-readable pointer emitted by office-hours is a deferred follow-up. |
| Tree moves underneath a halted run (force-push, manual edits, merged PR). | Validate-before-skip: recorded SHA must be ancestor-of/equal-to current HEAD and any open PR must resolve to OPEN, else restart the affected phase. |

## Definition of done

- [ ] `/cj_goal_feature "<topic>"` runs worktree → office-hours → APPROVED → silent build → `/ship` PR → STOP, zero AUQ between approval and the PR.
- [ ] Resume validates SHA/PR against current HEAD; never re-runs office-hours on an unchanged APPROVED doc; never skips a phase on stale state.
- [ ] No autoplan, no auto-merge/deploy; nesting depth ≤ 2.

## Not in scope

- Auto-merge+deploy — parked, unsafe-by-construction (see parent DESIGN "Not in scope").
- `/CJ_goal_auto`'s no-office-hours fast path — office-hours always runs inline.
- A machine-readable design-doc pointer from office-hours — deferred follow-up.

## Pointers

- Parent feature design: [../F000027_DESIGN.md](../F000027_DESIGN.md)
- Story tracker: [S000059_TRACKER.md](S000059_TRACKER.md)
- Story spec: [S000059_SPEC.md](S000059_SPEC.md)
- Depends on: S000057 (`cj-worktree-init.sh --caller feature` + `cj-goal-common.sh` + early feature smoke harness)
