---
type: test-spec
parent: S000030
feature: F000015
title: "/wc-qa — QA walkthrough + receipt-schema lock — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000030_SPEC.md
reviewers: []
---

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `qa.prompt.md` exists and has the required `tools:` array | Story #1 / prompt is installed | `test -f work-copilot/prompts/qa.prompt.md && grep -q "tools: \['codebase', 'search', 'searchResults', 'findTestFiles', 'editFiles'\]" work-copilot/prompts/qa.prompt.md` |
| S2 | core | AC-8 | Prompt body documents the full `receipts.qa` schema | Story #8 / contract is locked | `grep -E "(test_rows_run\|ac_ids_covered\|ac_ids_uncovered\|diff_audit\|journal_entries\|ready_for_ship\|next_legal)" work-copilot/prompts/qa.prompt.md \| wc -l` (expect ≥ 7 matches) |
| S3 | resilience | AC-6 | Prompt mentions the Working-Tree Rule hard-stop language | Story #6 | `grep -q "git status --porcelain" work-copilot/prompts/qa.prompt.md && grep -q "commit those files first" work-copilot/prompts/qa.prompt.md` |
| S4 | core | AC-5 | Prompt mentions the `receipts.scaffold` fallback | Story #5 | `grep -q "receipts.scaffold" work-copilot/prompts/qa.prompt.md` |
| S5 | core | AC-1 | `validate.sh` existence check (parent milestone #2) catches a deleted prompt | Existence check works | `mv work-copilot/prompts/qa.prompt.md /tmp/qa.prompt.bak && ./scripts/validate.sh; EXIT=$?; mv /tmp/qa.prompt.bak work-copilot/prompts/qa.prompt.md; [ "$EXIT" -ne 0 ]` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,2,3,7,8,9 | Happy-path QA walkthrough on a fixture user-story | (1) In a target test repo with the bundle installed, open Copilot Chat. (2) Invoke `/wc-qa <fixture-user-story-path>`. (3) Watch /validate pass. (4) See the test-row checklist printed. (5) Paste a clean `git log --name-only` output when asked. (6) Paste a clean `git status --porcelain` when asked. (7) Walk the checklist replying pass/pass/.../pass. | (a) Tracker journal gets `[smoke-pass]` entries. (b) Tracker frontmatter gains a valid `receipts.qa` block matching the schema. (c) Final chat line: "READY_FOR_SHIP: yes". | Receipts block parses as valid YAML; all 9 schema fields populated; READY_FOR_SHIP line printed. |
| E2 | resilience | AC-6 | Working-Tree Rule hard-stops | (1) On the same fixture, edit a source file but don't commit. (2) Invoke `/wc-qa <fixture>`. (3) When prompted, paste `git status --porcelain -- <file>` output that shows the dirty entry. | Prompt refuses to write receipts.qa; prints "Please commit those files first and re-invoke /wc-qa; I'll wait." Tracker is unchanged. | No receipts.qa block written; tracker journal unchanged; clear "commit first" message. |
| E3 | core | AC-3,4 | Uncovered AC + changed-files-without-tests both surface | (1) Use a fixture where SPEC defines AC-3 but TEST-SPEC has no row for it. (2) Also use a fixture where a source file changed since the last `[qa-*]` entry but no test row covers it. (3) Invoke `/wc-qa`, follow through. | Prompt prints "AC-3 uncovered" warning AND `diff_audit.changed_files_without_tests` contains the changed file. `receipts.qa.ac_ids_uncovered` contains "AC-3". `ready_for_ship: false`. | Both diagnostics present; ready_for_ship correctly false. |
| E4 | resilience | AC-10 | YAML parse failure aborts cleanly | (1) Manually corrupt a fixture tracker's frontmatter (insert a stray colon). (2) Invoke `/wc-qa`. | Prompt aborts with "tracker frontmatter could not be parsed — fix manually before re-invoking." No partial edits to the tracker. | Tracker unchanged; clear error message; no silent corruption. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| /wc-qa on a feature work-item (multi-story parent) | Features delegate to child user-stories per /CJ_implement-from-spec's pattern; /wc-qa on a feature is not in the V1 contract. | Feature-level QA is run via /wc-qa on each child. Acceptable for V1; revisit if a feature-level smoke surface emerges. |
| CI-mode /wc-qa (non-interactive) | V1 is interactive only — see SPEC Open Question. | If V2 adds CI mode, add new test rows for non-interactive paths. |
| Multi-language `git log` paste tolerance | Localized git output is rare in dev environments. | Risk: a non-English `git log` paste could confuse the parser. Acceptable; document in V2. |
