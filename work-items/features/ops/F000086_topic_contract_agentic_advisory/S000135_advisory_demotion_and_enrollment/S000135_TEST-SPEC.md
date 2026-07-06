---
type: test-spec
parent: S000135
feature: F000086
title: "Advisory agentic demotion + validator/full-suite enrollment — Test Specification"
version: 1
status: Draft
date: 2026-07-06
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. Smoke = automated regression (CI). E2E = manual
     user-scenario verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-3 | Topic-contract check green with exactly TWO advisory notes | Enrollment `[portability, validator, full-suite]` passes the three deterministic points; the agentic point prints an advisory note for validator + full-suite only (portability has an agentic row); `findings=0`, exit 0 | `bash scripts/test-spec.sh --check-topic-contract` |
| S2 | resilience | AC-7 | Rewritten Check 30 negative drill (both arms, temp registry copy, engine-only) | (a) validator's CI-push row removed → exit 1 + `FINDING:` line; (b) portability's agentic row removed → exit 0 + `findings=0` + advisory note present | `bash scripts/test.sh` (Check 30 drill step) |
| S3 | usability | AC-5 | Topic docs present for all three enrolled topics | Dream docs (`docs/goals/{validator,full-suite}.md`) + topic subdirs (`docs/tests/topics/{validator,full-suite}/` index + per-layer pages) exist and pass; exit 0 | `bash scripts/test-spec.sh --check-topic-docs` |
| S4 | core | AC-2 | Seed identity after the topic-axis prose rewrite | `spec/test-spec.md` is byte-identical to the `_emit_seed` heredoc output (the dual-write footgun guard) | `diff <(bash scripts/test-spec.sh --seed) spec/test-spec.md` |
| S5 | integration | AC-4, AC-8 | Full deterministic gate green after all edits | Checks 15/15a/17/19 (doc declarations, no orphans, no work-item IDs), Check 24 (the preserved `"=== Check 30:"` banner anchor), Check 26 (catalog regen after units-row rewording), Checks 27/30/31; plus the full suite + shellcheck | `bash scripts/validate.sh && bash scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3 | Operator runs the topic selector for the newly enrolled topics | Run `bash scripts/test-run.sh --topic validator`, then `bash scripts/test-run.sh --topic full-suite`, with no tier flags | The new rows (validate-hook, validate-nightly, suite-nightly, suite-local + the existing CI-push rows) resolve by topic; free-tier commands run; nothing agentic executes; report + ledger written | PASS if both selectors resolve the declared rows and no model/agentic execution occurs by default; FAIL on unknown-topic, unresolved rows, or any agentic execution |
| E2 | integration | AC-6 | Audit operator runs a Stage-1 test audit against this repo | Invoke `/CJ_test_audit` on the workbench repo and read the Stage-1 report | The engine-call list includes `--check-topic-contract` + `--check-topic-docs`; their verbatim output appears, including the TWO advisory agentic notes (validator + full-suite); no `stage1/` topic-contract findings on the green repo | PASS if both engine calls run and the advisory notes are visible in the report; FAIL if either call is absent (the F000082 inherited drift) or notes are swallowed |

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Portability's agentic test actually PASSING (`/CJ_test_run --topic portability --e2e`) | No local claude CLI on this Windows box; agentic proofs run on-demand / on another machine — the very posture this story encodes | The agentic proof could silently rot; mitigated by it staying declared + the advisory note keeping the gap visible |
| Consumer-repo seeded-prose drift (existing consumers keep the old "agentic required" prose while the engine behaves advisory) | `seed-contracts` is idempotent (present ⇒ skip); no consumer fixture exercises a stale seed | Prose-vs-engine mismatch in existing consumer repos; accepted + documented — the engine governs regardless |
| Festive-margulis session's revised enrollment (per-verb topics on the relaxed contract) | Operator-coordinated follow-up in a different session; not this story's artifact | That session could re-introduce an engine flavor; mitigated by coordination + this landing first |
| `deploy-harness` (and cj-goal-eval, doc-sync, e2e, cj-goal-gate) remaining unenrolled | Deliberate deferral (F000081 speed decision; missing surfaces) — enrollment would need dishonest rows | These topics keep only advisory-matrix coverage; documented in the overlay comment + TODOS note |
