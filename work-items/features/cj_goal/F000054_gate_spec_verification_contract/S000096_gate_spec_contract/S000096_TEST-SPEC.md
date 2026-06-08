---
type: test-spec
parent: S000096
feature: F000054
title: "gate-spec.md contract — the doc-spec mirror for gates — Test Specification"
version: 1
status: Draft
date: 2026-06-07
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. For a single fix or task, use test-plan.md instead.

     Two tiers, distinguished by who edits them and when they run:
     - Smoke = automated regression. Lives in CI. You write it once and
       never touch it again.
     - E2E   = manual user-scenario verification. You sit down and run it
       after implementing and before /ship.

     Soft cap: 5 rows per tier. Validator emits [INFO] advisory if exceeded;
     not a violation. Exceed only when justified — the cap is a forcing
     function to pick the tests that prove the story works, not the tests
     that demonstrate completeness. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Once written, you should not need to edit these. Soft cap: 5 rows.
     Pick the structural checks that catch real regressions, not all checks
     that could exist. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2 | Registry parses | `gate-spec.sh --validate` exits 0 + `OK schema_version=<n>` on the committed registry (schema_version present, every gate has id/layer/order/markers/disposition/backing, every layer + disposition in its closed enum, every `markers` value a `"[...]"` literal or `{enforced_by: subagent\|auq}`) | `bash scripts/gate-spec.sh --validate` (expect exit 0) |
| S2 | core | AC-2 | Reader emits the right sets | `--list-layers` emits every declared layer id; `--list-gates` emits every gate id (sorted, unique) | `bash scripts/gate-spec.sh --list-layers && bash scripts/gate-spec.sh --list-gates` |
| S3 | observability | AC-3 | Check 22 is wired, advisory, and green on the clean tree | `scripts/validate.sh` carries Check 22 (per-mode marker drift guard); it runs and reports NO finding on the clean tree, and `validate.sh` exits 0 (advisory) | `bash scripts/validate.sh` (Check 22 runs, no finding, exit 0) |
| S4 | observability | AC-3 | Universal + per-mode markers resolve | The universal markers (`[portability-red]`, `[doc-sync-red]`) resolve in all four modes' files, and the per-mode isolation markers (`[feature-not-isolated]` / `[investigate-not-isolated]` / `[task-not-isolated]`) resolve in their declared mode's file | `bash scripts/test.sh` (gate-spec marker-resolution assertion) |
| S5 | integration | AC-3 | zzz-test-scaffold still green with Check 22 active | The `scripts/test.sh` `zzz-test-scaffold` integration fixture passes with Check 22 present (Check 22 greps `skills/CJ_goal_*/`, and zzz-test-scaffold is not a `CJ_goal_*` skill, so it is naturally skipped — but verify) | `bash scripts/test.sh` (zzz-test-scaffold case passes) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifiers (can combine with any tag): post-ship (see E2E Tests section
     below for semantics — applies to E2E rows only; smoke rows do not support
     post-ship deferral). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     You drive the feature as a real user would and observe the outcome.
     Soft cap: 5 rows. Each row should be one user-visible scenario,
     not one branch in the code. AC column maps each row to a SPEC
     acceptance criterion.

     Post-ship rows: if a row is structurally only verifiable AFTER the PR
     merges to main (e.g., `gh workflow run` against a CI workflow that
     doesn't exist on remote refs until merge), add the literal token
     `post-ship` to the row's Tag column (e.g., Tag = `core post-ship`
     or just `post-ship`). /CJ_qa-work-item Step 4 will filter these rows
     out of the E2E subagent dispatch and record a [qa-e2e-deferred] journal
     entry naming the row + its AC instead of forcing a pretend-green
     adjudication. Verification of post-ship rows happens after merge (via
     manual `gh workflow run` or via post-merge tooling). -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-1 | The one-minute legibility test | Hand `gate-spec.md` to someone (or an independent-inspection subagent) who has NOT seen this design; ask only "Reading only this file, can you tell me what stops a broken cj_goal change from landing, and at which layer?" | The reader names the four layers (local-hook / ci / pipeline-gate / ratchet) and the owning layer for a sample guarantee, in under a minute, without opening any script | PASS = the question is answered correctly from the file alone in under a minute; FAIL = the reader must open a script or cannot map a guarantee to a layer |
| E2 | observability | AC-3 | Check 22 fires on injected drift, stays advisory | In a scratch copy, delete a declared literal marker (e.g. `[portability-red]`) from BOTH of a mode's files (or corrupt the registry), then run `bash scripts/validate.sh` | Check 22 reports the missing marker / drift in its output, and `validate.sh` still exits 0 (advisory, not a hard fail) | PASS = the drift is named in the output AND exit code is 0; FAIL = drift unreported, or the check hard-fails CI |
| E3 | core | AC-2 | The reader matches the live tree | Run `gate-spec.sh --list-gates` and `--list-layers`; cross-check the gate ids + layer ids against the registry block in `gate-spec.md`; run `--validate` on a hand-corrupted copy (drop a required key) | The list subcommands emit exactly the registry's gate/layer ids; `--validate` exits 0 on the committed registry and exits 1 + `[gate-spec-no-config]` on the corrupted copy | PASS = lists match the registry AND validate's exit codes are correct on clean vs corrupted; FAIL = list mismatch, or validate misreports either case |
| E4 | usability | AC-4 | "Gate" is disambiguated + docs trace to the contract | Read `docs/architecture.md` (the new gate-spec section + the relabeled "CI gate" heading), `docs/philosophy.md §4` (the pointer), the four `CJ_goal_*` pipeline/SKILL reference lines, the `doc-spec.md` registry entry, and the `CLAUDE.md` pointer | architecture.md no longer mislabels validate.sh as "the CI gate" without qualification; every doc surface points at `gate-spec.md` as the single map; the word "gate" reads unambiguously per layer | PASS = the relabel is done AND all five doc surfaces reference gate-spec.md; FAIL = the "CI gate" mislabel remains, or any doc surface still re-describes the sequence without naming the contract |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The advisory→strict ratchet (Check 22 hard-failing on drift) | Out of scope — this story lands Check 22 advisory-first (exit 0); the strict flip is its own follow-up PR once the registry runs clean across a few real cj_goal builds | Drift could be merged while the check is only advisory; accepted because advisory-first is the established workbench pattern (Check 18 / Check 21) and the check still surfaces the drift in output |
| Live runtime gate *execution* (an orchestrator actually halting at a gate at runtime) | This story declares + cross-checks the gate *sequence*; gate implementations stay where they are and re-plumbing execution into a shared runner is explicitly deferred to a future epic | A gate could regress in behavior without the declared sequence changing; mitigated because each gate's own existing inline halt + its existing tests are unchanged, and Check 22 catches a marker drifting out of a pipeline |
| `--seed` / `--list-for <mode>` reader subcommands | Deferred — no v1 consumer (the check computes the per-mode subset internally; no skill recreates a missing gate-spec.md) | A future caller wanting an ordered per-mode view must add `--list-for` first; surfaced as a documented deferral, not a silent gap |
| Exhaustive gate census (every possible halt in every leaf skill enumerated) | The registry enumerates the cj_goal orchestrator-layer gate set (isolation / design-summary / QA / doc-sync / portability / ship), not every transitively-reachable halt | A halt deep in a leaf skill but absent from the registry is not cross-checked; accepted because the orchestrator-layer gates are the ones the "what stops a broken change?" question is about, and a new orchestrator gate is added by one registry row |
