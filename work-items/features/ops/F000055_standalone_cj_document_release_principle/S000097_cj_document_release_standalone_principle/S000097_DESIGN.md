---
type: design
parent: S000097
title: "Standalone /CJ_document-release + general/custom doc-contract principle — Design"
version: 1
status: Draft
date: 2026-06-08
author: chjiang
reviewers: []
---

<!-- Atomic user-story design. Brief by design — the parent feature's DESIGN.md
     carries the cross-story shape; this captures the story-local decisions. -->

## Problem

`/CJ_document-release` is framed as a workbench-internal wrapper, yet the operator
wants to trigger it in **any** repo for peace of mind that docs are current, with
the same machine-readable contract later wired into CI. Two of the three asks
(the general/custom two-tier model; the single canonical seed) already exist; the
gaps are: the model is not named as a principle, the cold-run experience is ragged
(stderr `jq` noise + a silently skill-MD-less audit + a stray `.cj-goal-feature/`
artifact when `skills-catalog.json` is absent), and the gstack-hard-require
failure is not clearly messaged. See the parent feature DESIGN for the full
problem framing: [../F000055_DESIGN.md](../F000055_DESIGN.md).

## Shape of the solution

Five small, separable changes (Approach A): (1) a new sibling principle in
`docs/philosophy.md` under `## Topic: Deployment` + its front-table row;
(2) a guard around the Step 6.7.2 `skills-catalog.json` read in
`skills/CJ_document-release/SKILL.md` (skip the skill-MD audit half + the
`.cj-goal-feature/` scratch write when the catalog is absent, preserving the
`$(…)`-capture / `|| true` idiom so no `set -e` abort is introduced);
(3) a `[doc-sync-red]` message at the Step 4→5 boundary naming
"gstack `/document-release` not installed"; (4) honest bookkeeping — portability
stays `local-only`, USAGE.md bumped; (5) a portable-CI-hook recipe in
`docs/architecture.md` (scoped honestly) + a cold-repo smoke row in
`tests/cj-document-release-config.test.sh`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Guard ONLY the 6.7.2 skill-MD enumeration half | 6.7.1 + 6.7.3 (incl. the portable human-doc no-work-item-ID lint) must keep running cold. |
| 2 | Also skip the `.cj-goal-feature/` scratch write in non-workbench mode | That scratch only feeds the cj_goal PR-body surfacing (absent standalone) and isn't gitignored in a consumer repo. |
| 3 | gstack message at the Step 4→5 boundary, not Step-5-only | gstack-absent is a Step-4 resolution failure, a different mode from Step-5 non-green; the boundary covers both. |
| 4 | Portability stays `local-only` | Still hard-deps gstack + `_cj-shared` + `doc-spec.sh`; the guard only removes one repo-local dep (trends more portable, not a tier change). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Guard introduces a `set -e` abort the current code avoids. | Preserve `$(…)`-capture / `|| true`; the cold-repo smoke row mechanically gates it. |
| Over-claiming "general for any repo" (prose + declared⇔on-disk loop do NOT travel). | architecture.md recipe states the boundary plainly. |

## Definition of done

- [ ] All five deltas land; `validate.sh` Checks 14/19/20 green; Step 5.7 portability gate green; `scripts/test.sh` green incl. the new cold-repo smoke row.

## Not in scope

- Native rebuild / dropping gstack — rejected (Approach B).
- `doc-spec.sh --check-on-disk` subcommand — deferred TODOS follow-up.
- A new CI workflow file — documented, not built.

## Pointers

- Parent tracker: [S000097_TRACKER.md](S000097_TRACKER.md)
- SPEC: [S000097_SPEC.md](S000097_SPEC.md)
- TEST-SPEC: [S000097_TEST-SPEC.md](S000097_TEST-SPEC.md)
- Parent feature design: [../F000055_DESIGN.md](../F000055_DESIGN.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-sleepy-cerf-e8f24b-design-20260608-093825.md`
