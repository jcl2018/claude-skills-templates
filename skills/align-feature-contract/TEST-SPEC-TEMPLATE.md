---
type: test-spec
parent: {FEATURE_ID}
title: "{Feature Name} — Test Specification"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

<!-- Each row maps to a PRD acceptance criterion via the AC column.
     Every P0 criterion needs at least one test case. -->

| # | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | {description} | AC-{n} | {setup} | {steps} | {expected} | P0/P1/P2 | Unit/Integration/E2E |

## Test Tiers

<!-- Every feature has two test tiers. Smoke tests validate structure without
     running the full system. E2E tests validate real user experience. -->

### Tier 1: Smoke Tests (automated, no skill execution)

<!-- Static/structural checks: file existence, schema validation, section headers,
     frontmatter fields. Can run in CI or via a shell script. Fast, deterministic. -->

| # | Check | What It Validates | Script/Command |
|---|-------|-------------------|---------------|
| S1 | {description} | {what passes/fails} | `{command}` |

### Tier 2: E2E Tests (manual, real user workflow)

<!-- Full skill execution: invoke the actual skill, observe output, verify behavior
     matches AC. Requires Claude. Rubric-scored by human. -->

| # | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|----------|----------------------------|-----------------|--------|
| E1 | {description} | {step-by-step what user does} | {what user sees} | {pass/fail criteria} |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| {untested scenario} | {reason} | {what could go wrong} |
