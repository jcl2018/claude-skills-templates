---
type: test-spec
parent: S000035
feature: F000015
title: "/wc-pipeline — Test Specification"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
spec: S000035_SPEC.md
reviewers: []
---

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `pipeline.prompt.md` exists; tools array is read-only | Read-only at harness level | `test -f work-copilot/prompts/pipeline.prompt.md && grep -q "tools: \['codebase', 'search', 'searchResults'\]" work-copilot/prompts/pipeline.prompt.md && ! grep -q "editFiles" work-copilot/prompts/pipeline.prompt.md` |
| S2 | core | AC-6 | Stale check is binary (no commit count) | Binary signal | `grep -q "HEAD matches" work-copilot/prompts/pipeline.prompt.md && grep -q "HEAD has moved past" work-copilot/prompts/pipeline.prompt.md && grep -q "For exact count, run: git log" work-copilot/prompts/pipeline.prompt.md` |
| S3 | core | AC-9 | Ship-not-opened rule keys on `pr_opened` + 24h | Correct trigger | `grep -q "pr_opened == false" work-copilot/prompts/pipeline.prompt.md && grep -q "24h" work-copilot/prompts/pipeline.prompt.md` |
| S4 | core | AC-11 | Status block template documented | Output format | `grep -q "WORK-ITEM:" work-copilot/prompts/pipeline.prompt.md && grep -q "STALE:" work-copilot/prompts/pipeline.prompt.md && grep -q "NEXT LEGAL:" work-copilot/prompts/pipeline.prompt.md` |
| S5 | core | AC-12 | Review-type tolerance documented | Empty arrays don't drift | `grep -q "review" work-copilot/prompts/pipeline.prompt.md && grep -q "empty arrays" work-copilot/prompts/pipeline.prompt.md` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3,5,6,7,8,10,11 | Drifted fixture — all 5 drift signals fire | (1) Use the hand-crafted `work-copilot/fixtures/drifted-feature-dir/` (commits ahead of receipts.implement; receipts.qa has ac_ids_uncovered + diff_audit; receipts.ship has pr_opened: false older than 24h). (2) Invoke `/wc-pipeline <drifted-fixture>`. | All 5 drift signals appear in the status block: STALE (HEAD moved), COVERAGE (AC uncovered), DIFF AUDIT (changed files without tests), SHIP-NOT-OPENED (>24h). Status block format matches template. NEXT LEGAL is non-empty. | All 5 drift lines printed with correct content; format matches template; no mutations to fixture. |
| E2 | core | AC-2 | Design-doc input mode | (1) Use a `.github/work-copilot/designs/<slug>-design-<datetime>.md` with status: DRAFT and only receipts.investigate. (2) Invoke `/wc-pipeline <design-doc-path>`. | Status block shows phase 0 ✓ (investigate complete); next legal: [scaffold]; no other phases referenced. | Output reflects design-doc state only; clean transition from one mode to the other. |
| E3 | core | AC-12 | Review-type fixture — empty arrays NOT flagged | (1) Build a fixture review work-item where receipts.implement has empty files_touched, commits_since_scaffold, ac_ids_targeted; open_risks is "Reviewed FOO; no action needed." (2) Invoke `/wc-pipeline`. | Implement phase shown as ✓ (complete); COVERAGE and DIFF AUDIT rules do NOT fire on the empty arrays. | No false positives on empty arrays; status block shows clean review work-item. |
| E4 | core | AC-1 | Read-only enforcement | (1) Try to invoke /wc-pipeline on any fixture. (2) Observe tools array surfaced by Copilot. | The harness exposes only codebase/search/searchResults — no editFiles capability. No file writes possible. | Tools array matches spec; no fixture files modified during exercise. |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Schema-version mismatch (AC-13) | V1 emits a clean error message; auto-tested via S2 (presence of error language). | If a future receipt schema drifts, V1 may show partial output; acceptable for V1. |
| Color codes in status block | V1 plain-text only. | Terminal vs Chat rendering differences are acceptable for V1. |
| Multi-work-item / cross-feature drift | V1 prints one work-item at a time. | A feature with 6 children needs 6 separate /wc-pipeline calls; user-acceptable in V1; V2 candidate for roll-up reports. |
