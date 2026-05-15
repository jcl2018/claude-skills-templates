---
type: test-plan
parent: T000023
title: "/CJ_qa-work-item refuse-on-vacuous-PASS — Test Plan"
date: 2026-05-14
author: chjiang
status: Draft
---

<!-- Scope: ONE small fix to qa.md Step 4 "Edge cases" sub-section, replacing
     the "Test rows empty (only placeholder rows)" vacuous-PASS behavior with
     an explicit HALT. -->

## Scope

The fix modifies `skills/CJ_qa-work-item/qa.md` Step 4 "Edge cases (all types)" sub-section (lines ~207-217). Specifically, the bullet point at lines 209-211 (`Test rows empty (only placeholder rows): log INFO ... treating as vacuous PASS. Skip to Step 9 (gate transition / [qa-pass]).`) is replaced with a HALT instruction that refuses to write `[qa-pass]` for an empty test-plan and returns a refuse-RESULT that the orchestrator's Step 7 will interpret as halt-at-gate.

Modified file: `skills/CJ_qa-work-item/qa.md`.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | qa.md Step 4 Edge cases sub-section documents HALT (not vacuous PASS) for empty-rows case | grep `vacuous PASS` in qa.md | No matches (the old prose has been removed/replaced) | Pending |
| 2 | qa.md Step 4 documents the new HALT behavior with refuse-RESULT | grep `placeholder.*HALT\|refuse.*placeholder\|qa-refused` in qa.md | At least one match present in the edge-cases sub-section | Pending |
| 3 | qa.md Step 4 still handles "smoke empty, E2E populated" (user-story-only path) unchanged | grep `no smoke rows; proceeding to E2E directly` in qa.md | Match still present (untouched edge case) | Pending |
| 4 | qa.md Step 4 still handles "smoke populated, E2E empty" path unchanged | grep `skip Step 7; proceed to gate transition only if smoke green` in qa.md | Match still present (untouched edge case) | Pending |
| 5 | qa.md Step 4 documents that the HALT applies to ALL types (defect, task, user-story) — not just task | Read the new HALT prose; verify it doesn't accidentally exempt user-story or other types | Prose explicitly names all-types applicability | Pending |
| 6 | No regression: other qa.md sections (Step 2 boundary check, Step 5 smoke execution, Step 7 E2E dispatch, Step 9 gate transition) unchanged | git diff main -- skills/CJ_qa-work-item/qa.md | Diff scoped to lines 207-217 (and possibly a small halt taxonomy addition); no unrelated edits | Pending |

## Verification Steps

- [ ] `./scripts/validate.sh` passes (structural validation)
- [ ] `./scripts/test.sh` passes (full test suite)
- [ ] All 6 grep smoke rows above pass
- [ ] Manual inspection: read qa.md edge-cases sub-section — the refuse behavior is unambiguous to an implementer

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS 25.3 (Darwin) | main @ v3.4.2 + this PR | Pending |
