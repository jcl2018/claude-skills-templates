---
type: test-plan
parent: T000056
title: "Add a Topic column to docs/tests/index.md grouping related tests by topic (portability / core-suite / cj-goal-workflows) so a reader knows which tests fully cover a topic — Test Plan"
date: 2026-07-04
author: Charlie Jiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

<!-- What does the fix change? Which files/components were modified? -->

Adds a hand-maintained **Topic** column to `docs/tests/index.md` (between the
`Tier` and `Doc` columns) grouping the declared category tests by topic
(`portability` / `core-suite` / `cj-goal-workflows`), plus a one-line intro
paragraph explaining the grouping and a comment noting the column is NOT sourced
from the `categories:` axis. Rows are reordered to sit together by topic. Pure
hand-maintained-doc edit — NO change to the `categories:` contract, the engine,
or any script. Only `docs/tests/index.md` is modified.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Topic column added to docs/tests/index.md, index still a valid declared human-doc referencing all 12 declared tests, safe from doc-sync/Check 26 | Run `bash scripts/test-spec.sh --check-structure` (six checks a-f); `bash scripts/doc-spec.sh --check-on-disk`; grep the index for `[FSTD][0-9]{6}` (Check 19); `bash scripts/test-spec.sh --render-docs` then confirm the index is byte-identical | check-structure: a-f PASS findings=0 (check (e) references all declared names); check-on-disk: 5 checks findings=0; no work-item IDs; render leaves index byte-identical | Pass |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [x] `bash scripts/test-spec.sh --check-structure` → six checks a-f PASS, findings=0, exit 0
- [x] `bash scripts/doc-spec.sh --check-on-disk` → 5 checks, findings=0, exit 0 (valid declared human-doc)
- [x] Check 19: `grep -E '[FSTD][0-9]{6}' docs/tests/index.md` → no work-item IDs
- [x] `bash scripts/test-spec.sh --render-docs` → `docs/tests/index.md` byte-identical (hash unchanged) — Topic column safe from doc-sync + Check 26

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | main / current branch | Pending |
