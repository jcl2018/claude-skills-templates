---
type: design
parent: S000027
title: "Personal-pipeline skill implementation — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Brief stub — see parent F000014_DESIGN.md for full orchestrator design.
     This story owns the implementation layer (file structure, frontmatter
     decisions, fixture layout). -->

## Problem

F000014's design specifies the /personal-pipeline orchestrator's behavior. This
story implements that design as an actual skill in the workbench: SKILL.md as
the entry point, pipeline.md as the step-by-step logic, fixtures for regression
testing, and a catalog entry to make it deployable.

Blocked on S000026 because two of the orchestration steps (Phase 2 AUQ
propagation, all subagent return parsing) hinge on subagent behavior that hasn't
been verified.

## Shape of the solution

```
skills/personal-pipeline/
├── SKILL.md          # frontmatter + preamble + path resolution + usage + error handling (compact)
├── pipeline.md       # the 9-step orchestration logic (the meaty file)
└── fixtures/
    ├── example-design-doc/                       # synthetic design that exercises all phases (happy path)
    ├── regression-pre-scaffold-idempotency/      # F000010 design as input → expect Phase 1 short-circuit
    ├── regression-partial-write-halt/            # partial scaffold dir → expect halt on Step 2 branch (c)
    └── regression-broken-validate/               # implement output breaking validate.sh → expect post-implement halt
```

Plus: one entry in `skills-catalog.json` and the catalog metadata (name, version, description, source, depends, portability=standalone, status=experimental).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Two-file skill (SKILL.md + pipeline.md), like F000010's children | SKILL.md becomes a small entry point (preamble, paths, error table); pipeline.md holds the meaty logic. Matches established workbench convention. |
| 2 | Three regression fixtures + one happy-path | Each regression case maps to a specific design decision (pre-scaffold idempotency, partial-write recovery, post-implement gate). One happy-path proves the full chain. |
| 3 | `subagent_type: general-purpose` everywhere in v1 | Custom subagent types deferred per F000014_DESIGN Open Q1. Revisit if tool-access lockdown becomes load-bearing. |
| 4 | Status: experimental in catalog (not active) | Sunset criterion built into the skill itself; experimental status signals "may be deleted at run 6 if trip-wire fires." |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| If S000026 finds AUQ doesn't bubble, Phase 2 redesign required (pre-collect AUQs at orchestrator) | Wait for S000026 findings.md before authoring pipeline.md |
| Fixtures may not deterministically reproduce subagent behavior across model versions | Document Claude Code version + model overlay used when fixtures were validated |
| `skill-deploy install` may need to copy `fixtures/` (or skip them as test artifacts) | Check existing F000010 children's deployment behavior; mirror it |

## Definition of done

- [ ] SKILL.md + pipeline.md authored, total ≤ 800 lines combined
- [ ] Catalog entry validates; `skills-deploy install` deploys cleanly to `~/.claude/skills/personal-pipeline/`
- [ ] All 4 fixtures (1 happy + 3 regression) exist with documented expected outcomes
- [ ] First real run on a TODOS.md entry green end-to-end
- [ ] Bootstrap re-pipe of F000014's own design doc hits pre-scaffold idempotency short-circuit (proves the dogfooding case)

## Not in scope

- Multi-story feature looping (parent F000014_DESIGN halt-after-scaffold for ≥1 child)
- `scripts/test.sh` in post-implement gate
- Custom `subagent_type` definitions
- Behavioral eval harness integration (TODOS.md F000013 V1 covers eval.sh; integration deferred until orchestrator stable)
- TODOS.md:26 fix in this story (separate item, defense-in-depth for direct scaffold use)

## Pointers

- Parent tracker: [S000027_TRACKER.md](S000027_TRACKER.md)
- SPEC: [S000027_SPEC.md](S000027_SPEC.md)
- TEST-SPEC: [S000027_TEST-SPEC.md](S000027_TEST-SPEC.md)
- Parent feature design: [F000014_DESIGN.md](../F000014_DESIGN.md)
- Sibling: [S000026_DESIGN.md](../S000026_subagent_spike/S000026_DESIGN.md) (the spike that gates this story)
