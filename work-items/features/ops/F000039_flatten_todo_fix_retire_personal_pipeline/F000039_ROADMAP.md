---
type: roadmap
parent: F000039
title: "Flatten /CJ_goal_todo_fix off /CJ_personal-pipeline and retire the skill — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals, decomposition, delivery timeline. -->

## Scope

Flatten `/CJ_goal_todo_fix` (both single-TODO and drain modes) so it dispatches
`/CJ_implement-from-spec` → `/CJ_qa-work-item` as leaf Agent subagents directly — the
proven F000027 feature/defect pattern — instead of driving the `/CJ_personal-pipeline`
middle layer. With its last caller gone, delete `/CJ_personal-pipeline` outright and
sweep every live-surface reference (catalog, docs, rules, README, sibling skills,
handoff-gate, validate.sh Check 12, test.sh). Rename the halt taxonomy and rewrite the
catalog `depends.skills`. The end state: all three cj_goal orchestrators share one
flatten shape, and the workbench loses an experimental skill whose only job was a chain
the other orchestrators already run inline.

## Non-Goals

- A downstream-portability guard for `/CJ_goal_todo_fix` — the rationale Check 12 protected dies with the skill; whether todo_fix needs its own is a separate follow-up.
- Touching `/CJ_personal-workflow` (the validator) — a different skill, untouched.
- Cleaning `work-items/` history references to `CJ_personal-pipeline` — out of scope; history retained.
- Re-consolidating the three orchestrators into one shared engine (Approach C) — rejected.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] `/CJ_goal_todo_fix` single-TODO mode dispatches `/CJ_implement-from-spec` → `/CJ_qa-work-item` leaf subagents; no `/CJ_personal-pipeline` reference remains in its SKILL.md / pipeline.md / scripts.
- [ ] Drain mode dispatches impl→qa per drained TODO; `drain-one-todo.sh:255` `--force-create` isolation unchanged and still asserted.
- [ ] `skills/CJ_personal-pipeline/` deleted; catalog entry removed; `CJ_goal_todo_fix.depends.skills` rewritten to the real dispatch list.
- [ ] Halt taxonomy renamed (`halted_at_pipeline_*` → `halted_at_impl`/`halted_at_qa`).
- [ ] `validate.sh` Check 12 block removed AND `test.sh` (~line 1138) reconciled in the same change.
- [ ] `./scripts/validate.sh` green; `./scripts/test.sh` green.
- [ ] `grep -rI "CJ_personal-pipeline" skills/ scripts/ doc/ rules/ CLAUDE.md README.md` returns nothing.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000072](S000072_flatten_and_retire_impl/S000072_TRACKER.md) | Flatten todo_fix + retire /CJ_personal-pipeline (implementation) | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000072 — flatten both modes, rename taxonomy, delete skill, clean references, reconcile validate.sh/test.sh | — | Not Started | chjiang | Single implementation story carrying the whole change | — |
| 2 | End-to-end verification — validate.sh + test.sh green; live-surface grep sweep returns nothing | — | Not Started | chjiang | Final acceptance gate | 1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. -->

- 2026-06-03: Scaffolded F000039 + child S000072 from the APPROVED office-hours design.

## Dependency Graph

<!-- Visual representation of milestone ordering. -->

```
#1 Ship S000072 (flatten + delete + reference cleanup) --> #2 E2E verification (validate.sh + test.sh green + grep sweep clean)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| `depends.skills` final list — include `CJ_scaffold-work-item` if the bash scaffold counts as a dependency? | Resolve during implementation against the real dispatch list (S000072 SPEC AC #3). |
| Does `/CJ_goal_todo_fix` need its own portability guard once Check 12 is gone? | Out of scope — separate follow-up if ever needed. |
