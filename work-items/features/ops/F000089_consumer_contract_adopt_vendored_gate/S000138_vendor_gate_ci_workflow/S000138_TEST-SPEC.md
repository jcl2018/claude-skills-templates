---
type: test-spec
parent: S000138
feature: F000089
title: "Vendor the gate + drop the CI workflow — Test Specification"
version: 1
status: Draft
date: 2026-07-07
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | integration | AC-1 | Adopt into a scratch consumer repo vendors 4 engines | `.cj-contract/` holds cj-contract-gate.sh + doc-spec.sh + test-spec.sh + workflow-spec.sh, each executable, each with the stamped header | `bash scripts/test-deploy.sh` (new vendor case) |
| S2 | integration | AC-2 | Adopt drops the CI workflow | `.github/workflows/cj-contract-gate.yml` exists, triggers on pull_request + push:main, runs `bash .cj-contract/cj-contract-gate.sh --repo .` | `bash scripts/test-deploy.sh` (new drop case) |
| S3 | resilience | AC-3 | Bare-runner gate proof (no `_cj-shared`) | Vendored `.cj-contract/cj-contract-gate.sh --repo .` exits 0 on clean, non-zero on planted violation, SKIP on unadopted — with `HOME` pointed away from any `_cj-shared` | `bash scripts/test-deploy.sh` (bare-runner case) |
| S4 | usability | AC-4 | `--remove` cleans up symmetrically | After `--remove`, `.cj-contract/` + the dropped workflow are gone (sentinel-marked); a hand-edited file survives | `bash scripts/test-deploy.sh` (remove case) |
| S5 | security | AC-5 | Self-repo skip + seed identity | Running adopt against the workbench self-repo drops no `.cj-contract/` / workflow; `test-spec.sh --seed` byte-identity + `validate.sh` stay green | `bash scripts/validate.sh && bash scripts/test-deploy.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Soft cap: 5 rows. AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | integration | AC-1, AC-2 | Adopt a real consumer repo end to end | In a scratch git repo, run `skills-deploy install-contract-gate`; inspect `.cj-contract/` + `.github/workflows/cj-contract-gate.yml`; `git add` + commit them | Both artifacts present + committed; workflow references the vendored gate | 4 engines vendored + stamped; workflow runs the vendored gate |
| E2 | resilience | AC-3 | CI would gate a planted drift | With `HOME` re-pointed (no `_cj-shared`), run `.cj-contract/cj-contract-gate.sh --repo .` on the clean adopt, then plant a structural violation and re-run | Green first, non-zero after the plant | Exit code flips 0 → non-zero on the planted violation |
| E3 | usability | AC-6 | Hand-authored workflow is protected | Pre-place a differing `.github/workflows/cj-contract-gate.yml`, then run adopt | Existing workflow untouched; skip-with-note emitted | No clobber; note printed |
| E4 | usability | AC-7 | Adopt doc reads clearly | Open `docs/adopting-the-contract.md` | Documents run-adopt → commit → drift-reds-PR; declared + ID-free | A new maintainer can adopt from the doc alone |

<!-- Post-ship rows: none — the vendored gate proof runs against a scratch repo,
     not a merged remote workflow, so it is verifiable pre-ship. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The dropped workflow actually running on real GitHub Actions | test-deploy runs in isolated temp dirs, not against live GH Actions; the bare-runner proof (S3/E2) simulates the runner locally | A GH-Actions-specific YAML/syntax issue could slip past local sim — mitigated by the YAML being a static template + a post-ship manual `gh workflow run` if desired |
| Cross-platform vendor (Windows Git Bash copy-mode) beyond what `windows-smoke.sh` covers | test-deploy is CI-nightly + posix-focused per F000075; a fast windows-smoke assertion is added only if cheap | A Windows-specific LF/exec-bit quirk on the vendored scripts — mitigated by the existing LF `.gitattributes` pin + the portability topic already proving cross-machine parity |
