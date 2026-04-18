---
type: pr-description
parent: T000008
title: "refactor-shared-helper — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000008] refactor-shared-helper

## Summary

Extracts the `.knowledge.yml` parser and category/file enumeration from T000006's always-on block into a shared helper in SKILL.md, so T000009 (on-demand matching) can reuse it without duplication. Pure refactor — no behavior change.

## Motivation

Always-on (S000005) and on-demand (S000006) both need the same three primitives: enumerate top-level categories, parse `.knowledge.yml` (subset: `surface`, `triggers`), recursively list `*.md` under a category with deterministic sort. Inlining twice creates drift risk. Shipping the refactor as its own PR gives reviewers a clean behavior-preservation diff before T000009 introduces new semantics on top.

## Changes

- Moved shared parsing + enumeration into a named section (e.g., `## Knowledge Helpers`) inside `skills/company-workflow/SKILL.md`
- Rewrote `## Knowledge Loading` (always-on) to call the helper instead of inlining the logic
- Added a small `## Knowledge Helpers` note to `skills/company-workflow/WORKFLOW.md` describing the supported yml subset (so callers know what works)
- No change to output format, warning text, or exit codes

## Affected Workflows

**company-workflow validate:** Output unchanged.
**skills-deploy install:** Unchanged (same files deploy).

## Test Plan

Full regression against T000006 + T000007 test suites — both must pass unchanged post-refactor. New primary case: diff skill output on a fixture before vs. after the refactor should be empty.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | T000006 + T000007 assertions unchanged | `./scripts/test.sh` | Pending |
| 2 | Skill output diff on fixture is empty | Manual diff | Pending |
| 3 | Helper callable from a second site (on-demand TODO marker) | grep | Pending |
