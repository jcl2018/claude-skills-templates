---
type: test-spec
parent: S000132
feature: F000082
title: "Topic contract + portability agentic proof — Test Specification"
version: 1
status: Draft
date: 2026-07-04
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | `topic:` parses + lists on all 12 rows | `--validate` passes with the 9th column; `--list-categories` emits a topic per row (no TSV field-count drift) | `bash scripts/test-spec.sh --validate && bash scripts/test-spec.sh --list-categories` |
| S2 | core | AC-2 | `topic_contracts: [portability]` parses | portability reads as enrolled; unenrolled topics unaffected | `bash scripts/test-spec.sh --check-topic-contract` (enrolled list non-empty) |
| S3 | resilience | AC-3 | Hard Check catches an under-covered enrolled topic | removing portability's agentic row → engine exits non-zero naming the missing local-hook+agentic coverage; restore → exit 0 (targeted engine only, no whole-validate re-run) | negative test in `scripts/test.sh` (plant → `! bash scripts/test-spec.sh --check-topic-contract` → restore → `bash scripts/test-spec.sh --check-topic-contract`) |
| S4 | integration | AC-4 | Hard Check wired into `validate.sh`, CI-safe | `validate.sh` green on this repo with the new Check; zero model spend | `bash scripts/validate.sh` |
| S5 | core | AC-5 | Agentic-sandbox deterministic helpers smoke | neutral sandbox + `git init --bare` tagged upstream via `SKILLS_UPDATE_REMOTE_URL` (no `git` shim) succeed with no model spend | the deterministic-helper unit test for `scripts/lib/agentic-sandbox.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. Soft cap: 5 rows.
     Post-ship rows carry the literal `post-ship` token in the Tag column. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | observability | AC-6 | Portability agentic test SKIPs clean, then proves the nudge locally | (a) Run `bash tests/portability-version-agentic.test.sh` with `CJ_E2E_LOCAL` unset. (b) Locally with `CJ_E2E_LOCAL=1` + a verified `claude` login, run it again. | (a) SKIP, exit 0, no model spend. (b) Drives `claude --print` (budget `$0.50`) and PASSES with a `{surfaced_nudge:true, evidence:...}` verdict. | (a) exit 0 + a SKIP line + no `claude` call; (b) PASS iff the agent SURFACES the upgrade nudge (not merely that the banner is emitted), with cited evidence. |
| E2 | usability | AC-7 | Run + audit the row through the cj_test_ verbs | (a) `/CJ_test_run portability-version-agentic --e2e`. (b) `/CJ_test_run portability-version-agentic` (default free). (c) `/CJ_test_run --topic portability`. (d) `/CJ_test_audit`. | (a) executes the agentic row; (b) SKIPs it (tier-not-selected); (c) runs every portability-topic row; (d) Stage 1 reports `--check-topic-contract` + `--check-structure` wired. | Each sub-step matches its expected selection/skip; the audit's Stage-1 output verbatim shows the new row wired. |
| E3 | integration | AC-8, AC-9 | Docs + contract prose are green and grandfather recorded | Run `bash scripts/validate.sh` (Checks 24/26/27/28 + `doc-spec --check-on-disk`); open the front-door doc + `docs/tests/index.md` + `spec/doc-spec-custom.md`; confirm CLAUDE.md + `spec/test-spec.md`/`--seed` prose + the grandfather follow-up TODOs. | All named checks pass; the front-door doc has the three sections (`## What it is` / `## How to run` / `## Explanation`); the seed-identity test passes; grandfather TODOs exist in `TODOS.md`. | Green validate + a human read confirms the three sections, the index/doc-spec rows, and the recorded grandfather TODOs. |

<!-- E2E test skill: none for this story; verification is via the named scripts + skill invocations above. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The agentic test's live `claude --print` path in CI | Agentic is local-only by house rule (F000080) — CI never spends a model; the hard Check proves declaration only | CI cannot regress-detect the live agent behavior; a human runs E1(b) locally before ship |
| The real release-tag inertness (upstream `v1.1.0` vs VERSION 6.0.116) | Separate defect; this story builds the CATCH mechanism (a tagged sandbox upstream), not the tagging fix | The live inertness persists until the separate defect ships; the agentic test would catch its CLASS given a tagged upstream |
| The 11 grandfathered non-portability topics' three-layer coverage | Enrollment is opt-in; only portability is enrolled + proven this story | Those topics keep the advisory matrix until enrolled via their follow-up TODOs |
| `run_preamble_via_claude`'s model-spend path in the deterministic smoke | The smoke exercises only the two deterministic helpers (no model); the model helper is covered by E1(b) local run | The model helper is not unit-smoked; its behavior rides the local E2E |
