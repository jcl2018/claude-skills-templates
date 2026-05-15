---
type: design
parent: S000042
title: "/CJ_suggest preflight-aware mode + --limit flag (WI-A) — Design"
version: 1
status: Draft
date: 2026-05-15
author: chjiang
reviewers: []
---

<!-- This story derives from the parent feature's /office-hours session.
     See parent F000020_DESIGN.md for full context, problem statement, and
     scope decisions. This doc captures only the WI-A-specific shape. -->

## Problem

`/CJ_goal` no-args path reads `/CJ_suggest` top-1 then post-filters via skip-list. Two compounding problems make this unreliable under `/loop /CJ_goal`:

1. /CJ_suggest hard-caps output at top-5. When 5+ of those top ranks are skip-listable (P1 size-cap rows + sensitive-surface rows + meta-`/CJ_goal` polish TODOs), the post-filter empties and `/CJ_goal` halts even though TODOS.md has more eligible-but-lower-ranked rows.
2. /CJ_suggest's ranker has no knowledge of `/CJ_goal`'s preflight rejects (P1 size-cap, size L/X, sensitive surfaces, design-needed keywords). So /CJ_suggest's top-5 routinely contains rows /CJ_goal will reject 100% of the time, wasting budget against the cap.

See parent F000020_DESIGN.md for full context.

## Shape of the solution

Add two opt-in flags to `/CJ_suggest`:

- `--for-skill <name>` — applies named-skill's preflight criteria at ranking time, excluding rows that will preflight-reject. Initial supported value: `cj-goal`. Forward-extensible via per-skill predicate sets.
- `--limit N` — extends the top-N cap. Default remains 5 for un-flagged callers (no behavior change).

`/CJ_goal` no-args path then calls `/CJ_suggest --for-skill cj-goal --limit 15`. Sensitive-surface rows simply never enter the candidate window under /loop, so the gate never fires (and #1 of the parent design — sensitive-surface STOP — disappears as a side effect for the /loop case).

| Concern | User-story | Artifact |
|---------|-----------|----------|
| /CJ_suggest pre-filter + extended limit | S000042 | This story |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Pre-filter lives in /CJ_suggest, not in /CJ_goal post-filter | Single mechanism; doesn't waste preflight scaffolding budget on rows that'll reject. Coupling is opt-in (default behavior preserved). |
| 2 | `--limit N` default stays at 5 | Interactive /suggest output stays compact; only /CJ_goal callers opt into deeper queue. |
| 3 | Predicate set per-`<name>`, not generic predicate API | `cj-goal` is the only consumer today; YAGNI on a generic API. New consumers add a per-name predicate block (one-liner per criterion). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| If /CJ_suggest's pre-filter empties the candidate set entirely, /CJ_goal halts at_resolve. With WI-A this is more likely. Acceptable? | Bundle acceptance verification; current pick: yes — `halted_at_resolve` is honest signaling. |
| Coupling /CJ_suggest with /CJ_goal preflight knowledge — drift risk if /CJ_goal's preflight changes without updating /CJ_suggest. | Documented as known coupling; address via shared predicate file if drift becomes painful. |

## Definition of done

- [ ] `/CJ_suggest --for-skill cj-goal --limit 15` returns up to 15 rows, none of which trip /CJ_goal preflight.
- [ ] `/CJ_suggest` with no flags returns top-5 unchanged (regression test).
- [ ] /CJ_goal no-args path calls /CJ_suggest with the new flags.
- [ ] /loop /CJ_goal session that previously starved at iter 10 now drains 12+ iterations.

## Not in scope

- Generic `--predicate` API on /CJ_suggest — per-`<name>` block is enough; YAGNI.
- Adding additional `--for-skill <name>` consumers beyond `cj-goal` in this story.
- WI-B halt-class rename (separate user-story S000043).
- WI-C skip-list reset RCA (separate defect D000020).

## Pointers

- Parent tracker: [S000042_TRACKER.md](S000042_TRACKER.md)
- Parent feature: [../F000020_TRACKER.md](../F000020_TRACKER.md)
- Source design: /Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260515-125052.md
