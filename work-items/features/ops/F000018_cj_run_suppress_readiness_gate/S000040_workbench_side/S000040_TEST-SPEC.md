---
type: test-spec
parent: S000040
feature: F000018
title: "Workbench-side change: pass --suppress-readiness-gate, fix Branch(f) open_pr — Test Specification"
version: 1
status: Draft
date: 2026-05-13
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-8 | grep run.md Step 5 prose for `--suppress-readiness-gate` | Step 5 invocation passes the flag | `grep -n -- '--suppress-readiness-gate' skills/CJ_run/run.md` (≥ 2 matches: Step 5 + Branch(f) open_pr) |
| S2 | core | AC-2, AC-3 | grep run.md Branch(f) `open_pr` row for both flag + PR_NUM parsing | Branch(f) auto-dispatches with PR_NUM | `grep -nE "open_pr.*land-and-deploy.*suppress-readiness-gate" skills/CJ_run/run.md` |
| S3 | core | AC-4 | grep SKILL.md for version 0.5.0 | Version bumped | `grep -E '^version: 0\.5\.0' skills/CJ_run/SKILL.md` |
| S4 | core | AC-6 | grep SKILL.md Phase 4 entry mentions --suppress-readiness-gate | Phase 4 line reflects new behavior | `grep -nE 'Phase 4.*suppress-readiness-gate' skills/CJ_run/SKILL.md` |
| S5 | usability | AC-9 | `./scripts/validate.sh` returns 0 | catalog / template integrity | `./scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification. Drives the feature as a real user would.
     Soft cap: 5 rows. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Read Step 5 prose; verify flag is passed | Open `skills/CJ_run/run.md` to Step 5 (~line 745+); read the /land-and-deploy invocation prose | The prose contains `--suppress-readiness-gate` literally; PR_NUM is threaded as `#<PR_NUM>` when non-empty | PASS = flag present + PR_NUM threaded; FAIL = either missing |
| E2 | core | AC-2, AC-3 | Read Branch(f) `open_pr` row; verify auto-dispatch | Open `skills/CJ_run/run.md` to the Branch(f) dispatch table (~line 267); read the `open_pr` row | The row instructs to (a) parse PR_NUM inline from PR_URL/gh fallback, (b) invoke `/land-and-deploy --suppress-readiness-gate #<PR_NUM>` via the Skill tool, (c) NOT print-and-exit 0 | PASS = both flag + PR_NUM logic present; FAIL = still print-and-exit |
| E3 | core | AC-5 | Read CHANGELOG entry | Open `CHANGELOG.md`; find the new entry | Entry mentions Step 5 flag pass-through, Branch(f) auto-dispatch, forward-compat note | PASS = all 3 mentioned; FAIL = any missing |
| E4 | resilience | AC-7 | Confirm forward-compat (mental check) | Read S000040_SPEC.md "Forward-compat safe no-op" AC; cross-check `skills/CJ_run/run.md` invocation form | The invocation passes the flag as a literal positional arg before `#<PR_NUM>`; gstack's pre-flag arg parser would not error on it | PASS = literal form matches gstack's loose-parse contract; FAIL = form would cause an error in older gstack |
| E5 | observability | AC-8 | Greppability check | `grep -n suppress-readiness-gate skills/CJ_run/run.md` | ≥ 2 matches (Step 5 + Branch(f) open_pr) | PASS = 2+ matches; FAIL = fewer than 2 |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| End-to-end run from APPROVED design doc through merge with zero readiness AUQ | Requires gstack PR also landed AND a fresh approved design doc to dogfood on. Out of scope until both PRs land. | Verified post-land via dogfood; if regression, file follow-up D-ticket. |
| Branch(f) `open_pr` exit-0 vs auto-dispatch behavior diff on a real work-item | Requires a real work-item in `open_pr` state. Can be smoke-tested via the doc-grep checks above; full E2E happens once a work-item naturally reaches this state. | Doc-grep + manual read confirms shape; runtime verification deferred. |
| Cross-version compatibility (new workbench + old gstack) on a live machine | The user maintains both repos; verification is a manual smoke after the gstack PR lands. | gstack's case-statement-warn-and-continue arg parsing is the contract; if violated, gstack PR review catches it. |
