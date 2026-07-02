---
type: roadmap
parent: F000073
title: "Remove the portability-audit gate from the cj_goal orchestrators — Roadmap"
date: 2026-07-02
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Remove the pre-ship portability gate (`cj-goal-common.sh --phase portability-audit`,
F000051 / S000091) from all four `CJ_goal_*` orchestrators and delete its
mechanism, so the portable orchestrators carry zero workbench-specific portability
logic. Portability remains enforced by the separate test: `validate.sh` Check 18
(strict-by-default global ratchet) plus the standalone `/CJ_portability-audit`
skill and its engine. This is a single atomic multi-file change — all edits land
together so the pre-commit `validate.sh` + CI `test.sh` stay green.

## Non-Goals

- Touching the portability ENGINE (`scripts/cj-portability-audit.sh`) — it is the separate test and stays.
- Touching `validate.sh` Check 18 — the strict global ratchet is the separate test and stays.
- Touching the standalone `/CJ_portability-audit` skill (SKILL.md + USAGE.md) — it is the separate test and stays.
- Relabeling any skill's declared `portability` tier — this removes the gate, not any declaration.
- Removing the `spec/test-spec-custom.md` Check 18 unit rows / engine unit row or the F000047/S000083 engine fixture block in `test.sh` — those back the separate test.

## Success Criteria

- [ ] `grep -rn "phase portability-audit\|portability-red\|halted_at_portability"` over `scripts/cj-goal-common.sh` + the four `skills/CJ_goal_*/` dirs returns nothing.
- [ ] `./scripts/validate.sh` passes (Check 18 still strict; Check 24 marker cross-check consistent; Check 27 workflow docs fresh).
- [ ] `./scripts/test.sh` passes (no reference to the deleted test/integration block; the `task`-enum probe repointed and green).
- [ ] `/CJ_portability-audit` + `validate.sh` Check 18 still function unchanged.
- [ ] A dry-run of a cj_goal orchestrator no longer lists a portability gate node.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000123](S000123_remove_portability_gate/S000123_TRACKER.md) | Remove the portability gate from the cj_goal build path | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000123 (full extraction of the portability gate) | — | Not Started | chang | Single atomic multi-file change | — |
| 2 | End-to-end pipeline run: a cj_goal dry-run shows no portability node + full suite green | — | Not Started | chang | Success criteria 1–5 verified | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-07-02: Scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000123 (remove portability gate) --> #2 E2E: dry-run shows no portability node + suite green
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| None — scope, safety net, and file inventory are pinned in DESIGN.md + the source design doc's "Precise file inventory". | Resolved at scaffold time. |
