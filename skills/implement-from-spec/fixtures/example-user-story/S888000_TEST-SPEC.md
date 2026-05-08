---
type: test-spec
parent: S888000
feature: F888888
title: "Greeting writer fixture — Test Specification"
version: 1
status: Draft
date: 2026-05-08
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Synthetic fixture for /implement-from-spec v1 manual testing. The
     dogfood deletes output/greeting.txt before running, then verifies the
     produced file matches the asserted content exactly. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | output/greeting.txt exists after run | File was written | `test -f skills/implement-from-spec/fixtures/example-user-story/output/greeting.txt` |
| S2 | core | AC-2 | output/greeting.txt content matches exactly | LLM didn't drift the content | `grep -Fxq 'Hello from /implement-from-spec' skills/implement-from-spec/fixtures/example-user-story/output/greeting.txt` |

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Implement the greeting file from SPEC | 1. Confirm `output/greeting.txt` does not exist (canonical fixture state). 2. Run `/implement-from-spec skills/implement-from-spec/fixtures/example-user-story/`. 3. Approve the propose-and-confirm preview. 4. Verify the file was created with exact content. | greeting.txt exists with `Hello from /implement-from-spec\n` content; tracker journal has [impl-decision], [impl], [impl-pass] entries; Phase 2 implementer-owned gates green; /personal-workflow check PASS | PASS if SPEC verbatim; FAIL on content drift, missing tracker entries, or compliance break |
| E2 | usability | AC-9 | Propose-and-confirm preview fires by default | 1. Run skill WITHOUT --auto. 2. Inspect the preview output before approving. | Preview shows: "PROPOSED IMPLEMENTATION: S888000" with file list, diff highlights, tracker updates section. AUQ presents Apply / Modify / Cancel | PASS if preview is readable AND AUQ fires; FAIL on silent write |
| E3 | usability | AC-10 | --auto on trivial change | 1. Run skill WITH `--auto`. 2. Verify NO propose preview fires. | No AUQ; skill writes directly; tracker entry includes `[impl-auto]` prefix | PASS if no preview AND tracker records auto-mode; FAIL if preview fired (would mean trivial detection broke) |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Sensitive-surface AUQ (AC-8) | Synthetic fixture deliberately AVOIDS catalog/manifest/validator paths so default trivial-mode runs. Tested separately by hand-toggling SPEC's Components Affected to include `skills-catalog.json` and observing AUQ fires regardless of `--auto`. | Low: easy hand-toggle to verify |
| Phase 1 incomplete refusal (AC-5) | Tested by hand-unchecking a Phase 1 gate in the fixture's tracker and observing the boundary-check refusal at Step 2. | Low: easy hand-toggle to verify |
| Idempotency NO-OP (AC-4) | Tested by re-running on the same fixture after a successful run; the [impl-pass] journal entry should make Step 3 NO-OP on second invocation. | Low: deterministic via journal-state |
| Multi-file implementations | This fixture is single-file by design; multi-file behavior is exercised by real user-stories during ship cycles, not fixtures. | Medium: real-world coverage rather than fixture |
| LLM drift on multi-line / complex content | Same — single-line content keeps the byte-equality check crisp. Real user-stories test multi-line behavior. | Medium: shifts coverage from fixture to dogfood |
