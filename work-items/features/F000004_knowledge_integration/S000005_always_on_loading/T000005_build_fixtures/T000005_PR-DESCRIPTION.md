---
type: pr-description
parent: T000005
title: "build-fixtures — PR Description"
date: 2026-04-16
author: chjiang
status: Draft
---

<!--
PR Description Template — TASK
TFS limit: 4,000 chars. Self-contained.
-->

[T000005] build-fixtures

## Summary

Adds `skills/company-workflow/fixtures/valid-knowledge-dir/` with five categories exercising every `.knowledge.yml` state the knowledge-loading impl needs: valid always-on, valid on-demand with triggers, missing yml, malformed yml, and empty-triggers on-demand.

## Motivation

S000005 (always-on loading) and S000006 (on-demand matching) both rely on deterministic, shared test fixtures. Authoring them as one standalone task keeps the impl PRs focused on code and lets reviewers diff the fixture tree in isolation. Unique canary strings per file enable unambiguous E2E assertions in downstream test tasks.

## Changes

- Created `fixtures/valid-knowledge-dir/` root
- `coding/` — `surface: always`; nested `cpp/errors.md` + top-level `style.md` with canaries
- `runbooks/` — `surface: on-demand`, `triggers: [pricing, "pricing engine"]`; `pricing.md` with canary
- `notes/` — no `.knowledge.yml` (missing-yml default behavior)
- `broken/` — intentionally malformed yml (error-path fixture)
- `empty-triggers/` — `surface: on-demand`, `triggers: []` (never-matched fixture)
- Added fixture README explaining each category's test intent

## Affected Workflows

**Test suite:** New test tasks (T000007, T000010) will assert against this fixture.
**Skill runtime:** Unaffected — fixture directory is not auto-loaded by any command.

## Test Plan

Structural assertions only — fixture files are inputs to downstream impl tests.

| # | Scenario | Verified By | Result |
|---|----------|-------------|--------|
| 1 | All category dirs present | `./scripts/test.sh` (post-T000007 wiring) | Pending |
| 2 | `.knowledge.yml` contents match declarations | grep assertions in T000007 | Pending |
| 3 | Each canary string is unique | `grep -R CANARY_ fixtures/valid-knowledge-dir | sort -u | wc -l` | Pending |
