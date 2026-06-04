---
type: test-spec
parent: S000081
feature: F000045
title: "Pre-build base-freshness + skills-sync — Test Specification"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. Soft cap 5 rows/tier; exceeded here with
     justification — the four Fork-1 freshness branches plus the three
     sync-phase modes are each a distinct regression surface that the
     design's Test Plan calls out by name. -->

## Smoke Tests

<!-- Automated regression. Runnable from `tests/cj-worktree-init.test.sh`
     and `scripts/test.sh`. AC column maps each row to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | behind: local main 1 behind a fake `origin/main` → ff happens, worktree base == origin tip | Fork-1 fast-forwards when behind; `note` carries `ff'd N commits` | `tests/cj-worktree-init.test.sh` (behind case) |
| S2 | resilience | AC-2 | diverged: local main has a commit origin doesn't → warn + no ff + proceed | Fork-1 warns and proceeds on divergence, no halt | `tests/cj-worktree-init.test.sh` (diverged case) |
| S3 | resilience | AC-3 | offline: unreachable/absent remote → proceed on local main, exit 0 | Fork-1 fail-soft on offline; `note` carries `freshness skipped (offline)` | `tests/cj-worktree-init.test.sh` (offline case) |
| S4 | core | AC-1 | already-fresh: local main already at origin tip → no-op ff path | Fork-1 no-op when already current (the `.source==root` collapse case) | `tests/cj-worktree-init.test.sh` (already-fresh case) |
| S5 | resilience usability observability | AC-5, AC-6, AC-8 | sync dry-run previews (no mutation); `--no-sync` → `PHASE_RESULT=skipped`, no install invoked; guard refusal (`.source` dirty / not-on-main) → `skipped`, exit 0; every mode emits the `SYNC_RAN`/`VERSION_BEFORE`/`VERSION_AFTER`/`PHASE_RESULT` KEY=VALUE keys | Fork-2 fail-soft + opt-out + dry-run + stable output schema; never blocks the build | sync-phase test (cj-goal-common test surface or new file) |
| S6 | integration | AC-7 | `scripts/test.sh` `zzz-test-scaffold` fixture exercises the new `--phase sync` end-to-end | The full suite (incl. the recurring fixture blind spot) stays green | `scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-4 | Build from a behind-origin machine lands on fresh base + synced skills | On a checkout 1 commit behind `origin/main`, invoke a cj_goal orchestrator from `main` with args; let the preamble run `--phase sync` then the worktree phase | Worktree base == `origin/main` tip (`git merge-base --is-ancestor origin/main <worktree-base>` true); sync phase reported `VERSION_BEFORE`→`VERSION_AFTER`; install came from `.source` | PASS if the worktree branches off the fresh tip AND the sync phase ran from `.source` with a version report |
| E2 | usability | AC-6 | Fast start with `--no-sync` | Invoke a cj_goal orchestrator with `--no-sync` on a behind machine | The install phase is skipped (`PHASE_RESULT=skipped`, no `skills-deploy install`), but Fork-1 ff still fast-forwards local main; build proceeds | PASS if no install runs AND the worktree base is still the fresh origin tip |
| E3 | integration | AC-7 | All three orchestrators exhibit the behavior; todo_fix gains update-check | Invoke each of `/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix` from `main`; observe the preamble | Each runs `--phase sync` before the worktree block; `/CJ_goal_todo_fix` additionally emits the `skills-update-check` advisory it previously lacked | PASS if all three call the sync phase AND todo_fix shows the update-check snippet |
| E4 | resilience | AC-3, AC-5 | Offline build never blocks | Disconnect network (or point origin at an unreachable ref), invoke a cj_goal orchestrator | Sync phase → `PHASE_RESULT=skipped`; Fork-1 → `freshness skipped (offline)`; build proceeds, exit 0, no operator-facing error | PASS if the build proceeds cleanly offline with both halves fail-soft |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Hot-swapping the already-in-context running orchestrator | Out of reach by design (self-modification reality — the sync updates the next invocation, not the running one) | The current run uses the pre-sync orchestrator; expected and documented. |
| `work-copilot/` Copilot consumers | No preamble surface (same boundary as F000009) | Copilot bundle is unaffected; out of scope. |
| Real multi-machine cross-host race (two machines building the same trunk simultaneously) | Requires two hosts; smoke/E2E use fake `origin` fixtures locally | The existing ID/VERSION queue-collision safety nets (open-PR scan, /land-and-deploy drift check) cover the ship-time collision. |
