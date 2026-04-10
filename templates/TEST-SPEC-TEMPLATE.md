---
type: test-spec
parent: {PARENT_ID}
feature: {FEATURE_ID}
title: "{Feature Name} — Test Specification"
version: 1
status: Draft
date: {YYYY-MM-DD}
author: {author}
prd: PRD.md
architecture: ARCHITECTURE.md
---

## Test Matrix

<!-- Each row maps to a PRD acceptance criterion via the AC column.
     Every P0 criterion needs at least one test case.
     "Tag" = domain keyword matching the PRD story this test traces to
       (core, resilience, observability, usability, security, integration). -->

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | {tag} | {description} | AC-{n} | {setup} | {steps} | {expected} | P0/P1/P2 | Unit/Integration/E2E |

## Test Tiers

<!-- Every feature has two test tiers. Both are needed:
     - Tier 1 (smoke): Fast, deterministic, catches structural regressions without invoking AI
     - Tier 2 (E2E): Real execution, catches behavioral regressions in prompts and output
     Tier 1 alone can't test AI behavior. Tier 2 alone is slow and non-deterministic.
     Together they form a fast-then-thorough pipeline. -->

### Tier 1: Smoke Tests (automated, no live execution)

<!-- Static/structural checks: file existence, schema validation, section headers,
     frontmatter fields. Can run via a shell script. Fast, deterministic. -->

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | {tag} | {description} | {what passes/fails} | `{command}` |

### Tier 2: E2E Tests (real end-to-end execution)

<!-- Full end-to-end execution: invoke the actual feature, observe output, verify behavior
     matches AC. Requires Claude. Can be manual (rubric-scored) or automated
     via an E2E test skill that creates fixtures and invokes the skill under test. -->

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | {tag} | {description} | {step-by-step what user does} | {what user sees} | {pass/fail criteria} |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| {untested scenario} | {reason} | {what could go wrong} |
