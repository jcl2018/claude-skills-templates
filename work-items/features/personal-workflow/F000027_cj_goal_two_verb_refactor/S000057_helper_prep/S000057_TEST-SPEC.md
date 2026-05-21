---
type: test-spec
parent: S000057
feature: F000027
title: "Helper prep — cj-worktree-init.sh --caller extension + cj-goal-common.sh + early feature smoke harness — Test Specification"
version: 1
status: Draft
date: 2026-05-21
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `--caller feature` resolves to `cj-feat`, exit 0 | New feature caller accepted (no lines 55-57 rejection) | `bash tests/cj-worktree-init.test.sh` |
| S2 | core | AC-1 | `--caller defect` resolves to `cj-def`, exit 0 | New defect caller accepted | `bash tests/cj-worktree-init.test.sh` |
| S3 | integration | AC-2 | `cj-goal-common.sh --phase ship --mode feature` exits 0 and performs the phase op | Common helper dispatches by phase+mode | `bash scripts/cj-goal-common.sh --phase ship --mode feature` |
| S4 | resilience | AC-4 | `--caller cj-run` / `cj-todo` / `cj-inv` still resolve unchanged | Existing callers non-regressed | `bash tests/cj-worktree-init.test.sh` |
| S5 | resilience | AC-3 | feature smoke harness exits 0 with no `/cj_goal_feature` skill present | Feature path validated before PR #2 | `bash tests/cj-goal-feature-smoke.test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Author creates a worktree via the new feature caller | Run `scripts/cj-worktree-init.sh --caller feature` from a clean checkout | A `cj-feat-*` worktree is created and the script reports success | PASS if worktree exists with the `cj-feat` prefix and exit 0; FAIL on `state:failed` |
| E2 | integration | AC-2 | Author drives the common helper across phases for a feature run | Invoke `cj-goal-common.sh` with `--phase`/`--mode feature` for worktree, telemetry, and PR-check steps | Each phase performs its deterministic op (telemetry line written, PR check returns a clear result) | PASS if every invoked phase completes deterministically; FAIL if any phase errors or no-ops silently |
| E3 | resilience | AC-3 | Author runs the early feature smoke harness before S000059 lands | Run `tests/cj-goal-feature-smoke.test.sh` on the S000057 branch | The harness exercises and confirms the feature-path shape and passes | PASS if the harness reports green without the verb skill installed; FAIL otherwise |

<!-- E2E test skill: none for this story. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Full `/cj_goal_feature` end-to-end run | The skill lands in S000059; S000057 only validates the path shape via the smoke harness | A defect in the full feature orchestration surfaces in S000059's tests, not here |
| `cj-handoff-gate.sh` markers-writer behavior | Dropped from the `feature` path (PR-stop); not in this story's scope | None — the dependency is intentionally removed |
