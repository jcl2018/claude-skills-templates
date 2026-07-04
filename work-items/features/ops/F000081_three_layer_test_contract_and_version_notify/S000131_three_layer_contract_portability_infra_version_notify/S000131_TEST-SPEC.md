---
type: test-spec
parent: S000131
feature: F000081
title: "Three-layer contract + portability→infra + git ls-remote version-notification + retire /CJ_portability-audit — Test Specification"
version: 1
status: Draft
date: 2026-07-04
author: Charlie Jiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Two tiers: Smoke = automated regression (CI);
     E2E = manual user-scenario verification before /ship. Soft cap: 5 rows/tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Seed byte-identity + advisory matrix render | `spec/test-spec.md` stays byte-identical to the seed; `--check-structure` prints the per-category × 3-layer matrix + a `NOTE:` per empty cell and exits 0 | `bash tests/test-spec.test.sh` (seed-identity case + the missing-layer→NOTE / full-matrix→clean / no-categories→inactive fixture cases) |
| S2 | core | AC-2 | Portability reclass + doc-move integrity | The two portability rows report `category: infra`; the moved `docs/tests/infra/…` front-door docs resolve declared↔on-disk (no orphans) and the regenerated catalog matches | `bash scripts/doc-spec.sh --check-on-disk && bash scripts/test-spec.sh --render-docs --check && bash scripts/test-spec.sh --list-categories` |
| S3 | integration | AC-3, AC-4 | Checkout-independent version-check | With a stubbed `git ls-remote` + a `.source`-absent manifest, the banner fires when remote > local, is silent when equal, and fail-softs when unreachable | `bash tests/skills-update-check.test.sh` |
| S4 | resilience | AC-4, AC-5 | Reverse-sweep + workflow registration | Check 24's reverse sweep resolves both `tests/skills-update-check.test.sh` and `.github/workflows/nightly.yml` to exactly one `units:` row each; the merged registry validates | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --check-coverage` |
| S5 | usability | AC-6 | Whole-suite green after retirement | With `/CJ_portability-audit` removed everywhere but the engine + Check 18 kept, the full validator (Error checks 1/4/5, Checks 13/14/18/24/27, workflow-spec `--validate`, philosophy New-skills) is green | `bash scripts/validate.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Each row is one user-visible scenario. AC column maps to a SPEC AC.
     post-ship rows (verifiable only after merge, e.g. `gh workflow run` against a
     workflow not on remote refs until merge) carry the literal `post-ship` token. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Maintainer reads the coverage matrix | Run `bash scripts/test-spec.sh --check-structure` in the workbench (and via `/CJ_test_audit` Stage 1) | A printed per-category × {CI-push, CI-nightly, local-hook} matrix table with an advisory `NOTE:` under each empty cell; exit code 0 | PASS if the matrix table renders, empty cells show `NOTE:` (not `FINDING:`), and exit 0; FAIL if any empty cell hard-fails or exit ≠ 0 |
| E2 | integration | AC-3 | Remote/foreign-repo install gets a staleness nudge | On a checkout WITHOUT `.source` (or with `.git` removed), set the manifest `collection_version` below the latest published `v`-tag and invoke a skill preamble (`skills-update-check`) | A `SKILLS_UPGRADE_AVAILABLE <local> <remote>` banner + a context-appropriate hint (`skills-deploy install --bundle` / `setup.sh` when `.source` is absent) | PASS if the banner + non-`.source` hint appear with no `.git` checkout present; FAIL if the check silently no-ops (the old blind-spot) |
| E3 | usability | AC-6 | Maintainer confirms the verb is gone but the property is proven | Attempt to route `/CJ_portability-audit` (absent), then run `bash scripts/validate.sh` and inspect the Check 18 output | The verb no longer routes / is absent from the catalog, routing, workflow-spec, and philosophy; `validate.sh` is green and Check 18 still lints declared-vs-actual portability | PASS if the verb is unroutable everywhere AND Check 18 + the engine still run green; FAIL if any retirement touchpoint still references the verb or the engine broke |
| E4 | resilience | AC-5 | Nightly full-suite runs off the per-PR path | `post-ship` — after merge, trigger `.github/workflows/nightly.yml` via `gh workflow run nightly.yml` (the workflow does not exist on remote refs until merge) | The nightly workflow dispatches and runs the full `scripts/test.sh` on ubuntu to green | PASS if the dispatched run completes green; FAIL if it errors or the workflow is unregistered as a `ci` unit |

<!-- E4 is post-ship: /CJ_qa-work-item Step 4 filters it from the E2E subagent dispatch
     and records a [qa-e2e-deferred] journal entry; verified after merge via `gh workflow run`. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| A truly agentic portability local-hook run (a real `claude --print` skill preamble in a stale sandbox) | Deferred (Q1); the local-hook cell is backfilled deterministically via a stubbed-remote sandbox, which the advisory matrix permits | The local-hook level is proven deterministically, not agentically, this increment — a real model-surfaced-prompt regression is deferred |
| The `validate.yml` per-PR trim + the moved units' `layer` reclass to `CI-nightly` | Out of scope — deferred attended follow-up; an autonomous PR-stop can't verify a trimmed gate | The per-PR gate stays heavy until the deferred trim; the advisory matrix reports the current (honest `CI-push`) placement |
| A live-network `git ls-remote` against the real upstream | Unit tests stub the remote (PATH-stub / `SKILLS_UPDATE_REMOTE_URL`) for hermetic, no-network CI | A real-remote regression (auth, transport, rate-limit) is not exercised in CI; fail-soft covers the unreachable path |
| An untagged-upstream consumer repo path | P2 #9 — fail-soft to silent is asserted logically, not against a real untagged remote | A consumer whose `upstream_url` never tags releases gets no nudge (accepted: no false nudge), un-exercised against a live untagged repo |
