---
type: test-spec
parent: S000028
feature: F000014
title: "Auto-mode for /personal-pipeline — Test Specification"
version: 1
status: Draft
date: 2026-05-10
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion (Stories #1-#10). P1 (Story #11) covered by S5.

     Smoke = automated regression. Lives in CI / repeatable shell.
     E2E   = manual user-scenario verification. Run before /ship.

     Soft cap: 5 rows per tier. Both tiers at 5 here, pulling double duty
     on multi-AC mappings. -->

## Smoke Tests

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Manual mode bash-block byte-identity | Manual code path of `pipeline.md` is unchanged at the Bash-block level vs v1.13.0 baseline | `git diff v1.13.0 -- skills/personal-pipeline/pipeline.md \| grep -E '^\\+.*\\\$\\(' \| wc -l` (expect: only added lines for `if $AUTO_MODE` blocks; no removed/modified existing Bash-emitting lines) |
| S2 | core, observability | AC-3, AC-9 | $DECISION_LOG line shape | A run with one sensitive-surface AUQ produces a JSONL line with required fields and the run_id tag | `jq -e 'select(.run_id == "$RUN_ID") \| select(.classification == "user_challenge_approved") \| select(.gate_id != null) \| select(.files_affected \| type == "array") \| select(.reasoning != null)' ~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl` (exit 0) |
| S3 | resilience | AC-4, AC-5, AC-5b | Halt contracts diverge correctly | Boundary-check-red and subagent-crash halts produce NO $DECISION_LOG line for that gate; Halt-at-Gate User Challenges DO produce a `user_challenge_halt` line | `! jq -e 'select(.run_id == "$BOUNDARY_RED_RUN") \| select(.gate_id == "boundary-check")' decisions.jsonl && jq -e 'select(.run_id == "$HALT_AT_GATE_RUN") \| select(.classification == "user_challenge_halt")' decisions.jsonl` |
| S4 | usability | AC-7 | Empty-state short-circuit | A SPEC-light run logs only `mechanical` decisions; Step 8.5 short-circuits without surfacing AUQ; tracker journal contains `[auto-pipeline-clean]` | Run pipeline on `fixtures/regression-auto-empty-spec/` design doc; assert `grep -q '\\[auto-pipeline-clean\\]' work-items/.../TRACKER.md` AND assert no Step 8.5 AUQ event in transcript |
| S5 | observability | AC-11 | Multi-classification synthetic SPEC counts | Synthetic SPEC with 1 sensitive surface + 2 Tradeoff rows + green QA produces $N≥1 + $M=2 + $K=1 at Step 8.5 | Run pipeline on `fixtures/regression-auto-multi-classification/`; assert `jq -c "select(.run_id==\"$RUN_ID\")" decisions.jsonl \| jq -s 'group_by(.classification) \| map({(.[0].classification): length}) \| add'` matches `{"mechanical":N, "taste":2, "user_challenge_approved":1}` (N≥1) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core, usability | AC-2, AC-6 | Green-path auto run with Step 8.5 surface | 1) Pick a TODOS.md item that touches `skills-catalog.json` (e.g., the `qa-work-item` description bump). 2) Run `/office-hours` to produce a small design doc with one Tradeoff row. 3) Run `/personal-pipeline --auto <design-doc-path>`. 4) Wait for Step 8.5 AUQ. 5) Inspect the AUQ summary. | Pipeline runs scaffold/implement/QA without inline AUQs. Step 8.5 surfaces with $K≥1 user_challenge_approved (the catalog change) + $M≥1 taste (the Tradeoff). AUQ format matches gstack: D-numbered header, Project line, ELI10, Stakes, Recommendation, Note, Decision summary, Log path, Pros/Cons (≥40 chars each), Net. Picking Approve sets `end_state=green`. | PASS if AUQ surface matches gstack format AND $K + $M counts match decision log AND Approve writes `[auto-final-gate-approved]` to tracker journal. |
| E2 | usability, resilience | AC-8 | Abort at Step 8.5 prints reverts | 1) Run E1's pipeline up to Step 8.5. 2) At the AUQ, pick **Abort + show what to revert**. 3) Inspect printed output. 4) Run `git status` to confirm files are still mutated. 5) Run `git restore <files>` per the printed list. | Output groups files_affected by gate, naming each User-Challenge-Approved decision and its files. `end_state=user_aborted`. Pipeline state preserved (work-item dir + repo files NOT auto-reverted). After manual `git restore`, working tree clean. | PASS if printed output is per-decision grouped AND files still mutated AND `git restore` succeeds AND working tree clean post-restore. |

<!-- E2E test skill: not yet — file follow-up if /personal-pipeline gets its own
     E2E skill in v2. Manual walkthrough for v1. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Multi-User-Challenge wall-of-text UX (Step 8.5 with $K > 5) | No real workflow currently produces $K > 5; would need synthetic SPEC with 6+ sensitive surfaces | Acceptable: if real usage hits this, file follow-up; v1 ships text-block at any $K |
| Sunset trip-wire integration with auto mode | Trip-wire fires at invocation 6; smoke-testing requires 6+ telemetry lines, which is a long ramp | Acceptable: AC-10 is verified by reading the Step 9.2 code path during implementation review; integration test deferred to first natural sunset trigger |
| `--auto` interaction with `--manual` flag (or any future flag combinations) | No flag combinations exist in v1 | Acceptable: v1 is single-flag only; if combinations land in v2, add new TEST-SPEC rows |
| Programmatic rollback for partial Approve | Out of scope for v1 (chose Abort + manual revert) | Acceptable: Definition of Done explicitly excludes programmatic rollback; user reverts manually |
| Dogfood: running `/personal-pipeline --auto` on this story's own design doc | Bootstrapping problem (the auto mode doesn't exist until this story ships) | Acceptable: post-ship, run /personal-pipeline --auto on any P3/S TODOS.md item as bootstrap dogfood; record result in TRACKER journal |
