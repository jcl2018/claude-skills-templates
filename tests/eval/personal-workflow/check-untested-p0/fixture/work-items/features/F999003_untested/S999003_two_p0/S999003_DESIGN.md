---
type: design
parent: S999003
title: "Untested P0 fixture — Design"
version: 1
status: Draft
date: 2026-05-09
author: eval
reviewers: []
---

## Problem

Eval fixture exercising Step 18's `[UNTESTED]` flagging — a P0 story exists in SPEC but has no matching `AC-<n>` in the TEST-SPEC's `ac_set`.

## Shape of the solution

Two P0 stories (#1, #2). TEST-SPEC covers AC-1 only; AC-2 is intentionally absent. Step 18 must flag P0 #2 as `[UNTESTED]`.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Two P0s, one with coverage and one without | Cleanest signal: validator distinguishes covered from uncovered P0s |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| N/A — fixture | N/A |

## Definition of done

- [x] Fixture authored

## Not in scope

- Real implementation; this is a test fixture.

## Pointers

- Source: `tests/eval/personal-workflow/check-untested-p0/`
