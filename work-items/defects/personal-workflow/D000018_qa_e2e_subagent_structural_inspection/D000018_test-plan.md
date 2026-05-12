---
type: test-plan
parent: D000018
title: "/CJ_qa-work-item E2E subagent does structural inspection instead of real verification — Test Plan"
date: 2026-05-11
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect). Cases are regression cases for the specific bug. -->

## Scope

The fix touches:

- `skills/CJ_qa-work-item/qa.md` — Step 4 (E2E row planning + new tool-need classifier in Step 4.5), Step 7 (add Skill to subagent prompt's tool list), new Step 7.5 (parent-inline execution for `interactive` / `recursive` rows), Step 8 (two-source verdict aggregator).
- `skills/CJ_qa-work-item/SKILL.md` — Overview describes the parent-inline path; per-type table notes the classifier.
- `tests/spike/subagent-capabilities/findings.md` — appended 2026-05-11 re-probe note documenting `SKILL=yes` for both subagent types.

No changes to /CJ_personal-workflow, /CJ_scaffold-work-item, /CJ_implement-from-spec, or work-copilot. Defect scope is /CJ_qa-work-item only.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | Step 7 preamble grants Skill access | `grep -n 'Skill' skills/CJ_qa-work-item/qa.md` | Output includes Step 7's tool-list line mentioning Skill alongside Read/Bash/Grep/Glob | Pending |
| 2 | Step 4.5 (or equivalent) classifier exists | `grep -nE 'classifier\|read-only\|skill-invoking\|interactive\|recursive' skills/CJ_qa-work-item/qa.md` | At least one section documents the four-category mapping from TEST-SPEC row shape to category | Pending |
| 3 | Step 7.5 (or equivalent) exists and runs parent-inline rows | `grep -n 'Step 7.5\|parent-inline\|parent inline' skills/CJ_qa-work-item/qa.md` | Output shows a step or named section that executes interactive/recursive rows in parent context before subagent dispatch | Pending |
| 4 | Step 8 aggregates from two sources | `grep -nE 'aggregate\|merge.*qa-e2e\|row number' skills/CJ_qa-work-item/qa.md` (Step 8 region) | Step 8 documents merging `[qa-e2e]` entries from both subagent and parent-inline by row number | Pending |
| 5 | `scripts/validate.sh` exits 0 | `./scripts/validate.sh` | Exit code 0; no new errors introduced | Pending |
| 6 | `scripts/test.sh` exits 0 | `./scripts/test.sh` | Exit code 0; full suite passes | Pending |
| 7 | Bootstrap dogfood: re-QA S000019 (the qa-work-item's birthplace) | `/CJ_qa-work-item work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item` | Both smoke and E2E phases produce non-`ambiguous` verdicts; tracker passes /CJ_personal-workflow check | Pending |
| 8 | Bootstrap fixture unchanged behavior | `/CJ_qa-work-item skills/CJ_qa-work-item/fixtures/example-user-story` | S1 + S2 smoke pass; E1 still red (planted bug intact); verdict shape unchanged from pre-fix | Pending |
| 9 | Idempotency on green re-run | After test #7 passes, re-run `/CJ_qa-work-item work-items/features/personal-workflow/F000010_pipeline_skills/S000019_qa_work_item` | NO-OP per Step 3; no new journal entries written; exit 0 | Pending |
| 10 | SKILL.md describes parent-inline path | `grep -nE 'parent-inline\|classifier' skills/CJ_qa-work-item/SKILL.md` | Overview and/or per-type table mentions the parent-inline path and tool-need classifier | Pending |
| 11 | Spike findings reflect re-probe | `grep -n '2026-05-11' tests/spike/subagent-capabilities/findings.md` | A 2026-05-11 dated note exists documenting `SKILL=yes` for both subagent types | Pending |
| 12 | Verdict aggregator handles parent-inline + subagent overlap | Construct a TEST-SPEC with one `read-only` row + one `interactive` row; run `/CJ_qa-work-item`; inspect aggregate `[qa-e2e-summary]` | Aggregator produces a single coherent verdict; no double-counted rows; both source paths contributed entries with consistent shape | Pending |

## Verification Steps

- [ ] `scripts/validate.sh` passes locally
- [ ] `scripts/test.sh` passes locally
- [ ] Manual reproduction: a user-story with a `skill-invoking` E2E row produces a non-`ambiguous` verdict and the journal entry's content describes actual /skill invocation (not "structural inspection of skills/X/SKILL.md")
- [ ] Bootstrap dogfood on S000019 still passes after the qa.md changes
- [ ] Re-run idempotency: re-running QA on the already-green dogfood target is a NO-OP (Step 3 contract preserved)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (darwin 25.3.0) + Claude Code 2.1.91 | claude/admiring-kowalevski-0ec061 | Pending |
