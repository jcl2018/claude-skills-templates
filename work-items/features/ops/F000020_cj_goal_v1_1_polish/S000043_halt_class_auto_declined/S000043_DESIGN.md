---
type: design
parent: S000043
title: "Halt-class semantic rename `_user_declined` → `_auto_declined` (WI-B) — Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- This story derives from the parent feature's /office-hours session.
     See parent F000020_DESIGN.md for full context. -->

## Problem

`/CJ_goal`'s sensitive-surface gate at `goal.sh:296` emits end_state `halted_at_sensitive_surface_user_declined` when the bash AUQ auto-defaults. This is a misnomer — under bash there is no AUQ tool, so the script defaults regardless of caller (no human ever declined). The end_state name lies about what happened. The halt-class table maps `_user_declined` to STOP (correct interpretation given the name), so `/loop /CJ_goal` halts on what is structurally an auto-default routine "needs human" gate.

See parent F000020_DESIGN.md for full context and how this complements WI-A.

## Shape of the solution

A one-line semantic rename plus a halt-class table update:

1. Rename the case in `goal.sh:296` from `halted_at_sensitive_surface_user_declined` to `halted_at_sensitive_surface_auto_declined`.
2. Update the halt-class lookup table so `_auto_declined` is in the **continue** column (mirror `halted_at_preflight`).
3. Update `skills/CJ_goal/SKILL.md` halt-class documentation table to reflect the new end_state and its continue-set membership.
4. The original `_user_declined` end state remains reserved for the future interactive AUQ at orchestrator layer (currently no consumer; lands when interactive path ships).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Semantic rename + halt-class continue-set update | S000043 | This story |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Just rename the existing end_state, don't introduce both `_auto_declined` AND `_user_declined` upfront | YAGNI — `_user_declined` has no consumer today; lands when interactive AUQ ships at orchestrator layer. |
| 2 | Discriminator is disposition (was-a-human-present), not caller-detection (was-it-/loop) | Smaller blast radius; no /loop env contract introduced; future-proof for non-/loop unattended contexts (cron, daemon). |
| 3 | Add to continue set (mirror `halted_at_preflight`) | Auto-default + skip-list = defer gate; same semantic as preflight rejection. /loop continues; next interactive run re-encounters the row. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Anyone consuming the old `_user_declined` end state externally? | Grep this repo + codex consumers; rename is breaking only if external consumers parse end_states (low risk; all known consumers are internal). |
| Semantic rename in addition to WI-A pre-filter — both bypass the gate; redundant? | Defense in depth: WI-A handles happy path (sensitive rows never enter candidate set); WI-B handles bypass paths (interactive fragment from inside /loop, regex updates landing out of sync). Keep both. |

## Definition of done

- [ ] `goal.sh:296` emits `_auto_declined` (not `_user_declined`).
- [ ] Halt-class table in SKILL.md lists new end_state in continue column.
- [ ] /loop /CJ_goal hitting sensitive-surface row continues to next iteration.

## Not in scope

- Introducing `halted_at_sensitive_surface_user_declined` as a separately-emitted end state — defers until interactive AUQ at orchestrator layer ships (no concrete consumer today).
- Changing the gate's behavior when it fires — gate still skip-lists the row + writes journal entry; only the end_state name and halt-class membership change.
- WI-A pre-filter (separate story S000042).
- WI-C skip-list reset RCA (separate defect D000020).

## Pointers

- Parent tracker: [S000043_TRACKER.md](S000043_TRACKER.md)
- Parent feature: [../F000020_TRACKER.md](../F000020_TRACKER.md)
- Source design: /Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-125052.md
