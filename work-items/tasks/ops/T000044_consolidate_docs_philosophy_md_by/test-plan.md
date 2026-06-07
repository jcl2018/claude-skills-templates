---
type: test-plan
parent: T000044
title: "Consolidate docs/philosophy.md by grouping principles under named topics: the five harness-engineering principles under a Harness-engineering best practices topic, and one-source-of-truth / two-delivery / doc-contract under a new Deployment topic — Test Plan"
date: 2026-06-07
author: Charlie
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

Documentation-only reorganization of `docs/philosophy.md`: introduces a **topic**
(principle-group) layer — a **Deployment** topic grouping the 3 build/delivery
principles and a **Harness-engineering best practices** topic grouping the 5
runtime principles — plus a redesigned leading summary table and one anchor-link
fix in `docs/architecture.md`. No code, no behavior change.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | `validate.sh` stays green | `bash scripts/validate.sh` | Exit 0; Checks 15/15a/15b/16/17/19/20 + New-skills check all pass | Pending |
| 2 | Front table precedes first `##` (Check 20) | Inspect `docs/philosophy.md` head | A summary table appears before the first `## ` heading | Pending |
| 3 | No work-item IDs (Check 19) | `grep -nE '[FSTD][0-9]{6}' docs/philosophy.md` | Zero matches | Pending |
| 4 | Two topic headings exist | `grep -nE '^## (Topic: )?(Deployment\|Harness-engineering)' docs/philosophy.md` | Both topic `##` headings present | Pending |
| 5 | All former principles survive as `###` | Inspect headings | 3 Deployment `###` + 5 harness `###` principle headings present; no content deleted | Pending |
| 6 | Decision-tree anchor preserved | `grep -n '^## Decision tree: which CJ_ skill do I call?' docs/philosophy.md` | Exact heading present and is the last `##` | Pending |
| 7 | Every routable skill still named in Decision tree | `jq -r '.[]\|select(.status=="active")\|select((.files\|length)>0).name' skills-catalog.json` then grep each in the Decision-tree section | Every active routable skill name appears | Pending |
| 8 | architecture.md anchor link fixed | `grep -n 'philosophy.md#' docs/architecture.md` | No dangling `#principle-2-…` link; points at `#two-delivery-surfaces-one-contract` | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `bash scripts/validate.sh` exits 0
- [ ] `docs/philosophy.md` renders the two-topic structure correctly (manual read)
- [ ] No inbound anchor link to `docs/philosophy.md` is left dangling

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
