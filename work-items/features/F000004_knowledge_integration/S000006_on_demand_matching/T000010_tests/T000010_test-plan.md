---
type: test-plan
parent: T000010
title: "tests — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Adds automated tests for S000006 (on-demand trigger matching + loading). Covers Tier 1 structural assertions, Tier 2 canary-based E2E scenarios spanning single-word / phrase / empty-triggers / case variations / multi-match / match-log, plus a regression diff.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tier 1 S1: SKILL.md has On-Demand Matching section | `grep -q "^## On-Demand Matching" skills/company-workflow/SKILL.md` | Match | Pending |
| 2 | Tier 1 S2: emits `## On-Demand Knowledge Candidates` | grep | Match | Pending |
| 3 | Tier 1 S3: instruction mentions match + Read | case-insensitive grep | Match | Pending |
| 4 | Tier 1 S4: case-insensitive + phrase semantics documented | grep | Match | Pending |
| 5 | Tier 1 S5: match log format present | grep `[knowledge] matched` | Match | Pending |
| 6 | Tier 1 S6–S7: fixtures + WORKFLOW.md current | `test -f`, grep | Match | Pending |
| 7 | Tier 2 E1: single-word trigger pulls category | Ask "explain pricing"; assert `CANARY_PE_1` in reply | Canary present | Pending |
| 8 | Tier 2 E2: phrase trigger matches phrase | Ask "how does the pricing engine handle rounding?" | Category loaded (canary quoted) | Pending |
| 9 | Tier 2 E3: phrase NOT match on substring | Ask "what is pricing?" (no "pricing engine") | Category NOT loaded | Pending |
| 10 | Tier 2 E4: no trigger in prompt → nothing loaded | Unrelated prompt | Zero on-demand canaries in reply | Pending |
| 11 | Tier 2 E5: multi-match loads all | Ask "audit pricing auth" | Both category canaries in reply | Pending |
| 12 | Tier 2 E6: case variations | Ask with CPP / Cpp / cpp | All three trigger loading | Pending |
| 13 | Tier 2 E7: empty triggers never load | Any prompt | `empty-triggers/` canary absent | Pending |
| 14 | Tier 2 E8: match log emitted on matches | Matching scenario | stderr contains `[knowledge] matched: runbooks via pricing` | Pending |
| 15 | Regression diff: validate stdout unchanged | Run validate with / without on-demand categories | Empty diff | Pending |

## Verification Steps

- [ ] All new assertions pass `./scripts/test.sh`
- [ ] E2E scenarios reproducible manually in a Claude Code session
- [ ] Canary strings declared once (no duplication across T000007 and T000010)
- [ ] Tier 2 suite runtime kept manageable (flag or subset for fast loops)
- [ ] Match log text captured as a test fixture so regressions are loud

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
