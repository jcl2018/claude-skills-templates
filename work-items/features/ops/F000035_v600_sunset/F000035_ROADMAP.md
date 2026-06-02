---
type: roadmap
parent: F000035
title: "v6.0.0 sunset — full nuke of deprecated shims + deprecation infrastructure — Roadmap"
date: 2026-06-02
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

F000035 executes the documented v6.0.0 sunset wave AND retires the deprecation infrastructure that was originally built to support graceful deprecations in a multi-operator world. Concretely: 5 deprecated alias-shim skill directories deleted, 5 catalog entries removed, the `deprecated/` directory deleted in its entirety, `--include-deprecated` flag removed from `skills-deploy`, `status: deprecated` removed from the validate.sh closed enum (becomes `{active, experimental}`), F000030 retired-skill drift audit convention removed from CLAUDE.md, tombstone sections retired from PHILOSOPHY.md + ARCHITECTURE.md + skill-routing.md, dead investigate-specific tests deleted, live tests updated, TODOS.md hygiene sweep, memory cleanup, VERSION 5.0.19 → 6.0.0, CHANGELOG entry, README.md regen. Workbench-only.

## Non-Goals

- work-copilot/ bundle changes — byte-mirrored; out of workbench scope.
- Re-design of a future deprecation pattern — re-introduced when an actual retirement needs it.
- Eval-hardening (D000023 scope) — `tests/eval/CJ_goal_run/` deletion is incidental cleanup; D000023 itself stays deferred.
- Automatic merge / land-and-deploy — PR-stop; operator merges manually per workbench safety convention.
- Tombstone preservation — CHANGELOG + git history form the audit trail; no per-deprecation tombstones in the live tree.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. -->

- [ ] `jq 'length' skills-catalog.json` returns the pre-PR count minus 5
- [ ] `jq -r '.[] | .status' skills-catalog.json | sort -u` returns ONLY `"active"` and `"experimental"`
- [ ] `ls deprecated/ 2>&1` returns "No such file or directory"
- [ ] `ls skills/CJ_goal_run skills/CJ_goal_auto 2>&1` returns "No such file or directory" for both
- [ ] `grep -c 'deprecat' scripts/skills-deploy` returns 0
- [ ] `grep -c 'Retired skills' doc/PHILOSOPHY.md` returns 0
- [ ] `grep -c 'Deprecation tombstones' doc/ARCHITECTURE.md` returns 0
- [ ] `grep -c 'Deprecated front doors' rules/skill-routing.md` returns 0
- [ ] `./scripts/validate.sh` passes with 0 errors
- [ ] `./scripts/test.sh` passes
- [ ] `VERSION` reads `6.0.0`; `CHANGELOG.md` has the `## [6.0.0]` entry
- [ ] README.md (post-regen) has no `### Deprecated` table

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000068](S000068_v600_sunset_execution/S000068_TRACKER.md) | v6.0.0 sunset execution (atomic full-nuke commit) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000068 | 2026-06-02 | Not Started | chjiang | Single atomic-commit user-story executing all 16 Recommended-Approach steps | — |
| 2 | End-to-end pipeline run (PR opened against main) | 2026-06-02 | Not Started | chjiang | /ship runs from the feature branch; PR-stop (no auto-merge) | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- {pending PR merge}

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000068 (atomic full-nuke commit) --> #2 PR opened against main
```

## Open Questions

| Question | Next check |
|----------|-----------|
| `tests/eval/` parent dir: delete if empty post-`CJ_goal_run` removal, leave if other eval dirs exist | S000068 Phase 2 — `ls tests/eval/` after removing CJ_goal_run subdir |
| `tests/cj-worktree-init.test.sh` investigate references: surgical update vs no-op | S000068 Phase 2 — grep + inspect |
| `tests/cj-goal-doc-sync-auq-recommendation.test.sh` deprecated assertions: update vs no-op | S000068 Phase 2 — grep + inspect |
