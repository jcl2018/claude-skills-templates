---
type: design
parent: F000043
title: "Make /CJ_suggest rows self-explanatory (what-it-does + effort) — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

`/CJ_suggest` prints a ranked top-5 of next-up work items as a markdown table
(`Rank | Title | Pri | Size | Status | Why`). To decide what to pick up you have
to already know what each TODO *is* — the title is terse, `Size` is a bare
`S/M/L` letter, and there's no plain-language description of what the work
actually does. The operator ends up opening `TODOS.md` to read the body before
choosing.

The ask: make each ranked row self-explanatory at a glance — carry a short
"what it does" line and a readable effort estimate inline. The data is already
there (every TODO heading has body prose; the `Size` letter already encodes
effort), so this is pure formatting leverage — no model call, no new data source.

## Shape of the solution

A single render fork in `suggest.sh`. The default interactive invocation
renders each ranked item as a card block: a header line
(`N. [ID] Title   Pri · Effort`), a wrapped `What:` line drawn from the body's
first non-empty prose line (via the existing `extract_body` helper), and a
`Status:` line folding in the existing `Why` reasons. When `--for-skill` is
non-empty (the machine path, e.g. `/CJ_goal_todo_fix`), the code falls through
to the current markdown table renderer unchanged. The render keys on
`[ -n "$FOR_SKILL" ]`. Effort labels expand the existing `Size` letter:
`S → quick (<1h)`, `M → ~half-day`, `L → large (1-2 days)`.

This is one cohesive single-script change, scoped as one atomic user-story.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Card render fork + effort labels + docs/test | S000076 | [S000076_self_explanatory_suggest_cards/S000076_TRACKER.md](S000076_self_explanatory_suggest_cards/S000076_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Card list for interactive only; keep the markdown table for `--for-skill` consumers (Approach A) | Approach B (add `What`/`Effort` columns to the one table) wraps badly in a terminal — the exact "hard to scan" problem being fixed, just wider. Approach C (cards everywhere) is a breaking change to a second skill (`todo_fix.sh` awk parser + its test fixture) with larger blast radius for no interactive-UX gain. A leaves the consumer path literally untouched. |
| 2 | "What it does" = first non-empty prose line of the TODO body (via `extract_body`), not a truncated summary | Keep the explanation a clean deterministic thing the author controls, not a heuristic blurb that's sometimes cut mid-thought. Quality tracks TODOS.md authoring — that's already where the detail lives. |
| 3 | Effort = the existing `Size` letter expanded to a label, no new judgement | Coarse rough estimates that reuse the Size signal; add no new input or scoring change. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Consumer table must stay byte-stable or `/CJ_goal_todo_fix` drain mode breaks (todo_fix.sh:334-337 parses col 2 = title) | TEST-SPEC smoke row asserts `--for-skill cj-goal` output is byte-identical to today |
| `What` line is only as good as the TODO body's first line | Accepted: low-signal first line → fix is better TODOS.md authoring, not skill logic. No fallback heuristic in v1 beyond `(no description)` for empty bodies. |
| A `--table` flag to force the old table in interactive mode | Deferred follow-up, not in scope for v1 |

## Definition of done

- [ ] No-flag `suggest.sh` prints a card list (ID when present, title, `Pri · Effort`, `What:`, `Status:`).
- [ ] `--for-skill cj-goal --limit 15` prints the byte-stable table as today.
- [ ] Empty-body rows render `What: (no description)`; orphan / default signals still visible in `Status:`.
- [ ] Edge cases preserved: missing TODOS.md → exit 1; no actionable items → `No actionable items.` + exit 0.
- [ ] SKILL.md "Surface convention" + USAGE.md updated; a test asserts table byte-stability under `--for-skill` and card markers on the default path.

## Not in scope

- `--table` interactive override flag — deferred follow-up.
- Any change to scoring, candidate selection, ranking, or the `Why` reasons — render-only change.
- Touching the consumer path / `todo_fix.sh` / its awk parser — preserved, not modified.
- A fallback heuristic for low-signal first lines beyond `(no description)`.

## Pointers

- Parent tracker: [F000043_TRACKER.md](F000043_TRACKER.md)
- Roadmap: [F000043_ROADMAP.md](F000043_ROADMAP.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-225728-46346-design-20260603-230051.md`
