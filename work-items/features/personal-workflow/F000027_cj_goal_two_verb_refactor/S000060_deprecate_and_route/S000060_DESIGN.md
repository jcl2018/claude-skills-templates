---
type: design
parent: S000060
title: "Deprecate /CJ_goal_run + /CJ_goal_auto (alias + sunset) + routing + catalog — Design"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
reviewers: []
---

<!-- Atomic story under F000027. Design context comes from the parent feature's
     /office-hours session; see F000027_DESIGN.md for the cross-story picture. -->

## Problem

Once the two new verbs exist, the old front-door orchestrators `/CJ_goal_run` and `/CJ_goal_auto` are redundant and confusing — but consumers (routing rules, muscle memory, in-flight pipelines) still reference them. They must be deprecated cleanly: a banner + a route to the replacement + a removal date, without breaking items mid-pipeline and without touching the orthogonal drain utility.

## Shape of the solution

Convert `skills/CJ_goal_run/SKILL.md` and `skills/CJ_goal_auto/SKILL.md` into hard alias shims that print a one-line deprecation banner then route to `/cj_goal_feature`, each carrying a sunset date (next major, e.g. v6.0.0) — mirroring the existing `CJ_run → CJ_goal_run` pattern. Flip both catalog entries to `deprecated` (and confirm the two new verbs are `experimental`); deprecated skills stay installable via `--include-deprecated` so in-flight items finish under them. Update `rules/skill-routing.md` + `CLAUDE.md` routing. Keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`. See parent [F000027_DESIGN.md](../F000027_DESIGN.md).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Hard alias shims (banner → `/cj_goal_feature`) + sunset at next major. | Mirrors the proven `CJ_run → CJ_goal_run` pattern; gives a clear migration path + removal date (D5 CONFIRMED + GATE #1). |
| 2 | Keep `/CJ_goal_todo_fix` + `/CJ_personal-pipeline`. | The drain utility is orthogonal and working; personal-pipeline is still todo_fix's engine (migrating it off is a deferred follow-up). |
| 3 | Deprecated skills stay installable (`--include-deprecated`). | In-flight migration — items mid-pipeline must be able to finish under the old skills. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Relocating deprecated skill sources could break consumer scripts that derive paths. | The catalog is the source of truth for paths (scripts derive `dirname(files[0])`); follow the deprecation convention so `skills-deploy`/`validate.sh`/`test.sh` resolve correctly. |
| Routing edits in two files (`rules/skill-routing.md` + `CLAUDE.md`) could drift. | TEST-SPEC smoke rows assert both files route the new verbs and no longer recommend `run`/`auto` as primary. |

## Definition of done

- [ ] `run`/`auto` print a banner and route to `/cj_goal_feature`; sunset date recorded.
- [ ] Catalog: 2 new `experimental` entries + `run`/`auto` `deprecated`; `--include-deprecated` still installs them.
- [ ] Routing updated in both files; `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` + `/schedule` + `/loop` still work; `validate.sh` + `test.sh` green.

## Not in scope

- Deprecating `/CJ_personal-pipeline` — deferred until `/CJ_goal_todo_fix` is migrated off it. See parent DESIGN.
- Removing `run`/`auto` outright — they sunset at the next major, not in this story.

## Pointers

- Parent feature design: [../F000027_DESIGN.md](../F000027_DESIGN.md)
- Story tracker: [S000060_TRACKER.md](S000060_TRACKER.md)
- Story spec: [S000060_SPEC.md](S000060_SPEC.md)
- Depends on: S000058 + S000059 (the two new verbs must exist before `run`/`auto` route to them)
- Convention: `deprecated/README.md` (deprecation = catalog status + source relocation + history relocation)
