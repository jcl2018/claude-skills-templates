---
type: test-plan
parent: T000003_human_readable_report
title: "Human-readable work item health report — Test Plan"
date: 2026-04-12
author: chjiang
status: Draft
---

## Scope

Add `.docs/work-item-report.md` output to `/docs check` and `/docs tree`. A markdown file humans can read directly, similar to system-health's dashboard format.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Report generated on /docs check | Run `/docs check` | `.docs/work-item-report.md` exists with tree + badges + findings | Pending |
| 2 | Report regenerated each run | Run `/docs check` twice | Report reflects latest state, not stale | Pending |
| 3 | /docs tree writes lightweight report | Run `/docs tree` | `.docs/work-item-report.md` with structural badges only | Pending |
| 4 | Report readable without tooling | Open `.docs/work-item-report.md` in any markdown viewer | Clear, scannable, no JSON | Pending |
| 5 | Repos without work-items | Run `/docs check` on repo with no work-items/ | No report generated, no error | Pending |

## Verification Steps

- [ ] `.docs/work-item-report.md` renders correctly in GitHub markdown preview
- [ ] Report matches the console output from /docs check
- [ ] `./scripts/validate.sh` passes

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin) | feat/structural-completeness | Pending |
