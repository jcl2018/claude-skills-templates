---
type: design
parent: S000029
title: "Phase 0 spike — parser surface + Step 8.5 scan surface enumeration — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Atomic-story design. See parent F000015_DESIGN.md for cross-story context.
     Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md -->

## Problem

Two load-bearing assumptions sit under F000015's design:

1. The synthesized stub design doc satisfies `/scaffold-work-item`'s parser surface (title, mode, recommended-approach, type, component, possibly others).
2. The stub's `(none, brief mode bypasses ...)` placeholders cannot match any taste-fork scan pattern in `/personal-pipeline` Step 8.5 (auto-mode final gate).

If either is wrong, the design changes shape: extend the stub template (preferred), harden the stub (omit problem sections or use sentinel placeholder strings), or escalate to Approach B (deferred). Editing pipeline.md before verifying both is a recipe for cascading rework.

## Shape of the solution

A 10–15 line journal note on the S000029 tracker enumerating both surfaces and recording an explicit extend / harden / escalate action.

**Phase 0.a, parser-surface check:**
- Read `skills/scaffold-work-item/scaffold.md` end-to-end.
- Enumerate every design-doc field the parser consumes (frontmatter fields + section headers + content shapes).
- Cross-reference against the synthesized stub template (in F000015's DESIGN).
- Verdict: yes (stub satisfies) / no (stub needs extension or escalation).

**Phase 0.b, Step 8.5 scan-surface check:**
- Read `skills/personal-pipeline/pipeline.md` Step 8.5 implementation.
- Enumerate which design-doc / SPEC sections the auto-mode final gate scans for Taste / User-Challenge surfaces.
- Confirm the stub's `(none, brief mode bypasses ...)` placeholders cannot match any taste-fork scan pattern.
- Verdict: yes (placeholders are inert) / no (harden the stub).

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Spike is mandatory and BLOCKING before any pipeline.md edits | Either outcome workable, but the design changes shape. Editing pipeline.md against unverified assumptions risks cascading rework. |
| 2 | Combined output is a single journal note on this tracker, not a separate doc | The output is short (10–15 lines), action-oriented, and lives where the implementer of S000030 will look. |
| 3 | Three escape valves: extend, harden, escalate | Extend the stub template (preferred, low effort); harden the stub (use sentinel placeholders or omit sections); escalate to Approach B (deferred — document reason in TODOS.md). |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Parser field requires non-derivable input not in the brief | Phase 0.a; if true, escalate (document reason) |
| Step 8.5 scans top-level design-doc sections not just SPEC Tradeoffs | Phase 0.b; if true, harden stub (sentinel placeholders) |

## Definition of done

- [ ] Phase 0.a verdict written: parser fields enumerated, stub satisfies (yes/no)
- [ ] Phase 0.b verdict written: Step 8.5 scan surface enumerated, placeholders inert (yes/no)
- [ ] Action taken recorded: extend / harden / escalate
- [ ] If escalate: TODOS.md entry created with reason

## Not in scope

- Any pipeline.md edits — strictly read-only spike
- Implementing the stub template extension (S000030 owns implementation if extension is the action)

## Pointers

- Parent tracker: [S000029_TRACKER.md](S000029_TRACKER.md)
- Parent feature design: [../F000015_DESIGN.md](../F000015_DESIGN.md)
- Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md`
- Read-only inputs: `skills/scaffold-work-item/scaffold.md`, `skills/personal-pipeline/pipeline.md`
