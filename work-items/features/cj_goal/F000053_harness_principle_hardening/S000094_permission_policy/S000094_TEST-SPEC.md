---
type: test-spec
parent: S000094
feature: F000053
title: "Permission policy — one declared allow/ask/deny contract — Test Specification"
version: 1
status: Draft
date: 2026-06-06
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
| S1 | security | AC-1 | Policy parses | The policy file's fenced machine-readable block is well-formed and the `scripts/` helper parses it without error (rows have `{verb, mode ∈ allow|ask|deny, scope}`) | `bash scripts/<policy-parser>.sh --validate` |
| S2 | integration | AC-2 | Derived denylist matches the policy deny set | The denylist `cj-handoff-gate.sh` derives equals exactly the set of policy rows with `mode == deny` | `bash scripts/test.sh` (policy-derive assertion) |
| S3 | security | AC-3 | Absent verb resolves to deny | A verb NOT present in the policy resolves to `deny` via the parser | `bash scripts/<policy-parser>.sh --resolve <unknown-verb>` (expect `deny`) |
| S4 | observability | AC-4 | Advisory check is wired + parallel fixture present | `scripts/validate.sh` carries the advisory drift check (exit 0) AND `scripts/test.sh` carries the parallel zzz-test-scaffold integration fixture in the same PR | `bash scripts/validate.sh` (advisory check runs, exit 0) |

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
| E1 | observability | AC-4 | Advisory check fires on injected drift | Edit an enforcement point (or the policy) so the two diverge — e.g. a verb the policy denies appears in a live `allowed-tools` set — then run `bash scripts/validate.sh` | The advisory drift check reports the divergence in its output, and `validate.sh` still exits 0 (advisory, not a hard fail) | PASS = drift is named in the output AND exit code is 0; FAIL = drift unreported, or the check hard-fails CI |
| E2 | security | AC-1, AC-3 | Read the policy + confirm risky verbs + absent-verb default | Open the policy file; confirm git-push-to-main / gh-pr-merge / rm / network are present as deny (or ask); pick a plausible verb NOT listed and run `--resolve <verb>` | The risky verbs are enumerated as deny/ask, and the unlisted verb resolves to `deny` | PASS = all four risky verbs present as deny/ask AND unlisted verb → deny; FAIL = any risky verb missing/allow, or unlisted verb not deny |
| E3 | integration | AC-2 | Live points + dormant deriver all trace to the policy | Read the `skills/CJ_goal_*` SKILL.md references; confirm both live points (allowed-tools, sensitive-surface AUQ) cite the policy; confirm `cj-handoff-gate.sh`'s denylist is derived from the policy deny set | Both live points reference the policy and the dormant denylist is computed from it (not hand-maintained) | PASS = both live points reference policy AND denylist derives from it; FAIL = any point hardcodes its own list independent of the policy |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Live runtime enforcement of `deny` (an orchestrator actually being blocked from `git push to main` / `rm` at runtime) | The deny path runs through `cj-handoff-gate.sh`, which is DORMANT (no live consumer — `/CJ_goal_auto` + `/CJ_goal_run` are deleted); this story only DERIVES its denylist, it does not reactivate live enforcement | A risky verb could still be invoked at runtime via a path not gated by the policy; mitigated by the existing PR-stop + human review (the live containment) and by the allow/ask live points |
| The advisory→strict ratchet (the check hard-failing on drift) | Out of scope — this story lands the check advisory-first (exit 0); the strict flip is its own follow-up PR once the policy is reconciled | Drift could be merged while the check is only advisory; accepted because advisory-first is the established workbench pattern (portability Check 18) and the check still surfaces the drift in output |
| Cross-skill policy completeness (every verb every leaf skill could ever invoke is enumerated) | The policy enumerates the cj_goal orchestrator surface + the named risky verbs, not an exhaustive verb census of all transitively-reachable tools | A verb used deep in a leaf skill but absent from the policy resolves to `deny` by the fail-closed default — surfaced, not silently permitted, but may require a follow-up policy row |
