---
type: design
parent: F999001
title: "Test Feature — Feature Design"
version: 1
status: Draft
date: 2026-01-01
author: chjiang
reviewers: []
---

## Problem

Test fixture for the CJ_company-workflow validator's directory-mode happy-path
case. Demonstrates the canonical 4-artifact set required for `type: feature`
(tracker + feature-summary + DESIGN + milestones).

## Shape of the solution

| Concern | User-story | Artifact |
|---------|-----------|----------|
| (none — fixture has no nested user-stories) | — | — |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Use bare filenames (no `F999001_` prefix) | Fixture exercises the no-prefix branch of the directory-mode filename matching rule |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| — | — |

## Definition of done

- [ ] Validator returns no violations on this directory

## Not in scope

- Real-world feature semantics — this is a fixture, not a deliverable

## Pointers

- Parent tracker: [TRACKER.md](TRACKER.md)
- Milestones: [milestones.md](milestones.md)
