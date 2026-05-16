---
type: test-plan
parent: D000020
title: "/CJ_goal_investigate idempotency table — Regression Test Plan"
date: 2026-05-16
author: chjiang
---

<!-- Regression test plan for D000020 (idempotency table edge cases).
     Scope: ONE fix (defect) — verify both bugs are fixed AND no regression
     in the other idempotency rows. -->

## Smoke Tests

| # | Test | Command | Pass Criteria |
|---|------|---------|---------------|
| 1 | Bug A — RCA prose detected | Re-run dry-run logic against D000017 (RCA file with 110 lines, 17 under `## Root Cause`) | `R=1` (was `R=0` pre-fix) |
| 2 | Bug B — Row 4 wins on merged PR | Same input, full dispatch | `Resume row: 4` (was `5` pre-fix) |
| 3 | Row 1 unaffected (fresh) | Synthetic defect with no RCA file, no fix in tree | `Resume row: 1` |
| 4 | Row 2 unaffected (R=1 F=1 P=0 M=0) | Hypothetical post-impl/pre-ship defect | `Resume row: 2` |
| 5 | Row 3 unaffected (R=1 F=1 P=1 M=0) | Hypothetical PR-open defect | `Resume row: 3` |
| 6 | Row 5 still fires when not merged | Synthetic R=0 F=1 M=0 (RCA blank, fix in tree, PR not merged) | `Resume row: 5` (anomaly) |
| 7 | `./scripts/validate.sh` | Run from worktree | exit 0, RESULT: PASS |
| 8 | `./scripts/test.sh` | Run from worktree | exit 0, RESULT: PASS (modulo known worktree-version-mismatch flake) |

## E2E Tests

E2E (full chain dispatch) deferred. v1.0 of `/CJ_goal_investigate` itself is
the system-under-test; the sentinel-emission contract that E2E would exercise
is the subject of a separate (follow-up) dogfood validation after D000020 lands.

| # | Test | Status |
|---|------|--------|
| 1 | Full chain on a non-merged defect (sentinel observation) | DEFERRED to next dogfood run |
