---
type: test-spec
parent: S000112
feature: F000068
title: "The --phase recap formatter — Test Specification"
version: 1
status: Draft
date: 2026-06-28
author: chjiang
spec: SPEC.md
reviewers: []
---

## Smoke Tests

<!-- Automated regression. Hermetic, lives in tests/cj-goal-common-recap.test.sh.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `--phase recap --when before` with all three fields renders Delivered / How to E2E-test it / Next step | The 3-part labelled block is emitted with each field's content in its section | `bash tests/cj-goal-common-recap.test.sh` |
| S2 | core | AC-2 | `--when before` vs `--when after` produce different headers | The header switches on `--when`; both keep the three body sections | `bash tests/cj-goal-common-recap.test.sh` |
| S3 | resilience | AC-4 | Omitting a `--field` renders an empty section and still exits 0 with `PHASE_RESULT=ok` | Fail-soft: no error, no halt, no mutation on a missing field | `bash tests/cj-goal-common-recap.test.sh` |
| S4 | integration | AC-3 | A `--field` value with spaces / special chars renders verbatim | The telemetry-reused parser prints content without eval or truncation | `bash tests/cj-goal-common-recap.test.sh` |
| S5 | observability | AC-5 | The new test resolves to exactly one test-spec units row | Check 24 forward + reverse sweep pass for the new test | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --check-coverage` |

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | Operator-facing recap renders for both points | Run `bash scripts/cj-goal-common.sh --phase recap --mode feature --when before --field delivered="x" --field e2e="run scripts/test.sh" --field next="open the PR"`, then again with `--when after` | Two readable 3-part blocks print to stdout — a BEFORE header and an AFTER header — each with Delivered / How to E2E-test it / Next step populated; `PHASE_RESULT=ok`; exit 0 | PASS if both blocks are human-readable, headers differ, all three sections populated, exit 0 |
| E2 | observability | AC-5 | Full suite stays green with the new test | Run `bash scripts/validate.sh` then `bash scripts/test.sh` | validate green; test.sh runs `tests/cj-goal-common-recap.test.sh` and the whole suite passes | PASS if both exit 0 with no failures and the recap test is among those run |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The four pipelines actually CALLING the recap helper | That wiring is S000113's scope; verified there by grep + manual confirmation (not gated, per the advisory posture) | A pipeline could silently omit the recap pointer — accepted (the chosen advisory posture). |
| Absent-helper prose fallback in the orchestrators | The fallback lives in the pipeline.md prose (S000113), not in the helper | A deploy missing the helper degrades to prose; documented, not automatically verified. |
