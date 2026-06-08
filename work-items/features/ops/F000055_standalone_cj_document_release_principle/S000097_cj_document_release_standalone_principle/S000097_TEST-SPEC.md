---
type: test-spec
parent: S000097
feature: F000055
title: "Standalone /CJ_document-release + general/custom doc-contract principle — Test Specification"
version: 1
status: Draft
date: 2026-06-08
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
| S1 | usability | AC-1 | philosophy.md has the new principle + front-table row, no work-item IDs | Checks 19 + 20 stay green; the new principle text + front-table row are present | `scripts/validate.sh` |
| S2 | resilience | AC-2 | cold-repo guard path runs clean | A synthetic temp repo with `doc-spec.md` but NO `skills-catalog.json` runs the Step 6.7.2 guard with no `jq` stderr error and no stray `.cj-goal-feature/` artifact | `bash tests/cj-document-release-config.test.sh` (new cold-repo smoke row) |
| S3 | integration | AC-5 | mechanical portable guarantee holds cold | `doc-spec.sh --validate` passes in a repo with no skills catalog | `scripts/doc-spec.sh --validate` (run in the synthetic cold repo) |
| S4 | core | AC-4 | portability stays honest | `CJ_document-release` catalog entry portability == `local-only`; Step 5.7 portability gate emits no `[portability-red]` | `scripts/cj-portability-audit.sh` / `PORTABILITY_STRICT=1 cj-goal-common.sh --phase portability-audit` |
| S5 | core | AC-1,2,3,4,5 | full suite + validate green | `scripts/test.sh` (superset of validate) passes with all five deltas in place, incl. the new smoke row and USAGE.md Check-14 resolution | `scripts/test.sh` |

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
| E1 | resilience | AC-2 | Run the skill cold in a non-workbench repo | In a temp repo with `doc-spec.md` but no `skills-catalog.json`, invoke `/CJ_document-release`; observe Step 6.7.2 output and the working tree afterward | One clean skip note printed (no `jq` stderr); 6.7.1/6.7.3 incl. the human-doc no-work-item-ID lint still run; no untracked `.cj-goal-feature/` dir left behind | PASS = clean note + no stray artifact + registry audit ran; FAIL = `jq` stderr noise or stray `.cj-goal-feature/` |
| E2 | observability | AC-3 | Trigger the gstack-absent message | With gstack `/document-release` not resolvable, run `/CJ_document-release` and reach the Step 4→5 boundary | A `[doc-sync-red]` message surfaces naming "gstack `/document-release` not installed" as a possible cause | PASS = the actionable `[doc-sync-red]` cause appears for the resolution-failure case; FAIL = silent/unhelpful failure |
| E3 | usability | AC-1 | Read the new principle in context | Open `docs/philosophy.md`, read the front-table, then the new sibling principle under `## Topic: Deployment` | The principle states the general/custom two-tier model + portable any-repo pass + wire-into-CI hook; a matching front-table row exists; reads as a sibling to `### The doc contract is one file`, not a duplicate | PASS = principle + row present and coherent, no work-item IDs; FAIL = missing row, duplicated content, or leaked ID |

<!-- If an E2E test skill exists for this feature, reference it here:
     E2E test skill: the test skill for the feature
     Run with: `/test-{skill-name}-e2e` -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The per-`requirement` audit pass running fully cold | It is agent-judged and needs gstack present — not a self-contained binary; the "cold" success bar is the mechanical `doc-spec.sh --validate`, not the agent pass | A cold repo without gstack gets schema validation but not the agent requirement audit; acceptable per the design's Scope honesty |
| Broadcasting the philosophy prose into consumer repos | Out of scope — the seed carries `doc-spec.md` structure, not `philosophy.md` text | Each repo writes its own prose; "general by default" is true at the declared-and-stubbed level only |
| `doc-spec.sh --check-on-disk` (declared⇔on-disk in the portable helper) | Deferred to a TODOS follow-up; not built here | Consumer-repo CI carries schema validation only until the follow-up lands |
