---
type: test-spec
parent: S000080
feature: F000044
title: "Windows CI job + docs — Test Specification"
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
| S1 | observability | AC-1 | workflow has a windows job | catches a missing/renamed job | `grep the workflow YAML for 'runs-on: windows-latest'` |
| S2 | usability | AC-3 | README has Windows section | catches missing docs | `grep README.md for a "Running on Windows" heading` |
| S3 | usability | AC-4 | CLAUDE.md notes Windows (WSL2 + Git Bash) support | catches missing agent-facing doc note | `grep -iE 'windows' CLAUDE.md` (non-empty = pass) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core post-ship | AC-2 | Windows CI runs green on a PR | Open a PR; observe the windows-latest job | job runs and passes | pass if the job is green (post-ship: the workflow only exists on remote refs AFTER merge, so per TEST-SPEC post-ship semantics /CJ_qa-work-item defers this row; verify via `gh workflow run` / a follow-up PR) |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| WSL2 CI job | not added in v1 (needs a marketplace action) | deferred; Git Bash job is the Windows signal |
| Full suite on Windows | only a subset runs on windows-latest | full suite stays on ubuntu/macOS |
