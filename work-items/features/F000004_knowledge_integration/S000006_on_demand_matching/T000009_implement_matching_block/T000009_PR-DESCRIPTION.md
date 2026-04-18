---
type: pr-description
parent: T000009
title: "implement-matching-block — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000009] implement-matching-block

## Summary

Adds on-demand knowledge loading to the company-workflow skill. The skill emits candidate categories (path + triggers + files) and instructs Claude to match triggers against the user's latest message and Read the matched categories before answering.

## Motivation

Third vertical slice of F000004. Always-on (S000005) loads house knowledge every turn; on-demand (this story) only loads when the user mentions a category's declared triggers — the escape hatch from context-budget inflation when knowledge bases grow large. Matching runs in Claude (it has the prompt) not bash (it doesn't); the skill's role is to discover candidates and instruct precisely.

## Changes

- Added `## On-Demand Matching` section to `skills/company-workflow/SKILL.md`, running after `## Knowledge Loading`
- Reuses shared helper (T000008) for enumeration + yml parsing
- Emits `## On-Demand Knowledge Candidates`: one block per category with root path, triggers list, recursive `*.md` paths
- Claude-facing instruction: case-insensitive whole-word match on prompt tokens; multi-word triggers treated as phrases at token boundaries; match on ANY trigger; load ALL matched categories; scoped to latest user message only
- Match log format: `[knowledge] matched: <cat> via <trigger>; ...` on stderr (observability for trigger tuning)
- Empty-triggers categories never emitted as candidates (unreachable by design)
- Extended `valid-knowledge-dir/` fixture with phrase-only trigger category (if not already present)
- Updated `skills/company-workflow/WORKFLOW.md`: on-demand worked example, trigger-authoring guidance, security callout (knowledge file content is trusted by Claude via Read)

## Affected Workflows

**company-workflow validate:** Prelude runs one extra step; stdout output unchanged.
**skills-deploy install:** SKILL.md + WORKFLOW.md continue to deploy via existing path.

## Test Plan

T000010 owns automated tests. This PR's dev-loop gate: manual checklist in T000009 test-plan.md + fixture-driven trigger scenarios.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | Trigger keyword pulls category into Reads | Manual E2E with canary | Pending |
| 2 | Phrase trigger matches only the phrase | Manual | Pending |
| 3 | No-trigger prompt loads nothing on-demand | Manual | Pending |
| 4 | `./scripts/validate.sh` passes | CI | Pending |
