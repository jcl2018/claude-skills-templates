---
type: test-spec
parent: S000105
feature: F000063
title: "doc-spec table-ification + test-spec/gate-spec full merge — Test Specification"
version: 1
status: Draft
date: 2026-06-12
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together cover every SPEC P0
     acceptance criterion. Smoke = automated regression (CI). E2E = manual
     user-scenario verification before /ship. Soft cap: 5 rows per tier. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | 3-way seed identity | `spec/doc-spec.md` is byte-identical to `doc-spec.sh --seed` and `templates/doc-spec-common.md`, and contains no fenced-YAML block | `diff <(scripts/doc-spec.sh --seed) spec/doc-spec.md && diff spec/doc-spec.md templates/doc-spec-common.md && ! grep -q '^\`\`\`yaml' spec/doc-spec.md` |
| S2 | core | AC-2 | `--check-on-disk` runs 4 checks | Output reports `CHECKS_RUN=4`; human-doc-ids check present; `--render`/`--list-front-table-docs` removed | `scripts/doc-spec.sh --check-on-disk \| grep -q 'CHECKS_RUN=4' && ! scripts/doc-spec.sh --render 2>/dev/null` |
| S3 | integration | AC-3 | Retired files gone + grep-clean | None of the 5 retired files exist; no live reference remains | `! ls docs/doc-general.md docs/doc-custom.md scripts/generate-doc-views.sh scripts/gate-spec.sh spec/gate-spec.md 2>/dev/null && ! grep -rE 'generate-doc-views\|gate-spec\.(sh\|md)\|doc-(general\|custom)\.md' scripts skills docs tests` |
| S4 | core | AC-4 | test-spec `--validate` accepts layers[] + gates[] | `test-spec.sh --validate` exits 0 with the merged registry; general byte-identical to `--seed` | `scripts/test-spec.sh --validate && diff <(scripts/test-spec.sh --seed) spec/test-spec.md` |
| S5 | resilience | AC-5, AC-6 | Suite green + checks 20/23 gone | `validate.sh` + `test.sh` pass; Check 20 + Check 23 banners absent; Check 22 advisory inside Check 24 | `scripts/validate.sh && scripts/test.sh && ! scripts/validate.sh \| grep -qE 'Check 20\|Check 23'` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     Each row is one user-visible scenario. AC column maps to a SPEC AC. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-7 | Audit skills run clean standalone in a bare repo | In a fresh temp git repo, run `/CJ_doc_audit` then `/CJ_test_audit`; each seeds its contract, then re-run each | Both seed on first run (`seeded: yes`), run Stage 1 clean (`CHECKS_RUN=4` for doc; coverage-inactive for test), and report `seeded: no` idempotently on re-run | PASS if both audits seed + run with no engine error and the doc audit shows 4 checks; FAIL on any seed/parse error |
| E2 | usability | AC-7 | Audit skills run clean in this workbench | From the workbench root, run `/CJ_doc_audit` and `/CJ_test_audit` | Doc audit reports `CHECKS_RUN=4` + clean Stage 1; test audit validates the merged `layers[]`/`units:`/`gates:` registry and runs coverage cross-check | PASS if both run with no findings attributable to the format change; FAIL if a retired surface (`--render`, gate-spec) is still invoked |
| E3 | integration | AC-6 | cj_goal pipeline cites test-spec as canonical gate sequence | Open each of the four cj_goal `{pipeline,SKILL}.md` and locate the canonical-gate-sequence reference | Every reference names `spec/test-spec.md`; none names gate-spec | PASS if all four cite test-spec.md; FAIL on any surviving gate-spec cite |

<!-- Post-ship rows: none — all rows are verifiable pre-merge from the branch. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Behavior of the table parser on a malformed cell containing a literal `\|` | No current doc/requirement uses a pipe; the parser rejects it but no fixture exercises every malformed shape | A future requirement text with a pipe would be caught at edit time by `--validate`, not silently mis-parsed |
| Per-mode marker-drift advisory path under an actual induced drift | Inducing a real marker drift across four pipelines is heavy for a smoke row; S5 asserts the disposition (advisory) structurally | An advisory finding that silently became hard-fail would surface as a red suite, caught by S5 |
| Downstream consumer repos that already seeded the OLD doc-spec/test-spec format | Out of scope — this workbench owns the seed; consumers re-seed on next audit | A stale-format consumer re-seeds via `--seed` on its next `/CJ_doc_audit` / `/CJ_test_audit` run |
