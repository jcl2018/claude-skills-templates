---
type: test-plan
parent: T000057
title: "Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report. — Test Plan"
date: 2026-07-05
author: Charlie Jiang
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
| 1 | Manual verification: Make /CJ_test_run's report show the agentic cold-agent prompt and response — the portability-version-agentic test currently prints only a one-line PASS summary; surface the exact prompt sent to claude --print and the agent's JSON verdict/response in a detailed report. | Apply the change and exercise it | Behavior matches the topic description | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
