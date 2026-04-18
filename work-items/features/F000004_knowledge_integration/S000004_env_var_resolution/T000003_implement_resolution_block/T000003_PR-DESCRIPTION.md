---
type: pr-description
parent: T000003
title: "implement-resolution-block — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained — TFS reviewers cannot click links to
local files (RCA.md, test-plan.md, etc.). Inline-summarize whatever they need.

To paste:
  1. Strip this comment block and the YAML frontmatter above.
  2. Fill in {placeholders}. Keep prose tight — every sentence costs ~80 chars.
  3. Paste the body below into the TFS PR description field.
  4. Verify length under 4,000 chars before submitting.
-->

[T000003] implement-resolution-block

## Summary

Adds a Knowledge Resolution step to the company-workflow skill that reads `AI_KNOWLEDGE_DIR`, validates the path, exposes the result as `$_KNOWLEDGE_DIR`, and emits a one-line warning on stderr when the variable is unset or points at a non-directory.

## Motivation

First of three vertical slices (S000004 / S000005 / S000006) delivering F000004 knowledge integration. This slice only teaches the skill where knowledge lives; loading ships in follow-ups. The warn-every-invocation behavior is deliberate — it nudges engineers to configure the feature rather than silently losing its value. No knowledge files are read yet, so context size is unchanged.

## Changes

- Added `## Knowledge Resolution` section to `skills/company-workflow/SKILL.md`, running after `## Path Resolution`
- Bash block: reads `AI_KNOWLEDGE_DIR`, validates with `[ -d ... ]`, sets skill-local `$_KNOWLEDGE_DIR` (empty on failure)
- Warning text: one line, names the variable, points at WORKFLOW.md setup section; exit code unchanged
- Distinct failure-mode warnings: unset/empty vs. path-not-found vs. path-is-file
- Added `## Knowledge Configuration` (or similar) subsection under WORKFLOW.md Installation with export example

## Affected Workflows

**company-workflow validate (file + directory mode):** Prelude runs one extra step; validate output on stdout is byte-identical to pre-change.
**skills-deploy install:** No change; SKILL.md + WORKFLOW.md still deploy via existing mechanism.

## Test Plan

Covered by T000004: Tier 1 grep-based smoke on SKILL.md structure + Tier 2 E2E with env unset / valid-path / bad-path / file-not-dir + regression diff on existing fixture output.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | Env unset → single stderr warning, exit 0 | T000004 Tier 2 E1 | Pending |
| 2 | Env set to valid dir → no warning | T000004 Tier 2 E2 | Pending |
| 3 | Env set to bad path → warning names path | T000004 Tier 2 E3 | Pending |
| 4 | Zero regression on existing fixtures | T000004 regression diff | Pending |
