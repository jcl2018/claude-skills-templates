---
type: test-plan
parent: D000026
title: "doc-sync AUQ recommendation polarity fix — Test Plan"
date: 2026-05-31
author: chjiang
status: Draft
---

## Scope

Fix changes the AUQ template recommendation in 3 cj_goal SKILL.md preambles + 1 CLAUDE.md mechanism note. The change is text-only (no behavioral code change in the preamble bash) — the AUQ semantic flips polarity for the branch-aware recommendation. Regression tests assert both POSITIVE (corrected wording present) and NEGATIVE (pre-fix wording absent) via grep against the source files.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | regression test for D000026 root cause | `bash tests/cj-goal-doc-sync-auq-recommendation.test.sh` | 17/17 OK, PASS — all 3 SKILL.md + CLAUDE.md show corrected wording + pre-fix wording absent | smoke |
| 2 | full test suite still passes | `bash scripts/test.sh` | 0 failures, RESULT: PASS — new regression test wired in correctly | smoke |
| 3 | catalog/filesystem cross-check still passes | `bash scripts/validate.sh` | 0 errors, 0 warnings, RESULT: PASS | smoke |

## Verification Steps

- [x] `bash tests/cj-goal-doc-sync-auq-recommendation.test.sh` — 17/17 OK (verified by /investigate Phase 4)
- [x] `bash scripts/validate.sh` — 0 errors, 0 warnings (verified by /investigate Phase 4)
- [x] `bash -n scripts/test.sh` — syntax OK (verified by /investigate Phase 4)
- [x] `grep` sweep for pre-fix wording → confirmed gone from all source files (verified by /investigate Phase 4)
- [ ] Manual post-merge: next session's `/CJ_goal_feature` invocation should surface a doc-sync AUQ with B recommended on main, A flagged "would abort upstream"
