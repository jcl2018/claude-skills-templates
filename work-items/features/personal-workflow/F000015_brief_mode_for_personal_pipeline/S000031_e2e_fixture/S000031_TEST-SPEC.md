---
type: test-spec
parent: S000031
feature: F000015
title: "End-to-end brief-mode fixture — Test Specification"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Smoke = automated structural checks on the fixture and test.sh wiring.
     E2E = manual driver-runs of the fixture against `scripts/test.sh`. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Fixture directory exists | `skills/personal-pipeline/fixtures/brief-mode/` is present and contains expected files | `test -d skills/personal-pipeline/fixtures/brief-mode && test -f skills/personal-pipeline/fixtures/brief-mode/run.sh` |
| S2 | core | AC-2 | Brief text has special chars | brief-text source contains at least one backtick AND at least one `## ` line | `grep -q '\`' skills/personal-pipeline/fixtures/brief-mode/brief-text.txt && grep -q '^## ' skills/personal-pipeline/fixtures/brief-mode/brief-text.txt` |
| S3 | integration | AC-7 | test.sh references fixture | `scripts/test.sh` references the brief-mode fixture path | `grep -q 'fixtures/brief-mode' scripts/test.sh` |
| S4 | resilience | AC-6 | Fixture has cleanup | run.sh contains a teardown / cleanup block (trap or explicit cleanup) | `grep -E '(trap.*EXIT\|cleanup\|teardown)' skills/personal-pipeline/fixtures/brief-mode/run.sh` |
| S5 | observability | AC-5 | Legacy telemetry input present | `legacy-telemetry-line.json` exists and does NOT contain a `mode` key | `test -f skills/personal-pipeline/fixtures/brief-mode/legacy-telemetry-line.json && ! grep -q '"mode"' skills/personal-pipeline/fixtures/brief-mode/legacy-telemetry-line.json` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3, AC-4 | Fixture green run with telemetry assertion | Run `bash skills/personal-pipeline/fixtures/brief-mode/run.sh` from repo root. Inspect exit code and assertion output. | Exit code 0; assertion log shows pipeline GREEN end-to-end and `mode: "brief"` in telemetry | PASS if exit 0 with all 4 P0 assertions logged as PASS; FAIL on any assertion fail |
| E2 | observability | AC-5 | Legacy telemetry default | Run the fixture; verify the regression block parses `legacy-telemetry-line.json` and reports `mode = "manual"` | Assertion logged as `legacy mode default: manual (PASS)` | PASS if logged exactly; FAIL otherwise |
| E3 | resilience | AC-6 | Idempotent fixture rerun | Run the fixture twice in succession via `scripts/test.sh`. Verify both runs are green and no orphan state remains. | Two consecutive PASS lines; no orphan files in `~/.gstack/projects/{slug}/` or `~/.gstack/analytics/` after teardown | PASS if both pass and no orphans; FAIL on second-run regression |
| E4 | core | AC-2 | Special-char insulation regression | Manually break the synthesized stub by editing the fenced verbatim block to drop the closing ` ``` `. Rerun the fixture. | Fixture FAILs with a clear assertion message about stub-structure violation | PASS if FAIL is explicit and points at the structural break; FAIL if the fixture passes despite the broken stub (regression net is broken) |
| E5 | integration | AC-7 | test.sh default invocation includes fixture | Run `scripts/test.sh` with no args from a fresh checkout. | Output mentions running brief-mode fixture; final summary includes brief-mode in case count | PASS if visible; FAIL if fixture is silently skipped |

<!-- E2E test skill: none in v1 (fixture itself IS the smoke + E2E surface) -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Concurrent-invocation race | Per parent F000015, accepted risk in v1 | Documented; if a real collision happens, surface in TODOS.md |
| Brief-mode `--auto` combination as a separate fixture | Combined into the same fixture for v1 simplicity | If `--auto` interaction with brief-mode regresses independently of plain `--brief`, separate fixture may be needed in v1.1 |
| `mode` value validation (typo `breif` etc.) | Out of scope; the writer is the only source of `mode` values | If parser semantics expand, invalid values may silently fall through |
| Performance profiling | Out of scope for v1 | If fixture runtime becomes a CI burden, opt-out flag can be added later |
