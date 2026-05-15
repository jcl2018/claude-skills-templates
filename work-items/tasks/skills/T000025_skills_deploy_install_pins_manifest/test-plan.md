---
type: test-plan
parent: T000025
title: "`skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S) — Test Plan"
date: 2026-05-14
author: test
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

<!-- What does the fix change? Which files/components were modified? -->

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Manual verification: `skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S) | `scripts/skills-deploy install` records `manifest.source` (in `~/.claude/.skills-templates.json`) as the running clone's `REPO_ROOT`, computed from the script's own path. When invoked from `.claude/wo | Behavior matches the TODO body and the heading description | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
