---
type: design
parent: S000017
title: "scaffold-work-item skill — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Atomic story scaffold; the parent feature's DESIGN.md is the primary
     context. This DESIGN.md is a brief stub. -->

## Problem

`/scaffold-work-item` is the first of three pipeline skills. Today the user manually directs Claude to read `WORKFLOW.md`, `personal-artifact-manifests.json`, and `templates/personal-workflow/*`, then write a directory tree. The skill codifies that operation into a single command.

See parent: [F000010_DESIGN.md](../F000010_DESIGN.md) for the full feature shape and the other two pipeline skills' interactions with this one.

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Read design doc + templates + manifest | S000017 | this story |
| Determine work-item type, generate ID, fill placeholders | S000017 | this story |
| Write directory tree + run boundary check | S000017 | this story |

This is an atomic story — no further sub-decomposition.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Skill takes one explicit path argument (design-doc-path) | Explicit > inferred. User always knows what input drove the scaffold |
| 2 | Type derived from branch name with AskUserQuestion fallback | Branch naming is the existing convention (per WORKFLOW.md); on `main` or unmatched branches, ask the user |
| 3 | Multi-story decomposition: AskUserQuestion to confirm N + slugs | Design docs vary in how alternatives map to user-stories; no auto-magic |
| 4 | No validator subagent in v1 (boundary check via /personal-workflow check) | Source design says optional; 1.3A boundary check covers the same drift detection |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Where does multi-story slug suggestion come from (design's "Recommended Approach" parsing)? | Implementation: read design doc, surface alternatives via AskUserQuestion |
| Should scaffold append a footer to the source design doc at `~/.gstack/projects/...`? (Open Q3 of source) | Implementation: yes, recommended; small `Status: SCAFFOLDED → ...` footer for traceability |
| What about scaffolding nested children (feature → user-story but not feature → user-story → task)? | v1: scaffold one level deep (feature + immediate children); deeper nesting is manual |

## Definition of done

- [ ] Skill file written, validated by `validate.sh`, deployed by `skills-deploy install`
- [ ] Acceptance criteria in [TRACKER.md](S000017_TRACKER.md) all green
- [ ] Golden fixture authored and snapshot-diff documented in SKILL.md

## Not in scope

- Validator subagent — already optional in source; covered by 1.3A
- Auto-iteration over children (scaffold one feature dir at a time, not "scaffold this whole tree of features")

## Pointers

- Parent: [S000017_TRACKER.md](S000017_TRACKER.md)
- Spec: [S000017_SPEC.md](S000017_SPEC.md)
- Test spec: [S000017_TEST-SPEC.md](S000017_TEST-SPEC.md)
- Feature design: [F000010_DESIGN.md](../F000010_DESIGN.md)
