---
type: test-spec
parent: S000083
feature: F000047
title: "Layer 1 static dependency lint — Test Specification"
version: 1
status: Draft
date: 2026-06-04
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. Soft cap: 5 rows per tier (advisory only). -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1, AC-3 | Engine runs over the real catalog and derives the audit set at runtime; no hardcoded skill name/count in the engine source | The catalog-derived selector (AC-1) + the engine is executable and produces output (AC-3 ladder runs) | `bash scripts/cj-portability-audit.sh >/dev/null && ! grep -qE 'CJ_(suggest\|qa-work-item\|goal_feature)' scripts/cj-portability-audit.sh` |
| S2 | resilience | AC-2, AC-4, AC-5, AC-8 | The `zzz-test-scaffold` fixture: a synthetic standalone skill EXECUTING a root helper yields a FINDING; a DOCUMENTED-only mention does not; a bundled-own script + a `portability_requires`-listed dep are OK | EXECUTED-vs-documented precision (AC-2), carve-outs (AC-4), adjudication (AC-5), AND the engine's test.sh integration fixture itself (AC-8 — the parallel test.sh edit) all exercised in one fixture | `bash scripts/test.sh 2>&1 \| grep -q 'portability'` |
| S3 | integration | AC-7, AC-9 | `validate.sh` runs the advisory check, prints portability findings, and EXITS 0 with the pre-seeded catalog | Advisory posture (exit 0, AC-7) + green-by-adjudication (AC-9) | `./scripts/validate.sh; echo "exit=$?"` (expect `exit=0`, output contains portability findings) |
| S4 | observability | AC-6, AC-12 | A run over the unadjudicated set surfaces the three `CJ_goal_*` orchestrators + `CJ_qa-work-item` + `CJ_implement-from-spec` with `findings:`, each naming skill+dep+why; verdicts are one of the three values | Three-value verdict shape (AC-6) + non-no-op predicted findings (AC-12) | `bash scripts/cj-portability-audit.sh --no-adjudication 2>&1 \| grep -E 'CJ_goal_feature.*findings'` (flag name per implementation; assert the five expected skills appear with findings) |
| S5 | usability | AC-10 | Doc-presence + New-skills no-vanish: SKILL.md+USAGE.md exist with 5 H2 sections; WORKFLOWS/ARCHITECTURE/PHILOSOPHY reference the skill | The skill is registered + documented to convention so validate.sh's doc checks pass | `./scripts/validate.sh 2>&1 \| grep -qiE 'error\|drift' && echo FAIL \|\| echo PASS` (expect PASS; skill appears in PHILOSOPHY decision tree + ARCHITECTURE roster + WORKFLOWS section) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration.
     Modifier: post-ship (E2E rows only). -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Drive the feature as a real user would. AC column maps to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-3, AC-4, AC-6 | Maintainer runs the audit skill and reads the per-skill verdict table | Invoke `/CJ_portability-audit` in the workbench; read the printed table | A per-skill table appears: `CJ_document-release` OK (workbench within-tier), `CJ_suggest` OK (local-only + bundled own script), the orchestrators/`CJ_qa-work-item`/`CJ_implement-from-spec` shown (findings pre-adjudication; OK/adjudicated after pre-seed), each finding naming skill+dep+why | PASS if the table is scannable, verdicts are the three values, and each finding is actionable (names declared vs actual) |
| E2 | observability | AC-12 | Maintainer confirms the audit is non-no-op | Temporarily inspect the raw (pre-adjudication) findings via the documented flag/path | The five predicted skills appear with findings (declared `standalone`, reach root helpers / `.source`) — the D4 headline is demonstrated | PASS if all five predicted skills are present in the unadjudicated findings |
| E3 | integration | AC-11 | Maintainer runs the ONE Layer-2 dynamic case locally | Run `scripts/eval.sh --portability` for the `CJ_suggest` case against the stripped + `.source`-neutralized scratch repo (per the helper's docs) | The single case runs green within budget; `CJ_suggest` degrades gracefully in the stripped repo; the `--portability` mode + fixture-prep helper are proven to exist (broad coverage NOT attempted — Story 2) | PASS if the one case completes green and the run did NOT fall through to the real workbench `.source` (the redirect held) |
| E4 | integration | AC-7, AC-9 | Maintainer confirms advisory posture in a full validate run | Run `./scripts/validate.sh` with no `PORTABILITY_STRICT` | Portability findings print; `validate.sh` exits 0; no new hard failure introduced by this feature | PASS if exit code is 0 and the portability findings are visible in the output |

<!-- If an E2E test skill exists for this feature, reference it here. None for v1. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. Honesty beats false confidence. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Broad Layer-2 dynamic coverage across all runnable leaf skills + orchestrator partial runs | Deferred to Story 2 — re-imports the parked-eval-harness cost/flake (D000023); only ONE `CJ_suggest` proof-of-life case is in v1 scope | A runnable skill OTHER than `CJ_suggest` could fail in a stripped repo undetected until Story 2 wires broad coverage |
| Nightly-CI execution of the `--portability` job | Deferred to Story 2 (CI wiring) | The Layer-2 case is only run locally on demand in v1; no automated nightly signal yet |
| `PORTABILITY_STRICT=1` hard-fail behavior end-to-end | The default is advisory in v1; the strict path is documented but not the gate | A future strict flip could surface ordering/edge issues not exercised while the default is exit-0 |
| Heuristic graceful-degradation classifier accuracy (ref behind a `.source` fallback / presence guard) | v1 leans conservative (flag-and-adjudicate) rather than parsing the guard | A ref genuinely guarded by a presence check may be flagged as a finding and need manual `portability_requires` adjudication (false positive, surfaced not silent) |
