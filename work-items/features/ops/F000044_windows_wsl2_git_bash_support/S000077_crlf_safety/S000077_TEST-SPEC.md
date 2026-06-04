---
type: test-spec
parent: S000077
feature: F000044
title: "CRLF safety (.gitattributes) — Test Specification"
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
| S1 | core | AC-1 | All `*.sh` are checked out with LF | Catches a CRLF regression on tracked shell scripts | `git ls-files --eol -- '*.sh' \| grep -v 'w/lf'` (empty = pass) |
| S2 | core | AC-2 | Entrypoint `eol` attribute is `lf` | Catches missing extensionless coverage | `git check-attr eol -- scripts/skills-deploy` |
| S3 | core | AC-3 | `*.png`/`*.jpg`/`*.ico` marked `binary` in .gitattributes | Catches EOL munging of binary files | `grep -E 'binary' .gitattributes` (non-empty = pass) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core post-ship | AC-1 | Fresh Windows clone has runnable scripts | Clone repo on Windows Git Bash; run `bash scripts/validate.sh` | scripts run; no `\r` / bad-interpreter errors | pass if validate.sh starts without CRLF errors (post-ship: requires a real Windows checkout, verified via the windows-latest CI from S000080) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Real Windows checkout line endings | Verified locally only via git attributes, not a live Windows FS | windows-latest CI (S000080) is the live check |
