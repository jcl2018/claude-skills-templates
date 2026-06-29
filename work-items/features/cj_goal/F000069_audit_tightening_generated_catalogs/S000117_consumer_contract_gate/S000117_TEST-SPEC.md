---
type: test-spec
parent: S000117
feature: F000069
title: "Consumer-repo deterministic Stage-1 enforcement gate — Test Specification"
version: 1
status: Draft
date: 2026-06-29
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE story S000117. Smoke + E2E together cover every SPEC P0 AC
     (stories #1-#8). AC column maps each row to a SPEC story # (acceptance-criteria
     block): AC-1=gate engine-only checks, AC-2=HARD/SOFT/SKIP disposition,
     AC-3=install ships gate to _cj-shared, AC-4=consumer auto-install guarded,
     AC-5=standalone install-contract-gate/--remove, AC-6=CI snippet, AC-7=test-deploy
     + hermetic test, AC-8=declared in test contract. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-2 | Gate PASS / hard-FAIL / declared-exists SOFT / registry-absent SKIP | `cj-contract-gate.sh` PASSes on a clean contract; hard-FAILS (non-zero) on a planted violation (stale generated catalog / malformed registry / unregistered `tests/*.test.sh`); treats a missing declared doc as a SOFT remediation (exit 0, not a block); a registry-absent contract is a clean SKIP; per-check summary printed | `tests/cj-contract-gate.test.sh` (the gate PASS/FAIL/soft/skip cases) |
| S2 | integration | AC-4 | Consumer auto-install installs the sentinel hook | In a temp consumer git repo, the consumer-install path installs a pre-commit hook carrying the `setup-hooks` SENTINEL whose body resolves + runs `cj-contract-gate.sh`; a re-run is idempotent (no duplicate) | `tests/cj-contract-gate.test.sh` (the consumer auto-install case) |
| S3 | integration | AC-4 | Guarded skips: husky / workbench-self | A temp repo with `core.hooksPath` set (husky-like) is SKIPPED with a note; the workbench self-repo is SKIPPED (runs `validate.sh`); a non-git cwd is a clean no-op; a non-workbench pre-commit hook is backed up + WARNed, not clobbered | `tests/cj-contract-gate.test.sh` (the guard-skip cases) |
| S4 | usability | AC-5 | Standalone `install-contract-gate --remove` uninstalls | `skills-deploy install-contract-gate` installs the gate hook on cwd; `--remove` uninstalls the sentinel hook leaving a non-workbench hook untouched | `tests/cj-contract-gate.test.sh` + `scripts/test-deploy.sh` (the `--remove` case) |
| S5 | integration | AC-3, AC-7, AC-8 | Deploy set + test-deploy coverage + units row resolve | `cj-contract-gate.sh` is in the shared-scripts deploy set (deployed to `_cj-shared`); `scripts/test-deploy.sh` carries the gate-hook auto-install + skip + `--remove` cases; the new test's `spec/test-spec-custom.md` units row validates; Check 24 reverse-sweep resolves the new `tests/*.test.sh`; full `validate.sh` is 0/0 | `grep -n 'cj-contract-gate' scripts/skills-deploy scripts/test-deploy.sh` + `scripts/test-spec.sh --validate --check-coverage` + `scripts/validate.sh` |

