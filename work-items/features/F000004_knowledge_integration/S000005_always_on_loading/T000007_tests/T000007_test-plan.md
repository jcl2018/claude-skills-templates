---
type: test-plan
parent: T000007
title: "tests — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Adds automated tests for S000005 (always-on category loading). Covers Tier 1 structural assertions, Tier 2 canary-based E2E scenarios, and a regression diff. No production code changes.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Tier 1 S1: SKILL.md has Knowledge Loading section | `grep -q "^## Knowledge Loading" skills/company-workflow/SKILL.md` | Match | Pending |
| 2 | Tier 1 S2: SKILL.md emits `## Always-On Knowledge` | grep output contract | Match | Pending |
| 3 | Tier 1 S3: SKILL.md instructs Claude to Read listed paths | case-insensitive grep | Match | Pending |
| 4 | Tier 1 S4: fixture `valid-knowledge-dir/coding/` present | `test -d` | True | Pending |
| 5 | Tier 1 S5: fixture has malformed-yml variant | `test -f .../broken/.knowledge.yml` | True | Pending |
| 6 | Tier 1 S6: WORKFLOW.md documents `.knowledge.yml` schema | grep `surface.*always\|always.*on-demand` | Match | Pending |
| 7 | Tier 2 E1: always-on canary reaches Claude | Export env to `valid-knowledge-dir`; ask about canaries; assert reply contains `CANARY_ALPHA_*` from `coding/` | Canary quoted | Pending |
| 8 | Tier 2 E2: on-demand canary NOT in reply when no trigger mentioned | Same env; ask about canaries without trigger keywords | No `runbooks/` canary | Pending |
| 9 | Tier 2 E3: malformed-yml warns + others load | Same env; inspect stderr + assert `coding/` canary still quoted | Warning for `broken/`; `coding/` canary present | Pending |
| 10 | Tier 2 E4: env unset → no always-on canaries | `unset AI_KNOWLEDGE_DIR`; ask | No canaries in reply | Pending |
| 11 | Regression: validate output stable | `validate` on `fixtures/valid-feature-dir` with env unset vs. set-to-valid-knowledge-dir; diff stdout | Empty diff | Pending |

## Verification Steps

- [ ] All new assertions pass `./scripts/test.sh`
- [ ] E2E scenarios reproducible manually in a real Claude Code session (not just scripted)
- [ ] Canary strings in tests reference the canaries from T000005 fixtures (no duplication)
- [ ] Test runtime under 30 s for Tier 1 (keeps pre-commit hook usable)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
