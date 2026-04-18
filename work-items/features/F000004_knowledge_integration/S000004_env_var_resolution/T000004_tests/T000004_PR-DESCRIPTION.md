---
type: pr-description
parent: T000004
title: "tests — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained — TFS reviewers cannot click links to
local files (RCA.md, test-plan.md, etc.). Inline-summarize whatever they need.
-->

[T000004] tests

## Summary

Adds Tier 1 smoke, Tier 2 E2E, and a regression diff for S000004 (knowledge-dir env var resolution). No production code changes; test wiring only.

## Motivation

S000004's resolution block (T000003) ships first; without tests, a future edit to the warning text or the variable name would silently drift and the feature's user-facing contract would erode. The regression diff ensures the new prelude step does not alter any existing `validate` output.

## Changes

- Extended `scripts/test.sh` with Tier 1 grep assertions: SKILL.md has Knowledge Resolution section; references `AI_KNOWLEDGE_DIR` and `_KNOWLEDGE_DIR`; WORKFLOW.md documents the env var
- Added Tier 2 E2E scenarios: env unset, env=valid dir, env=bad path, env=file — asserts stderr warning text and exit code
- Added regression diff: runs validate on `fixtures/valid-feature-dir/` with env unset vs. env=valid dir, asserts empty diff
- Test fixtures created in-script via `mktemp -d` (no new fixture files on disk)

## Affected Workflows

**Local dev / pre-commit:** `./scripts/test.sh` runs +9 new assertions; adds <5 s.
**CI:** same test script; CI turnaround unchanged materially.

## Test Plan

Meta: this task IS the test code. Manual verification — run `./scripts/test.sh` after checkout, confirm all new cases pass; toggle `AI_KNOWLEDGE_DIR` in a real shell and confirm warning matches.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | New Tier 1 asserts pass | `./scripts/test.sh` | Pending |
| 2 | E2E env-unset emits warning | Manual: `unset AI_KNOWLEDGE_DIR; /company-workflow validate <fixture>` | Pending |
| 3 | Regression diff is empty | `./scripts/test.sh` diff step | Pending |