<!-- Soft cap: 5 rows — met. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1, AC-2 | Operator runs the gate on a clean contract, then on a planted violation | In a temp consumer repo with seeded contracts, run `cj-contract-gate.sh`; then hand-edit a generated catalog stale (or malform a registry / drop a test's units row) and re-run; then delete a declared doc and re-run | Clean run: all checks PASS/SKIP, exit 0. Planted violation: the relevant HARD check prints `FINDING` and the gate exits non-zero. Missing declared doc: a `REMEDIATION` note points at `/CJ_document-release` and the gate exits 0 (not a block) | PASS if the gate is green on a clean contract, hard-fails on a planted violation, and treats a missing declared doc as a soft remediation |
| E2 | core | AC-2 | Operator confirms registry-gating + rules-only handling | In a temp repo missing one contract (e.g. no `spec/workflow-spec.md`), run the gate; in a rules-only test-spec repo (no units rows), run the gate | The absent contract's check is a clean SKIP (`REGISTRY=absent`, exit 0 for that check); the rules-only `--check-coverage` reports "inactive" (not a finding); the gate's overall exit reflects only the HARD findings present | PASS if an absent contract SKIPs and a rules-only coverage cross-check reports inactive (neither blocks) |
| E3 | integration | AC-3, AC-4 | Operator adopts via consumer `install` and the gate auto-installs (guarded) | From a temp consumer git repo, run `skills-deploy install`; inspect `_cj-shared` for the deployed gate and `.git/hooks/pre-commit` for the sentinel hook; then make a contract-violating change and `git commit`; repeat from a workbench self-checkout and from a temp repo with `core.hooksPath` set | `install` deploys `cj-contract-gate.sh` to `_cj-shared` and installs the sentinel pre-commit hook; a violating `git commit` is BLOCKED by the gate; the workbench self-install SKIPS the hook (runs `validate.sh`); the husky-like repo SKIPS with a note; a non-git install is a clean no-op | PASS if consumer install ships + installs the gate, a violating commit is blocked, and the self/husky/non-git guards all hold |
| E4 | usability | AC-5, AC-6 | Operator uses the standalone command + reads the CI snippet | In a temp consumer repo run `skills-deploy install-contract-gate`, then `--remove`; read the CI snippet in `docs/architecture.md` / `CLAUDE.md` and run the gate the way the snippet shows | `install-contract-gate` installs the gate hook; `--remove` uninstalls the sentinel hook (a non-workbench hook is left untouched); the documented GitHub Actions snippet runs `cj-contract-gate.sh` on PRs and is doc-only (no `.github/workflows/*.yml` shipped into the consumer) | PASS if the standalone install/remove works and the CI snippet runs the gate without a shipped workflow file |
| E5 | integration | AC-7, AC-8 | Suite proves the gate + the guarded install + the registration | Run the full suite: `scripts/test.sh` (includes `tests/cj-contract-gate.test.sh` + the `scripts/test-deploy.sh` cases) | The suite is green; `tests/cj-contract-gate.test.sh` ends `RESULT: PASS` and exercises gate PASS/hard-FAIL/declared-exists-soft/registry-absent-SKIP + consumer auto-install sentinel/husky-skip/self-skip/`--remove`; `scripts/test-deploy.sh` covers the gate-hook install + skips + `--remove`; Check 24 reverse-sweep resolves the new test; `validate.sh` 0/0 | PASS if `scripts/test.sh` is green incl. the new test + test-deploy coverage and the units row resolves |

<!-- Soft cap: 5 rows — met. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Cross-machine consumer-repo adopt drill (real second machine) | The hermetic test + the in-repo temp-dir drills exercise the gate, the guarded install, and the remove path deterministically; a true second-machine adopt is out of scope for an in-repo story | A genuinely different machine's `_cj-shared` / manifest could differ; mitigated by the machine-independent `${CJ_SHARED_SCRIPTS:-...}` resolution + the `is_workbench_self_repo` guard + the temp-dir assertions |
| Agent-judged Stage 2/3 enforcement in the gate | The gate is the deterministic engine-only subset by design — a git hook / CI step can't run an agent | Stage 2/3 (requirement compliance + implementation drift) stay on-demand via `/CJ_doc_audit` / `/CJ_test_audit`; the gate enforces only the deterministic contract |
| Real husky / lefthook / pre-commit-framework interaction | The guard keys on a custom `core.hooksPath` being set (the signal these frameworks use) and SKIPS with a note rather than fighting them; the specific framework internals are not simulated | A repo using an exotic hook manager that does NOT set `core.hooksPath` could double-install; documented as the `core.hooksPath` detection boundary, mitigated by the standalone `--remove` opt-out |
| Every engine's deterministic-check edge (e.g. a partially-adopted contract mixing present + absent surfaces) | The gate composes the engines' own `--check-on-disk` / `--validate` / `--check-coverage` / `--render-docs --check` dispositions; each engine owns + tests its own check semantics (S000114/S000115/the doc-spec engine) | A malformed engine disposition surfaces through the gate as a FINDING (correct) with the root-cause fix owned by that engine's story; the gate only composes + thresholds the dispositions |
