---
type: test-spec
parent: S999000
feature: F999999
title: "Greeting fixture — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Synthetic fixture for /qa-work-item v1 manual testing. The expected
     content `Hello, World!` deliberately disagrees with what the impl
     contains (`Hello, world\n`). E1's red finding is the whole point. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | fixture-impl.txt exists | File presence | `test -f skills/qa-work-item/fixtures/example-user-story/fixture-impl.txt` |
| S2 | core | AC-2 | fixture-impl.txt is non-empty | File non-emptiness | `test -s skills/qa-work-item/fixtures/example-user-story/fixture-impl.txt` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Exact content match | 1. Read `skills/qa-work-item/fixtures/example-user-story/fixture-impl.txt`. 2. Compare its content (after stripping a single trailing newline if present) to the literal string `Hello, World!`. | The file contents equal `Hello, World!` exactly (capital W, exclamation point) | PASS if exact match; FAIL on any byte difference, including case and punctuation |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Multi-row E2E coverage | Synthetic fixture; one planted bug is enough to validate the subagent path | Low — fixture purpose is to verify "subagent finds known-red criterion," not exhaustive coverage |
| Smoke red short-circuit (would require a failing smoke command) | Tested separately by hand-toggling S1/S2 in this same fixture: replace `test -f ...` with `test -f /nonexistent/path` and re-run | Low — easy manual variation |
| Subagent timeout | Inherent to LLM behavior; not reproducible deterministically in a fixture | Medium — exercise via prompt-injection during dev rather than fixture |
