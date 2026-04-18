---
type: pr-description
parent: T000006
title: "implement-loading-block — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000006] implement-loading-block

## Summary

Adds Knowledge Loading to the company-workflow skill. After resolution (T000003), the skill enumerates top-level categories under `$_KNOWLEDGE_DIR`, reads each `.knowledge.yml`, and for `surface: always` categories emits a deterministic block listing their markdown files so Claude reads them before answering.

## Motivation

Second vertical slice of F000004. Layer 1 (resolution) only tells the skill where knowledge lives; Layer 2 (this change) actually injects the "always-apply" material — house coding style, team conventions — so the user doesn't copy-paste it into every prompt. Isolated per category: a malformed `.knowledge.yml` warns and skips, other categories keep loading.

## Changes

- Added `## Knowledge Loading` section to `skills/company-workflow/SKILL.md`, running after `## Knowledge Resolution`
- Minimal bash yml parser for two supported keys (`surface`, `triggers`); flat scalar + list-of-strings values
- Category enumeration: top-level subdirs of `$_KNOWLEDGE_DIR`, skipping hidden + non-dirs
- Deterministic output: categories lex-sorted; files within each lex-sorted by relative path
- Emits `## Always-On Knowledge` with absolute paths, plus a Claude-facing instruction block: "Before answering, Read every path listed"
- Warning for malformed `.knowledge.yml`: one line, names the file + reason; skip category; continue
- Missing `.knowledge.yml` treated as on-demand + empty triggers (silent, no warning)
- Soft warning above 50 KB total always-on content
- Updated `skills/company-workflow/WORKFLOW.md`: `.knowledge.yml` schema, worked always-on example, bash-parser supported subset, malformed-file behavior

## Affected Workflows

**company-workflow validate:** Prelude runs one extra step when `$_KNOWLEDGE_DIR` is populated; stdout output unaffected.
**skills-deploy install:** SKILL.md + WORKFLOW.md continue to deploy via existing path.

## Test Plan

T000007 owns automated tests. This PR's ship-gate: manual dev-loop checklist in T000006 test-plan.md + new fixture from T000005.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | Always-on loaded, others not | Manual against `valid-knowledge-dir` fixture | Pending |
| 2 | Malformed yml warns + skips; others load | Manual vs. `broken/` category | Pending |
| 3 | `./scripts/validate.sh` passes | CI | Pending |
