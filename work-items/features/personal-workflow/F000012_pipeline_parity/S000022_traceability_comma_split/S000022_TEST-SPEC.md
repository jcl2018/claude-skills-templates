---
type: test-spec
parent: S000022
feature: F000012
title: "Step 18 traceability comma-split fix — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke = automated regression. E2E = manual user-scenario walkthrough.
     Soft cap: 5 rows per tier. AC column maps to SPEC story numbers. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Step 18 prose contains explicit comma-split instruction | Prose tightening landed | `grep -q "split the cell on comma" skills/personal-workflow/check.md` |
| S2 | core | AC-4 | Running `/personal-workflow check` on F000010 produces zero false `[UNTESTED]` findings on multi-AC P0 stories | The bug is gone end-to-end | manual: `/personal-workflow check work-items/features/personal-workflow/F000010_pipeline_skills/`; inspect output for S000018 P0 #2/#3/#5/#6 and S000019 P0 #2/#4 |
| S3 | resilience | AC-3 | Mixed cell `AC-{n}, AC-1` correctly drops placeholder, keeps real AC | Comma-split runs before placeholder filter | manual: scaffold a fixture TEST-SPEC with `AC-{n}, AC-1` cell; run check; observe AC-1 in ac_set, no spurious UNTESTED |
| S4 | resilience | AC-5 | Existing edge cases (`-` / blank cells, placeholder rows) still produce expected output | No regression on edge-case behavior | manual: run check on a TEST-SPEC with blank AC cell + placeholder row; confirm same output as v1.10.0 |
| S5 | usability | AC-6 | Step 18's existing edge-case list (smoke-only / both-empty / blank cells) is preserved | Prose readability not bloated | `grep -qE "Smoke section present|both sections present but empty|cell is .-." skills/personal-workflow/check.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2, AC-4 | User runs `/personal-workflow check` on F000010 after the fix and gets clean traceability badges | 1. Checkout the merged feat/pipeline-parity branch; 2. `/personal-workflow check work-items/features/personal-workflow/F000010_pipeline_skills/`; 3. Read the output | Traceability badge for S000018 and S000019 is PASS; no `[UNTESTED]` findings on multi-AC P0 stories | PASS if both badges show PASS; FAIL on any `[UNTESTED]` finding for S000018 P0 #2/#3/#5/#6 or S000019 P0 #2/#4 |
| E2 | core | AC-2 | User reading Step 18 understands the rule + worked example without ambiguity | 1. Open `skills/personal-workflow/check.md`; 2. Read Step 18 lines 339-371 cold | The reader can answer: "What does the parser do with a cell containing AC-1, AC-2, AC-3?" with the correct answer ({AC-1, AC-2, AC-3}) | PASS if the worked example unambiguously shows the answer; FAIL on hedge words ("may", "consider") or missing example |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Adversarial AC cell formats (e.g., `AC-1,AC-2` no spaces, `AC-1 ,AC-2` weird spacing) | Trim handles whitespace; comma-split handles both formats; not separately fixtured | Low — Step 18's "trim whitespace" instruction covers it |
| AC cells with mixed real ACs and placeholders (`AC-1, AC-{n}`) where placeholder is in the middle | Order-independent: placeholder filter is post-comma-split, so position doesn't matter | Low — verified by S3 above |
| Performance on large TEST-SPECs (100+ AC column cells) | Out of scope; LLM execution is not a hot path | Low — acceptable since check is a manual / pre-commit invocation |
