---
type: design
parent: F000043
title: "Self-explanatory suggest cards — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- Atomic story. This DESIGN.md is a brief stub; the full problem shape,
     big decisions, and rejected alternatives live in the parent feature's
     design. See parent F000043_DESIGN.md for context. -->

## Problem

`/CJ_suggest`'s interactive top-5 table is hard to scan — terse titles, a bare
`S/M/L` Size letter, and no plain-language description force the operator to
open `TODOS.md` before choosing. See parent F000043_DESIGN.md for the full
problem statement.

## Shape of the solution

Add a `render_cards` path in `suggest.sh` gated on an empty `$FOR_SKILL`. Each
ranked item becomes a card: header (`N. [ID] Title   Pri · Effort`), a wrapped
`What:` line (first non-empty body line via `extract_body`), and a `Status:`
line (the existing `Why` reasons). `--for-skill` falls through to the unchanged
markdown table. Effort = the `Size` letter expanded to a label. See parent
F000043_DESIGN.md `## Shape of the solution`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Render fork on `[ -n "$FOR_SKILL" ]`; consumer path untouched | Keeps the table byte-stable for `/CJ_goal_todo_fix`. See parent F000043_DESIGN.md decision 1. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Consumer table byte-stability | TEST-SPEC smoke S1 asserts `--for-skill cj-goal` output is byte-identical to today. See parent for full risk table. |

## Definition of done

- [ ] Default path renders cards; `--for-skill` renders the byte-stable table; edge cases (missing TODOS.md, no items, empty body) preserved. See parent F000043_DESIGN.md `## Definition of done`.

## Not in scope

- `--table` interactive override flag — deferred. See parent F000043_DESIGN.md `## Not in scope` for the full boundary.

## Pointers

- Parent feature design: [../F000043_DESIGN.md](../F000043_DESIGN.md)
- Parent tracker: [../F000043_TRACKER.md](../F000043_TRACKER.md)
- Story tracker: [S000076_TRACKER.md](S000076_TRACKER.md)
- SPEC: [S000076_SPEC.md](S000076_SPEC.md)
- TEST-SPEC: [S000076_TEST-SPEC.md](S000076_TEST-SPEC.md)
