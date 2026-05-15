---
type: test-plan
parent: T000027
title: "Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S) — Test Plan"
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
| 1 | Manual verification: Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S) | When a work-item's acceptance criteria include rows that are structurally only verifiable post-ship (e.g., S000025 ACs 2/3/4/7 require `gh workflow run eval-nightly.yml` against merged main — the work | Behavior matches the TODO body and the heading description | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
