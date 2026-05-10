---
type: design
parent: S999000
title: "Greeting fixture — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Synthetic fixture stub. Each section gets a single brief sentence — the
     real value is in TEST-SPEC.md and fixture-impl.txt. -->

## Problem

A trivial "produce a greeting file" user-story exists solely to give /CJ_qa-work-item something to QA. The implementation has a planted bug so the QA engineer subagent has a known-red criterion to find.

## Shape of the solution

Author `fixture-impl.txt` containing a greeting string. SPEC asserts the exact greeting; the planted bug is that `fixture-impl.txt` disagrees with the assertion.

## Big decisions

- Plant the bug in content, not structure. Smoke (file existence, non-empty) passes; E2E (exact content match) fails.

## Risks & open questions

- Subagent ambiguity: the subagent might judge "Hello, world" as semantically equivalent to "Hello, World!" and call it green. The TEST-SPEC explicitly demands exact match (capital W, exclamation point) to keep the verdict crisp.

## Definition of done

- `/CJ_qa-work-item skills/CJ_qa-work-item/fixtures/example-user-story/` returns smoke green + E2E red, with the red finding naming the content mismatch.

## Not in scope

- Anything beyond the single planted bug. v1 ships one fixture per /plan-eng-review Issue 3.1A.

## Pointers

- `S999000_TEST-SPEC.md` for the exact assertions
- `fixture-impl.txt` for the planted bug
- `../../../../skills/CJ_qa-work-item/qa.md` Step 7 for the subagent contract
