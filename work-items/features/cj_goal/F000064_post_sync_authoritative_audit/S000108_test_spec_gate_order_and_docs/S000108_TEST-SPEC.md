---
type: test-spec
parent: S000108
feature: F000064
title: "test-spec gate-order swap + docs + named tests — Test Specification"
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
| S1 | core | AC-1 | The test-spec registry validates after the order swap | The `order:` swap keeps the registry valid | `./scripts/test-spec.sh --validate` |
| S2 | core | AC-1 | doc-sync's gate order is less than qa-audit's | doc-sync precedes qa-audit in the declared sequence | `./scripts/test-spec.sh --list-units 2>/dev/null; grep -nE 'order:' spec/test-spec-custom.md` |
| S3 | core | AC-3 | Check 15b passes on the updated charts | The per-`CJ_goal_*` ASCII charts reflect the reordered sequence | `./scripts/validate.sh` |
| S4 | integration | AC-5 | The ORDERING assertion passes on the new order | `cj-goal-doc-sync-wiring.test.sh` asserts the reordered sequence | `./tests/cj-goal-doc-sync-wiring.test.sh` |
| S5 | integration | AC-6 | Full suite green incl. Check 24 | The reorder + docs + tests land without regressions | `./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. One user-visible scenario per row. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-2,AC-4 | Read the gate docs after the swap | Read the `qa-audit` gate backing in `spec/test-spec-custom.md`, the CLAUDE.md ordering prose, a `docs/workflow.md` chart, and a SKILL.md Overview chain | All four describe doc-sync → audit → checkpoint; the qa-audit backing names the orchestrator-level post-sync audit + checkpoint AUQ; none claims the old order | PASS if every surface is internally consistent with the reordered sequence |
| E2 | integration | AC-5 | The ORDERING test fails pre-edit, passes post-edit | Stash the test edit, run `cj-goal-doc-sync-wiring.test.sh` against reordered pipelines (expect FAIL), apply the test edit, re-run (expect PASS) | The test is the canary: red before its assertion is updated, green after | PASS if the test flips red→green exactly with the assertion update |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Whether every prose surface (all four SKILL.md chains, all catalog descriptions) was caught | A whole-tree grep for the old-order phrasing is the manual sweep; no single automated assertion enumerates all prose | A missed prose surface is cosmetic (not gated); the registry + charts + named tests are the gated surfaces |
| Per-pipeline halt-marker tests beyond the ORDERING test | Only the ORDERING test is named in the design; other halt-marker tests are grepped during implementation | A halt-marker test pinning the old order would fail in S5's full-suite run and be caught |
