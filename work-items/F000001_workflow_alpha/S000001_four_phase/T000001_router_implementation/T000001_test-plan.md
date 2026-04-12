---
type: test-plan
parent: "T000001_router_implementation"
title: "Router Implementation — Test Plan"
date: "2026-04-11"
author: chjiang
status: Complete
---

## Scope

Validate the branch-aware SKILL.md router that detects work item type from branch naming
and dispatches to the correct subcommand (track, implement, review, ship).

## Regression Test Cases

| # | Test Case | Steps | Expected | Status |
|---|-----------|-------|----------|--------|
| 1 | feat/* branch resolves to feature type | On feat/test branch, invoke /workflow | Type=feature detected | Superseded (skill deleted) |
| 2 | fix/* branch resolves to defect type | On fix/test branch, invoke /workflow | Type=defect detected | Superseded (skill deleted) |
| 3 | task/* branch resolves to task type | On task/test branch, invoke /workflow | Type=task detected | Superseded (skill deleted) |

## Verification Steps

Router implementation was verified during F000001 workflow-alpha development. The /workflow
skill was subsequently deleted (commit 8a03260) and its logic moved to CLAUDE.md rules.
These test cases are historical.

## Environments Tested

- macOS Darwin 25.x, Claude Code CLI
