---
type: design
parent: F000068
title: "Wire the recap into the 4 pipelines + reframe the CLAUDE.md convention — Story Design"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
reviewers: []
---

<!-- Brief stub. Full design context lives in the parent feature design. -->

## Problem

The `--phase recap` formatter (S000112) exists but is unused until the four
cj_goal pipelines call it at their land/PR-stop steps and the CLAUDE.md
convention is reframed to describe the new before+after 3-part shape. This story
does that wiring.

## Shape of the solution

Reshape the terminal blocks of the two PR-stop verbs (feature Step 6.5, task
Step 7) to a single at-PR 3-part recap that calls the helper; add a before-recap
plus reshape the after-recap for the two landing verbs (defect around Step 10,
todo_fix around the `/ship → /land-and-deploy` tail per drained TODO). Each call
documents a prose fallback for an absent helper. Reframe `CLAUDE.md`
`## Post-land recap` to the 3-part before+after convention, name the helper as
producer, make the agent's content-authoring responsibility explicit, and keep
the advisory framing; update the `cj-goal-common.sh` Scripts-reference row. Add
`recap` to any docs Touches blocks that enumerate cj-goal-common phases. See the
parent design for the full rationale. Upstream `/land-and-deploy` is NOT edited.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Before+after for landing verbs; one at-PR recap for PR-stop verbs | The PR-stop verbs never land in-pipeline, so a single at-PR recap is correct; the human's later `/land-and-deploy` is the existing direct-land recap path. |
| 2 | Recap calls live in this repo's pipeline.md, not in `/land-and-deploy` | `/land-and-deploy` is untouchable upstream gstack (same rule as `/CJ_document-release`). |
| 3 | Documented prose fallback at each call site | Advisory posture — an absent helper must degrade to prose, never break the run. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Does the todo_fix verb wire the recap in `pipeline.md` or `SKILL.md`? | Resolve at implement — inspect the todo verb's file structure. |
| Do any docs Touches blocks enumerate cj-goal-common phases (needing a `recap` entry)? | Resolve at implement / doc-sync — grep the Touches blocks. |
| Advisory ⇒ a pipeline could silently drop the pointer | Accepted; QA greps each of the 4 pipeline.md files for the recap call. |

## Definition of done

- [ ] All four pipeline.md files reference the recap at their terminal/land step (before+after for landing verbs; one at-PR recap for PR-stop verbs).
- [ ] `CLAUDE.md` `## Post-land recap` reframed (3-part before+after, names the helper, agent-authoring + advisory framing explicit); Scripts-reference row updated.
- [ ] `scripts/validate.sh` green; grep confirms the recap pointer in each of the 4 pipelines.

## Not in scope

- Building the `--phase recap` formatter (that is S000112).
- Any `validate.sh` presence-check (advisory posture, parent decision).
- Editing upstream `/land-and-deploy`.

## Pointers

- Parent feature design: [../F000068_DESIGN.md](../F000068_DESIGN.md)
- Parent tracker: [../F000068_TRACKER.md](../F000068_TRACKER.md)
- Helper story: [../S000112_recap_helper/S000112_TRACKER.md](../S000112_recap_helper/S000112_TRACKER.md)
- Spec: [S000113_SPEC.md](S000113_SPEC.md)
- Test-spec: [S000113_TEST-SPEC.md](S000113_TEST-SPEC.md)
