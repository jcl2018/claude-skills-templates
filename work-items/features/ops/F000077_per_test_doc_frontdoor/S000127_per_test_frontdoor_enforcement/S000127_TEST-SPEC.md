---
type: test-spec
parent: S000127
feature: F000077
title: "Per-test doc front-door enforcement — Test Specification"
version: 1
status: Draft
date: 2026-07-03
author: chang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0 AC.
     Smoke = automated regression (CI). E2E = manual user-scenario verification.
     Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic. AC column maps to a SPEC AC. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | Seed byte-identity after the rule edit | `spec/test-spec.md` equals the `--seed` heredoc output; the rule text is present in both | `bash tests/test-spec.test.sh` (the `cmp -s` / `--seed` case) |
| S2 | core | AC-4 | `--check-structure` content check flags a missing section and passes a complete doc | A per-test doc missing What/How/Why yields a finding; a complete one passes | `bash tests/test-spec.test.sh` (content-check present/missing-section fixtures) |
| S3 | resilience | AC-4 | Content check inactive without a categories axis | A registry with no `categories:` axis reports the content check inactive, exit 0 (no crash) | `bash tests/test-spec.test.sh` (no-categories fixture) |
| S4 | usability | AC-2 | Enriched `--seed-docs` template + idempotency | `--seed-docs` seeds a doc with the three sections + family cross-link; a re-run skips the present doc | `bash tests/test-spec.test.sh` (`--seed-docs` enriched + present-⇒-skip fixtures) |
| S5 | integration | AC-7 | Repo-wide contract green after registry + doc edits | doc-spec + test-spec validate; family render freshness unchanged | `bash scripts/validate.sh` (Checks 15/15a/16/24/26) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-3 | The 7 category docs read as real front doors | Open each of the 7 `docs/tests/<category>/<name>.md` files | Each has a filled What it is / How to run / Explanation and a working link to its family doc | Pass = all 7 have the three sections filled (not stubs) + a resolvable family-doc link; Fail = any stub or dead link |
| E2 | observability | AC-5 | `/CJ_test_audit` catches a rotted doc | Deliberately edit one per-test doc's How-to-run to a wrong command, run `/CJ_test_audit`, then revert | Stage 1 structure check stays green (section present) but Stage 2 flags the how-to-run mismatch with cited evidence | Pass = Stage 2 reports the untruthful doc; Fail = audit passes the wrong command |
| E3 | usability | AC-6 | Run and doc agree on the command | Run `/CJ_test_run <name>` for a known test (e.g. `validate`) | The output surfaces/links the per-test doc's How-to-run and it matches the executed command | Pass = doc How-to-run shown/linked and consistent with the run; Fail = missing or inconsistent |
| E4 | usability | AC-8 | Skills' docs describe the enforced model | Read `CJ_test_audit` + `CJ_test_run` SKILL.md/USAGE.md + their catalog descriptions | They describe the enforced per-test-doc-content model (What/How/Why + Stage-2 truthfulness / How-to-run surfacing) | Pass = docs match implemented behavior; Fail = stale description |

<!-- If an E2E test skill exists for this feature, reference it here. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Consumer-repo propagation of the seed rule on next contract seed | Requires an adopting repo; out of this repo's CI scope | A consumer might lag until its next seed; the rule is additive and portable, so low risk |
| Exhaustive per-family cross-link correctness for every unit | Smoke checks section presence + one link per doc, not every family mapping | A mis-targeted family link in one doc could slip; E1 manual review is the backstop |
| Stage-2 agent judgment determinism | Agent-judged, not a deterministic assertion | Stage-2 verdict may vary; the deterministic Stage-1 structure check is the hard gate |
