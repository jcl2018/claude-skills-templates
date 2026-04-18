---
type: pr-description
parent: T000010
title: "tests — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000010] tests

## Summary

Adds Tier 1 smoke, Tier 2 canary-based E2E, and a regression diff for S000006 (on-demand trigger matching). Closes the test coverage for F000004 knowledge integration.

## Motivation

T000009 ships the on-demand matching contract between the skill and Claude. The match rule (case-insensitive whole-word + quoted-phrase) and the "no match → don't load" behavior are both user-observable and easy to regress on a careless SKILL.md edit. Canary-based E2E tests pin the behavior precisely; Tier 1 greps pin the contract text.

## Changes

- Extended `scripts/test.sh` with Tier 1 asserts (S1–S7): section presence, candidates block format, instruction wording, case-insensitive + phrase match spec, match log format
- Tier 2 E2E (E1–E8): single-word match; phrase match; phrase non-match on substring; no-trigger silence; multi-match union; case variants; empty-triggers dark; match log emission
- Regression diff: validate output byte-identical with / without on-demand categories
- Reuses canary infrastructure from T000007
- Wired into `./scripts/test.sh` (pre-commit + CI)

## Affected Workflows

**Local / CI test suite:** +15 assertions total; Tier 1 fast; Tier 2 behind a flag for long-loop runs.
**Skill runtime:** Unaffected.

## Test Plan

Meta — this is the test code. Manual verification: run the suite, toggle prompt wording, confirm match log + canaries track expected matches.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | Tier 1 asserts pass | `./scripts/test.sh` | Pending |
| 2 | E2E trigger-match canaries appear in Claude replies | Manual + E2E runner | Pending |
| 3 | E2E non-match keeps replies free of on-demand canaries | Same | Pending |
| 4 | Regression diff empty | Script step | Pending |
