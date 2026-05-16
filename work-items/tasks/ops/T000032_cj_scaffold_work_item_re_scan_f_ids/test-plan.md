---
type: test-plan
parent: T000032
title: "`/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S) — Test Plan"
date: 2026-05-16
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
| 1 | Manual verification: `/CJ_scaffold-work-item`: re-scan F-IDs against `origin/main` post-fetch (P2, S) | F000023 collision shipped through F000024 (PR #140). Root cause: scaffolder picked F000023 based on the worktree's view of `work-items/features/ops/`, which lagged behind `origin/main` by a few hours. | Behavior matches the TODO body and the heading description | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
