---
type: test-spec
parent: S000031
feature: F000015
title: "/wc-implement — implement from spec — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000031_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `implement.prompt.md` exists with correct `tools:` array | Prompt is installed | `test -f work-copilot/prompts/implement.prompt.md && grep -q "tools:" work-copilot/prompts/implement.prompt.md` |
| S2 | core | AC-6 | Prompt body documents the `receipts.implement` schema | Contract documented | `grep -E "(latest_sha_at_implement\|commits_since_scaffold\|files_touched\|ac_ids_targeted\|open_risks)" work-copilot/prompts/implement.prompt.md \| wc -l` (expect ≥ 5 matches) |
| S3 | core | AC-2 | Prompt body covers all 5 type dispatches | Per-type contract present | `grep -E "(user-story\|defect\|task\|feature\|review)" work-copilot/prompts/implement.prompt.md \| wc -l` (expect ≥ 5 matches) |
| S4 | resilience | AC-5 | Working-Tree Rule language present | Hard-stop documented | `grep -q "git status --porcelain" work-copilot/prompts/implement.prompt.md && grep -q "commit those files first" work-copilot/prompts/implement.prompt.md` |
| S5 | core | AC-7 | Degenerate review-type path documented | review type tolerated | `grep -A 5 "review" work-copilot/prompts/implement.prompt.md \| grep -q "open_risks"` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1,2,3,4,6 | Happy-path user-story implement | (1) Open Copilot Chat. (2) Invoke `/wc-implement <fixture-user-story>`. (3) Watch /validate pass. (4) See PRD + ARCHITECTURE + TEST-SPEC loaded. (5) See proposed plan; confirm. (6) Watch editFiles produce a diff; review; confirm. (7) Paste `git rev-parse HEAD` and `git log --oneline` outputs when asked. (8) Paste clean `git status --porcelain`. | (a) Code changes applied. (b) Tracker frontmatter gains `receipts.implement` with all required fields. (c) `next_legal: [qa]`. | All 8 schema fields populated; SHA is a valid 40-char hex; ac_ids_targeted is non-empty. |
| E2 | core | AC-7 | review-type degenerate receipt | (1) Use a fixture review work-item. (2) Invoke `/wc-implement <fixture-review>`. (3) Walk through reading review-notes; report what action you took. | `receipts.implement` has empty `files_touched`, `commits_since_scaffold`, `ac_ids_targeted`; `open_risks` has a 1-line summary; `/wc-pipeline` (eventually) treats this as a valid completion state. | Receipt parses; arrays are empty (not missing); open_risks has at least one entry. |
| E3 | core | AC-8 | feature-type delegation | (1) Use a fixture feature with 2+ child user-stories. (2) Invoke `/wc-implement <fixture-feature>`. (3) Pick a child when prompted. | Prompt re-invokes itself on the picked child path; the feature tracker is NOT modified (no receipts.implement on parent). | Feature tracker frontmatter unchanged; child tracker gains receipts.implement after the delegated run. |
| E4 | resilience | AC-5 | Working-Tree Rule hard-stops | (1) Edit a fixture file without committing. (2) Invoke `/wc-implement` and proceed to receipt-write step. (3) Paste dirty `git status --porcelain`. | Prompt refuses write; prints "commit those files first" message. | No receipts.implement block written; clear error message. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Task-type and defect-type happy paths | Smoke check S3 verifies the per-type dispatch language is present; E2E happy-path on user-story (E1) exercises the dispatch logic. Task and defect have the same dispatch shape — E2E redundant for V1. | If task/defect input contracts diverge subtly, V1 might miss it. Acceptable; revisit after first real-world target-repo run. |
| Multi-file refactor chunking heuristic | V1 spec leaves chunking judgment to the prompt + user. | Risk: a user might want batched edits; V1 chunks; revisit if friction shows up. |
| Cross-repo edits | Out of V1 scope. | Cross-repo work isn't a current pattern at the company. |
