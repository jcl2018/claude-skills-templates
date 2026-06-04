---
type: test-spec
parent: S000078
feature: F000044
title: "Portable POSIX runtime (date + OS gate) — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | suggest ranking runs on Linux | catches date/gate regression off macOS | run suggest.sh against a fixture on Linux, assert exit 0 |
| S2 | core | AC-3 | gate admits Linux | catches a too-narrow gate | assert no refuse when uname=Linux |
| S3 | observability | AC-4 | improve_queue audit on non-Darwin | proves the gated path is exercised in CI | `improve_queue.sh ... audit` returns non-refuse on ubuntu |
| S4 | core | AC-2 | improve_queue.sh date math on Linux/WSL2 | catches BSD-only `date -j` regression off macOS | run `improve_queue.sh ... evaluate` against a fixture on Linux; assert correct epoch, no error |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | WSL2 user ranks TODOs | On WSL2, run /CJ_suggest | ranked rows print, no macOS-only refusal | pass if rows rank with sane ages |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| True WSL2 environment | ubuntu-latest CI is the Linux proxy | minor: WSL2 ~= Linux for these scripts |
| Timezone edge cases for bare-date parsing | within-a-day divergence accepted for age_days | low risk |
