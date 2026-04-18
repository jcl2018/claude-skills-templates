---
type: test-plan
parent: T000008
title: "refactor-shared-helper — Test Plan"
date: 2026-04-16
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Refactor: extracts the yml parser + category/file enumeration shared between S000005 (always-on) and the upcoming S000006 (on-demand). Behavior-preserving. Test plan is the regression gate — the refactor must not change any observable output.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | T000006's full test-plan still passes | Run `./scripts/test.sh` post-refactor | All prior cases Pass | Pending |
| 2 | T000007's Tier 1 asserts still pass | Same | Pass | Pending |
| 3 | T000007's Tier 2 canary E2E still pass | E2E runner | Always-on canary still quoted; on-demand still absent | Pending |
| 4 | SKILL.md bytes differ (refactor landed) but `validate` output identical | `diff` on skill output pre/post refactor over a fixture | No output diff | Pending |
| 5 | Helper is callable/sourceable from both intended consumers | Dry-run: grep for helper usage in both Knowledge Loading and a placeholder On-Demand section | At least two call sites (one now + one commented TODO for T000009) | Pending |
| 6 | WORKFLOW.md helper contract matches actual bash | Manual doc review | Aligned | Pending |
| 7 | Malformed-yml category still isolated | Rerun S000005 E3 scenario | Warning emitted; others load | Pending |

## Verification Steps

- [ ] Running `./scripts/test.sh` before + after on the same branch shows identical Pass/Fail matrix
- [ ] `./scripts/validate.sh` passes
- [ ] Code review of the diff confirms behavior preservation (no silent semantic changes)
- [ ] A comment or TODO in SKILL.md indicates the helper is ready for T000009 consumption

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
