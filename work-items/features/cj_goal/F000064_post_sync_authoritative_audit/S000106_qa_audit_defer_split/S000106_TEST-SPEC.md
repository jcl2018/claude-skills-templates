---
type: test-spec
parent: S000106
feature: F000064
title: "qa.md Step 8.6 split + DEFER_AUDIT directive — Test Specification"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC. -->

## Smoke Tests

<!-- Automated regression. Soft cap: 5 rows. AC column maps to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | qa.md contains a `DEFER_AUDIT: true` detection branch that skips 8.6c/8.6d | The deferral mechanism exists and is keyed on the literal directive | `grep -q 'DEFER_AUDIT: true' skills/CJ_qa-work-item/qa.md` |
| S2 | core | AC-2 | qa.md sets `AUDITS=deferred` on the defer path | Deferred runs report `deferred` in the RESULT | `grep -qE 'AUDITS=deferred' skills/CJ_qa-work-item/qa.md` |
| S3 | core | AC-1 | qa.md keeps 8.6a/8.6b (overlay writes) inline regardless of the directive | Overlay writes are not gated by the defer branch | `grep -qE '8\.6a' skills/CJ_qa-work-item/qa.md` |
| S4 | core | AC-3 | qa.md retains the inline `/CJ_doc_audit` + `/CJ_test_audit` path for the no-directive (standalone) case | Standalone QA still audits inline | `grep -qE 'CJ_doc_audit' skills/CJ_qa-work-item/qa.md && grep -qE 'CJ_test_audit' skills/CJ_qa-work-item/qa.md` |
| S5 | integration | AC-1 | `./scripts/validate.sh` stays green after the qa.md edit | The catalog/doc/USAGE-drift checks pass with the modified skill | `./scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. One user-visible scenario per row. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-2,AC-4 | Orchestrator-driven deferred QA | Dispatch `/CJ_qa-work-item` on a green work-item with `DEFER_AUDIT: true` in the prompt | QA runs 8.6a/8.6b, skips 8.6c/8.6d, RESULT shows `AUDITS=deferred`, no `AUDIT_FINDINGS` block | PASS if audits skipped + `AUDITS=deferred` present + no `AUDIT_FINDINGS` |
| E2 | core | AC-3 | Standalone QA keeps inline audit | Run `/CJ_qa-work-item <dir>` directly (no directive) on a green work-item | QA runs 8.6c/8.6d inline and emits the `AUDIT_FINDINGS` fenced block, exactly as today | PASS if the inline audit runs + `AUDIT_FINDINGS` emitted |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior of a malformed/partial `DEFER_AUDIT` token (e.g. `DEFER_AUDIT:true` no space, or `DEFER_AUDIT: false`) | The directive is producer-controlled (pipeline.md templates emit the exact literal); a fuzzed token is not a real input | A typo in a pipeline template would fail E1's defer assertion and be caught at integration |
