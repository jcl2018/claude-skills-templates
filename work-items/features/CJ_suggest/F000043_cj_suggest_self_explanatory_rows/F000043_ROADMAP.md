---
type: roadmap
parent: F000043
title: "Make /CJ_suggest rows self-explanatory (what-it-does + effort) — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — scope/non-goals, decomposition, delivery timeline. -->

## Scope

Re-present what `/CJ_suggest` already computes so its interactive top-N is
scannable in under 10 seconds: each ranked item becomes a card carrying a
plain-language "what it does" line (the TODO body's first line) and a readable
effort label (the `Size` letter expanded). The machine-consumed path
(`--for-skill`) keeps emitting today's byte-stable markdown table so
`/CJ_goal_todo_fix` drain mode keeps parsing it. Render-only: no change to
scoring, ranking, or what's selected.

## Non-Goals

- A `--table` flag to force the old table in interactive mode — deferred follow-up, not needed for v1.
- Any change to scoring / candidate selection / ranking / the `Why` reasons — this feature only changes how the chosen rows render.
- Modifying the consumer path or `todo_fix.sh`'s awk parser — the table is preserved, not touched.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] No-flag invocation prints a card list (ID when present, title, `Pri · Effort`, `What:` line, `Status:` line).
- [ ] `--for-skill cj-goal --limit 15` prints output byte-identical to today's table.
- [ ] Empty-body rows render `What: (no description)`.
- [ ] Missing TODOS.md → exit 1; no actionable items → `No actionable items.` + exit 0.
- [ ] SKILL.md "Surface convention" + USAGE.md document the card layout and the consumer-table fork.

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000076](S000076_self_explanatory_suggest_cards/S000076_TRACKER.md) | Self-explanatory suggest cards | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000076 (card render fork + effort labels + docs + test) | — | Not Started | chjiang | Single-script change in suggest.sh | — |
| 2 | End-to-end pipeline run (scaffold → implement → QA → ship) | — | Not Started | chjiang | Feature-level verification | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-06-03: Scaffolded F000043 from /office-hours design.

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000076 (card render fork) --> #2 End-to-end pipeline run
```

## Open Questions

| Question | Next check |
|----------|-----------|
| Add a `--table` interactive override flag? | Deferred follow-up — revisit only if operators ask for the old table interactively |
| Fallback heuristic for low-signal first body lines? | Out of scope for v1 — fix is better TODOS.md authoring |
