---
type: test-spec
parent: S000120
feature: F000071
title: "Build-gate auto-answer seam (dormant, CI-green) — Test Specification"
version: 1
status: Draft
date: 2026-06-30
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story (Part A of F000071). Smoke + E2E together cover
     every SPEC P0 acceptance criterion. Smoke = automated regression (CI);
     E2E = manual verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-7 | Helper prints a well-formed verdict; full verdict matrix asserted deterministically | `cj-e2e-gate.sh --gate qa-audit` prints exactly one `AUTO=continue\|halt\|inactive` line and exits 0; the test asserts the whole flag/marker/allowlist/digest matrix (no Claude) | `bash tests/cj-e2e-gate.test.sh` |
| S2 | security | AC-2 | Dormant under an incomplete guard | flag-only → `inactive` AND marker-only → `inactive` (a normal run is behavior-unchanged) | `bash tests/cj-e2e-gate.test.sh` |
| S3 | security | AC-3 | Build-gates-only allowlist | both guards + a non-`{design-gate, qa-audit}` gate id → `inactive` (never matches ship/merge/deploy) | `bash tests/cj-e2e-gate.test.sh` |
| S4 | core | AC-4 | Green-only continue, halt on findings | both guards + qa-audit: green digest → `continue`; findings digest → `halt` (never auto-waive) | `bash tests/cj-e2e-gate.test.sh` |
| S5 | security | AC-6 | Marker cannot ship | `validate.sh` HARD-fails when `.cj-e2e-sandbox` is in the tracked tree; the test passes when it is gitignored/absent | `bash scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | integration | AC-5 | A normal cj_goal run is behavior-unchanged | Run a cj_goal pipeline WITHOUT the guard (no `CJ_GOAL_E2E_AUTO`, no `.cj-e2e-sandbox`); reach the qa-audit gate | The helper returns `inactive` and the qa-audit AUQ fires unchanged — no `[E2E-AUTO]` banner, no auto-continue | PASS if the AUQ fires exactly as before this story; FAIL on any silent skip |
| E2 | core | AC-4, AC-5 | The seam auto-continues a green qa-audit only under the full guard | In a sandbox with BOTH `CJ_GOAL_E2E_AUTO=1` AND `.cj-e2e-sandbox`, reach a qa-audit gate with a green digest | The pipeline skips the AUQ, prints the `[E2E-AUTO]` banner, and proceeds; with a findings digest it emits `[qa-audit-declined]` instead | PASS if continue happens ONLY on green and the banner prints; FAIL if findings are auto-waived |
| E3 | security | AC-3 | The seam never auto-answers a ship/merge/deploy gate | With the full guard active, observe the `/ship` (and any merge/deploy) gate in a cj_goal run | The `/ship` gate is NOT auto-answered — the helper returns `inactive` for it (allowlist is `{design-gate, qa-audit}` only) | PASS if `/ship`/merge/deploy always fires its human gate; FAIL if any is auto-answered |

<!-- Post-ship rows: none. All rows are verifiable pre-ship (deterministic
     smoke + local manual E2E). -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A real unattended `/CJ_goal_task` build driven through the seam | That is Part B (the local-E2E harness) — TRACKED FOLLOW-ON on F000071, not built in this story | The seam's *integration* into a full real run is proven later by Part B; this story proves the seam logic + wiring deterministically |
| The `[E2E-AUTO]` banner's exact wording in a live run | Manual E2E (E2) observes it; not asserted in deterministic smoke | Low — a cosmetic banner string; the verdict (continue/halt/inactive) is the load-bearing behavior and is fully smoke-asserted |
| Workflow-docs discoverability of the harness | That is Part C — TRACKED FOLLOW-ON; this story only adds a one-line test-hierarchy note | Low — the seam ships dormant; full workflow docs follow with Part B's harness |
