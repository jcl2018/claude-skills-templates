---
type: test-plan
parent: {ITEM_ID}
title: "{ITEM_NAME} — Test Plan"
date: {YYYY-MM-DD}
author: {author}
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
| 1 | {original bug scenario} | {steps} | {fixed behavior} | Pass/Fail/Pending |
| 2 | {related scenario} | {steps} | {expected} | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] Local build succeeds (Windows/Linux)
- [ ] L1 regression suite passes
- [ ] Manual reproduction of original bug confirms fix
- [ ] {additional verification specific to this fix}

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| {OS + config} | {build ID or branch} | Pass/Fail |
