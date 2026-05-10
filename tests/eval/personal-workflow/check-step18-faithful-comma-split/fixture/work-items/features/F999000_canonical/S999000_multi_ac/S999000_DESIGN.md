---
type: design
parent: S999000
title: "Multi-AC traceability fixture — Design"
version: 1
status: Draft
date: 2026-05-09
author: eval
reviewers: []
---

## Problem

Eval fixture for the comma-split traceability check. Stands in for a real user-story with multi-AC traceability cells.

## Shape of the solution

Three P0 stories (#1, #2, #3) covered via multi-AC cells in TEST-SPEC.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Multi-AC cells in both Smoke and E2E tables | Exercises the comma-split contract end-to-end |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| N/A — fixture | N/A |

## Definition of done

- [x] Fixture authored

## Not in scope

- Real implementation; this is a test fixture.

## Pointers

- Source: `tests/eval/personal-workflow/check-step18-faithful-comma-split/`
