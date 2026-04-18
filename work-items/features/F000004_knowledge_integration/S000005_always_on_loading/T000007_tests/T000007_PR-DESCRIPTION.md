---
type: pr-description
parent: T000007
title: "tests — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000007] tests

## Summary

Adds Tier 1 smoke, Tier 2 canary-based E2E, and a regression diff for S000005 (always-on category loading). No production code changes.

## Motivation

T000006 ships the always-on loading code. Without canary-based E2E tests, regressions where Claude silently stops reading listed knowledge paths would be invisible — the Tier 1 greps only catch structural drift. The regression diff guards `validate` stdout against the new prelude step.

## Changes

- Extended `scripts/test.sh` with Tier 1 asserts (S1–S6): SKILL.md has Knowledge Loading + Always-On Knowledge + Read instruction; WORKFLOW.md documents `.knowledge.yml` schema; fixtures present
- Added Tier 2 E2E (E1–E4) using T000005 fixtures + canary strings: always-on reaches Claude; on-demand doesn't surface without triggers; malformed-yml isolated; env-unset silent
- Added regression diff: validate on `valid-feature-dir` with env unset vs. `valid-knowledge-dir`, assert byte-identical stdout
- Wired new tests into `./scripts/test.sh` (runs in CI + pre-commit)

## Affected Workflows

**Local / CI test suite:** +10 assertions; Tier 1 adds <5 s; Tier 2 runs behind a flag to keep pre-commit fast.
**Skill runtime:** Unaffected.

## Test Plan

Meta — this task IS the test code. Manual verification: run the suite post-checkout; toggle fixture content and confirm Tier 2 reports the expected canaries.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | Tier 1 asserts pass | `./scripts/test.sh` | Pending |
| 2 | E2E always-on canary in Claude reply | Manual + E2E runner | Pending |
| 3 | Regression diff empty | Script step | Pending |
