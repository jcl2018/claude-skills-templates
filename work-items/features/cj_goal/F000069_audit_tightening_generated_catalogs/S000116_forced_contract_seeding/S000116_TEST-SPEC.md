---
type: test-spec
parent: S000116
feature: F000069
title: "Forced contract seeding + stale-engine-shadow fix — Test Specification"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE story S000116. Smoke + E2E together cover every SPEC P0 AC.
     AC column maps each row to a SPEC story # (acceptance-criteria block). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-2, AC-3, AC-4 | `seed-contracts` seeds all 3 + self-skip | In a temp consumer repo, `skills-deploy seed-contracts` creates valid `spec/{doc,test,workflow}-spec.md`; a re-run reports all `present` (no-op); a workbench-like temp repo is SKIPPED | `tests/seed-contracts.test.sh` (the seed-all-3 + idempotent + workbench-self-skip cases) |
| S2 | core | AC-1 | Stale-engine probe falls back + emits finding | With a planted stale repo-local engine stub (lacks `--classify`), the relevant resolution falls back to `_cj-shared` and emits `stage1/engine-stale` (not a silent no-op) | `tests/seed-contracts.test.sh` (the stale-engine probe case) |
| S3 | core | AC-2 | Corruption guard | `do_seed_contracts` only `mv`s a `--seed` output that is non-empty AND `--validate`-clean; a botched seed is reported `seed-failed` with nothing written to `spec/` | `tests/seed-contracts.test.sh` (the corruption-guard case) |
| S4 | integration | AC-7 | test-deploy coverage present | `scripts/test-deploy.sh` carries cases for `seed-contracts` + the install always-seeds-consumer path | `scripts/test-deploy.sh` + `grep -n 'seed-contracts\|always-seed' scripts/test-deploy.sh` |
| S5 | integration | AC-8 | Units rows + coverage resolve | The new test's `spec/test-spec-custom.md` units row(s) validate; Check 24 reverse-sweep resolves the new `tests/*.test.sh`; full `validate.sh` is 0/0 | `scripts/test-spec.sh --validate --check-coverage` + `scripts/validate.sh` |

<!-- Soft cap: 5 rows — met. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-4, AC-2, AC-3 | Operator force-seeds a fresh consumer repo, then re-runs | In a temp git repo with no `spec/`, run `skills-deploy seed-contracts`; inspect `spec/`; run it again | First run reports `doc-spec: seeded`, `test-spec: seeded`, `workflow-spec: seeded` and writes three valid (`--validate`-clean) registries; the re-run reports all three `present` (idempotent no-op) | PASS if all three contracts are seeded valid on the first run and the re-run is a clean no-op |
| E2 | security | AC-3 | Operator confirms the workbench self-repo is never re-seeded | From the workbench checkout (or a temp repo carrying the canonical non-skeleton contracts), run `skills-deploy seed-contracts` and `git status` the `spec/` dir | The routine reports the self-repo SKIP; `git status` shows `spec/*.md` UNTOUCHED (no skeleton overwrite, no diff) | PASS if the workbench self-repo is detected and skipped with the real contracts untouched |
| E3 | core | AC-1 | Operator proves the stale-engine probe fires in a real audit | In a temp consumer repo, plant a stale `scripts/doc-spec.sh` stub (lacks `--classify`); run `/CJ_doc_audit`; inspect the Stage-1 report | Stage 1 emits `FINDING: stage1/engine-stale — repo-local doc-spec.sh is stale (missing --classify); using _cj-shared. Remedy: ...`; the audit proceeds on `_cj-shared` (not a silent no-op); with no stale engine the finding is absent | PASS if the stale engine is detected, named with its remedy, and `_cj-shared` is used; clean when no stale engine |
| E4 | integration | AC-5, AC-6 | Operator adopts via consumer `install` and via first audit run | (a) From a temp consumer git repo, run `skills-deploy install` and inspect the visible seeding note + `spec/`; from the workbench self-checkout run `install` and confirm no re-seed; (b) in a temp consumer repo missing `spec/workflow-spec.md`, run `/CJ_doc_audit` and inspect Step 2 | (a) Consumer `install` seeds the three contracts (visible note says seeding ran); the workbench self-install skips (contracts untouched); `install` from a non-git dir is a clean no-op. (b) `/CJ_doc_audit` Step 2 lazily seeds `workflow-spec` (corruption-guarded); `/CJ_test_audit` still seeds test-spec | PASS if consumer install + lazy audit both force-generate the contracts, the workbench self-install skips, and the non-git install is a no-op |
| E5 | integration | AC-7, AC-8 | Suite proves the seeding triggers + the stale probe | Run the full suite: `scripts/test.sh` (includes `tests/seed-contracts.test.sh` + the `scripts/test-deploy.sh` cases) | The suite is green; `tests/seed-contracts.test.sh` exercises seed-all-3 + idempotent + workbench-self skip + the stale-engine probe + the corruption guard; `scripts/test-deploy.sh` covers `seed-contracts` + the install always-seeds path; Check 24 reverse-sweep resolves the new test | PASS if `scripts/test.sh` is green incl. the new test + test-deploy coverage and the units rows resolve |

<!-- Soft cap: 5 rows — met. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cross-machine consumer-repo adopt drill (real second machine) | The hermetic test + the in-repo temp-dir drills exercise the seeding/probe logic deterministically; a true second-machine adopt is out of scope for an in-repo story | A genuinely different machine's manifest `source` could differ; mitigated by the manifest-match + canonical-contract OR detection (machine-independent) and the temp-dir self-repo assertion |
| Consumer-repo deterministic Stage-1 enforcement gate | Belongs to deferred Story 4 (`scripts/cj-contract-gate.sh` + hook/CI), not this story | Portable hard enforcement of the contracts in a consumer repo is unproven until Story 4; this story ships the seeding + the audit's standalone Stage-1 path |
| Every engine's `--classify` staleness edge (e.g. an engine that emits a DIFFERENT marker) | The probe keys on the literal `GENERATION=` that all three current engines emit; an exotic future engine is not simulated | A future engine that changes its `--classify` output without keeping `GENERATION=` would be (correctly) treated as stale; documented as an engine-convention constraint |
| `--seed` skeleton content correctness per engine | Each engine's `--seed` output is owned + tested by that engine's own story (S000114/S000115/the doc-spec engine); this story only asserts the seed is non-empty + `--validate`-clean before mv | A malformed `--seed` from an engine surfaces as `seed-failed` here (caught by the corruption guard), with the root-cause fix owned by the engine's story |
