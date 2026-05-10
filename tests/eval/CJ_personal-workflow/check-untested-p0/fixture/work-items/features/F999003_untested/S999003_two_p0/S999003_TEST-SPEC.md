---
type: test-spec
parent: S999003
feature: F999003
title: "Untested P0 fixture — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: eval
spec: SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Smoke for behavior A | Feature A correctness | `bash test.sh A` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | E2E for behavior A | Run feature A | Expected output appears | Output matches |

## Coverage Gaps

P0 story #2 is deliberately uncovered for fixture purposes — Step 18 should flag `[UNTESTED] P0 story #2 has no TEST-SPEC coverage`.
