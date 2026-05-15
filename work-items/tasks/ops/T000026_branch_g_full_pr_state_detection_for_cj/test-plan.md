---
type: test-plan
parent: T000026
title: "Branch(g) full PR-state detection for `/CJ_run` (P2, M) — Test Plan"
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
| 1 | Manual verification: Branch(g) full PR-state detection for `/CJ_run` (P2, M) | Branch(g)'s current candidate filter uses TRACKER Phase 1/2/3 gate states to determine "in-progress" — it doesn't call `gh pr view` because the user-story TRACKER template has no `pr:` frontmatter fie | Behavior matches the TODO body and the heading description | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
