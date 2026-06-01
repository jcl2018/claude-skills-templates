---
type: roadmap
parent: F000031
title: "Casing-only rename of F000027 verbs (cj_goal_feature/defect → CJ_goal_feature/defect) — Roadmap"
date: 2026-05-31
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

This feature lands a casing-only refactor of two skill names: `cj_goal_feature` → `CJ_goal_feature` and `cj_goal_defect` → `CJ_goal_defect`. The goal token is preserved (it's a load-bearing family signal). Lowercase deprecation shims at `deprecated/{name}/` keep existing lowercase invocations working until v6.0.0 sunset, which bundles cleanly into the existing F000027 sunset wave (which already retires `CJ_goal_run` + `CJ_goal_auto`). Zero functional change to either pipeline; the cleanup is the entire point.

## Non-Goals

- Migrating F000027's existing `CJ_goal_run` + `CJ_goal_auto` shims from `skills/` to `deprecated/` — deferred to v6.0.0 sunset PR; mid-life migration is pure churn when v6.0.0 removes all four shims anyway.
- Renaming the worktree branch prefix `cj-feat-*` to uppercase — runtime artifact, not skill identity.
- Renaming resume state directories (`.cj-goal-feature/`, `.cj-goal-defect/`) — runtime state; flipping would break in-flight pipelines.
- Rewriting git history to flip lowercase references in F000027 commit messages — immutable record stays as-is.
- Editing operator-local memory files — workbench-only scope per `feedback_workbench_scope`.
- Downstream-consumer churn (portfolio / exploration repos) — workbench-only scope.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] Operator invokes `/CJ_goal_feature "<topic>"` and the feature pipeline runs end-to-end without a deprecation banner.
- [ ] Operator invokes `/cj_goal_feature "<topic>"` and sees a one-line deprecation banner then the same pipeline runs (via the shim).
- [ ] Same pair behaviors for `/CJ_goal_defect` + `/cj_goal_defect`.
- [ ] Fresh reader scanning `rules/skill-routing.md`, `CLAUDE.md`, `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `README.md` sees uniform uppercase `CJ_goal_*` naming across the whole CJ_* family — no parse-as-defect friction.
- [ ] `./scripts/validate.sh` exits 0 (catalog/filesystem consistency including the new deprecated entries).
- [ ] `./scripts/test.sh` exits 0 (S000060 regression test asserts against the new uppercase canonical).
- [ ] PR opens at v5.0.12 (or the slot reported by `check-version-queue.sh`) and stops for human review at the GitHub PR gate.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000064](S000064_casing_rename_impl/S000064_TRACKER.md) | Casing rename + shim creation + catalog + cross-reference flips | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000064 (rename + shims + catalog + docs + tests) | 2026-05-31 | In Progress | chjiang | Single atomic story; full PR | — |
| 2 | End-to-end pipeline run on PR (validate.sh + test.sh + pre-commit hook all green) | 2026-05-31 | Not Started | chjiang | PR-stop gate; human review at GitHub | #1 |
| 3 | (Deferred to v6.0.0 sunset PR) Remove all 4 CJ_goal_* deprecation shims (CJ_goal_run, CJ_goal_auto, cj_goal_feature, cj_goal_defect) and their catalog entries | TBD (v6.0.0) | Deferred | chjiang | TODOS row tagged [v6.0.0 sunset]; not part of this feature | #1, #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-05-31: Created. Awaiting implementation + ship.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 Ship S000064 (rename + shims + catalog + docs + tests)
        |
        v
#2 E2E pipeline run on PR (validate.sh + test.sh green, human gate at GitHub)
        |
        v (much later, v6.0.0 milestone)
#3 (Deferred) Remove all 4 CJ_goal_* deprecation shims at v6.0.0 sunset
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Will the version slot be 5.0.12 or higher (parallel worktree race)? | Implementer runs `./scripts/check-version-queue.sh` immediately before `/ship`; if collision, hand-edit the three baked-in `5.0.12` literals. |
| Does `git mv lower TMP && git mv TMP UPPER` need an `update-index --refresh` between steps on this specific APFS volume? | Implementer verifies each step's exit code; runs the refresh only if a stale-index error surfaces. |
| Will the F000027 commit-history references to lowercase names confuse fresh readers? | Acceptable cost (per design Open Q #2); shims keep the lowercase invocations working, so any open PR's bash examples still execute. |
