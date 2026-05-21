---
type: roadmap
parent: F000027
title: "CJ_goal family — two-verb refactor (feature / defect) over leaf skills — Roadmap"
date: 2026-05-21
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Collapse the cluttered CJ_goal front door (five overlapping orchestrators) to two clear verbs — `/cj_goal_feature` for new work and `/cj_goal_defect` for bugs — built flat over the proven leaf skills (depth ≤ 2, structurally immune to the nested-subagent wall). Common deterministic logic (worktree, telemetry, PR checks) lands in a `cj-goal-common.sh` bash helper with mode flags. `feature` runs office-hours inline then silently scaffolds/implements/QAs and stops at a `/ship` PR for human review; `defect` mirrors current `/CJ_goal_investigate` (root-cause via `/investigate`, human `/ship` gate, then deploy). `/CJ_goal_run` + `/CJ_goal_auto` are deprecated with hard alias shims + a sunset date; `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` are kept.

## Non-Goals

<!-- Explicit non-goals. -->

- Auto-merge+deploy for `feature` — unsafe-by-construction in this repo (the handoff-gate denylist blocks exactly the skill surfaces every feature touches). Parked, not deferred-with-intent.
- `/CJ_goal_auto`'s no-office-hours fast path — dropped; `feature` always runs office-hours inline.
- Wrap-over-engines, single-skill-two-modes, a shared LLM-followed `tail.md`, full leaf rebuild — all recreate the nesting/coupling this refactor removes.
- Migrating `/CJ_goal_todo_fix` off `/CJ_personal-pipeline` — deferred follow-up; only then could personal-pipeline be deprecated too.

## Success Criteria

<!-- Bulleted, measurable outcomes. -->

- [ ] `/cj_goal_feature "<topic>"` from clean `main`: worktree → office-hours → APPROVED doc → silent scaffold/impl/qa → `/ship` opens a PR → STOP, zero AUQ between the office-hours approval and the PR.
- [ ] Re-invoking `feature` after a halt resumes at `last_completed_phase`, validating SHA/PR against current HEAD; never re-runs office-hours on an unchanged APPROVED doc, never skips a phase on stale state.
- [ ] `/cj_goal_defect "<bug>"` with no pre-existing defect dir: scaffolds a bug report, root-causes via `/investigate` (Iron-Law), passes the human `/ship` gate, deploys.
- [ ] Nesting depth ≤ 2; no subagent-spawns-subagent path.
- [ ] Deprecated `run`/`auto` print a banner and route to `feature`; `/CJ_goal_todo_fix` + `/CJ_personal-pipeline` + `/schedule` + `/loop` still work.
- [ ] `validate.sh` + `test.sh` green; `cj-worktree-init.sh` accepts the new callers; the early feature smoke harness passes.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000057](S000057_helper_prep/S000057_TRACKER.md) | Helper prep — `cj-worktree-init.sh` `--caller` extension + `cj-goal-common.sh` + early feature smoke harness | Open |
| [S000058](S000058_defect_skill/S000058_TRACKER.md) | `/cj_goal_defect` skill — reshape of investigate v1.1 + no-doc bug-report scaffolding | Open |
| [S000059](S000059_feature_skill/S000059_TRACKER.md) | `/cj_goal_feature` skill — office-hours-inline → silent build → PR-stop, strengthened resume | Open |
| [S000060](S000060_deprecate_and_route/S000060_TRACKER.md) | Deprecate `/CJ_goal_run` + `/CJ_goal_auto` (alias + sunset) + routing + catalog | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000057 (helper prep + early feature smoke harness) | — | Not Started | chjiang | Foundation; the `--caller` extension + `cj-goal-common.sh` + smoke harness must land before the verb skills | — |
| 2 | Ship S000058 (`/cj_goal_defect`) | — | Not Started | chjiang | Defect-first (Approach C); ~80% reuse of investigate v1.1 | #1 |
| 3 | Ship S000059 (`/cj_goal_feature`) | — | Not Started | chjiang | office-hours-inline → silent build → PR-stop; strengthened resume | #1 |
| 4 | Ship S000060 (deprecate run/auto + routing + catalog) | — | Not Started | chjiang | Hard alias shims + sunset; keep todo_fix + personal-pipeline | #2, #3 |
| 5 | End-to-end pipeline run | — | Not Started | chjiang | Both verbs exercised end-to-end; `validate.sh` + `test.sh` green; smoke harness passes | #4 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- {YYYY-MM-DD}: {PR# or version} — {brief description}

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Helper prep (cj-worktree-init --caller + cj-goal-common.sh + smoke harness)
       │
       ├──────────────┐
       ▼              ▼
#2 /cj_goal_defect   #3 /cj_goal_feature
       │              │
       └──────┬───────┘
              ▼
#4 Deprecate run/auto + routing + catalog
              │
              ▼
#5 End-to-end pipeline run (validate + test green)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Auto-merge for `feature` (Open Question 1) — the author's override. Rev 2 drops it as unsafe-by-construction; a feature-specific gate profile would still block most dangerous files, buying little. | Author decides at approval. Re-open only with a concrete class of feature touching only low-risk surfaces. |
| Machine-readable design-doc pointer emitted by office-hours (replaces recorded-path recovery in S000059's resume). | Deferred follow-up; revisit if the recorded-path recovery proves fragile in practice. |
