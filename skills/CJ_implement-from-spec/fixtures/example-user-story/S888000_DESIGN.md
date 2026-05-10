---
type: design
parent: S888000
title: "Greeting writer fixture — Design"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
reviewers: []
---

<!-- Synthetic fixture stub. Each section gets a single brief sentence — the
     real value is in SPEC.md and the post-dogfood produced file. -->

## Problem

A trivial "write a single greeting file" user-story exists solely to give /CJ_implement-from-spec something to implement. The SPEC describes the file path and contents exactly; the dogfood verifies the skill can read SPEC, plan a one-file write, and execute it.

## Shape of the solution

SPEC names `output/greeting.txt` (NEW) and asserts content `Hello from /CJ_implement-from-spec\n`. The skill writes the file via `Write` tool, updates the tracker, runs boundary check.

## Big decisions

- One file, content exactly known. Tests that the skill can implement a SPEC verbatim, not that it can interpret ambiguous architecture. Real ambiguity is dogfooded by running on real user-stories (E1 in TEST-SPEC).

## Risks & open questions

- LLM determinism: the model might add extra whitespace, change capitalization, or include a comment. The TEST-SPEC's exact-byte-match is the calibration: mismatch means the skill failed to follow the SPEC verbatim.

## Definition of done

- `/CJ_implement-from-spec skills/CJ_implement-from-spec/fixtures/example-user-story/` (or with `--auto`) writes `output/greeting.txt` with exact content; tracker has `[impl-pass]` journal entry; Phase 2 implementer-owned gates green; `/CJ_personal-workflow check` PASS.

## Not in scope

- Multi-file implementations, sensitive-surface variations, propose-and-confirm modify-loop. Those are exercised via fixtures/README.md hand-toggle variations rather than separate fixtures.

## Pointers

- `S888000_SPEC.md` for the exact contract
- `S888000_TEST-SPEC.md` for verification logic
- `../../implement.md` Step 9 for the write logic
